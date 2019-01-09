library(shiny)
library(leaflet)
library(dplyr)
library(sf)
library(htmltools)

pop18 = read.csv("data/pop18.csv")
pop16 = read.csv("data/pop16.csv")
pop14 = read.csv("data/pop14.csv")
no_acc_18 = read.csv("data/no_acc_18.csv")
no_acc_16 = read.csv("data/no_acc_16.csv")
no_acc_14 = read.csv("data/no_acc_14.csv")

merged_14 = merge(pop14, no_acc_14, by=c("GID_1"), all=TRUE)
merged_16 = merge(pop16, no_acc_16, by=c("GID_1"), all=TRUE)
merged_18 = merge(pop18, no_acc_18, by=c("GID_1"), all=TRUE)

merged_14=subset(merged_14, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_16=subset(merged_16, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_18=subset(merged_18, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_14 = dplyr::filter(merged_14,  !is.na(GID_0.x))
merged_16 = dplyr::filter(merged_16,  !is.na(GID_0.x))
merged_18 = dplyr::filter(merged_18,  !is.na(GID_0.x))

merged_18$elrate=(1-(merged_18$sum.y / merged_18$sum.x))
merged_16$elrate=(1-(merged_16$sum.y / merged_16$sum.x))
merged_14$elrate=(1-(merged_14$sum.y / merged_14$sum.x))

elrates = data.frame(merged_18$elrate, merged_16$elrate, merged_14$elrate, merged_14$GID_1, merged_14$GID_0.x)

varnames<-c("elrate18", "elrate16", "elrate14", "GID_1", "GID_0")
library(data.table)
setnames(elrates,names(elrates),varnames )

elrates$eldiff = elrates$elrate18 - elrates$elrate14 
elrates$eldiffpc = (elrates$elrate18 - elrates$elrate14) / elrates$elrate14

shapefile = st_read("data/gadm36_1.shp")
shapefile = merge(shapefile, elrates, by=c("GID_1"), all=TRUE)
shapefile = st_simplify(shapefile, dTolerance = 0.05)

bins <- c(0, 0.25, 0.5, 0.75, 1)
pal <- colorBin("Spectral", domain = shapefile$elrate18, bins = bins)

labels <- sprintf(
  "<strong>%s</strong><br/>%s<br/>%g: electrification rate in 2018 <br/>%g: electrification rate in 2014 <br/>%g: electrification rate change",
  shapefile$NAME_1,  shapefile$NAME_0, shapefile$elrate18, shapefile$elrate14, shapefile$eldiff
) %>% lapply(htmltools::HTML)

