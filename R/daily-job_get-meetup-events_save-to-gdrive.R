library(rdrop2)
library(meetupr)
library(lubridate)
library(tidyverse)
library(googledrive)

# Need to setup the MEETUP KEY and read it
futile.logger::flog.info("\n \n ---------- Loading meetup api key ------------------------------ \n")

### TODO
# Add a ifelse when running the shinyapp

# read the meetup token (key). This token is saved on my local machine and encripted
# so travis could use (see .travis.yml)
# token_path <- file.path("~/.R/gargle/token-meetup.rds")
api_key <- readRDS(file = "token-meetup.rds")

# 

source("R/get-data-chapters.R")



# slowly function from Jenny Bryan
slowly <- function(f, delay = 0.5) {
  function(...) {
    Sys.sleep(delay)
    f(...)
  }
}





# data import -------------------------------------------------------------
futile.logger::flog.info("-------- Downloading meetup info ----------")
# rladies_groups
# need to wrap in safely - meetups that have not met (yet) throw an error, which seems to be causing map() to fail
# this takes a few seconds to download
rl_meetups_past <- map(rladies_groups$urlname, slowly(safely(get_events)), 
                       event_status = c("past"), api_key = api_key)

# str(rl_meetups_past, max.level = 1)

futile.logger::flog.info("Length meetup: %s", length(rl_meetups_past))

subset_past_meetups <- lapply(
  seq_along(rl_meetups_past), 
  function(x) rl_meetups_past[[x]]$result[, c(
    "local_date", "venue_city", "venue_country", "link"
    )]
  )

futile.logger::flog.info("Length meetup: %s", length(subset_past_meetups))

past_meetups <- bind_rows(subset_past_meetups)

futile.logger::flog.info("Length meetup: %s", dim(past_meetups))

# Clean up url to get the city name -------------------------------------
past_meetups$meetup_url <- gsub("events.*","", past_meetups$link)
length(unique(past_meetups$meetup_url))
futile.logger::flog.info("Length meetup: %s", dim(past_meetups))


past_meetups$city <- gsub("-|/|_", "", 
                          gsub(pattern = ".*(rladies|r-ladies|R-Ladies|RLadies)", "", 
                               past_meetups$meetup_url)
)
# unique(past_meetups$city)

# Small fixes
past_meetups[grep("%C4%B0zmiR", past_meetups$city, ignore.case = TRUE), "city"] <-"Izmir"
past_meetups[grep("https:www.meetup.comSpotkaniaEntuzjastowRWarsawRUsersGroupMeetup", 
                  past_meetups$city, ignore.case = TRUE), "city"] <- "Warsaw"

futile.logger::flog.info("Dataset rows: %s", dim(past_meetups))

# -------------------------------------------------------------------
# Save the data on GDRIVE 
# -------------------------------------------------------------------
# token_path <- file.path("~/.R/gargle/")
fn <- "token-gdrive.rds"
# gdrive_token_path <- file.path(paste0(token_path, fn))
drive_auth(fn)
fn <- paste0(today(), "_past_meetups.csv")
write_csv(past_meetups, fn)
futile.logger::flog.info("Uploading file to Google Drive ----------------------------")
# TODO: add overwrite - if the file was already uploded, should we overwrite it?
drive_upload(fn, as_id("19lhxDSX6EWRp3xLIZ-5KUjfmzHcplHNY"), name = fn)

