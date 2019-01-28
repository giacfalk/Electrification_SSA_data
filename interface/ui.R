ui <-shinyUI( 
  fluidPage(tags$head(
    tags$style(HTML(".leaflet-container { background: #FFFFFF; }"))
  ),
  leafletOutput("mymap", height = 800),
  hr(),
  print("Giacomo Falchetta, https://github.com/giacfalk/Electrification_SSA_data")
))