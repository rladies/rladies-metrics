# ------------------------------------------------------------- #
# The goal of the script is:
# 1) get R-Ladies past events (we will source get-data-chapters.R)
# 2) Save the data as .csv and then upload to google drive
#
# Files sourced in this script: get-data-chapters.R
# Tokens needed: token-gdrive.rds
# ------------------------------------------------------------- #
library(meetupr)
library(lubridate)
library(tidyverse)
library(googledrive)

# -------------------------------------------------------------------
# Read the script get-data-chapters.R - it grabs all the info from meetups
# using the meetupr package
# -------------------------------------------------------------------

source("R/get-data-chapters.R")


# -------------------------------------------------------------------
# Save the data on GDRIVE 
# -------------------------------------------------------------------
fn <- "token-gdrive.rds"
drive_auth(fn)
fn <- paste0(today(), "_past_meetups.csv")
write_csv(past_meetups, fn)
futile.logger::flog.info(" -------------- Uploading file to Google Drive ------------------")
# TODO: add overwrite - if the file was already uploded, should we overwrite it?
drive_upload(fn, as_id("19lhxDSX6EWRp3xLIZ-5KUjfmzHcplHNY"), name = fn)

