library(rdrop2)
library(meetupr)
library(lubridate)

futile.logger::flog.info("Reading dropbox token")

## read data from Dropbox
dropbox_token <- readRDS("token.rds")
dt <- today()
fn <- paste0(dt, "_past_meetups.csv")
path <- paste0("rladies-metrics-data/", fn )
# rdrop2::drop_dir("rladies-metrics-data")
past_meetups <- drop_read_csv(path)

total_number_events <- past_meetups %>%
  filter(!is.na(venue_city)) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))

six_months_ago <- lubridate::today() %m-% months(6)
past_meetups$local_date <- as.Date(past_meetups$local_date, format = "%Y-%m-%d")
n_events_six_months <- past_meetups %>%
  filter(!is.na(venue_city) & local_date >= six_months_ago) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))


# Descriptions