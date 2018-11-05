library(rjson)
library(httr)
library(twitteR)

# -------------------
# Groups on twitter 
# -------------------
# We need several info from the twitter API
# app name (you can choose whatever you. Mine is "rtweet-pkg")
# consumer_key, consumer_secret, access_token, access_token_secret
# I save all the keys and tokens as rds and then 
# archive them as .tar (twitter-credentials-secret.tar)

# read keys and tokens
token_path <- file.path("~/.R/gargle/")
consumer_key <- readRDS(paste0(token_path, "twitter-consumer-key.rds"))
consumer_secret <- readRDS(paste0(token_path, "twitter-consumer-secret.rds"))
access_token <- readRDS(paste0(token_path, "twitter-access-token.rds"))
access_token_secret <- readRDS(paste0(token_path, "twitter-access-token-secret.rds"))



# function to authentincate twitter without opening an browser
createTokenNoBrowser<- function(appName, consumerKey, consumerSecret, 
                                accessToken, accessTokenSecret) {
  app <- httr::oauth_app(appName, consumerKey, consumerSecret)
  params <- list(as_header = TRUE)
  credentials <- list(oauth_token = accessToken, 
                      oauth_token_secret = accessTokenSecret)
  token <- httr::Token1.0$new(endpoint = NULL, params = params, 
                              app = app, credentials = credentials)
  return(token)
}

token <- createTokenNoBrowser("rtweet-pkg", consumer_key, consumer_secret,
                              access_token, access_token_secret)


# rladies_chapters_twitter <- lists_members(slug = "rladies-chapters", owner_user = "gdequeiroz")
# n_rladies_chapters_twitter <- nrow(rladies_chapters_twitter)

futile.logger::flog.info("Getting data from twitter")


# Set-up twitter authentication
setup_twitter_oauth(consumer_key, consumer_secret, access_token, access_token_secret)


resource_url <- "https://api.twitter.com/1.1/lists/members.json"
slug <- "rladies-chapters"
owner_id <- "16284661"

# API call 
api_url <- paste0(resource_url, "?slug=",
                  slug, "&owner_id=", owner_id, "&cursor=-1&count=5000")

response <- GET(api_url, config(token=twitteR:::get_oauth_sig()))
response_list <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

# Get the variables I'm interested in
users_names <- sapply(response_list$users, function(i) i$name)
users_screennames <- sapply(response_list$users, function(i) i$screen_name)
followers_count <- sum(sapply(response_list$users, function(i) i$followers_count))

n_rladies_chapters_twitter <- length(users_screennames)

# print(rladies_chapters_twitter)
# print(n_rladies_chapters_twitter)

