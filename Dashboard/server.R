library(shiny); library(leaflet); library(DT)

# Load objects from .RData into a sandbox env
data_env <- new.env()
load("Attempt2/lga_analysis_results.RData", envir = data_env)

top_lgas_clean     <- data_env$top_lgas_clean
lga_centroids_tbl  <- data_env$lga_centroids_clean   # likely plain tibble

# Load geometry from the gpkg (easiest for the map)
lga_sf <- sf::st_read("Attempt2/lga_data_center_analysis.gpkg", quiet = TRUE) |>
  sf::st_transform(4326)  # Leaflet wants WGS84

server <- function(input, output, session) {
  output$map <- leaflet::renderLeaflet({
    # pick the score column if it exists
    score_col <- if ("composite_score" %in% names(lga_sf)) {
      "composite_score"
    } else if ("score" %in% names(lga_sf)) {
      "score"
    } else {
      NULL
    }
    
    # palette + color vector (avoid mixing formula + string)
    pal <- if (!is.null(score_col))
      leaflet::colorNumeric("viridis", domain = lga_sf[[score_col]], na.color = "#bbb")
    else
      NULL
    
    col_vec <- if (!is.null(pal)) pal(lga_sf[[score_col]]) else rep("#4F46E5", nrow(lga_sf))
    
    # labels (fall back gracefully if name/state missing)
    base_name <- if ("lga_name" %in% names(lga_sf)) lga_sf$lga_name else rep("", nrow(lga_sf))
    state_part <- if ("state" %in% names(lga_sf)) paste0(" (", lga_sf$state, ")") else ""
    lbls <- if (!is.null(score_col)) {
      paste0(base_name, state_part, " — score: ", round(lga_sf[[score_col]], 2))
    } else {
      paste0(base_name, state_part)
    }
    
    m <- leaflet::leaflet(lga_sf) |>
      leaflet::addTiles() |>
      leaflet::addPolygons(
        weight = 0.5, color = "#444",
        fillColor = col_vec,
        fillOpacity = 0.6,
        label = lbls
      )
    
    if (!is.null(pal)) {
      m <- m |>
        leaflet::addLegend("bottomright", pal = pal, values = lga_sf[[score_col]], title = "Score")
    }
    m
  })
  output$scoreTable <- DT::renderDataTable({
    DT::datatable(top_lgas_clean, options = list(pageLength = 20, scrollX = TRUE), rownames = FALSE)
  })
  output$riskPlot <- renderPlot({
    cols <- intersect(names(top_lgas_clean), c("flood_risk","fire_risk","heat_risk"))
    if (length(cols) < 1) return(NULL)
    m <- colMeans(top_lgas_clean[cols], na.rm = TRUE)
    barplot(m, las = 2, main = "Mean Risk (Top 20)")
  })
}
