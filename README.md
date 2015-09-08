# rWatsonPI
Load unstructured data to Watson Personality Insights (PI) via post Multipart/Form-data by interacting with PI API.  Such an interaction will be posted on JSON format and then stored back into R on the same format as well.  User will have the capabilities of reformatting the JSON file into a CSV and exporting such results for analysis.

## Personality Insights Nodejs Starter Application
The IBM Watson [Personality Insights](https://github.com/watson-developer-cloud/personality-insights-nodejs) service uses linguistic analysis to extract cognitive and social characteristics from input text such as email, text messages, tweets, forum posts, and more. By deriving cognitive and social preferences, the service helps users to understand, connect to, and communicate with other people on a more personalized level.

## Getting Started on remote environment
1. It is assumed that you already have some sort of BlueMix environment that you can use.  If you do not have one, you will need to have one created/configured.
2. From R console download and install package from GitHub
``` R
	install.packages("devtools")
	devtools::install_github("blacknred0/rwatsonpi")
```
3. Activate rWatsonPI package
``` R
    library("rwatsonpi") #activate library
	pkgHC() #download and install R packages
    df <- read.table("sample.csv", sep=",", quote = "\"", header=TRUE, fill=FALSE) #import sample csv into R
    df$text <- clnTxt(df$text) #clean records and replace field
	selMeaningfulRecs(df, df$text) #select meaningful records based on criteria
	fetch <- getPI("https://www.example.com", df.sel$text, ssl=TRUE) #store PI JSON results. tranfer will be encrypted. if you do not want encryption, simply remove ssl
    fj <- fmtJSON(fetch, df.sel$person) #attach identifier to results
	exportPI(fj) #export to csv
```

## Getting Started on local environment
1. It is assumed that you already have some sort of BlueMix environment that you can use.  If you do not have one, you will need to have one created/configured.
2. From R console download and install package from GitHub
``` R
	install.packages("devtools")
	devtools::install_github("blacknred0/rWatsonPI")
```
3. Activate rWatsonPI package
``` R
    library("rwatsonpi") #activate library
    df <- read.table("sample.csv", sep=",", quote = "\"", header=TRUE, fill=FALSE) #import sample csv into R
    df$text <- clnTxt(df$text) #clean records and replace field
	selMeaningfulRecs(df, df$text) #select meaningful records based on criteria
    startPI("C:/watson-developer-cloudpersonality-insights-nodejs") #location where personality insights is located
    fetch <- getPI("http://localhost:3000", df.sel$text) #store PI JSON results.
    fj <- fmtJSON(fetch, df.sel$person) #attach identifier to results
	exportPI(fj) #export to csv
    stopPI() 
```

## How to contribute
See [TODO](TODO) for list of enhancements that could be made.

## License
  This sample code is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).

## Open Source @ IBM
  Find more open source projects on the [IBM Github Page](http://ibm.github.io/)