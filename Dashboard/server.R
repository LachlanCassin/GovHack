library(shiny); library(leaflet); library(DT)

server <- function(input, output, session) {
  output$map <- renderLeaflet({
    leaflet() |> addTiles() |> setView(lng = 146, lat = -34, zoom = 6)
  })
  output$scoreTable <- renderDT({
    datatable(data.frame(Location=c("Site A","Site B","Site C"), Score=c(85,78,90)),
              options = list(pageLength = 10), rownames = FALSE)
  })
  output$riskPlot <- renderPlot({
    barplot(c(3,5,2), names.arg = c("Flood","Fire","Heat"),
            col = "red", main = "Risk Levels")
  })
}
