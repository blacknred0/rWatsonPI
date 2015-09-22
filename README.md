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
	fetch <- getPI("https://www.example.com", df.sel$text, ssl=TRUE) #store PI JSON results. transfer will be encrypted. if you do not want encryption, simply remove ssl
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

# rWatsonPI meets CURL natively instead of form
## Install and setup
If you want to use curl natively on Linux or Mac, you are set.  Now, if you want to use it on Windows, there is some configuration that needs to take place.
1. Download curl zip
2. Extract all file and folders
3. Move parent folder (e.g. curl-7.27.0-rtmp-ssh2-ssl-sspi-zlib-idn-static-bin-w32) into a directory of your choice. (e.g. C:\curl\curl.exe)
4. To run curl from the command line
a) Right-hand-click on "My Computer" icon
b) Select Properties
c) Click "Advanced system settings" link
d) Go to tab "Advanced" and click "Environment Variables"
e) Under "System variables" select "Path" and click "Edit"
f) Add a semicolon followed by the path to where you curl.exe is located (e.g. ;C:\curl)
g) Now, Under "User variables for username" select "Path" and click "Edit"
h) Add a semicolon followed by the path to where you curl.exe is located (e.g. ;C:\curl)
Now you can run from the command line by typing:
```
	curl www.google.com
```

## Config to work with SSL
You do not need to do this unless you want to use SSL.  You do have the option to send data unencrypted.  

Here are the steps to get it configured.
1. Go to [CA cert page](http://curl.haxx.se/docs/caextract.html) 
2. Download "cacert.pem" by saving into your computer
3. Move "cacert.pem" into "C:\curl" folder

Now that you have the environment configured, then you should be able to use getPI2() function from rWatsonPI.
For more information on how to work with SSL certificates here is the [direct link](http://curl.haxx.se/docs/sslcerts.html) to the documentation.

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
    fetch <- getPI2("https://gateway.watsonplatform.net/personality-insights/api/v2/profile", df.sel$text, usr="bunch-of-ugly-letters-and-numbers-from-blue-mix", pwd="something-really-hard-to-remember") #store PI JSON results.
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