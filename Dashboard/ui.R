library(shiny); library(leaflet); library(DT)

ui <- htmlTemplate(
  "template.html",
  title = "Data Centre Location Dashboard",
  pageHeading = "Data Centre Location Dashboard",
  scores = DT::DTOutput("scoreTable"),        # list/search area
  map    = leafletOutput("map", height = 500),
  risk   = plotOutput("riskPlot", height = 300)
)
