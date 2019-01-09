bins <- c(0, 0.25, 0.5, 0.75, 1)
pal <- colorBin("Spectral", domain = shapefile$elrate18, bins = bins)

labels <- sprintf(
  "<strong>%s</strong><br/>%s<br/>%g: electrification rate in 2018 <br/>%g: electrification rate in 2014 <br/>%g: electrification rate change",
  shapefile$NAME_1,  shapefile$NAME_0, shapefile$elrate18, shapefile$elrate14, shapefile$eldiff
) %>% lapply(htmltools::HTML)

