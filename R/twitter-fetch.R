library(rjson)
library(httr)
library(twitteR)

load("twitter_tokens.RData")

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
