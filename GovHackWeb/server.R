library(shiny)
library(shinythemes)
library(leaflet)
library(plotly)
library(DT)
library(dplyr)
library(readr)
library(viridis)
library(sf)

# ---- LOAD DATA ----
# Load your GeoJSON file
lga_sf <- st_read("dataframe/lga.geojson")

# If your CSV data is separate, load and join it
lga_data <- read_csv("lga_data_center_analysis.csv")

# Ensure numeric columns in CSV data
lga_data <- lga_data %>%
  mutate(across(c(composite_score, PC1_score, power_score, pop_score, fire_risk_score), as.numeric))

# Fix the lga_name column type issue in the GeoJSON
if ("lga_name" %in% names(lga_sf) && is.list(lga_sf$lga_name)) {
  lga_sf$lga_name <- as.character(lga_sf$lga_name)
}

# Also ensure lga_name is character in CSV data
lga_data$lga_name <- as.character(lga_data$lga_name)

# Join CSV data with GeoJSON spatial data
lga_sf <- lga_sf %>%
  left_join(lga_data, by = "lga_name")

# Top 10 & Top 20 LGAs
top10_lgas <- lga_data %>% arrange(desc(composite_score)) %>% slice(1:10)
top20_lgas <- lga_data %>% arrange(desc(composite_score)) %>% slice(1:20)

# ---- SERVER ----
shinyServer(function(input, output, session) {
  
  # Reactive expression for the data to display on map
  mapData <- reactive({
    # Get the selected score type
    score_type <- input$map_score_type
    
    # Create a copy of the spatial data with the selected score
    data <- lga_sf
    data$selected_score <- data[[score_type]]
    
    return(data)
  })
  
  # Reactive expression for the color palette
  colorPalette <- reactive({
    data <- mapData()
    colorNumeric("viridis", domain = data$selected_score, na.color = "#808080")
  })
  
  # Leaflet Map
  output$lgaMap <- renderLeaflet({
    data <- mapData()
    pal <- colorPalette()
    
    # Create the base map
    map <- leaflet(data) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = 133.7751, lat = -25.2744, zoom = 4)  # Center on Australia
    
    # Add polygons from GeoJSON
    map <- map %>%
      addPolygons(
        fillColor = ~pal(selected_score),
        fillOpacity = 0.7,
        color = "#444444",
        weight = 1,
        smoothFactor = 0.5,
        popup = ~paste0(
          "<div style='padding: 10px;'>",
          "<h4>", lga_name, "</h4>",
          "<b>Composite Score:</b> ", round(composite_score, 2), "<br>",
          "<b>PCA Score:</b> ", round(PC1_score, 2), "<br>",
          "<b>Power Score:</b> ", round(power_score, 2), "<br>",
          "<b>Population Score:</b> ", round(pop_score, 2), "<br>",
          "<b>Fire Risk Score:</b> ", round(fire_risk_score, 2),
          "</div>"
        ),
        highlightOptions = highlightOptions(
          weight = 3,
          color = "#666",
          fillOpacity = 0.9,
          bringToFront = TRUE
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~selected_score,
        title = "Score Value",
        opacity = 0.7
      )
    
    return(map)
  })
  
  # Observe changes in score type and update the map
  observe({
    data <- mapData()
    pal <- colorPalette()
    score_type_name <- switch(input$map_score_type,
                              "composite_score" = "Composite Score",
                              "PC1_score" = "PCA Score",
                              "power_score" = "Power Infrastructure",
                              "pop_score" = "Population Density",
                              "fire_risk_score" = "Environmental Risk")
    
    # Update the map based on the selected score type
    leafletProxy("lgaMap", data = data) %>%
      clearShapes() %>%
      clearControls() %>%
      addPolygons(
        fillColor = ~pal(selected_score),
        fillOpacity = 0.7,
        color = "#444444",
        weight = 1,
        smoothFactor = 0.5,
        popup = ~paste0(
          "<div style='padding: 10px;'>",
          "<h4>", lga_name, "</h4>",
          "<b>Composite Score:</b> ", round(composite_score, 2), "<br>",
          "<b>PCA Score:</b> ", round(PC1_score, 2), "<br>",
          "<b>Power Score:</b> ", round(power_score, 2), "<br>",
          "<b>Population Score:</b> ", round(pop_score, 2), "<br>",
          "<b>Fire Risk Score:</b> ", round(fire_risk_score, 2),
          "</div>"
        ),
        highlightOptions = highlightOptions(
          weight = 3,
          color = "#666",
          fillOpacity = 0.9,
          bringToFront = TRUE
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~selected_score,
        title = paste(score_type_name, "Value"),
        opacity = 0.7
      )
  })
  
  # Top 20 Table
  output$top20Table <- renderDT({
    datatable(
      top20_lgas %>% select(lga_name, state, composite_score, composite_rank, PC1_score),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    )
  })
  
  # Top 10 Bar Plot
  output$top10BarPlot <- renderPlotly({
    plot_ly(top10_lgas,
            x = ~reorder(lga_name, composite_score),
            y = ~composite_score,
            type = 'bar',
            text = ~paste("Rank:", composite_rank),
            hoverinfo = 'text') %>%
      layout(xaxis = list(title = "LGA"),
             yaxis = list(title = "Composite Score"))
  })
  
  # Rankings Table reactive
  output$rankingsTable <- renderDT({
    # Determine which score to use for ranking
    score_type <- input$rankings_score_type
    
    filtered <- lga_data %>%
      filter(grepl(input$rankings_search, lga_name, ignore.case = TRUE)) %>%
      arrange(desc(.data[[score_type]])) %>%
      mutate(Rank = row_number())
    
    # Format numeric columns to 4 significant figures
    filtered <- filtered %>%
      mutate(across(where(is.numeric), ~signif(., 4)))
    
    # Select and rename columns for display
    filtered <- filtered %>%
      select(Rank, lga_name, state, 
             composite_score, PC1_score, power_score, pop_score, fire_risk_score)
    
    # Create the datatable with custom column names
    datatable(filtered,
              colnames = c("Rank", "LGA Name", "State", 
                           "Composite Score", "PCA Score", "Power Score", 
                           "Population Score", "Fire Risk Score"),
              options = list(pageLength = 10, scrollX = TRUE),
              rownames = FALSE) %>%
      formatStyle('Rank', fontWeight = 'bold')
  })
  
  # Score Distribution Histogram
  output$scoreHistogram <- renderPlotly({
    score_type <- input$rankings_score_type
    score_name <- switch(score_type,
                         "composite_score" = "Composite Score",
                         "PC1_score" = "PCA Score",
                         "power_score" = "Power Infrastructure Score",
                         "pop_score" = "Population Density Score",
                         "fire_risk_score" = "Environmental Risk Score")
    
    plot_ly(
      data = lga_data,
      x = ~.data[[score_type]],
      type = "histogram",
      marker = list(
        color = 'cornflowerblue',
        line = list(color = 'black', width = 1),
        opacity = 1
      )
    ) %>%
      layout(
        title = paste(score_name, "Distribution"),
        xaxis = list(title = score_name, autorange = TRUE),
        yaxis = list(title = "Count", autorange = TRUE),
        bargap = 0.05,
        autosize = TRUE,
        plot_bgcolor = '#ffffff',
        paper_bgcolor = '#ffffff'
      )
  })
  
  # Data Processing Code (for Methodology tab)
  output$dataProcessingCode <- renderText({
    if(file.exists("dataProcessing.R")) {
      paste(readLines("dataProcessing.R"), collapse = "\n")
    } else {
      "# Data processing code file not found\n# Please ensure dataProcessing.R is in your working directory"
    }
  })
})