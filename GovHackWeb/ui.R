library(shiny)
library(shinythemes)   # ⬅️ must be here
library(leaflet)
library(plotly)
library(DT)
library(dplyr)
library(readr)
library(viridis)
library(sf)

shinyUI(
  fluidPage(
    theme = shinytheme("cerulean"),
    
    # Navigation Bar
    navbarPage(
      title = div(icon("server"), "Data Center Location Analysis"),
      id = "nav",
      # Interactive Map Tab
      tabPanel("Interactive Map",
               
               tags$style(HTML("
           .map-container {
             background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
             padding: 25px;
             border-radius: 20px;
             margin: 20px;
           }
           .map-header {
             background: rgba(255, 255, 255, 0.95);
             padding: 25px;
             border-radius: 15px;
             box-shadow: 0 8px 32px rgba(0,0,0,0.1);
             margin-bottom: 20px;
           }
           .main-title {
             color: #2c3e50;
             font-weight: 700;
             text-align: center;
             margin-bottom: 10px;
             font-size: 32px;
           }
           .subtitle {
             color: #6c757d;
             text-align: center;
             font-size: 16px;
             margin-bottom: 20px;
           }
           .map-controls {
             background: rgba(255, 255, 255, 1);
             border-radius: 10px;
             padding: 20px;
             box-shadow: 0 4px 15px rgba(0,0,0,0.08);
           }
           .control-label {
             font-weight: 600;
             color: #2c3e50;
             margin-bottom: 10px;
             font-size: 16px;
           }
         ")),
               
               div(class = "map-container",
                   div(class = "map-header",
                       h1("Optimal Data Centre Locations by LGA", class = "main-title"),
                       p("Interactive exploration of suitability scores across Australian Local Government Areas", 
                         class = "subtitle")
                   ),
                   
                   # Map output
                   leafletOutput("lgaMap", height = "650px"),
                   
                   # Control panel
                   absolutePanel(top = 120, right = 30, draggable = FALSE,
                                 class = "map-controls",
                                 div(class = "control-label", "Map Display Options"),
                                 selectInput("map_score_type", NULL,
                                             choices = c(
                                               "Composite Score" = "composite_score",
                                               "PCA Score" = "PC1_score",
                                               "Power Infrastructure" = "power_score",
                                               "Population Density" = "pop_score",
                                               "Environmental Risk" = "fire_risk_score"
                                             ),
                                             selected = "composite_score",
                                             width = "250px")
                   )
               )
      ),
      # LGA Rankings Tab - Fix the score distribution histogram
      tabPanel("LGA Rankings",
               tags$style(HTML("
    .rankings-container {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 30px;
      border-radius: 20px;
      margin: 20px 0;
    }
    .rankings-header {
      background: #ffffff;
      padding: 30px;
      border-radius: 15px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.1);
      margin-bottom: 25px;
    }
    .main-title { color: #2c3e50; font-weight: 700; text-align: center; margin-bottom: 10px; font-size: 32px; }
    .subtitle { color: #6c757d; text-align: center; font-size: 16px; margin-bottom: 25px; }
    .score-selector { background: #f8f9f9; border-radius: 10px; padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
    .selector-label { font-weight: 600; color: #2c3e50; margin-bottom: 10px; font-size: 16px; }
    .search-box { background: #f8f9f9; border-radius: 10px; padding: 15px; margin-bottom: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
    .rankings-table-container { background: #ffffff; border-radius: 15px; padding: 25px; box-shadow: 0 8px 32px rgba(0,0,0,0.1); margin-top: 20px; }
  ")),
               
               div(class = "rankings-container",
                   div(class = "rankings-header",
                       h1("Local Government Areas Ranking", class = "main-title"),
                       p("All LGAs ranked by selected score type (lower rank = better suitability)", class = "subtitle"),
                       div(class = "score-selector",
                           div(class = "selector-label", "Select Ranking Criteria:"),
                           selectInput("rankings_score_type", NULL,
                                       choices = c(
                                         "Composite Score" = "composite_score",
                                         "PCA Score" = "PC1_score",
                                         "Power Infrastructure" = "power_score",
                                         "Population Density" = "pop_score",
                                         "Environmental Risk" = "fire_risk_score"
                                       ),
                                       selected = "composite_score",
                                       width = "300px")
                       )
                   ),
                   div(class = "search-box",
                       div(class = "selector-label", "Search LGAs:"),
                       textInput("rankings_search", NULL, placeholder = "Type to search...", width = "300px")
                   ),
                   div(class = "rankings-table-container",
                       DTOutput("rankingsTable")
                   ),
                   div(style = "background: #ffffff; padding: 20px; border-radius: 15px; margin-top: 20px;",
                       h4("Score Distribution", style = "text-align: center; color: #2c3e50;"),
                       plotlyOutput("scoreHistogram", height = "400px")  # Reduced height for better fit
                   )
               )
      ),
      
      # Analysis Results Tab
      tabPanel("Analysis Results",
               tags$style(HTML("
                 .analysis-container {
                   background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                   padding: 30px;
                   border-radius: 20px;
                   margin: 20px 0;
                 }
                 .analysis-section {
                   background: rgba(255, 255, 255, 0.95);
                   border-radius: 15px;
                   padding: 25px;
                   margin: 20px 0;
                   border-left: 5px solid #2c3e50;
                   box-shadow: 0 4px 15px rgba(0,0,0,0.1);
                 }
                 .section-title {
                   color: #2c3e50;
                   font-weight: 600;
                   margin-bottom: 20px;
                   text-align: center;
                   font-size: 24px;
                   border-bottom: 2px solid #3498db;
                   padding-bottom: 10px;
                 }
                 .section-description {
                   text-align: center;
                   color: #6c757d;
                   font-style: italic;
                   margin-top: 10px;
                   font-size: 14px;
                 }
                 .analysis-image {
                   max-width: 90%;
                   height: auto;
                   display: block;
                   margin: 20px auto;
                   border-radius: 12px;
                   box-shadow: 0 8px 25px rgba(0,0,0,0.15);
                   border: 3px solid #f8f9fa;
                   transition: transform 0.3s ease, box-shadow 0.3s ease;
                 }
                 .analysis-image:hover {
                   transform: translateY(-5px);
                   box-shadow: 0 12px 35px rgba(0,0,0,0.2);
                 }
               ")),
               
               div(class = "analysis-container",
                   fluidRow(
                     column(12,
                            div(class = "analysis-section",
                                h3("Top 20 Optimal Locations", class = "section-title"),
                                img(src = "Top20.png", class = "analysis-image"),
                                p("Visualization of the top 20 optimal data center locations based on composite scoring", 
                                  class = "section-description")
                            )
                     )
                   ),
                   fluidRow(
                     column(12,
                            div(class = "analysis-section",
                                h3("LGA Suitability Analysis", class = "section-title"),
                                img(src = "LGAComp.png", class = "analysis-image"),
                                p("Comprehensive suitability assessment across all Local Government Areas", 
                                  class = "section-description")
                            )
                     )
                   ),
                   fluidRow(
                     column(12,
                            div(class = "analysis-section",
                                h3("Principal Component Analysis", class = "section-title"),
                                img(src = "PC1.png", class = "analysis-image"),
                                p("First Principal Component analysis showing key variance patterns in the data", 
                                  class = "section-description")
                            )
                     )
                   )
               )
      ),
      
      # --- TEAM MEMBERS TAB ---
      tabPanel("Team Members",
               tags$style(HTML("
    .team-container {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 30px;
      border-radius: 20px;
      margin: 20px 0;
    }
    .team-header {
      background: rgba(255, 255, 255, 0.95);
      padding: 30px;
      border-radius: 15px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.1);
      margin-bottom: 25px;
      text-align: center;
    }
    .team-card {
      background: #ffffff;
      border-radius: 15px;
      padding: 25px;
      text-align: center;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
      margin: 15px 0;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .team-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 8px 25px rgba(0,0,0,0.2);
    }
    .team-photo {
      width: 120px;
      height: 120px;
      object-fit: cover;
      border-radius: 50%;
      margin-bottom: 15px;
      box-shadow: 0 4px 15px rgba(0,0,0,0.15);
    }
    .team-name {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 5px;
      color: #2c3e50;
    }
    .team-role {
      font-weight: bold;
      color: #007bff;
      margin-bottom: 10px;
    }
    .team-desc {
      color: #6c757d;
      font-size: 14px;
    }
  ")),
               
               div(class = "team-container",
                   div(class = "team-header",
                       h1("Our Team", class = "main-title"),
                       p("Meet the people behind the project", class = "subtitle")
                   ),
                   
                   fluidRow(
                     column(4,
                            div(class = "team-card",
                                img(src = "Cassin.jpg", class = "team-photo"),
                                div("Lachlan Cassin", class = "team-name"),
                                div("Shiny App Developer", class = "team-role"),
                                p("Developed Shiny app and integrated data into the web interface", class = "team-desc")
                            )
                     ),
                     column(4,
                            div(class = "team-card",
                                img(src = "Ryan.png", class = "team-photo"),
                                div("Ryan Ng", class = "team-name"),
                                div("Data Analyst", class = "team-role"),
                                p("Conducted data analysis and visualisation, ensuring data accuracy and meaningful insights", class = "team-desc")
                            )
                     ),
                     column(4,
                            div(class = "team-card",
                                img(src = "Graham.png", class = "team-photo"),
                                div("Graham Kong", class = "team-name"),
                                div("Data Analyst", class = "team-role"),
                                p("Contributed to data analysis and visualisation, supporting insight generation and presentation", class = "team-desc")
                            )
                     )
                   )
               )
      ),
      
      
      # Methodology Tab - Enhanced Style
      tabPanel("Methodology",
               tags$style(HTML("
    .methodology-container {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      padding: 30px;
      border-radius: 20px;
      margin: 20px 0;
    }
    .methodology-header {
      background: rgba(255, 255, 255, 0.95);
      padding: 30px;
      border-radius: 15px;
      box-shadow: 0 12px 35px rgba(0,0,0,0.15);
      margin-bottom: 25px;
      text-align: center;
    }
    .main-title { color: #2c3e50; font-weight: 700; font-size: 32px; margin-bottom: 10px; }
    .subtitle { color: #6c757d; font-size: 16px; margin-bottom: 0px; }
    
    .methodology-content {
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .methodology-section {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 15px;
      padding: 25px;
      box-shadow: 0 8px 25px rgba(0,0,0,0.15);
      border-left: 5px solid #3498db;
      transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    .methodology-section:hover {
      transform: translateY(-3px);
      box-shadow: 0 12px 35px rgba(0,0,0,0.2);
    }
    .section-title {
      color: #2c3e50;
      font-weight: 600;
      font-size: 22px;
      margin-bottom: 10px;
      border-bottom: 2px solid #3498db;
      padding-bottom: 8px;
    }
    .section-desc {
      color: #6c757d;
      font-size: 17px;
      margin-bottom: 10px;
    }
    .section-list {
      margin-left: 20px;
      margin-bottom: 17px;
      color: #6c757d;
    }
    .code-section {
      background: #2d2d2d;
      border-radius: 12px;
      padding: 20px;
      font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
      color: #f8f9fa;
      overflow-x: auto;
      box-shadow: 0 8px 25px rgba(0,0,0,0.15);
    }
  ")),
               
               div(class = "methodology-container",
                   div(class = "methodology-header",
                       h1("Our Methodology", class = "main-title"),
                       p("Step-by-step explanation of the LGA Data Center Location Analysis workflow", class = "subtitle")
                   ),
                   
                   div(class = "methodology-content",
                       
                       div(class = "methodology-section",
                           h3("1. Data Collection & Preparation", class = "section-title"),
                           p("We gather spatial and non-spatial datasets for infrastructure, population, environment, and reliability.", class = "section-desc"),
                           tags$ul(class = "section-list",
                                   tags$li("Australian LGA boundaries (GeoJSON)"),
                                   tags$li("Transmission substations & electricity transmission lines"),
                                   tags$li("Major power stations"),
                                   tags$li("Railway stations for connectivity"),
                                   tags$li("Environmental risk datasets: bushfires and cyclone paths"),
                                   tags$li("Population density raster (GeoTIFF)"),
                                   tags$li("Temperature stations for cooling analysis"),
                                   tags$li("Electricity outage records for reliability assessment")
                           )
                       ),
                       
                       div(class = "methodology-section",
                           h3("2. Spatial Transformations", class = "section-title"),
                           p("All spatial layers are transformed to a common CRS (GDA2020 / Australian Albers) and empty geometries removed for consistency.", class = "section-desc")
                       ),
                       
                       div(class = "methodology-section",
                           h3("3. Centroid & Distance Calculations", class = "section-title"),
                           p("We calculate distances from each LGA centroid to infrastructure and risk points for scoring.", class = "section-desc"),
                           tags$ul(class = "section-list",
                                   tags$li("High-voltage substations"),
                                   tags$li("Major power stations"),
                                   tags$li("Transmission lines"),
                                   tags$li("Nearest railway station"),
                                   tags$li("Bushfire sites"),
                                   tags$li("Cyclone paths weighted by intensity")
                           )
                       ),
                       
                       div(class = "methodology-section",
                           h3("4. Population & Temperature Metrics", class = "section-title"),
                           p("Population density is extracted from a high-resolution raster. Cooling efficiency is calculated from nearest temperature station.", class = "section-desc")
                       ),
                       
                       div(class = "methodology-section",
                           h3("5. Reliability Metrics", class = "section-title"),
                           p("Historical electricity outages per LGA are summarized to assess reliability; fewer outages yield higher reliability scores.", class = "section-desc")
                       ),
                       
                       div(class = "methodology-section",
                           h3("6. Score Normalization", class = "section-title"),
                           p("Metrics are normalized 0-1. For metrics where lower values are better (distance, risks, outages), scores are inverted.", class = "section-desc")
                       ),
                       
                       div(class = "methodology-section",
                           h3("7. Composite Scoring", class = "section-title"),
                           p("Weighted combination of scores to generate overall suitability for data centers:", class = "section-desc"),
                           tags$ul(class = "section-list",
                                   tags$li("Power Infrastructure (35%) - average of power, substation, transmission scores"),
                                   tags$li("Population & Connectivity (25%) - average of population and rail proximity scores"),
                                   tags$li("Environmental Risk (15%) - average of fire and cyclone risk scores"),
                                   tags$li("Cooling Efficiency (15%) - temperature-based score"),
                                   tags$li("Reliability (10%) - electricity outage score")
                           )
                       ),
                       
                       div(class = "methodology-section",
                           h3("8. Principal Component Analysis (PCA)", class = "section-title"),
                           p("PCA is applied to all numerical metrics to identify dominant variance patterns. PC1 score provides an additional suitability metric.", class = "section-desc")
                       ),
                       
                       div(class = "methodology-section",
                           h3("9. Output & Visualization", class = "section-title"),
                           p("Processed data is exported (CSV, RDS, GeoPackage) and visualized with interactive maps, top-20 plots, and score histograms.", class = "section-desc")
                       ),
                       
                       div(class = "methodology-section",
                           h3("10. Reproducibility", class = "section-title"),
                           p("All scripts, datasets, and outputs are versioned and stored to ensure analysis can be fully reproduced.", class = "section-desc")
                       ),
                       
                       
                   )
               )
      )
    ),
    
    # Add some custom CSS
    tags$head(
      tags$style(HTML("
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .navbar-default {
          background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%) !important;
          border: none;
        }
        .navbar-default .navbar-brand {
          color: white !important;
          font-weight: 600;
          font-size: 20px;
        }
        .navbar-default .navbar-nav > li > a {
          color: rgba(255,255,255,0.9) !important;
          font-weight: 500;
        }
        .navbar-default .navbar-nav > li > a:hover {
          color: white !important;
          background: rgba(255,255,255,0.1);
        }
        .shiny-output-error { 
          color: #e74c3c; 
          font-weight: 500;
          padding: 15px;
          background: rgba(231, 76, 60, 0.1);
          border-radius: 8px;
          border-left: 4px solid #e74c3c;
        }
      "))
    )
  )
)