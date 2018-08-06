suppressWarnings(library(shinydashboard))
suppressWarnings(library(shiny))
suppressWarnings(library(tidyverse))
# library(highcharter)
suppressWarnings(library(DT))
# library(htmltools)
suppressWarnings(library(rvest))
suppressWarnings(library(rtweet))
library(data.table)

futile.logger::flog.info("Loading chapters_source.R")
source("https://raw.githubusercontent.com/rladies/rshinylady/master/chapters_source.R")
# saveRDS(rladies_groups, "rladies_groups.RDS")
# rladies_groups <- readRDS("rladies_groups.RDS")

# 
rladies_list <- sort(rladies_groups$city)

# -------------------------------------------------------------------
# From Current-Chapters.csv 
# -------------------------------------------------------------------

# read the page where the list of chapters is located
url <- "https://raw.githubusercontent.com/rladies/starter-kit/master/"
file <- "Current-Chapters.csv"
current_chapters <- fread(paste0(url, file))


# -----------------------
# Groups on meetup.com
# -----------------------

# Countries: get the countries of the chapters ----------------------------
countries <- current_chapters$Country[!grepl("Remote", current_chapters$Country)]
n_countries <- length(unique(countries))

# Cities: get the cities of the chapters
cities <- current_chapters$City
n_cities <- length(cities)

# Meetup: has meetup page
has_meetup_page <- current_chapters[!Meetup %in% c("", NA), Meetup]
n_has_meetup_page <- length(has_meetup_page)

# get the url name - This will used to check if the url follows the 
# standard: rladies-CITY (ex: rladies-london, rladies-san-francisco)
rladies_urlname <- sub("/", replacement = "", 
                       sub("https://www.meetup.com/|http://www.meetup.com/", 
                           replacement = "", has_meetup_page))


# remove variables we are not going to use
rm(current_chapters, countries, cities, has_meetup_page)

# Compare what we have on the meetup page with what we have on the current_chapters.md
meetup_not_on_gh <- casefold(rladies_groups$urlname, upper = FALSE)[
  !(casefold(rladies_groups$urlname, upper = FALSE) %in% casefold(rladies_urlname, FALSE))
  ]

# -------------------
# Groups on twitter 
# -------------------
load("twitter_tokens.RData")

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


# twitter_token <- create_token(
#   app = "rtweet-pkg",
#   consumer_key = consumer_key,
#   consumer_secret = consumer_secret)

# rladies_chapters_twitter <- lists_members(slug = "rladies-chapters", owner_user = "gdequeiroz")
# n_rladies_chapters_twitter <- nrow(rladies_chapters_twitter)
futile.logger::flog.info("Loading twitter-fetch.R")
source("twitter-fetch.R")
n_rladies_chapters_twitter <- length(users_screennames)

# print(rladies_chapters_twitter)
# print(n_rladies_chapters_twitter)

