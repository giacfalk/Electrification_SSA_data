server <- function(input,output, session){

  output$mymap <- renderLeaflet({
  
  m <- leaflet(data = shapefile) %>%
    addProviderTiles("MapBox", options = providerTileOptions(
      id = "mapbox.light",
      accessToken = Sys.getenv('MAPBOX_ACCESS_TOKEN')))
  
  m <- m %>% addPolygons(
    group = "EL18",
    fillColor = ~pal(elrate18),
    weight = 1,
    opacity = 1,
    color = "white",
    dashArray = "1",
    fillOpacity = 0.9,
    highlight = highlightOptions(
      weight = 1,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.7,
      bringToFront = TRUE),
    label = labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "16px",
      direction = "auto")) %>% 
    addPolygons(
      group = "EL18",
      fillColor = ~pal(elrate18),
      weight = 1,
      opacity = 1,
      color = "white",
      dashArray = "1",
      fillOpacity = 0.9,
      highlight = highlightOptions(
        weight = 1,
        color = "#666",
        dashArray = "",
        fillOpacity = 0.7,
        bringToFront = TRUE),
      label = labels,
      labelOptions = labelOptions(
        style = list("font-weight" = "normal", padding = "3px 8px"),
        textsize = "16px",
        direction = "auto"))
  m
})
}