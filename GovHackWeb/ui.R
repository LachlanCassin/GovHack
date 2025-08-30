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
      # Team Members Tab
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
           }
           .team-card {
             background: rgba(255, 255, 255, 0.95);
             padding: 25px;
             border-radius: 12px;
             box-shadow: 0 4px 15px rgba(0,0,0,0.08);
             margin-bottom: 20px;
             border-left: 4px solid #667eea;
             transition: transform 0.3s ease, box-shadow 0.3s ease;
           }
           .team-card:hover {
             transform: translateY(-5px);
             box-shadow: 0 8px 25px rgba(0,0,0,0.15);
           }
           .team-name {
             color: #2c3e50;
             font-weight: 600;
             font-size: 18px;
             margin-bottom: 5px;
           }
           .team-role {
             color: #667eea;
             font-weight: 500;
             margin-bottom: 10px;
           }
           .team-contact {
             color: #6c757d;
             font-size: 14px;
           }
         ")),
               
               div(class = "team-container",
                   div(class = "team-header",
                       h1("Our Team", class = "main-title"),
                       p("Meet the experts behind the data center location analysis", class = "subtitle")
                   ),
                   
                   fluidRow(
                     column(4,
                            div(class = "team-card",
                                h4("Data Scientist", class = "team-role"),
                                p("Ryan Ng", class = "team-name"),
                                p("Found and processed data sets, created R scripts", style = "color: #6c757d;"),
                            )
                     ),
                     column(4,
                            div(class = "team-card",
                                h4("Shiny App Developer", class = "team-role"),
                                p("Lachlan Cassin", class = "team-name"),
                                p("Developed Shiny app and integrated data into the web interface", style = "color: #6c757d;"),
                            )
                     ),
                     column(4,
                            div(class = "team-card",
                                h4("Data Analyst", class = "team-role"),
                                p("Graham Kong", class = "team-name"),
                                p("Found data sets and created R scripts for analysis", style = "color: #6c757d;"),
                            )
                     )
                   )
               )
      ),
      # Replace your current Methodology tab with this code
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
      box-shadow: 0 8px 32px rgba(0,0,0,0.1);
      margin-bottom: 25px;
    }
    .code-section {
      background: #2d2d2d;
      border-radius: 10px;
      padding: 25px;
      margin: 20px 0;
      font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
      color: #f8f9fa;
      overflow-x: auto;
    }
    .methodology-content {
      background: rgba(255, 255, 255, 0.95);
      border-radius: 15px;
      padding: 30px;
      box-shadow: 0 4px 15px rgba(0,0,0,0.08);
    }
  ")),
               
               div(class = "methodology-container",
                   div(class = "methodology-header",
                       h1("Our Methodology", class = "main-title"),
                       p("Detailed explanation of our data processing and analysis approach", class = "subtitle")
                   ),
                   
                   div(class = "methodology-content",
                       h3("Analytical Approach", style = "color: #2c3e50; margin-bottom: 20px;"),
                       p("Our methodology combined Principal Component Analysis (PCA) with a weighted scoring system to identify optimal data center locations:", 
                         style = "color: #6c757d; margin-bottom: 15px;"),
                       
                       h4("Principal Component Analysis", style = "color: #2c3e50; margin-top: 25px;"),
                       p("We performed PCA to reduce dimensionality and identify the most influential factors:", 
                         style = "color: #6c757d; margin-bottom: 10px;"),
                       tags$ul(
                         tags$li("Standardized all variables to mean = 0, variance = 1"),
                         tags$li("Identified PC1 as explaining the highest proportion of variance"),
                         tags$li("Used PC1 loadings to determine variable importance"),
                         tags$li("Created PC1 scores for each LGA as a data-driven suitability metric")
                       ),
                       
                       h4("Composite Weighting System", style = "color: #2c3e50; margin-top: 25px;"),
                       p("Based on PCA results and domain knowledge, we developed a weighted scoring system:", 
                         style = "color: #6c757d; margin-bottom: 10px;"),
                       tags$ul(
                         tags$li("Power Infrastructure (35%): Distance to substations, power stations, and transmission lines"),
                         tags$li("Population & Connectivity (25%): Population density and railway access"),
                         tags$li("Environmental Risk (15%): Bushfire and cyclone risks"),
                         tags$li("Cooling Efficiency (15%): Annual temperature patterns"),
                         tags$li("Reliability (10%): Electricity outage history")
                       ),
                       
                       h4("Data Integration", style = "color: #2c3e50; margin-top: 25px;"),
                       p("We combined multiple data sources and performed spatial analysis:", 
                         style = "color: #6c757d; margin-bottom: 10px;"),
                       tags$ul(
                         tags$li("Geospatial processing of LGA boundaries"),
                         tags$li("Point-in-polygon analysis for infrastructure features"),
                         tags$li("Normalization of all scores to a 0-100 scale"),
                         tags$li("Calculation of final composite scores for ranking")
                       ),
                       
                       h3("Data Processing Code", style = "color: #2c3e50; margin-top: 30px; margin-bottom: 20px;"),
                       div(class = "code-section",
                           verbatimTextOutput("dataProcessingCode")
                       )
                   )
               )
      )
      # Methodology Tab
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
                   box-shadow: 0 8px 32px rgba(0,0,0,0.1);
                   margin-bottom: 25px;
                 }
                 .code-section {
                   background: #2d2d2d;
                   border-radius: 10px;
                   padding: 25px;
                   margin: 20px 0;
                   font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
                   color: #f8f9fa;
                   overflow-x: auto;
                 }
                 .methodology-content {
                   background: rgba(255, 255, 255, 0.95);
                   border-radius: 15px;
                   padding: 30px;
                   box-shadow: 0 4px 15px rgba(0,0,0,0.08);
                 }
               ")),
               
               div(class = "methodology-container",
                   div(class = "methodology-header",
                       h1("Our Methodology", class = "main-title"),
                       p("Detailed explanation of our data processing and analysis approach", class = "subtitle")
                   ),
                   
                   div(class = "methodology-content",
                       h3("Data Processing Code", style = "color: #2c3e50; margin-bottom: 20px;"),
                       div(class = "code-section",
                           verbatimTextOutput("dataProcessingCode")
                       ),
                       
                       h3("Weighted Scoring Methodology", style = "color: #2c3e50; margin-top: 30px;"),
                       p("Our composite score combines multiple factors with the following weights:", 
                         style = "color: #6c757d; margin-bottom: 15px;"),
                       tags$ul(
                         tags$li("Power Infrastructure (35%): Distance to substations, power stations, and transmission lines"),
                         tags$li("Population & Connectivity (25%): Population density and railway access"),
                         tags$li("Environmental Risk (15%): Bushfire and cyclone risks"),
                         tags$li("Cooling Efficiency (15%): Annual temperature patterns"),
                         tags$li("Reliability (10%): Electricity outage history")
                       )
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