bins <- c(0, 0.25, 0.5, 0.75, 1)
pal <- colorBin("Spectral", domain = shapefile$elrate18, bins = bins)
pal2 <- colorBin("Spectral", domain = shapefile$elrate14, bins = bins)
bins2 <- c(-0.2, 0, 0.05, 0.10, 0.15, 0.20, 0.5)
pal3 <- colorBin("Reds", domain = shapefile$eldiff, bins = bins2)


labels <- sprintf(
  "<strong>%s</strong><br/>%s<br/>%g: electrification rate in 2018 <br/>%g: electrification rate in 2014 <br/>%g: electrification rate change",
  shapefile$NAME_1,  shapefile$NAME_0, shapefile$elrate18, shapefile$elrate14, shapefile$eldiff
) %>% lapply(htmltools::HTML)

