
<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip) [![Travis-CI Build Status](https://travis-ci.org/OJWatson/rdhs.png?branch=master)](https://travis-ci.org/OJWatson/rdhs) [![codecov.io](https://codecov.io/github/OJWatson/rdhs/coverage.svg?branch=master)](https://codecov.io/github/OJWatson/rdhs?branch=master)

`rdhs` is a package for management and analysis of [Demographic and Health Survey (DHS)](www.dhsprogram.com) data. This includes functionality to:

1.  Access standard indicator data (i.e. [DHS STATcompiler](https://www.statcompiler.com/)) in R via the [DHS API](https://api.dhsprogram.com/).
2.  Identify surveys and datasets relevant to a particular analysis.
3.  Download survey datasets from the [DHS website](https://dhsprogram.com/data/available-datasets.cfm).
4.  Load datasets and associated metadata into R.
5.  Extract variables and combining datasets for pooled multi-survey analyses.

------------------------------------------------------------------------

Motivation
----------

The Demographic and Health Surveys (DHS) Program has collected and disseminated population survey data from over 90 countries for over 30 years. In many countries, DHS provide the key data that mark progress towards targets such as the Sustainable Development Goals (SDGs) and inform health policy such as detailing trends in child mortality and characterising the distribution of use of insecticide-treated bed nets in Africa. Though standard health indicators are routinely published in survey final reports, much of the value of DHS is derived from the ability to download and analyse standardized microdata datasets for subgroup analysis, pooled multi-country analysis, and extended research studies. The suite of tools within `rdhs` hopes to extend the accessibility of these datasets to more researchers within the global health community, who are increasingly using R for their statistical analysis, and is the output of conversations with numerous research groups globally. The end result aims to increase the end user accessibility to the raw data and create a tool that supports reproducible global health research, as well as simplifying commonly required analytical pipelines.

Installation
------------

You can install rdhs from github with:

``` r
# install.packages("devtools")
devtools::install_github("OJWatson/rdhs")
```

Further vignettes
-----------------

TODO: An example workflow using `rdhs` to calculate trends in anemia prevalence is available [here](INSERT%20LINK).

TODO: Full functionality is described in the tutorial [here](INSERT%20LINK).

Basic Functionality
-------------------

This is a basic example which shows you how to follow the 5 steps above to quickly identify, download and extract datasets you are interested in. The introductory vignette goes into more detail on each of these steps.

Let's say we want to get all the survey data from the Democratic Republic of Congo and Tanzania in the last 5 years (since 2013), which covers the use of rapid diagnostic tests (RDTs) for malaria. To begin we'll interact with the DHS API to identify our datasets.

To start our extraction we'll query the *surveyCharacteristics* endpoint using `dhs_surveyCharacteristics()`:

``` r
library(rdhs)
## make a call with no arguments
sc <- dhs_surveyCharacteristics()
sc[grepl("Malaria",sc$SurveyCharacteristicName),]
#>    SurveyCharacteristicID SurveyCharacteristicName
#> 1:                     96            Malaria - DBS
#> 2:                     90     Malaria - Microscopy
#> 3:                     89            Malaria - RDT
#> 4:                     57          Malaria module 
#> 5:                      8 Malaria/bednet questions
```

We can now pass that through to `dhs_surveys()` to grab the suveys for the countries and years we are interested in.

``` r
## what are the countryIds - we can find that using this API request
ids <- dhs_countries(returnFields=c("CountryName","DHS_CountryCode"))

## lets find all the surveys that fit our search criteria
survs <- dhs_surveys(surveyCharacteristicIds = 89,countryIds = c("CD","TZ"),surveyYearStart = 2013)

# and lastly use this to find the datasets we will want to download and let's download the spss (.sav) datasets (have a look in the dhs_datasets documentation for all argument options, and fileformat abbreviations etc.), and the household member recodes that details the children under 5s RDT status.
datasets <- dhs_datasets(surveyIds = survs$SurveyId, fileFormat = "SV", fileType = "PR")
str(datasets)
#> Classes 'data.table' and 'data.frame':   2 obs. of  13 variables:
#>  $ FileFormat          : chr  "SPSS dataset (.sav)" "SPSS dataset (.sav)"
#>  $ FileSize            : int  8364572 6949533
#>  $ DatasetType         : chr  "Survey Datasets" "Survey Datasets"
#>  $ SurveyNum           : int  421 485
#>  $ SurveyId            : chr  "CD2013DHS" "TZ2015DHS"
#>  $ FileType            : chr  "Household Member Recode" "Household Member Recode"
#>  $ FileDateLastModified: chr  "September, 19 2016 09:56:47" "December, 09 2016 14:08:46"
#>  $ SurveyYearLabel     : chr  "2013-14" "2015-16"
#>  $ SurveyType          : chr  "DHS" "DHS"
#>  $ SurveyYear          : int  2013 2015
#>  $ DHS_CountryCode     : chr  "CD" "TZ"
#>  $ FileName            : chr  "CDPR61SV.ZIP" "TZPR7HSV.ZIP"
#>  $ CountryName         : chr  "Congo Democratic Republic" "Tanzania"
#>  - attr(*, ".internal.selfref")=<externalptr>
```

We can now download our datasets. To do this we need to first create a `client`, which will be used to log in to your DHS account, download datasets for you, and help query those datasets for the question you are interested in.

To create our client we use the `client()` function and you need to specify your log in credentials for the DHS website as a file containing your email, password and project (see main vignette for specific line formats here).

``` r
## create a client
client <- client(credentials = "credentials")
```

Before we use our client to download our datasets, it is worth mentioning that the client can be passed as an argument to any of the API functions we have just seen. This will then cache the results for you, so that if you are working remotely or without a good internet connection you can still return your previous API requests:

``` r
# before it's cached we provide the client so the results is cached within our client
s <- dhs_surveys(client = client)

# with it cached now we will be able to instantly get our results
s <- dhs_surveys(client = client)
```

Now back to our dataset downloads:

``` r
# download datasets
downloads <- client$download_datasets(datasets$FileName)

str(downloads)
#> List of 2
#>  $ CDPR61SV: chr "C:\\Users\\Oliver\\AppData\\Local\\Oliver\\rdhs\\Cache/datasets/CDPR61SV.rds"
#>  $ TZPR7HSV: chr "C:\\Users\\Oliver\\AppData\\Local\\Oliver\\rdhs\\Cache/datasets/TZPR7HSV.rds"
#>  - attr(*, "reformat")= logi FALSE
```

The function returns a list with a file path to where the downloaded dataset has been saved to. We can then read in one of these datasets:

``` r
# read in our dataset
cdpr <- readRDS(downloads$CDPR61SV)
```

The dataset returned here is a list that contains the *dataset*, which has the survey data stored as a labelled class (see `haven::labelled` or our introduction vignette for more details). It also contains a data.frame called *variable\_names*. This contains all the survey questions within the dataset, and what their survey variable is, e.g. for RDT results it is *hml35*.

The saved datasets allow us to quickly query survey questionss:

``` r
# rapid diagnostic test search
questions <- client$survey_questions(datasets$FileName,search_terms = "malaria rapid test")
```

We an then use the questions to extract our datasets. We also have the option to add any geographic data available:

``` r
# and now extract the data
extract <- client$extract(questions,add_geo = TRUE)
#> Starting Survey 1 out of 2 surveys:CDPR61SV
#> Loading required package: sp
#> Warning: package 'sp' was built under R version 3.4.3
#> Starting Survey 2 out of 2 surveys:TZPR7HSV
```

The resultant extract is a list, with a new element for each different dataset that you have extracted.

We can also query our datasets for the survey question variables if we already know a list of survey variables we want:

``` r
# and grab the questions from this now utilising the survey variables
questions <- client$survey_variables(datasets$FileName,variables = c("hv024","hml35"))

# and now extract the data
extract2 <- client$extract(questions,add_geo = TRUE)
#> Starting Survey 1 out of 2 surveys:CDPR61SV
#> Starting Survey 2 out of 2 surveys:TZPR7HSV
```

We can now combine our two dataframes for further analysis using the `rdhs` package function `rbind_labelled()`. This function works specifically with our lists of labelled data.frames. We specify the labels we want for each variable: we want to keep all the hv024 labels (concatenate) but we want to recode the hml35 labels across both datasets to be "NegativeTest" and "PositiveTest".

``` r
# now let's try our second extraction
extract2_bound <- rbind_labelled(extract2, labels = list("hv024"="concatenate",
                                             "hml35"=c("NegativeTest"=0,"PositiveTest"=1)))
```

The other option is to not use the labelled class at all. We can control this when we download our datasets, using the argument `reformat=TRUE`. This will ensure that no factors or labels are used and it is just the raw data:

``` r
# grab the questions but specifying the reformat argument
questions <- client$survey_variables(datasets$FileName,variables = c("hv024","hml35"),
                                     reformat=TRUE)

# and now extract the data
extract3 <- client$extract(questions,add_geo = TRUE)
#> Starting Survey 1 out of 2 surveys:CDPR61SV
#> Starting Survey 2 out of 2 surveys:TZPR7HSV

# group our results
extract3_bound <- rbind_labelled(extract3)

# our hv024 variable is now just character strings, so you can decide when/how to factor/label it later
str(extract3_bound)
#> 'data.frame':    160829 obs. of  8 variables:
#>  $ hv024   : chr  "Equateur" "Equateur" "Equateur" "Equateur" ...
#>  $ hml35   : chr  NA NA NA NA ...
#>  $ CLUSTER : int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ ALT_DEM : int  407 407 407 407 407 407 407 407 407 407 ...
#>  $ LATNUM  : num  0.22 0.22 0.22 0.22 0.22 ...
#>  $ LONGNUM : num  21.8 21.8 21.8 21.8 21.8 ...
#>  $ ADM1NAME: chr  "Tshuapa" "Tshuapa" "Tshuapa" "Tshuapa" ...
#>  $ DHSREGNA: chr  "Equateur" "Equateur" "Equateur" "Equateur" ...
```
