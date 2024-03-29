% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Match_query_ccl_with_database.R
\name{match_query_ccl_to_database}
\alias{match_query_ccl_to_database}
\title{match_query_ccl_to_database}
\usage{
match_query_ccl_to_database(
  g_query,
  ref_gen = "GRCH37",
  library_name,
  mutational_weight_inclusion_threshold
)
}
\arguments{
\item{g_query}{IRanges object that contains the variants}

\item{ref_gen}{Reference genome version. All training sets are 
associated with a reference genome version. Default: GRCH37}

\item{library_name}{a character string giving the name of the library}

\item{mutational_weight_inclusion_threshold}{a numerical giving
the lower bound for mutational weight to be included}
}
\value{
The R Table sim_list which contains the CoSMIC CLP fingerprints
}
\description{
Matches query ccl to the database
}
