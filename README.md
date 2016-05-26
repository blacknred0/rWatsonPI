# rWatsonPI
Load unstructured data to Watson Personality Insights (PI) by interacting with the API or via post Multipart/Form-data.  Such an interaction will be posted on JSON format and then stored back into R on the same format as well.  User will have the capabilities of reformatting the JSON file into a CSV and exporting such results for analysis.

## Personality Insights Nodejs Starter Application
The IBM Watson [Personality Insights](https://github.com/watson-developer-cloud/personality-insights-nodejs) service uses linguistic analysis to extract cognitive and social characteristics from input text such as email, text messages, tweets, forum posts, and more. By deriving cognitive and social preferences, the service helps users to understand, connect to, and communicate with other people on a more personalized level.

## Getting Started

### Install and activate package in R
1. From R console download and install package from GitHub
``` R
install.packages("devtools")
devtools::install_github("blacknred0/rwatsonpi")
```
2. Activate rWatsonPI package
``` R
library("rwatsonpi") #activate library
```

## Run rWatsonPI using cURL
---

### Install and setup
If you want to use curl natively on Linux or Mac, you are set.  Now, if you want to use it on Windows, there is some configuration that needs to take place.
1. Download curl zip
2. Extract all file and folders
3. Move parent folder (e.g. curl-7.27.0-rtmp-ssh2-ssl-sspi-zlib-idn-static-bin-w32) into a directory of your choice. (e.g. C:\curl\curl.exe)
4. To run curl from the command line
  1. Right-hand-click on "My Computer" icon
  2. Select Properties
  3. Click "Advanced system settings" link
  4. Go to tab "Advanced" and click "Environment Variables"
  5. Under "System variables" select "Path" and click "Edit"
  6. Add a semicolon followed by the path to where you curl.exe is located (e.g. ;C:\curl)
  7. Now, Under "User variables for username" select "Path" and click "Edit"
  8. Add a semicolon followed by the path to where you curl.exe is located (e.g. ;C:\curl)
Now you can run from the command line by typing:
```
curl www.google.com
```

### Configure to work with SSL
You do not need to do this unless you want to use SSL.  You do have the option to send data unencrypted.  

Here are the steps to get it configured.
1. Go to [CA cert page](http://curl.haxx.se/docs/caextract.html)
2. Download "cacert.pem" by saving into your computer
3. Move "cacert.pem" into "C:\curl" folder

Now that you have the environment configured, then you should be able to use getPI2() function from rWatsonPI.
For more information on how to work with SSL certificates here is the [direct link](http://curl.haxx.se/docs/sslcerts.html) to the documentation.

### Working with remote environment
Since there have been changes to Watson Personality Insights, this process/functions will be the default going forward.

1. It is assumed that you already have some sort of BlueMix environment that you can use.  If you do not have one, you will need to have one created/configured. Also, if you are on Windows you will need to configure [cURL](#Run-rWatsonPI-using-cURL)
2. [Make sure that you activate the package and necessary libraries](#Install-and-activate-package-in-R)
3. Run main script
``` R
df <- read.table("sample.csv", sep=",", quote = "\"", header=TRUE, fill=FALSE) #import sample csv into R
df$text <- clnTxt(df$text) #clean records and replace field
selMeaningfulRecs(df, df$text) #select meaningful records based on criteria
fetch <- getPI2("https://gateway.watsonplatform.net/personality-insights/api/v2/profile", df.sel$text, usr="bunch-of-ugly-letters-and-numbers-from-blue-mix", pwd="something-really-hard-to-remember") #store PI JSON results
fj <- fmtJSON(fetch, df.sel$person) #attach identifier to results
df.sel.t <- data.frame(person=df.sel$person)
exportPI(df.sel.t, fj, "nameofcsv") #export to csv
```

## Run rWatsonPI using forms
---

Prior of new implementation of Watson Personality Insights, you were able to use forms.  Now, if you would still like to use forms to post and retrieve your data, you might want to go to  [this commit](https://github.com/watson-developer-cloud/personality-insights-nodejs/commit/8cdaeaf3a9b1f5d0f9222432bcace3fd0110252a).

## Working with local environment
1. It is assumed that you already have some sort of BlueMix environment that you can use.  If you do not have one, you will need to have one created/configured.
2. Make sure that you activate the package and necessary libraries
3. Run main script
``` R
df <- read.table("sample.csv", sep=",", quote = "\"", header=TRUE, fill=FALSE) #import sample csv into R
df$text <- clnTxt(df$text) #clean records and replace field
selMeaningfulRecs(df, df$text) #select meaningful records based on criteria
startPI("C:/watson-developer-cloudpersonality-insights-nodejs") #location where personality insights is located
fetch <- getPI("http://localhost:3000", df.sel$text) #store PI JSON results. For Windows, add parameter "win=TRUE"
fj <- fmtJSON(fetch, df.sel$person) #attach identifier to results
df.sel.t <- data.frame(person=df.sel$person)
exportPI(df.sel.t, fj, "nameofcsv") #export to csv
stopPI()
```

## Working with remote environment
1. It is assumed that you already have some sort of BlueMix environment that you can use.  If you do not have one, you will need to have one created/configured.
2. Make sure that you activate the package and necessary libraries
3. Run main script
``` R
df <- read.table("sample.csv", sep=",", quote = "\"", header=TRUE, fill=FALSE) #import sample csv into R
df$text <- clnTxt(df$text) #clean records and replace field
selMeaningfulRecs(df, df$text) #select meaningful records based on criteria
fetch <- getPI("https://www.example.com", df.sel$text, ssl=TRUE) #store PI JSON results. transfer will be encrypted. if you do not want encryption, simply remove ssl. For Windows, add parameter "win=TRUE"
fj <- fmtJSON(fetch, df.sel$person) #attach identifier to results
df.sel.t <- data.frame(person=df.sel$person)
exportPI(df.sel.t, fj, "nameofcsv") #export to csv
```

# Issues

* If for some reason the package is not activating properly, you can force the download and activation of all required packages by invoking the following function.
``` R
pkgHC() #download and install R packages
```

# How to contribute

See [TODO](TODO) for list of enhancements that could be made.

# License

This sample code is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).

# Open Source @ IBM

Find more open source projects on the [IBM Github Page](http://ibm.github.io/)
