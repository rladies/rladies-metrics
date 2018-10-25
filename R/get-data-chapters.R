# ----------------------------------------------------- #
# The goal of the script is to compare what we have in
# the meetup page and on the "Current-Chapters.csv"
# If there is a chapter that is on meetup.com but on 
# "Current-Chapters.csv", then we will have to manually
# add to the csv.
# ----------------------------------------------------- #


library(shinydashboard)
library(shiny)
library(tidyverse)
library(rvest)
library(rtweet)
library(data.table)
library(meetupr)

# -------------------------------------------------------------------
#  1. Get all rladies groups using the meetupr package
# -------------------------------------------------------------------
# meetup groups
api_key <- readRDS("meetup_key.RDS")
all_rladies_groups <- find_groups(text = "r-ladies", api_key = api_key)

# Cleanup
rladies_groups <- all_rladies_groups[grep(pattern = "rladies|r-ladies", 
                                          x = all_rladies_groups$name,
                                          ignore.case = TRUE), ]

rladies_list <- sort(rladies_groups$city)


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

