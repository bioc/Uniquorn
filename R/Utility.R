#' inititate_db_and_load_data
#' 
#' Intern utility function, loads database and return the sim_list and sim_list_stats variables.
#' 
#' @inheritParams identify_vcf_file
#' @param request_table Names of the tables to be extracted from the database
#' @return the sim_list and sim_list_stats variable
#' @usage 
#' inititate_db_and_load_data(
#' ref_gen = "GRCH37", 
#' distinct_mode = TRUE,
#' request_table = "sim_list" )
#' @import DBI RSQLite
inititate_db_and_load_data = function( ref_gen, distinct_mode, request_table ){
    
    package_path    = system.file("", package="Uniquorn")
    
    if (distinct_mode)
        database_path =  paste( package_path, "uniquorn_distinct_panels_db.sqlite", sep ="/" )

    if (!distinct_mode)
        database_path =  paste( package_path, "uniquorn_non_distinct_panels_db.sqlite", sep ="/" )
    
    if( ! file.exists( database_path ) ){

        database_path =  paste( package_path, "uniquorn_db_default.sqlite", sep ="/" )
        warning("CCLE & CoSMIC CLP cancer cell line fingerprint NOT found, defaulting to 60 CellMiner cancer cell lines! 
                    It is strongly advised to add ~1900 CCLE & CoSMIC CLs, see readme.")
    }
    
    drv = RSQLite::SQLite()
    con = DBI::dbConnect(drv, dbname = database_path)
    
    res = as.data.frame( DBI::dbReadTable( con, request_table) )

    DBI::dbDisconnect(con)
    
    return( res )
}

#' write_data_to_db
#' 
#' Intern utility function, writes to database the sim_list and sim_list_stats variables
#' 
#' @inheritParams identify_vcf_file
#' @param sim_list R Table which contain a mapping of mutations to cancer cell lines for a specific reference genome
#' @param sim_list_stats Contains an aggergated R table that shows the amount and weight of mutations for a reference genome
#' @param content_table Tables to be written in db
#' @param table_name Name of the table to be written into the DB
#' @param overwrite Overwrite the potentially existing table
#' @param test_mode Is this a test? Just for internal use 
#' @return the sim_list and sim_list_stats variable
#' @usage 
#' write_data_to_db( 
#' content_table = sim_list, 
#' table_name = "sim_list_stats",
#' ref_gen = "GRCH37",
#' distinct_mode = TRUE,
#' overwrite = TRUE,
#' test_mode = FALSE )
#' @import DBI RSQLite
write_data_to_db = function( content_table, table_name, ref_gen = "GRCH37", distinct_mode = TRUE, overwrite = TRUE, test_mode = FALSE ){
    
    package_path    = system.file("", package="Uniquorn")
    
    if (distinct_mode)
        database_path =  paste( package_path, "uniquorn_distinct_panels_db.sqlite", sep ="/" )

    if (!distinct_mode)
        database_path =  paste( package_path, "uniquorn_non_distinct_panels_db.sqlite", sep ="/" )
    
    if( ! file.exists( database_path ) ){
        warning("Writing to default database! This is not recommended. Please consider adding the CCLE and CoSMIC training sets for optimal Uniquorn function.")
        database_default_path =  paste( package_path, "uniquorn_db_default.sqlite", sep ="/" )
        database_path = database_default_path
    }
    
    drv = RSQLite::SQLite()
    con = DBI::dbConnect(drv, dbname = database_path)
    
    if( test_mode )
        con = DBI::dbConnect(drv, dbname = "")
    
    DBI::dbWriteTable( con, name = table_name, value = as.data.frame( content_table ), overwrite = overwrite )
    
    DBI::dbDisconnect(con)

}

#' Re-calculate sim_list_weights
#' 
#' This function re-calculates the weights of mutation after a change of the training set
#' @inheritParams write_data_to_db
re_calculate_cl_weights = function( sim_list, ref_gen, distinct_mode ){
    
    package_path    = system.file("", package="Uniquorn")
    
    list_of_cls = unique( as.character( sim_list$CL ) )
    panels = sapply( list_of_cls, FUN = stringr::str_split, "_"  )
    panels = as.character(unique( as.character( sapply( panels, FUN = utils::tail, 1) ) ))
    
    if (!distinct_mode){
        panels = paste0( c(panels), collapse ="|"  )
        database_path =  paste( package_path, "uniquorn_non_distinct_panels_db.sqlite3", sep ="/" )
    }
    
    print( paste( "Distinguishing between panels:",paste0( c(panels), collapse = ", "), sep = " ") )
    
    for (panel in panels) {
        
        print(panel)
        
        sim_list_panel   = sim_list[ grepl( panel, sim_list$CL) , ]
        member_var_panel = rep( 1, dim(sim_list_panel)[1] )
        
        sim_list_stats_panel = stats::aggregate( member_var_panel , by = list( sim_list_panel$CL ), FUN = sum )
        colnames(sim_list_stats_panel) = c( "CL", "Count" )
        
        print("Aggregating over mutational frequency to obtain mutational weight")
        
        weights_panel = stats::aggregate( member_var_panel , by = list( sim_list_panel$Fingerprint ), FUN = sum )
        weights_panel$x = 1.0 / as.double( weights_panel$x )
        
        mapping_panel = match( as.character( sim_list_panel$Fingerprint ), as.character( weights_panel$Group.1) )
        sim_list_panel = cbind( sim_list_panel, weights_panel$x[mapping_panel] )
        colnames( sim_list_panel )[3] = "Weight"
        
        # calculate weights
        
        aggregation_all_panel = stats::aggregate( 
            x  = as.double( sim_list_panel$Weight ),
            by = list( as.character( sim_list_panel$CL ) ),
            FUN = sum
        )
        
        mapping_agg_stats_panel = which( aggregation_all_panel$Group.1 %in% sim_list_stats_panel[,1], arr.ind = TRUE  )
        sim_list_stats_panel = cbind( sim_list_stats_panel, aggregation_all_panel$x[mapping_agg_stats_panel] )
        
        #print("Finished aggregating, writing to database")
        
        Ref_Gen = rep(ref_gen, dim(sim_list_panel)[1]  )
        sim_list_panel = cbind( sim_list_panel, Ref_Gen )
        Ref_Gen = rep( ref_gen, dim(sim_list_stats_panel)[1]  )
        sim_list_stats_panel = cbind( sim_list_stats_panel, Ref_Gen )
        colnames( sim_list_stats_panel ) = c( "CL","Count","All_weights","Ref_Gen" )
        
        if(! exists("sim_list_global"))
            sim_list_global <<- sim_list[0,]
        
        sim_list_global = rbind(sim_list_global,sim_list_panel)
        
        if(! exists("sim_list_stats_global"))
            sim_list_stats_global <<- sim_list_stats_panel[0,]
        
        sim_list_stats_global = rbind( sim_list_stats_global, sim_list_stats_panel  )
        
    }
    
    return( c( sim_list_global, sim_list_stats_global ) )
}