library(meetupr)
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
rl_meetups_past <- map(rladies_groups$urlname, slowly(safely(get_events)), event_status = c("past"))

str(rl_meetups_past, max.level = 1)


x <- lapply(seq_along(rl_meetups_past), 
       function(x) rl_meetups_past[[x]]$result[,c("local_date", "venue_city", "link")])

past_meetups <- bind_rows(x)
past_meetups$meetup_url <- gsub("events.*","", past_meetups$link)
past_meetups$city <- gsub("-|/|_", "", 
     gsub(pattern = ".*(rladies|r-ladies|R-Ladies|RLadies)", "", past_meetups$meetup_url)
)
unique(past_meetups$city)




