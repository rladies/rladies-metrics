library(rdrop2)
library(meetupr)
library(lubridate)


futile.logger::flog.info("Reading dropbox token")

## read data from Dropbox
# the dropbox key key was added to TRAVIS
dropbox_token <- readRDS("R/token-dropbox.rds")

# list files from Dropbox
files <- rdrop2::drop_dir("rladies-metrics-data")$name
dt <- max(substr(files, 1, 10))
# dt <- today()
fn <- paste0(dt, "_past_meetups.csv")
path <- paste0("rladies-metrics-data/", fn )
# rdrop2::drop_dir("rladies-metrics-data")
past_meetups <- drop_read_csv(path)

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
current_chapters[!(current_chapters$Meetup %in% past_meetups$meetup_url),]

six_months_ago <- lubridate::today() %m-% months(6)
past_meetups$local_date <- as.Date(past_meetups$local_date, format = "%Y-%m-%d")
n_events_six_months <- past_meetups %>%
  filter(!is.na(venue_city) & local_date >= six_months_ago) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))

