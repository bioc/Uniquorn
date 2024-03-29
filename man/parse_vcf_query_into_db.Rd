% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Add_custom_vcfs.R
\name{parse_vcf_query_into_db}
\alias{parse_vcf_query_into_db}
\title{parse_vcf_query_into_db
This function adds the variants of parsed custom CCLs to a monet DB instance}
\usage{
parse_vcf_query_into_db(
  g_query,
  ref_gen = "GRCH37",
  library_name,
  test_mode = FALSE
)
}
\arguments{
\item{g_query}{a GenomicRanges object}

\item{ref_gen}{a character string specifying the reference genome version.
All training sets are associated with a reference genome version.
Default is \code{"GRCH37"}.}

\item{library_name}{a character string giving the name of the library to add
the cancer cell lines to. Default is \code{"CUSTOM"}. 
Library name will be automatically added as a suffix to the identifier.}

\item{test_mode}{Is this a test? Just for internal use}
}
\value{
Message wheather the adding was successful
}
\description{
parse_vcf_query_into_db
This function adds the variants of parsed custom CCLs to a monet DB instance
}
