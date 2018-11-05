library(googledrive)
library(meetupr)
library(lubridate)

futile.logger::flog.info(
  "\n -------- Reading create-metrics-past-meetups.R \n"
  )

futile.logger::flog.info("Reading gdrive token")

## read data from google drive
token_path <- file.path("~/.R/gargle/")
fn <- "token-gdrive.rds"
gdrive_token_path <- file.path(paste0(token_path, fn))
drive_auth(gdrive_token_path)



# list files from a specific folder on gdrive and
# get their names
files <- drive_ls(path = as_id("19lhxDSX6EWRp3xLIZ-5KUjfmzHcplHNY"))$name
# get the latest file (based on the date)
dt <- max(substr(files, 1, 10))
fn <- paste0(dt, "_past_meetups.csv")
# save the file locally 
# (TODO: is there a way to read in place? similar to drop_read_csv)
drive_download(fn, overwrite = TRUE)
past_meetups <- readr::read_csv(fn)
# remove local file since we don't need it anymore
file.remove(fn)

# Total number of events ---------------------------------------------------------
total_number_events <- past_meetups %>%
  filter(!is.na(venue_city)) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))

# Number of events in the last 6 months ---------------------------------------
six_months_ago <- lubridate::today() %m-% months(6)
past_meetups$local_date <- as.Date(past_meetups$local_date, format = "%Y-%m-%d")
n_events_six_months <- past_meetups %>%
  filter(!is.na(venue_city) & local_date >= six_months_ago) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))

# NO events in the last 6 months ---------------------------------------
## 1. there are some groups that never had a meetup
## 
# read the page where the list of chapters is located
url <- "https://raw.githubusercontent.com/rladies/starter-kit/master/"
file <- "Current-Chapters.csv"
current_chapters <- fread(paste0(url, file))
# current_chapters[!(current_chapters$Meetup %in% past_meetups$meetup_url),]

six_months_ago <- lubridate::today() %m-% months(6)
past_meetups$local_date <- as.Date(past_meetups$local_date, format = "%Y-%m-%d")
n_events_six_months <- past_meetups %>%
  filter(!is.na(venue_city) & local_date >= six_months_ago) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))

#Get the list of cities without events in the last 6 months
#In total_number_events we have all the cities with some event
#In n_events_six_month we have all the cities with some event in the last six month
#The anti_join by city of this two dataset give us the list of cities without events in the last 6 month
no_events_six_month_ago <- total_number_events %>% anti_join(n_events_six_months, by = "city")

