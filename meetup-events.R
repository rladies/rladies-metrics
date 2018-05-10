library(meetupr)
library(lubridate)

# Need to setup the MEETUP KEY and read it
api_key <- readRDS("meetup_key.RDS")


# slowly function from Jenny Bryan
slowly <- function(f, delay = 0.5) {
  function(...) {
    Sys.sleep(delay)
    f(...)
  }
}


# data import -------------------------------------------------------------

# rladies_groups
# need to wrap in safely - meetups that have not met (yet) throw an error, which seems to be causing map() to fail
# this takes a few seconds to download
rl_meetups_past <- map(rladies_groups$urlname, slowly(safely(get_events)), 
                       event_status = c("past"), api_key = api_key)

# str(rl_meetups_past, max.level = 1)


subset_past_meetups <- lapply(seq_along(rl_meetups_past), 
                              function(x) rl_meetups_past[[x]]$result[,c("local_date", "venue_city", "link")])

past_meetups <- bind_rows(subset_past_meetups)

# Clean up url to get the city name
past_meetups$meetup_url <- gsub("events.*","", past_meetups$link)
past_meetups$city <- gsub("-|/|_", "", 
     gsub(pattern = ".*(rladies|r-ladies|R-Ladies|RLadies)", "", past_meetups$meetup_url)
)
# unique(past_meetups$city)

total_number_events <- past_meetups %>%
  filter(!is.na(venue_city)) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))

six_months_ago <- lubridate::today() %m-% months(6)
n_events_six_months <- past_meetups %>%
  filter(!is.na(venue_city) & local_date >= six_months_ago) %>% 
  group_by(city) %>% 
  count() %>% 
  arrange(desc(n))

