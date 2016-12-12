# Copyright 2016 IBM Corp. All Rights Reserved.
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
#' @import plyr
#' @export
#' @examples
#' pkgHC()
pkgHC <- function(){
	pkgs <- c("plyr", "RCurl", "jsonlite", "textcat") #update this section with the required packages
	npkgs <- pkgs[!(pkgs %in% installed.packages()[,"Package"])] #check library if package is not installed
	if(length(npkgs)) install.packages(npkgs, dependencies=TRUE, repos="http://cran.us.r-project.org") #if it is not installed, then install package with dependencies

	lapply(pkgs, require, character.only=T) #load require packages once they are all installed
}

#' Start Personality Insights (PI)
#'
#' ---NOTE: For Windows and Linux user only---. Start PI server and don't wait for anything to finish.  After using this, the user needs to remember to run stopPI() to stop server.
#' @keywords win7 linux node.js start server
#' @export
#' @examples
#' startPI(x="C:/local_path_to_watson-developer-cloud/personality-insights-nodejs")
startPI <- function(x){
	if(Sys.info()['sysname']=="Windows"){
		cat("\n Starting Node.js...")
		cat("\n Please wait for about 5-10 seconds and don't forget to run stopPI() function when you are done with your batches. \n")
		# Start PI server and don't wait for anything to finish
		system(paste("C:/Windows/system32/cmd.exe /c cd ", x, " & node app.js", sep=""), wait=FALSE)
		}
	if(Sys.info()['sysname']=="Linux"){
		cat("\n Starting Node.js...")
		cat("\n Please wait for about 5-10 seconds and don't forget to run stopPI() function when you are done with your batches. \n")
		# Start PI server and don't wait for anything to finish
		system(paste("cd ", x, " && node app.js", sep=""), wait=FALSE, ignore.stdout=TRUE)
	}
}

#' Stop Personality Insights (PI)
#'
#' ---NOTE: For Windows and Linux user only---. Kill PI server by filtering to image name and prompt output whether the kill was successful or not.  Note that this will only work on Win7 of above where the "taskkill" command is available and on Linux where "pkill" command is available.
#' @keywords win7 linux taskkill pkill stop server
#' @export
#' @examples
#' stopPI()
stopPI <- function(){
	if(Sys.info()['sysname']=="Windows"){
		# Kill PI server by filtering to image name and prompt output
		# whether the kill was successful or not
		system("taskkill /F /IM node.exe", intern=FALSE)
	}
	if(Sys.info()['sysname']=="Linux"){
		# Kill PI server by filtering to image name and prompt output
		# whether the kill was successful or not
		system("pkill node", intern=FALSE)
	}
}

#' Clean text fields
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
#' Keep will be the columns that you would like to keep once selection is processed.
#' @param x would be the field that wanted to be formatted.
#' @keywords clean text field
#' @import textcat
#' @export
#' @examples
#' selMeaningfulRecs(x, x$txt, keep=c("var1", "var2", "var3"))
selMeaningfulRecs <- function(x, txt, keep) {
	x$wcl <- ifelse(sapply(gregexpr("\\W+", txt), length) + 1 > 325, TRUE, FALSE) # count of word per record and if greater than 325, mark as true
	x$wcg <- ifelse(sapply(gregexpr("\\W+", txt), length) + 1 < 10000, TRUE, FALSE) # count of word per record and if less than 10000, mark as true
	x$lang <- textcat(txt) # get text nearest language
	x$le <- x$lang=='english' # classify with true or false for filtering

	for(i in 1:length(txt)){
		if(x$wcl[i]==TRUE & x$wcg[i]==TRUE & x$le[i]==TRUE){
			xs <- x[ which(x$wcl==TRUE & x$wcg==TRUE & x$le==TRUE), ] # only select those records where the count of words are greater than 325 and less than 10000 and the text is mostly in english
			df.sel <<- xs[, keep] # only select needed columns
		}
		else{
			xns <- x[ which(x$wcl==FALSE | x$wcg==FALSE | x$le==FALSE), ] # only select those records where the count of words are not greater than 325 or less than 10000 or not mostly in english
			df.notsel <<- xns[, keep] # only select needed columns
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
#' @import RCurl
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
				Sys.sleep(0.1) #put the system to sleep after each URL is being fetched
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
				Sys.sleep(0.1) #put the system to sleep after each URL is being fetched
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
} #dump

#' Get PI data results 2
#'
#' This function will post the data from R into PI as JSON format and store it back to R by using CURL natively from the system.
#' CURL will need to be installed and configured properly (specially on Windows) to make sure that the queries run successfully.
#' User will have the capability of encrypting with server (which it is not default).  This would have to be enable since the script is configured to be run with Node.js locally.
#' @keywords download pi native curl
#' @import RCurl
#' @export
#' @examples
#' new.x1 <- getPI2(url="http://www.example.com", x=data$field, dump=NULL) # store results into new var x2
#' new.x2 <- getPI2(url="https://www.example.com", x=data$field, dump=NULL, ssl=TRUE) # store results into new var x2, but information is encrypted with server
#' new.x3 <- getPI2(url="https://www.example.com", x=data$field, dump=NULL, win=TRUE) # store results into new var x3 and using windows
#' new.x4 <- getPI2(url="https://www.example.com", x=data$field, dump=NULL, win=TRUE, capath="C:/pathtoca/cacert.pem") # store results into new var x4 and using windows
getPI2 <- function(url, x, usr, pwd, dump, ssl=FALSE, win=FALSE, capath){
	dump = NULL;

	if(url=="https://gateway.watsonplatform.net/personality-insights/api/v2/profile"){
		for (i in 1:length(x)){
			if(win==TRUE){
				dump[i] <- system(paste('C:/Windows/system32/cmd.exe /c curl -s -X POST -u ', usr, ':', pwd, ' -H "Content-Type: text/plain" -d "', x[i], '" ', url, sep=""), intern=TRUE) #send command to curl securely. Do not record progress.
			}
			if(win==FALSE){
				dump[i] <- system(paste('curl -s -X POST -u ', usr, ':', pwd, ' -H "Content-Type: text/plain" -d "', x[i], '" ', url, sep=""), intern=TRUE) #send command to curl securely. Do not record progress.
			}
			# progress is being made in the loop
			pb <- txtProgressBar(min=1, max=length(x), style=3) #style=3 would allow to see the percent and no new lines would be added while it loops through
			setTxtProgressBar(pb, i)
			Sys.sleep(0.1) #put the system to sleep after each URL is being fetched
			# perform a system clean-up by removing the user name and password from the vector
			# once all of the variables have been counted for
			if(i==length(x)){
				close(pb); remove(pb) # close and remove the progress bar connection
				cat("\n Done fetching remote. \n")
			}
		}
	}
	else if(ssl==FALSE & substring(url, 0, 5)=="https"){
		cat("\n This is an encrypted connection, but you did not identify by using ssl=TRUE on function. Will continue insecurely. \n")
		for (i in 1:length(x)){
			if(win==TRUE){
				dump[i] <- system(paste('C:/Windows/system32/cmd.exe /c curl --insecure -s -X POST -u ', usr, ':', pwd, ' -H "Content-Type: text/plain" -d "', x[i], '" ', url, sep=""), intern=TRUE) #send command to curl insecurely. Do not record progress.
			}
			if(win==FALSE){
				dump[i] <- system(paste('curl --insecure -s -X POST -u ', usr, ':', pwd, ' -H "Content-Type: text/plain" -d "', x[i], '" ', url, sep=""), intern=TRUE) #send command to curl insecurely. Do not record progress.
			}
			# progress is being made in the loop
			pb <- txtProgressBar(min=1, max=length(x), style=3) #style=3 would allow to see the percent and no new lines would be added while it loops through
			setTxtProgressBar(pb, i)
			Sys.sleep(0.1) #put the system to sleep after each URL is being fetched
			# perform a system clean-up by removing the user name and password from the vector
			# once all of the variables have been counted for
			if(i==length(x)){
				close(pb); remove(pb) # close and remove the progress bar connection
				cat("\n Done fetching remote and unencrypted. \n")
			}
		}
	}
	else{
		if(win==TRUE & capath==""){
			stop("\n When using Windows, need to identify path to certificate authority. \n")
		}
		for (i in 1:length(x)){
			if(win==TRUE & capath!=""){
				dump[i] <- system(paste('C:/Windows/system32/cmd.exe /c curl --cacert ', capath, ' -s -X POST -u ', usr, ':', pwd, ' -H "Content-Type: text/plain" -d "', x[i], '" ', url, sep=""), intern=TRUE) #send command to curl securely. Do not record progress.
			}
			if(win==FALSE){
				dump[i] <- system(paste('curl -s -X POST -u ', usr, ':', pwd, ' -H "Content-Type: text/plain" -d "', x[i], '" ', url, sep=""), intern=TRUE) # send command to curl securely. Do not record progress.
			}

			# progress is being made in the loop
			pb <- txtProgressBar(min=1, max=length(x), style=3) #style=3 would allow to see the percent and no new lines would be added while it loops through
			setTxtProgressBar(pb, i)
			Sys.sleep(0.1) #put the system to sleep after each URL is being fetched
			# perform a system clean-up by removing the user name and password from the vector
			# once all of the variables have been counted for
			if(i==length(x)){
				close(pb); remove(pb) # close and remove the progress bar connection
				cat("\n Done fetching remote and encrypted.\n")
			}
		}
	}

	return(dump)
} #dump

#' Format JSON field
#'
#' This function will format JSON field by making it uniform and removing "warnings" and "word_count_message".  This is a result form PI if the word count is too low.  It will also add the person name from the data frame.
#' @param x would be the field that wanted to be formatted.
#' @keywords json format clean
#' @export
#' @examples
#' clean.json <- fmtJSON(x, pname="Joe Doe") # Format JSON by adding person name
fmtJSON <- function(x, pname){
	# do some data clean up to make the JSON uniform
	x <- gsub(",\"warnings\".*]", "", x) # find and replace warnings towards end of json string 
	x <- gsub(",\"word_count_message\":\"There were \\d+.* words in the input. We need a minimum of 3,500, preferably 6,000 or more, to compute statistically significant estimates\"", "", x) # find and replace if record contains word_count_message and replace it with nothing

	# only select the dataset after the first { bracket }"
	x <- paste("{\"person\":\"", pname, "\",", substring(x, 2), sep="") # add person profile prior of output

	return(x)
}

#' Export PI data to CSV
#'
#' This function will export the clean JSON vector into a CSV file.
#' @keywords json csv clean
#' @import jsonlite
#' @export
#' @examples
#' exportPI(data, json, file_output) #create CSV based on data and json
exportPI <- function(data, json, output){
	#load variables names
	pinames <- c("Openness", "Conscientiousness", "Extraversion", "Agreeableness",
				"Neuroticism", "Adventurousness", "Artistic interests", "Emotionality",
				"Imagination", "Intellect", "Liberalism", "Achievement striving", "Cautiousness",
				"Dutifulness", "Orderliness", "Self-discipline", "Self-efficacy", "Activity level",
				"Assertiveness", "Cheerfulness", "Excitement-seeking",
				"Friendliness", "Gregariousness", "Altruism", "Cooperation", "Modesty",
				"Morality", "Sympathy", "Trust", "Anger", "Anxiety", "Depression",
				"Immoderation", "Self-consciousness", "Vulnerability", "Challenge", "Closeness", "Curiosity",
				"Excitement", "Harmony", "Ideal", "Liberty", "Love", "Practicality",
				"Self-expression", "Stability", "Structure", "Conservation", "Openness to change",
				"Hedonism", "Self-enhancement", "Self-transcendence")

	#loop through each json string
	#reused on Oct 10, 2015 -> https://github.com/IBMPredictiveAnalytics/Watson-Personality-Insights/blob/master/Source%20code/script.r
	for(q in 1:length(json)){
		res <- fromJSON(json[q])

		#check if var="error" is found on res, then set data frame to be blank for export
		if("error" %in% names(res)==TRUE){
			dump <- rep(NA,52)
			wc <- NA
		}
		else if(length(res)==2){
			dump <- rep(NA,52)
		}
		else{
			wc <- res$word_count #get word count variable
			res <- res$tree$children #get main variables from PI results
			dump <- NULL
			for(i in 1:length(res)){
				a <- res$children[[i]]
				for(j in 1:length(a$children)){
					b <- a$children[[j]]
					dump <- c(dump,b$percentage)
					for (k in 1:length(b$children)){
						c <- b$children[[k]]
						dump <- c(dump,c$percentage)
					}
				}
			}
		}
		t <- rbind.data.frame(dump) #convert vector to df
		t <- as.data.frame(c(wc, t)) #attach word count var to df
		dd <- cbind(data[q, ], t) #select current json loop and attach calc results
		colnames(dd) <- c(colnames(data), "word_count", pinames) #rename columns to proper names

		#do output if word_count is not NA
		if(q==1 & is.na(dd$word_count)!=TRUE){
			write.table(dd, paste(output, ".csv", sep=""), sep=",", row.names=FALSE, append=FALSE) #export the data on a csv format
		}
		else if(q>1 & is.na(dd$word_count)!=TRUE){
			write.table(dd, paste(output, ".csv", sep=""), sep=",", row.names=FALSE, append=TRUE, col.names=FALSE) #append data and don't include column names
		}
		else{
			#nothing
		}
	}
}
