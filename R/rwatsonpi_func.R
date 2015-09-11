# Copyright 2015 IBM Corp. All Rights Reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# 	http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Package(s) Health Check
#'
#' This function runs proper packages install if they don't exist on the library and then load those packages.
#' @keywords package install healthchecks
#' @export
#' @examples
#' pkgHC()
pkgHC <- function(){
	pkgs <- c("plyr", "RCurl", "rjson", "textcat") #update this section with the required packages
	npkgs <- pkgs[!(pkgs %in% installed.packages()[,"Package"])] #check library if package is not installed
	if(length(npkgs)) install.packages(npkgs, dependencies=TRUE, repos="http://cran.us.r-project.org") #if it is not installed, then install package with dependencies
	
	lapply(pkgs, require, character.only=T) #load require packages once they are all installed
}

#' Start Personality Insights (PI)
#'
#' ---NOTE: For Windows user only---. Start PI server and don't wait for anything to finish.  After using this, the user needs to remember to run stopPI() to stop server.
#' @keywords node.js start server
#' @export
#' @examples
#' startPI(x="C:/local_path_to_watson-developer-cloud/personality-insights-nodejs")
startPI <- function(x){
	cat("\n Starting Node.js...")
	cat("\n Please wait for about 5-10 seconds and don't forget to run stopPI() function when you are done with your batches. \n")
	# Start PI server and don't wait for anything to finish
	system(paste("C:/Windows/system32/cmd.exe /c cd ", x, " & node app.js", sep=""), wait=FALSE)
}

#' Stop Personality Insights (PI)
#'
#' ---NOTE: For Windows user only---. Kill PI server by filtering to image name and prompt output whether the kill was successful or not.  Note that this will only work on Win7 of above where the "taskkill" command is available.  Also, the user will get feedback when the server has been fully stop.
#' @keywords win7 taskkill stop server
#' @export
#' @examples
#' stopPI()
stopPI <- function(){
	# Kill PI server by filtering to image name and prompt output
	# whether the kill was successful or not
	system("taskkill /F /IM node.exe", intern=FALSE)
}

#' Clean Text fields
#'
#' Clean text field so there are less issues when posting the data to PI.  This function will only leaves letters and numbers and remove multiple and trailing spaces and characters that are now UTF-8.
#' @param x would be the field that wanted to be formatted.
#' @keywords clean text field
#' @export
#' @examples
#' x$field <- clnTxt(x$field) # You can opt to store your clean values on a new field
clnTxt <- function(x) {
	x <- gsub("[^0-9A-Za-z ]", " ", x) # only leaves letters and numbers
	x <- gsub("^ *|(?<= ) | *$", "", x, perl=TRUE) # remove multiple and trailing spaces
	#In internationalization, CJK is a collective term for the Chinese, Japanese, and Korean (CJK unicode). 
	#This convert character vector between encoding by using system encoding for internationalization.  If the character doesn't exist on current encoding, then it will be removed.
	iconv(x, "UTF-8", "ASCII", sub="")
	
	return(x)
}

#' Select meaningful records
#'
#' This clean up will allow PI to run smooth where records that might not meet the criteria below will be removed: 
#' The number of words X is less than the minimum number of words required for analysis: 100 AND 
#' The input you provided matched X words from our lexicon, we require 70 matching words to calculate characteristics with any confidence AND 
#' Too many words .... greater than 10k.  These could be run manually in the tool instead of using RCURL as there is a max limitation  AND
#' The records need to be in English in order to fully be process through Watson PI.
#' This will produce two new vars, df.sel and df.notsel, where df.sel will be the records that meet the criteria and df.notsel would be the records that did not meet criteria.  At this point the user should be able to do a write.table() and export those records and do it manually where applicable.
#' @param x would be the field that wanted to be formatted.
#' @keywords clean text field
#' @export
#' @examples
#' selMeaningfulRecs(x, x$txt)
selMeaningfulRecs <- function(x, txt) {
	x$wcl <- ifelse(sapply(gregexpr("\\W+", txt), length) + 1 > 325, TRUE, FALSE) # count of word per record and if greater than 325, mark as true
	x$wcg <- ifelse(sapply(gregexpr("\\W+", txt), length) + 1 < 10000, TRUE, FALSE) # count of word per record and if less than 10000, mark as true
	x$lang <- textcat(txt) # get text nearest language
	x$le <- x$lang=='english' # classify with true or false for filtering

	for(i in 1:length(txt)){
		if(x$wcl[i]==TRUE & x$wcg[i]==TRUE & x$le[i]==TRUE){
			xs <- x[ which(x$wcl==TRUE & x$wcg==TRUE & x$le==TRUE), ] # only select those records where the count of words are greater than 325 and less than 10000 and the text is mostly in english
			df.sel <<- xs[, 1:2] # only select needed columns
		}
		else{
			xns <- x[ which(x$wcl==FALSE | x$wcg==FALSE | x$le==FALSE), ] # only select those records where the count of words are not greater than 325 or less than 10000 or not mostly in english
			df.notsel <<- xns[, 1:2] # only select needed columns
		}
	}
	
	cat("\n New data frame got created with the following variable name -> df.sel.  \n For the records not selected, they will be stored in data frame -> df.notsel.")
	cat("\n You can run a write.table() to export those variables and you might be able to run them manually against the PI server. \n")
}

#' Get PI data results
#'
#' This function will post the data from R into PI as JSON format and store it back to R.
#' User will have the capability of encrypting with server (which it is not default).  This would have to be enable since the script is configured to be run with Node.js locally.
#' @keywords download pi rcurl
#' @export
#' @examples
#' new.x1 <- getPI(url="http://www.example.com", x=data$field, dump=NULL) # store results into new var x2
#' new.x2 <- getPI(url="https://www.example.com", x=data$field, dump=NULL, ssl=TRUE) # store results into new var x2, but information is encrypted with server
getPI <- function(url, x, dump, ssl=FALSE){
	dump = NULL;
	
	if(ssl==FALSE & substring(url, 0, 5)=="https"){
		cat("\n Please run with ssl=TRUE to ensure that you get your results back. \n")
	}
	else if(ssl==FALSE){
		if(url.exists(url)){
			for (i in 1:length(x)){
				dump[i] <- postForm(url, 
									text = x[i], 
									button = "Analyze",
									httpheader=c('Host'=paste("\"", url, "\"", sep=""), 'User-Agent'="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20100101 Firefox/31.0", 'Accept'="application/json, text/javascript, */*; q=0.01", 'Accept-Language'="en-US,en;q=0.5", 'Accept-Encoding'="gzip, deflate", 'Content-Type'="application/x-www-form-urlencoded; charset=UTF-8", 'X-Requested-With'="XMLHttpRequest", 'Referer'=paste("\"http://", url, "\"", sep="")), 
									style="post")
				# progress is being made in the loop
				pb <- txtProgressBar(min=1, max=length(x), style=3) #style=3 would allow to see the percent and no new lines would be added while it loops through
				setTxtProgressBar(pb, i)
				Sys.sleep(runif(1, 2, 5)) #randomly put the system to sleep after each URL is being fetched - between 2 to 5 seconds
				# perform a system clean-up by removing the user name and password from the vector
				# once all of the variables have been counted for
				if(i==length(x)){
					close(pb); remove(pb) # close and remove the progress bar connection
					cat("\n Done fetching.  If you are running this on your localhost DO NOT forget to run stopPI() \n")
				}
			}
		}
		else{
			cat("Error in URL since it doesn't exist\n")
		}
	}
	else{
		# set SSL certs globally.  IF this is not set, then the secure connection will
		# not take place when connecting to URL.
		options(RCurlOptions = list(cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")))
		if(url.exists(url)){
			for (i in 1:length(x)){
				dump[i] <- postForm(url, 
									text = x[i], 
									button = "Analyze",
									httpheader=c('Host'=paste("\"", url, "\"", sep=""), 'User-Agent'="Mozilla/5.0 (Windows NT 6.1; WOW64; rv:31.0) Gecko/20100101 Firefox/31.0", 'Accept'="application/json, text/javascript, */*; q=0.01", 'Accept-Language'="en-US,en;q=0.5", 'Accept-Encoding'="gzip, deflate", 'Content-Type'="application/x-www-form-urlencoded; charset=UTF-8", 'X-Requested-With'="XMLHttpRequest", 'Referer'=paste("\"https://", url, "\"", sep="")), 
									style="post")
				# progress is being made in the loop
				pb <- txtProgressBar(min=1, max=length(x), style=3) #style=3 would allow to see the percent and no new lines would be added while it loops through
				setTxtProgressBar(pb, i)
				Sys.sleep(runif(1, 2, 5)) #randomly put the system to sleep after each URL is being fetched - between 2 to 5 seconds
				# perform a system clean-up by removing the user name and password from the vector
				# once all of the variables have been counted for
				if(i==length(x)){
					close(pb); remove(pb) # close and remove the progress bar connection
					cat("\n Done fetching remote and encrypted.\n")
				}
			}
		}
		else{
			cat("Error in URL since it doesn't exist\n")
		}
	}
	
	return(dump)
} #fget

#' Format JSON field
#'
#' This function will format JSON field by making it uniform and removing "word_count_message".  This is a result form PI if the word count is too low.  It will also add the person name from the data frame.
#' @param x would be the field that wanted to be formatted.
#' @keywords json format clean
#' @export
#' @examples
#' clean.json <- fmtJSON(x, pname="Joe Doe") # Format JSON by adding person name
fmtJSON <- function(x, pname){
	# do some data clean up to make the JSON uniform
	x <- gsub(",\"word_count_message\":\"There were \\d+.* words in the input. We need a minimum of 3,500, preferably 6,000 or more, to compute statistically significant estimates\"", "", x) # find and replace if record contains word_count_message and replace it with nothing
	
	# only select the dataset after the first { bracket }"
	x <- paste("{\"person\":\"", pname, "\",", substring(x, 2), sep="") # add person profile prior of output
	
	return(x)
}

#' Export PI data to CSV
#'
#' This function will export the clean JSON vector into a CSV file.
#' @keywords json csv clean
#' @export
#' @examples
#' exportPI(x) # create CSV based on x
exportPI <- function(x){
	# export by grouping all of the variables at once
	for (i in 1:length(x)){
		if(i==1){
			write.table(fromJSON(x[i]), paste("system_u", ".csv", sep=""), sep=",", row.names=FALSE, append=FALSE) #export the data on a csv format
		}
		else{
			write.table(fromJSON(x[i]), paste("system_u", ".csv", sep=""), sep=",", row.names=FALSE, append=TRUE, col.names=FALSE) #append data and don't include column names
		}
	} #write.csv(fget[1], "system_u_debug.csv")
}