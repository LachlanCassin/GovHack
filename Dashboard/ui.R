library(shiny); library(leaflet); library(DT)

ui <- htmlTemplate(
  "template.html",
  title = "Data Centre Location Dashboard",
  pageHeading = "Data Centre Location Dashboard",

  
  #Data Cells / Graphic Displays
  
  scores = DT::DTOutput("scoreTable"),           # sample list/search area - rank scores, select individual locations, etc.
  map    = leafletOutput("map", height = 500),   # sample map - replace with GK's map
  risk   = plotOutput("riskPlot", height = 300)  # sample chart - more likely for specific information on selected location
)
