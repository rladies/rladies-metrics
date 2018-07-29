suppressWarnings(library(shinydashboard))
suppressWarnings(library(shiny))
suppressWarnings(library(tidyverse))
# library(highcharter)
suppressWarnings(library(DT))
# library(htmltools)
suppressWarnings(library(rvest))
suppressWarnings(library(rtweet))


source("https://raw.githubusercontent.com/rladies/rshinylady/master/chapters_source.R")
# saveRDS(rladies_groups, "rladies_groups.RDS")
# rladies_groups <- readRDS("rladies_groups.RDS")


rladies_list <- sort(rladies_groups$city)

# read the page where the list of chapters is located
page <- read_html("https://github.com/rladies/starter-kit/blob/master/Current-Chapters.md")


# -----------------------
# Groups on meetup.com
# -----------------------

# Countries: get the countries of the chapters ----------------------------
countries <- page %>% 
  html_nodes("ul+ h2 , p+ h2") %>% 
  html_text() 
countries <- countries[!grepl("Remote", countries)]

n_countries <- length(countries)

## Get the cities of the chapters
cities <- page %>%
  html_nodes("#readme strong") %>% 
  html_text() %>% 
  tbl_df()

cities_plus_dc <- page %>%
  html_nodes("h3:nth-child(150) , #readme strong") %>% 
  html_text() 


n_cities <- length(cities_plus_dc)

# has meetup page
has_meetup_page <- page %>% 
  html_nodes("#readme li:nth-child(1) a") %>% 
  html_text()
has_meetup_page <- has_meetup_page[grepl("meetup.com", has_meetup_page)]
n_has_meetup_page <- length(has_meetup_page)

rladies_urlname <- sub("/", replacement = "", 
                       sub("https://www.meetup.com/|http://www.meetup.com/", 
                           replacement = "", has_meetup_page))



rm(page, countries, cities, cities_plus_dc, has_meetup_page)

# Compare what we have on the meetup page with what we have on the current_chapters.md
meetup_not_on_gh <- rladies_groups$urlname[!(rladies_groups$urlname %in% rladies_urlname)]

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
source("twitter-fetch.R")
n_rladies_chapters_twitter <- length(users_screennames)

# print(rladies_chapters_twitter)
# print(n_rladies_chapters_twitter)
