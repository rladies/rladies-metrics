library(DT)

futile.logger::flog.info("Loading data.R")
source("data.R")
futile.logger::flog.info("Loading metrics-past-meetups.R")
source("metrics-past-meetups.R")




# Header ----------------------------------------------------------------------

header <- dashboardHeader(title = "R-Ladies Metrics Dashboard",
                          titleWidth = 200)

# Sidebar ---------------------------------------------------------------------
# sidebar <- dashboardSidebar(
#   selectInput(
#     inputId = "rladies",
#     label = "City:", 
#     choices = rladies_list, 
#     selectize = FALSE)
# )

sidebar <- dashboardSidebar(disable = TRUE)

# Body --------------------------------------------------------------------- 
body <- dashboardBody(
  
  tabsetPanel(
    id = "tabs",
    
    tabPanel(
      title = "Main Dashboard",
      value = "page1",
      
      fluidRow(
        
        absolutePanel(style = "z-index: 2000", 
                      fixed = TRUE, draggable = TRUE,
          top  = 10, left = "auto", right = 20, width = "250px",
          div(
            tags$a(target="_blank", 
                   href = "http://www.rladies.org", 
                   tags$img(src="R-LadiesGlobal_RBG_online_LogoWithText.png", 
                            height = "30px", id = "logo") 
            )
          )
        ),
        
        # Info boxes
        valueBox(n_cities, "Cities", icon("globe", "font-awesome"), width = 2),
        valueBox(n_countries, "Countries", icon("globe", "font-awesome"), width = 2),
        valueBox(n_has_meetup_page, "Has meetup page", icon("meetup", lib = "font-awesome"), 
                 width = 2, color = "red"),
        valueBoxOutput("n_tweets", width = 2)
        
      ),
      
      fluidRow(
        
        # Tables
        
        ## total number of events
        box(title = "Total number of events", width = 2, solidHeader = TRUE, status = "primary", 
            collapsible = TRUE, DT::dataTableOutput("total_number_events")),
        
        # "number of events in the last 6 months"
        box(title = "Total number of events in the last 6 months", width = 2, solidHeader = TRUE, status = "primary", 
            collapsible = TRUE, DT::dataTableOutput("n_events_six_months")),
        
        
        box(
          title = "Need to be added to the repo", width = 2,
          tableOutput("tbl_meetup_not_on_gh"),
          status = "warning", collapsible = TRUE)
      )
      
    )
  )
  
  
)


## ui --------------------------------------------------------------
ui <- dashboardPage(skin = "purple", header, sidebar, body)




## server --------------------------------------------------------------
server <- function(input, output) { 
  
  
  output$n_tweets <- renderValueBox({
    valueBox(value = n_rladies_chapters_twitter, "R-Ladies on Twitter", 
             icon = icon("twitter"), color = "purple" )
  })
  
  
  meetup_not_on_gh <- as.data.frame(meetup_not_on_gh)
  colnames(meetup_not_on_gh) <- "meetup name"
  output$tbl_meetup_not_on_gh <- renderTable(meetup_not_on_gh)
  
  
  output$total_number_events <- DT::renderDataTable(total_number_events, 
                                                    rownames= FALSE, 
                                                    options = list(pageLength = 20, autoWidth = TRUE))
  
  output$n_events_six_months <- DT::renderDataTable(n_events_six_months,
                                                    rownames= FALSE, 
                                                    options = list(pageLength = 20, autoWidth = TRUE))

  
}
  
  
  
  
  




shinyApp(ui, server)