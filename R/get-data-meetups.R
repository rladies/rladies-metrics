library(rdrop2)
library(meetupr)
library(lubridate)
library(tidyverse)


# Need to setup the MEETUP KEY and read it
futile.logger::flog.info("Loading meetup api key")

### TODO
# Add a ifelse when running the shinyapp
# The app needs the RDS but travis doesn't

# api_key <- readRDS("meetup_key.RDS")
api_key <- Sys.getenv("meetup_key")

# source("https://raw.githubusercontent.com/rladies/rshinylady/master/chapters_source.R")
source("R/chapters_source.R")



# slowly function from Jenny Bryan
slowly <- function(f, delay = 0.3) {
  function(...) {
    Sys.sleep(delay)
    f(...)
  }
}

# Only run this if there is 



# data import -------------------------------------------------------------

# rladies_groups
# need to wrap in safely - meetups that have not met (yet) throw an error, which seems to be causing map() to fail
# this takes a few seconds to download
rl_meetups_past <- map(rladies_groups$urlname, slowly(safely(get_events)), 
                       event_status = c("past"), api_key = api_key)
futile.logger::flog.info("-------- Downloading meetup info ----------")
# str(rl_meetups_past, max.level = 1)

futile.logger::flog.info("Length meetup: %s", length(rl_meetups_past))

subset_past_meetups <- lapply(seq_along(rl_meetups_past), 
                              function(x) rl_meetups_past[[x]]$result[,c("local_date", "venue_city", "link")])

past_meetups <- bind_rows(subset_past_meetups)

# Clean up url to get the city name
past_meetups$meetup_url <- gsub("events.*","", past_meetups$link)
past_meetups$city <- gsub("-|/|_", "", 
                          gsub(pattern = ".*(rladies|r-ladies|R-Ladies|RLadies)", "", past_meetups$meetup_url)
)
# unique(past_meetups$city)

futile.logger::flog.info("Dataset rows: %s", dim(past_meetups))

# -------------------------------------------------------------------
# Save the Data on dropbox 
# -------------------------------------------------------------------
futile.logger::flog.info("Reading Dropbox token")
dropbox_token <- readRDS("R/token.rds")
# token <- drop_auth()
# saveRDS(token, file = "token.rds")
fn <- paste0(today(), "_past_meetups.csv")
write_csv(past_meetups, fn)
futile.logger::flog.info("Uploading file to Dropbox")
drop_upload(fn, "rladies-metrics-data/")
