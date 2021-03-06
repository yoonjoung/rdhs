% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_dhs_dta.R
\name{parse_map}
\alias{parse_map}
\title{Create dictionary from DHS .MAP codebook}
\usage{
parse_map(map, all_lower = TRUE)
}
\arguments{
\item{map}{A character vector containing .MAP file, e.g. from `readLines()`.}

\item{all_lower}{Logical indicating whether all value labels should be
converted to lower case}
}
\value{
A data frame containing metadata, principally variable labels and
  a vector of value labels.
}
\description{
Create dictionary from DHS .MAP codebook
}
\details{
Currently hardcoded for 111 char width .MAP files, which covers the
  vast majority
  of DHS Phase V, VI, and VIII. To be extended in the future and perhaps add other useful options.
}
\examples{
mrdt_zip <- tempfile()
download.file(
paste0(
"https://dhsprogram.com/customcf/legacy/data/sample_download_dataset.cfm",
"?Filename=ZZMR61DT.ZIP&Tp=1&Ctry_Code=zz&survey_id=0&doctype=dhs"),
mrdt_zip, mode="wb"
)

map <- rdhs::read_zipdata(mrdt_zip, "\\\\.MAP", readLines)
dct <- rdhs:::parse_map(map)

}
