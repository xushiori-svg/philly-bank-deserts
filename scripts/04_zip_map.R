#install.packages(c("leaflet", "leaflet.extras", "tigris"))
library(dplyr)
library(sf)
library(tigris)
library(leaflet)
library(leaflet.extras)
library(htmlwidgets)
library(htmltools)
library(scales)

options(tigris_use_cache = TRUE)

tracts <- st_read("data/clean/tracts_bank_access.gpkg")
branches <- st_read("data/clean/branches_philly.gpkg")

# ZIP code areas starting with 191 (PA)
zips <- zctas(cb = TRUE, year = 2020, starts_with = "191")

zip_pts <- zips %>%
  st_transform(2272) %>%
  st_point_on_surface() %>%
  st_transform(4326)

tracts <- st_transform(tracts, 4326)
branches <- st_transform(branches, 4326)

tract_label <- paste0(
  "<b>", tracts$tract, "</b><br>",
  "Median income: ", dollar(tracts$income, accuracy = 1), "<br>",
  "Households without a car: ", percent(tracts$nocar_rate, accuracy = 1), "<br>",
  "Nearest branch: ", round(tracts$dist_mi, 2), " mi (", tracts$nearest_bank, ")"
) %>%
  lapply(HTML)

pal <- colorNumeric("Reds", domain = tracts$dist_mi)

zip_map <- leaflet() %>%
  addTiles() %>%
  setView(lng = -75.13, lat = 40.00, zoom = 11) %>%
  addPolygons(
    data = tracts,
    fillColor = ~pal(dist_mi),
    fillOpacity = 0.7,
    color = "white",
    weight = 0.5,
    label = tract_label,
    highlightOptions = highlightOptions(weight = 2, color = "black", bringToFront = TRUE)
  ) %>%
  addCircleMarkers(
    data = branches,
    radius = 3,
    color = "black",
    weight = 1,
    fillColor = "white",
    fillOpacity = 1,
    label = ~NAME
  ) %>%
  addCircleMarkers(
    data = zip_pts,
    radius = 0,
    opacity = 0,
    fillOpacity = 0,
    label = ~ZCTA5CE20,
    group = "zip"
  ) %>%
  addSearchFeatures(
    targetGroups = "zip",
    options = searchFeaturesOptions(
      zoom = 14,
      firstTipSubmit = TRUE,
      collapsed = FALSE,
      autoCollapse = FALSE,
      textPlaceholder = "Enter a ZIP code, e.g. 19104"
    )
  ) %>%
  addLegend(
    pal = pal,
    values = tracts$dist_mi,
    title = "Miles to nearest<br>bank branch",
    position = "bottomright"
  )

zip_map
saveWidget(zip_map, "results/fig2_zip_map.html", selfcontained = TRUE)
unlink("results/fig2_zip_map_files", recursive = TRUE)
