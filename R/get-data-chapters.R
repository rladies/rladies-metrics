# ----------------------------------------------------- #
# The goal of the script is:
# 1) get the basic data from all groups
# 2) get past events data from all groups
# 3) read the "Current-Chapters.csv"
# 4) compare what the data we on meetup with the data 
#    from "Current-Chapters.csv". If there is a chapter 
#    that is on meetup.com but on "Current-Chapters.csv", 
#    then we will have to manually add to the csv.
#
#
# Tokens needed: token-meetup.rds (meetup API key)
# ----------------------------------------------------- #

library(shinydashboard)
library(shiny)
library(tidyverse)
library(rvest)
library(rtweet)
library(data.table)
library(meetupr)

# -------------------------------------------------------------------
#  1. Get the basic data from all groups using the meetupr package
# -------------------------------------------------------------------
futile.logger::flog.info("\n \n -------- Loading meetup api key ------------ \n")

# Read the meetup token (key). This token is saved on my local machine and encripted
# so travis could use (see .travis.yml)
api_key <- readRDS("token-meetup.rds")

all_rladies_groups <- find_groups(text = "r-ladies", api_key = api_key)

# Cleanup groups' names
rladies_groups <- all_rladies_groups[grep(pattern = "rladies|r-ladies", 
                                          x = all_rladies_groups$name,
                                          ignore.case = TRUE), ]

rladies_cities_sorted <- sort(rladies_groups$city)

# -------------------------------------------------------------------
#  2. Get past events data from all groups
# -------------------------------------------------------------------

# Slowly function from Jenny Bryan
slowly <- function(f, delay = 0.5) {
  function(...) {
    Sys.sleep(delay)
    f(...)
  }
}
futile.logger::flog.info("\n \n -------- Downloading past events ---------- \n \n")

# need to wrap in safely - meetups that have not met (yet) throw an error, 
# which seems to be causing map() to fail
# this takes a few seconds to download
# -- output: list containing all the info from past events
rl_meetups_past <- map(rladies_groups$urlname, slowly(safely(get_events)), 
                       event_status = c("past"), api_key = api_key)

# -- output of rl_meetups_past
# > str(rl_meetups_past[1], max.level = 2)
# List of 1
# $ :List of 2
# ..$ result:Classes ‘tbl_df’, ‘tbl’ and 'data.frame':	10 obs. of  21 variables:
#   ..$ error : NULL


futile.logger::flog.info("\n \n Number of chapters (list length): %s \n \n", length(rl_meetups_past))

# We don't need to save all the data. 
# We need: "local_date", "venue_city", "venue_country", "link"
# -- output: list containing info from past events
subset_past_meetups <- lapply(
  seq_along(rl_meetups_past), 
  function(x) rl_meetups_past[[x]]$result[, c(
    "local_date", "venue_city", "venue_country", "link"
  )]
)
# -- output of subset_past_meetups
# > str(subset_past_meetups[1], max.level = 2)
# List of 1
# $ :Classes ‘tbl_df’, ‘tbl’ and 'data.frame':	10 obs. of  4 variables:
#   ..$ local_date   : Date[1:10], format: "2016-11-21" "2016-12-05" "2017-01-16" "2017-02-20" ...
# ..$ venue_city   : chr [1:10] NA "Barcelona" "Barcelona" "Barcelona" ...
# ..$ venue_country: chr [1:10] NA "es" "es" "es" ...
# ..$ link         : chr [1:10] "https://www.meetup.com/rladies-barcelona/events/235064329/"  ...


# Combine the list and create a df
# -- output: "tbl_df" "tbl" "data.frame"
# one row for each event
past_meetups <- bind_rows(subset_past_meetups)

# -- output of past_meetups
# > head(past_meetups)
# # A tibble: 6 x 4
# local_date venue_city venue_country link                                                      
# <date>     <chr>      <chr>         <chr>                                                     
#   1 2016-11-21 NA         NA            https://www.meetup.com/rladies-barcelona/events/235064329/
#   2 2016-12-05 Barcelona  es            https://www.meetup.com/rladies-barcelona/events/235593376/


futile.logger::flog.info("Dataset contains %s rows and %s columns", nrow(past_meetups), ncol(past_meetups))

# Clean up url to get the city name -------------------------------------

# if you look at the "venue_city", some of the values are NA so a work around
# would be to get the city in the url. The url link is in the form of:
# https://www.meetup.com/rladies-barcelona/events/238510980/
# "meetup.com" + "rladies-" + city "+ "/events/" + number of the event

# First we need to get everything before events
past_meetups$meetup_url <- gsub("events.*","", past_meetups$link)

# Then we can get the city name. For that we need:
# 1) Match and Replace by "" everything that comes before rladies (and its variation)
#   -- output: "-austin/"; "-porto-alegre/" (for example)
# 2) Match and Replace by "" forward slash or the hifen in the beginning or the undescore
#   -- output: "austin"; "porto-alegre" (for example)
# 3) Match and Replace by " " (space) the hifen between words
#   -- output: "austin"; "porto alegre" (for example)
# 4) Capitalize first letter of every word

past_meetups$city <- str_to_title(gsub("-", " ", 
                          gsub("/|^-|_", "", 
                               gsub(pattern = ".*(rladies|r-ladies|R-Ladies|RLadies)", "", 
                               past_meetups$meetup_url)
)
))



# unique(past_meetups$city)

# Small fixes
past_meetups[grep("%C4%B0zmiR", past_meetups$city, ignore.case = TRUE), "city"] <-"Izmir"
past_meetups[grep("https:www.meetup.comSpotkaniaEntuzjastowRWarsawRUsersGroupMeetup", 
                  past_meetups$city, ignore.case = TRUE), "city"] <- "Warsaw"

futile.logger::flog.info("Dataset rows: %s", nrow(past_meetups))


# -------------------------------------------------------------------
# 2. Get all chapters from our source "Current-Chapters.csv" 
# -------------------------------------------------------------------

# read the page where the list of chapters is located
url <- "https://raw.githubusercontent.com/rladies/starter-kit/master/"
file <- "Current-Chapters.csv"
current_chapters <- fread(paste0(url, file))

# 2.1 Countries: get the countries of the chapters ----------------------------
countries <- current_chapters$Country[!grepl("Remote", current_chapters$Country)]
n_countries <- length(unique(countries))

# 2.2 Cities: get the cities of the chapters
cities <- current_chapters$City
n_cities <- length(cities)

# 2.3 Meetup: has meetup page
has_meetup_page <- current_chapters[!Meetup %in% c("", NA), Meetup]
n_has_meetup_page <- length(has_meetup_page)

# 2.4 get the url name - This will used to check if the url follows the 
# standard: rladies-CITY (ex: rladies-london, rladies-san-francisco)
rladies_urlname <- sub("/", replacement = "", 
                       sub("https://www.meetup.com/|http://www.meetup.com/", 
                           replacement = "", has_meetup_page))


## remove variables we are not going to use
rm(current_chapters, countries, cities, has_meetup_page)

# 2.5 Compare what we have on the meetup page with what we have on "Current-Chapters.csv"
meetup_not_on_gh <- casefold(rladies_groups$urlname, upper = FALSE)[
  !(casefold(rladies_groups$urlname, upper = FALSE) %in% casefold(rladies_urlname, FALSE))
  ]

