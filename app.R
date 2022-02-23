require(bslib)
require(shiny)
require(dbplyr)
require(dplyr, include.only = "%>%")

# connect -----------------------------------------------------------------
host <- Sys.getenv("DB2_HOST")
user <- Sys.getenv("DB2_USER")
password <- Sys.getenv("DB2_PASSWORD")

url <- 
  glue::glue("jdbc:db2://{host}/bludb:user={user};password={password};sslConnection=true;")

pool <- pool::dbPool(
  drv = RJDBC::JDBC("com.ibm.db2.jcc.DB2Driver", "jars/db2jcc4.jar"),
  url = url
)
onStop(function() {
  pool::poolClose(pool)
})

# theme -------------------------------------------------------------------
theme <- bs_theme(
  bg = "#16181C", fg = "#FFE800", primary = "#FCC780",
  base_font = font_google("Space Mono"),
  code_font = font_google("Space Mono")
)

last_date <- pool %>% 
  dplyr::tbl("COVID19") %>% 
  dplyr::pull(DATE) %>% 
  max()

# ui ----------------------------------------------------------------------
ui <- fluidPage(
  navbarPage("COVID 19: # of Cases in South America"),
  theme = theme,
  sidebarLayout(
    sidebarPanel(
      dateInput("date", "Date", value = last_date)
    ),
    
    mainPanel(
      leaflet::leafletOutput("map"),
    )
  )
)

# server ------------------------------------------------------------------
server <- function(input, output) {
  
  dataset <-
    reactive({
      pool %>%
        dplyr::tbl("COVID19") %>%
        dplyr::as_tibble() %>% 
        dplyr::filter(DATE == input$date) %>% 
        dplyr::mutate(radius = CUMULATE/max(CUMULATE) * 20)
    })
  
  output$map <- leaflet::renderLeaflet({
    dataset() %>%
      leaflet::leaflet() %>%
      leaflet::addProviderTiles("CartoDB.DarkMatter") %>%
      leaflet::addCircleMarkers(~LONG, ~LAT, 
                                label = paste(dataset()$COUNTRY, " ", dataset()$CUMULATE), 
                                radius = ~radius,
                                color = "#FFE800")
  })

  
}

shinyApp(ui, server)