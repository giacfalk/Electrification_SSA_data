##R Script for: 
##A High-Resolution Gridded Dataset to Assess Electrification in Sub-Saharan Africa
##Giacomo Falchetta, Shonali Pachauri, Simon Parkinson, Edward Byers
## Version: 29/04/18

##NB This script must be run after the Earth Engine (EE) javascript code. 
#The googledrive package will call and download the files generated in EE. 
#The script produces figures and statistics, and can be easily manipupalted to produce new metrics.
#Supporting files and folder structure as in the GitHub repository are required for the script to run successfully.
#Any question should be addressed to giacomo.falchetta@feem.it

##NB First, set the working directory to the directory of the cloned repository

#Install the appropriate version of the required libraries 
install.packages("checkpoint")
library(checkpoint)
checkpoint("2019-04-28")

#Load libraries
library(raster)
library(ncdf4)
library(RNetCDF)
library(googledrive)
library(data.table)
library(dplyr)
library(ggplot2)
library(scales)
library(ggpmisc)
library(wbstats)
library(ggrepel)
library(ineq)
library(sf)
library(cowplot)
library(rworldmap)
library(rgdal)
library(reshape2)
library(latex2exp)
library(tidyr)
library(sf)
library(rgdal)
library(ggthemes)
library(RColorBrewer)
library(gtools)

#Google Drive authentication (to be run before launching the entire script)
drive_find(n_max = 30)

#0) Generate the NetCDF4 dataset for people without access
drive_download("pop_noaccess-0000000000-0000014848.tif", type = "tif", overwrite = TRUE)
data = stack("pop_noaccess-0000000000-0000014848.tif")

names(data)<-c(2014:2018)

writeRaster(data, "noaccess_SSA_2014_2018.nc", overwrite=TRUE, varname="Pop_no_access", varunit="n", 
            longname="People_without_access", xname="Longitude",   yname="Latitude", zname="Year", force_v4=TRUE, compression=7)

#0.1) Generate the NetCDF4 dataset for tiers
drive_download("tiers-0000000000-0000000000.tif", type = "tif", overwrite = TRUE)
data = raster("tiers-0000000000-0000000000.tif")

writeRaster(data, "tiersofaccess_SSA_2018.nc", overwrite=TRUE, varname="Tiers_of_access", varunit="tier", 
            longname="Tiers_of_access", xname="Longitude",   yname="Latitude", force_v4=TRUE, compression=7)

#1) Import data for populaiton and population without access

drive_download("pop18.csv", type = "csv", overwrite = TRUE)
pop18 = read.csv("pop18.csv")
    
drive_download("pop16.csv", type = "csv", overwrite = TRUE)
pop16 = read.csv("pop16.csv")

drive_download("pop14.csv", type = "csv", overwrite = TRUE)
pop14 = read.csv("pop14.csv")
    
drive_download("no_acc_18.csv", type = "csv", overwrite = TRUE)
no_acc_18 = read.csv("no_acc_18.csv")

drive_download("no_acc_16.csv", type = "csv", overwrite = TRUE)
no_acc_16 = read.csv("no_acc_16.csv")
    
drive_download("no_acc_14.csv", type = "csv", overwrite = TRUE)
no_acc_14 = read.csv("no_acc_14.csv")
    
#1.1) Merge different years, remove non Sub-Saharan countries and other misc provinces
merged_14 = merge(pop14, no_acc_14, by=c("GID_1"), all=TRUE)
merged_16 = merge(pop16, no_acc_16, by=c("GID_1"), all=TRUE)
merged_18 = merge(pop18, no_acc_18, by=c("GID_1"), all=TRUE)
    
merged_14=subset(merged_14, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_16=subset(merged_16, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_18=subset(merged_18, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
    
merged_14 = dplyr::filter(merged_14,  !is.na(GID_0.x))
merged_16 = dplyr::filter(merged_16,  !is.na(GID_0.x))
merged_18 = dplyr::filter(merged_18,  !is.na(GID_0.x))
    
#2) Calculate province-level electrification rates and merge them into a single dataframe 
merged_18$elrate=(1-(merged_18$sum.y / merged_18$sum.x))
merged_16$elrate=(1-(merged_16$sum.y / merged_16$sum.x))
merged_14$elrate=(1-(merged_14$sum.y / merged_14$sum.x))
    
elrates = data.frame(merged_18$elrate, merged_16$elrate, merged_14$elrate, merged_14$GID_1, merged_14$GID_0.x, merged_18$sum.x, merged_14$sum.x)
    
varnames<-c("elrate18", "elrate16", "elrate14", "GID_1", "GID_0", "pop18", "pop14")

setnames(elrates,names(elrates),varnames )
    
#2.1) Calculate the change in electrification rates over the two years considered
elrates$eldiff = elrates$elrate18 - elrates$elrate14 
elrates$eldiffpc = (elrates$elrate18 - elrates$elrate14) / elrates$elrate14
    
#3) Calculate national electrification rates

merged_14_countrylevel = merged_14 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_14_countrylevel$elrate = (1-(merged_14_countrylevel$popnoacc/merged_14_countrylevel$pop))
    
merged_16_countrylevel = merged_16 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_16_countrylevel$elrate = (1-(merged_16_countrylevel$popnoacc/merged_16_countrylevel$pop))

merged_18_countrylevel = merged_18 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_18_countrylevel$elrate = (1-(merged_18_countrylevel$popnoacc/merged_18_countrylevel$pop))
    
merged_diff=data.frame(merged_18_countrylevel$GID_0.x, (merged_18_countrylevel$elrate-merged_14_countrylevel$elrate), merged_18_countrylevel$elrate, merged_16_countrylevel$elrate, merged_14_countrylevel$elrate, merged_14_countrylevel$pop, merged_18_countrylevel$pop)
merged_diff <- na.omit(merged_diff)
varnames<-c("GID_0", "elrate_diff", "elrate18", "elrate16","elrate14", "pop14", "pop18")
setnames(merged_diff,names(merged_diff),varnames )
merged_diff$popch=merged_diff$pop18-merged_diff$pop14
    
#3.1) Urban and rural electrificaiton estimation
drive_download("pop18_rur.csv", type = "csv", overwrite = TRUE)
pop18_rur = read.csv("pop18_rur.csv")

drive_download("pop16_rur.csv", type = "csv", overwrite = TRUE)
pop16_rur = read.csv("pop16_rur.csv")

drive_download("pop14_rur.csv", type = "csv", overwrite = TRUE)
pop14_rur = read.csv("pop14_rur.csv")

drive_download("no_acc_18_rur.csv", type = "csv", overwrite = TRUE)
no_acc_18_rur = read.csv("no_acc_18_rur.csv")

drive_download("no_acc_16_rur.csv", type = "csv", overwrite = TRUE)
no_acc_16_rur = read.csv("no_acc_16_rur.csv")

drive_download("no_acc_14_rur.csv", type = "csv", overwrite = TRUE)
no_acc_14_rur = read.csv("no_acc_14_rur.csv")

#Merge different years, remove non Sub-Saharan countries and other misc provinces
merged_14_rur = merge(pop14_rur, no_acc_14_rur, by=c("GID_1"), all=TRUE)
merged_16_rur = merge(pop16_rur, no_acc_16_rur, by=c("GID_1"), all=TRUE)
merged_18_rur = merge(pop18_rur, no_acc_18_rur, by=c("GID_1"), all=TRUE)

merged_14_rur=subset(merged_14_rur, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_16_rur=subset(merged_16_rur, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_18_rur=subset(merged_18_rur, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_14_rur = dplyr::filter(merged_14_rur,  !is.na(GID_0.x))
merged_16_rur = dplyr::filter(merged_16_rur,  !is.na(GID_0.x))
merged_18_rur = dplyr::filter(merged_18_rur,  !is.na(GID_0.x))

merged_18_rur$elrate=(1-(merged_18_rur$sum.y / merged_18_rur$sum.x))
merged_16_rur$elrate=(1-(merged_16_rur$sum.y / merged_16_rur$sum.x))
merged_14_rur$elrate=(1-(merged_14_rur$sum.y / merged_14_rur$sum.x))

elrates_rur = data.frame(merged_18_rur$elrate, merged_16_rur$elrate, merged_14_rur$elrate, merged_14_rur$GID_1, merged_14_rur$GID_0.x, merged_18_rur$sum.x, merged_14_rur$sum.x)

varnames<-c("elrate18", "elrate16", "elrate14", "GID_1", "GID_0", "pop18", "pop14")

setnames(elrates_rur,names(elrates_rur),varnames )

#Calculate the change in electrification rates over the two years considered
elrates_rur$eldiff = elrates_rur$elrate18 - elrates_rur$elrate14 
elrates_rur$eldiffpc = (elrates_rur$elrate18 - elrates_rur$elrate14) / elrates_rur$elrate14

#Calculate rural electrification rates
merged_14_countrylevel_rur = merged_14_rur %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_14_countrylevel_rur$elrate = (1-(merged_14_countrylevel_rur$popnoacc/merged_14_countrylevel_rur$pop))

merged_16_countrylevel_rur = merged_16_rur %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_16_countrylevel_rur$elrate = (1-(merged_16_countrylevel_rur$popnoacc/merged_16_countrylevel_rur$pop))

merged_18_countrylevel_rur = merged_18_rur %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_18_countrylevel_rur$elrate = (1-(merged_18_countrylevel_rur$popnoacc/merged_18_countrylevel_rur$pop))

merged_diff_rur=data.frame(merged_18_countrylevel_rur$GID_0.x, (merged_18_countrylevel_rur$elrate-merged_14_countrylevel_rur$elrate), merged_18_countrylevel_rur$elrate, merged_16_countrylevel_rur$elrate, merged_14_countrylevel_rur$elrate, merged_14_countrylevel_rur$pop, merged_18_countrylevel_rur$pop)
merged_diff_rur <- na.omit(merged_diff_rur)
varnames<-c("GID_0", "elrate_diff", "elrate18", "elrate16","elrate14", "pop14", "pop18")
setnames(merged_diff_rur,names(merged_diff_rur),varnames )

##Urban
drive_download("pop18_urb.csv", type = "csv", overwrite = TRUE)
pop18_urb = read.csv("pop18_urb.csv")

drive_download("pop16_urb.csv", type = "csv", overwrite = TRUE)
pop16_urb = read.csv("pop16_urb.csv")

drive_download("pop14_urb.csv", type = "csv", overwrite = TRUE)
pop14_urb = read.csv("pop14_urb.csv")

drive_download("no_acc_18_urb.csv", type = "csv", overwrite = TRUE)
no_acc_18_urb = read.csv("no_acc_18_urb.csv")

drive_download("no_acc_16_urb.csv", type = "csv", overwrite = TRUE)
no_acc_16_urb = read.csv("no_acc_16_urb.csv")

drive_download("no_acc_14_urb.csv", type = "csv", overwrite = TRUE)
no_acc_14_urb = read.csv("no_acc_14_urb.csv")

#Merge different years, remove non Sub-Saharan countries and other misc provinces
merged_14_urb = merge(pop14_urb, no_acc_14_urb, by=c("GID_1"), all=TRUE)
merged_16_urb = merge(pop16_urb, no_acc_16_urb, by=c("GID_1"), all=TRUE)
merged_18_urb = merge(pop18_urb, no_acc_18_urb, by=c("GID_1"), all=TRUE)

merged_14_urb=subset(merged_14_urb, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_16_urb=subset(merged_16_urb, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_18_urb=subset(merged_18_urb, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_14_urb = dplyr::filter(merged_14_urb,  !is.na(GID_0.x))
merged_16_urb = dplyr::filter(merged_16_urb,  !is.na(GID_0.x))
merged_18_urb = dplyr::filter(merged_18_urb,  !is.na(GID_0.x))

#Calculate province-level electrification rates and merge them into a single dataframe 
merged_18_urb$elrate=(1-(merged_18_urb$sum.y / merged_18_urb$sum.x))
merged_16_urb$elrate=(1-(merged_16_urb$sum.y / merged_16_urb$sum.x))
merged_14_urb$elrate=(1-(merged_14_urb$sum.y / merged_14_urb$sum.x))

elrates_urb = data.frame(merged_18_urb$elrate, merged_16_urb$elrate, merged_14_urb$elrate, merged_14_urb$GID_1, merged_14_urb$GID_0.x, merged_18_rur$sum.x, merged_14_rur$sum.x)

varnames<-c("elrate18", "elrate16", "elrate14", "GID_1", "GID_0", "pop18", "pop14")
setnames(elrates_urb,names(elrates_urb),varnames )

#Calculate the change in electrification rates over the two years considered
elrates_urb$eldiff = elrates_urb$elrate18 - elrates_urb$elrate14 
elrates_urb$eldiffpc = (elrates_urb$elrate18 - elrates_urb$elrate14) / elrates_urb$elrate14

#Calculate urban electrification rates
merged_14_countrylevel_urb = merged_14_urb %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_14_countrylevel_urb$elrate = (1-(merged_14_countrylevel_urb$popnoacc/merged_14_countrylevel_urb$pop))

merged_16_countrylevel_urb = merged_16_urb %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_16_countrylevel_urb$elrate = (1-(merged_16_countrylevel_urb$popnoacc/merged_16_countrylevel_urb$pop))

merged_18_countrylevel_urb = merged_18_urb %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_18_countrylevel_urb$elrate = (1-(merged_18_countrylevel_urb$popnoacc/merged_18_countrylevel_urb$pop))

merged_diff_urb=data.frame(merged_18_countrylevel_urb$GID_0.x, (merged_18_countrylevel_urb$elrate-merged_14_countrylevel_urb$elrate), merged_18_countrylevel_urb$elrate, merged_16_countrylevel_urb$elrate, merged_14_countrylevel_urb$elrate, merged_14_countrylevel_urb$pop, merged_18_countrylevel_urb$pop)
merged_diff_urb <- na.omit(merged_diff_urb)
varnames<-c("GID_0", "elrate_diff", "elrate18", "elrate16","elrate14", "pop14", "pop18")
setnames(merged_diff_urb,names(merged_diff_urb),varnames )

#4) Calculate the total number of people without access in each country
merged_noaccess = data.frame(merged_14_countrylevel$GID_0.x, merged_14_countrylevel$popnoacc,  merged_18_countrylevel$popnoacc)
merged_noaccess$difference = merged_noaccess$merged_18_countrylevel.popnoacc-merged_noaccess$merged_14_countrylevel.popnoacc

#########
#5) Download World Bank / ESMAP electrification data to validate the approach
formula <- y ~ x

elrate_wb <- wb(indicator = "EG.ELC.ACCS.ZS", startdate = 2016, enddate = 2016)
elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)
merged_18_countrylevel = merge(merged_18_countrylevel, elrate_wb, by.x = "GID_0.x", by.y = "elrate_wb.iso3c")

gdppc <- wb(indicator = "NY.GDP.PCAP.PP.KD", startdate = 2016, enddate = 2016)
gdppc = data.frame(gdppc$iso3c, gdppc$value)
merged_18_countrylevel = merge(merged_18_countrylevel, gdppc, by.x = "GID_0.x", by.y = "gdppc.iso3c")

#5.1) Calculate the discrepancy between estimate and WB data
merged_18_countrylevel$discrepancy = merged_18_countrylevel$elrate - merged_18_countrylevel$elrate_wb.value/100

#5.2) Validation plot

my_breaks = c(1000, 2500, 7500)

comparisonwb = ggplot(merged_18_countrylevel, aes(x=elrate, y=elrate_wb.value/100))+
  geom_point(data=merged_18_countrylevel, aes(x=elrate, y=elrate_wb.value/100, size=pop/1e06, colour=gdppc.value), alpha=0.7)+
  geom_label_repel(data=merged_18_countrylevel, aes(x=elrate, y=elrate_wb.value/100, label = GID_0.x),
                   box.padding   = 0.2, 
                   point.padding = 0.3,
                   segment.color = 'grey50') +
  scale_size_continuous(range = c(3, 14), name = "Total pop. (million)")+
  scale_colour_continuous(name = "PPP per-capita GDP", type = "viridis", trans = "log", breaks = my_breaks, labels = my_breaks)+
  theme_classic()+
  geom_abline()+
  ylab("Country-level electrification level - ESMAP/World Bank")+
  xlab("Country-level electrification level - Estimated")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  theme(axis.title=element_text(size=12), axis.title.y = element_text(size = 14), axis.title.x = element_text(size = 14), legend.text=element_text(size=14))+
  stat_poly_eq(aes(label = paste(..rr.label..)), 
               label.x.npc = "right", label.y.npc = 0.15,
               formula = formula, parse = TRUE, size = 8)


ggsave("Comparison_national.pdf", comparisonwb, device = "pdf", width = 20, height = 12, units = "cm", scale=1.2)

#6) Create plot for province-level electrification validation based on DHS Statcompiler survey data
province = read.csv("shapefile/Parsing.csv")

#DRC, Zambia, Burkina Faso 2014
#Mozambique, Angola, Malawi, Zimbabwe, Nigeria 2015
#Burundi, Ethiopia, Ghana, Sierra Leone 2016
# Senegal, Togo, Tanzania 2017

drive_download("pop18_valid.csv", type = "csv", overwrite = TRUE)
pop18 = read.csv("pop18_valid.csv")

drive_download("no_acc_14_valid.csv", type = "csv", overwrite = TRUE)
no_acc_14 = read.csv("no_acc_14_valid.csv")

drive_download("no_acc_15_valid.csv", type = "csv", overwrite = TRUE)
no_acc_15 = read.csv("no_acc_15_valid.csv")

drive_download("no_acc_16_valid.csv", type = "csv", overwrite = TRUE)
no_acc_16 = read.csv("no_acc_16_valid.csv")

drive_download("no_acc_17_valid.csv", type = "csv", overwrite = TRUE)
no_acc_17 = read.csv("no_acc_17_valid.csv")

#Merge with corresponding year, clean
merged_14 = merge(no_acc_14, pop18, by=c("GID_1"))
merged_15 = merge(no_acc_15, pop18, by=c("GID_1"))
merged_16 = merge(no_acc_16, pop18, by=c("GID_1"))
merged_17 = merge(no_acc_17, pop18, by=c("GID_1"))

merged_14=subset(merged_14, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_15=subset(merged_15, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_16=subset(merged_16, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_17=subset(merged_17, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_14 = dplyr::filter(merged_14,  !is.na(GID_0.x))
merged_15 = dplyr::filter(merged_15,  !is.na(GID_0.x))
merged_16 = dplyr::filter(merged_16,  !is.na(GID_0.x))
merged_17 = dplyr::filter(merged_17,  !is.na(GID_0.x))


#6.1) Calculate province-level electrification rates for validation 
merged_14$elrate=(1-(merged_14$sum.x / merged_14$sum.y))
merged_15$elrate=(1-(merged_15$sum.x / merged_15$sum.y))
merged_16$elrate=(1-(merged_16$sum.x / merged_16$sum.y))
merged_17$elrate=(1-(merged_17$sum.x / merged_17$sum.y))

prova = rbind(merged_14, merged_15, merged_16, merged_17)
prova = merge(province, prova, by="GID_1")

formula <- y ~ x

#6.2) Province-level validation plot
ggplot(data=prova, aes(x=elrate, y=elaccess/100))+
  geom_point(aes(x=elrate, y=elaccess/100, color=GID_0.x, size=sum.y/1e06), alpha=0.7)+
  theme_classic()+
  geom_abline()+
  scale_size_continuous(range = c(3, 14), name = "Total pop. (million)")+
  scale_colour_discrete(name = "Country")+
  ylab("Province-level electrification level - DHS surveys data")+
  xlab("Province-level electrification level - Estimated")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  guides(colour = guide_legend(override.aes = list(size=7), ncol=2))+
  theme(axis.title=element_text(size=12), axis.title.y = element_text(size = 14), axis.title.x = element_text(size = 14), legend.text=element_text(size=10))+
  stat_poly_eq(aes(label = paste(..rr.label..)), 
               label.x.npc = "right", label.y.npc = 0.15,
               formula = formula, parse = TRUE, size = 8)


ggsave("Comparison_province.pdf", device = "pdf", width = 20, height = 12, units = "cm", scale=1.2)

formula = "elaccess/100  ~ elrate"
model = lm(formula, data = prova)
prova$resid <- residuals(model)

#######
## Define and validate rural/urban distinction
drive_download("popu0.csv", type = "csv", overwrite = TRUE)
popu0 = read.csv("popu0.csv")

drive_download("popu1.csv", type = "csv", overwrite = TRUE)
popu1 = read.csv("popu1.csv")

drive_download("popu2.csv", type = "csv", overwrite = TRUE)
popu2 = read.csv("popu2.csv")

drive_download("popu3.csv", type = "csv", overwrite = TRUE)
popu3 = read.csv("popu3.csv")

drive_download("popu4.csv", type = "csv", overwrite = TRUE)
popu4 = read.csv("popu4.csv")

drive_download("popu5.csv", type = "csv", overwrite = TRUE)
popu5 = read.csv("popu5.csv")

#

drive_download("popt0.csv", type = "csv", overwrite = TRUE)
popt0 = read.csv("popt0.csv")

drive_download("popt1.csv", type = "csv", overwrite = TRUE)
popt1 = read.csv("popt1.csv")

drive_download("popt2.csv", type = "csv", overwrite = TRUE)
popt2 = read.csv("popt2.csv")

drive_download("popt3.csv", type = "csv", overwrite = TRUE)
popt3 = read.csv("popt3.csv")

drive_download("popt4.csv", type = "csv", overwrite = TRUE)
popt4 = read.csv("popt4.csv")

drive_download("popt5.csv", type = "csv", overwrite = TRUE)
popt5 = read.csv("popt5.csv")

#

popu = rbind(popu0, popu1, popu2, popu3, popu4, popu5)
popt = rbind(popt0, popt1, popt2, popt3, popt4, popt5)

#

merged = merge(popu, popt, by=c("ISO3"), all=TRUE)

merged$urbrate = merged$sum.x / merged$sum.y

elrate_wb <- wb(indicator = "SP.URB.TOTL.IN.ZS", startdate = 2017, enddate = 2017)

elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)

merged_countrylevel = merge(merged, elrate_wb, by.x = "ISO3", by.y = "elrate_wb.iso3c")

merged_countrylevel$discrepancy = merged_countrylevel$elrate_wb.value / 100 - merged_countrylevel$urbrate

formula = "elrate_wb.value/100 ~ urbrate"
summary(lm(data= merged_countrylevel, formula=formula))

formula = y ~ x

my_breaks = c(1000, 2500, 7500)

gdppc <- wb(indicator = "NY.GDP.PCAP.PP.KD", startdate = 2016, enddate = 2016)
gdppc = data.frame(gdppc$iso3c, gdppc$value)
merged_countrylevel = merge(merged_countrylevel, gdppc, by.x = "ISO3", by.y = "gdppc.iso3c")

library(ggrepel)
library(ggpmisc)

ruralvalid = ggplot(merged_countrylevel, aes(x=urbrate, y = elrate_wb.value/100))+
  geom_point(data=merged_countrylevel, aes(x=urbrate, y = elrate_wb.value/100, size=sum.y/1e06, colour=gdppc.value), alpha=0.7)+
  geom_label_repel(data=merged_countrylevel, aes(x=urbrate, y = elrate_wb.value/100, label = ISO3),
                   box.padding   = 0.2, 
                   point.padding = 0.3,
                   segment.color = 'grey50') +
  scale_colour_continuous(name = "PPP per-capita GDP", type = "viridis", trans = "log", breaks = my_breaks, labels = my_breaks)+
  theme_classic()+
  geom_abline()+
  scale_size_continuous(range = c(3, 14), name = "Total pop. (million)")+
  xlab("Estimated urban population share")+
  ylab("World Bank reported urban population share")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0.1,0.8))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0.1,0.8))+
  theme(axis.title=element_text(size=12), axis.title.y = element_text(size = 14), axis.title.x = element_text(size = 14), legend.text=element_text(size=14))+
  stat_poly_eq(aes(label = paste(..rr.label..)), 
               label.x.npc = "right", label.y.npc = 0.15,
               formula = formula, parse = TRUE, size = 8)


ggsave("Ruralvalid.pdf", ruralvalid, device = "pdf", width = 20, height = 12, units = "cm", scale=1.2)

##Define percentiles and thresholds of light per capita in urban and rural areas and plot histogram
drive_download("pctiles_pc_urban.csv", type = "csv", overwrite = TRUE)
histogram = read.csv("pctiles_pc_urban.csv")

histogram = histogram %>% gather(percentile, value, -c(ISO3))

histogram = histogram[complete.cases(histogram$value), ]

library(plyr)
cdat <- ddply(histogram, "percentile", summarise, value.mean=median(value))

histogram1 = ggplot(subset(histogram, value < 1.5), aes(x=value, fill=percentile)) +
  scale_x_continuous(limits = c(0,1.5))+
  theme_classic()+
  geom_density(alpha=.4) +
  geom_vline(data=cdat, aes(xintercept=value.mean,  colour=percentile),
             linetype="dashed", size=1)+
  xlab(TeX("Radiance ($\\mu W \\cdot cm^{-2} \\cdot sr^{-1}$)"))+
  ylab("Density")+
  scale_color_discrete(name="Median")+
  scale_fill_discrete(name="Percentile")

ggsave("Histogram_urban.pdf", plot = histogram1, device = "pdf", width = 20, height = 12, units = "cm", scale=0.8)

drive_download("pctiles_pc_rural.csv", type = "csv", overwrite = TRUE)
histogram = read.csv("pctiles_pc_rural.csv")

histogram = histogram %>% gather(percentile, value, -c(ISO3))

histogram = histogram[complete.cases(histogram$value), ]

library(plyr)
cdat <- ddply(histogram, "percentile", summarise, value.mean=median(value))

histogram2 = ggplot(subset(histogram, value < 1.5), aes(x=value, fill=percentile)) +
  theme_classic()+
  geom_density(alpha=.4) +
  scale_x_continuous(limits = c(0,1.5))+
  geom_vline(data=cdat, aes(xintercept=value.mean,  colour=percentile),
             linetype="dashed", size=1)+
  xlab(TeX("Radiance ($\\mu W \\cdot cm^{-2} \\cdot sr^{-1}$)"))+
  ylab("Density")+
  scale_color_discrete(name="Median")+
  scale_fill_discrete(name="Percentile")

ggsave("Histogram_rural.pdf", plot = histogram2, device = "pdf", width = 20, height = 12, units = "cm", scale=0.8)

pgrid = plot_grid(histogram1 + theme(legend.position="none"), histogram2 + theme(legend.position="none"), label_size = 10, label_x = c(0.15, 0.15), ncol=1, labels = c("Urban", "Rural"))
legend <- get_legend(histogram1)
p <- plot_grid(pgrid, legend, ncol = 2, rel_widths = c(0.6, .15))
ggsave("Histograms_joint.pdf", p, device = "pdf", width = 18, height = 24, units = "cm", scale=0.7)

####################
#Import rural 'consumption' tiers for 2018
drive_download("pop18_tier_1_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_1_rural = read.csv("pop18_tier_1_rural.csv")
pop18_tier_1_rural = data.frame(pop18_tier_1_rural$sum, pop18_tier_1_rural$GID_1)
varnames<-c("pop_tier_1_rural", "GID_1")
setnames(pop18_tier_1_rural,names(pop18_tier_1_rural),varnames )

drive_download("pop18_tier_2_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_2_rural = read.csv("pop18_tier_2_rural.csv")
pop18_tier_2_rural = data.frame(pop18_tier_2_rural$sum, pop18_tier_2_rural$GID_1)
varnames<-c("pop_tier_2_rural", "GID_1")
setnames(pop18_tier_2_rural,names(pop18_tier_2_rural),varnames )

drive_download("pop18_tier_3_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_3_rural = read.csv("pop18_tier_3_rural.csv")
pop18_tier_3_rural = data.frame(pop18_tier_3_rural$sum, pop18_tier_3_rural$GID_1)
varnames<-c("pop_tier_3_rural", "GID_1")
setnames(pop18_tier_3_rural,names(pop18_tier_3_rural),varnames )

drive_download("pop18_tier_4_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_4_rural = read.csv("pop18_tier_4_rural.csv")
pop18_tier_4_rural = data.frame(pop18_tier_4_rural$sum, pop18_tier_4_rural$GID_1)
varnames<-c("pop_tier_4_rural", "GID_1")
setnames(pop18_tier_4_rural,names(pop18_tier_4_rural),varnames )

elrates18 = Reduce(function(x,y) merge(x,y,by="GID_1",all=TRUE) ,list(elrates, pop18_tier_1_rural, pop18_tier_2_rural, pop18_tier_3_rural, pop18_tier_4_rural))
elrates_BK_18 = elrates18

elrates18=subset(elrates18, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
elrates18 = dplyr::filter(elrates18,  !is.na(GID_0))

#6) calculate gini index of consumption among those with access within each province and produce plots of use tiers
colist=unique(elrates18$GID_0)
output_d_18=list()
for (A in colist){
  datin=subset(elrates18, elrates18$GID_0== A)
  
  datin$share_tier_1_rural=datin$pop_tier_1_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  datin$share_tier_2_rural=datin$pop_tier_2_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  datin$share_tier_3_rural=datin$pop_tier_3_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  datin$share_tier_4_rural=datin$pop_tier_4_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  
  datin=data.frame(datin$GID_0, datin$GID_1, datin$share_tier_1_rural,datin$share_tier_2_rural,datin$share_tier_3_rural,datin$share_tier_4_rural)
  
  #reshape by making rows columns and by naming such columns after GID_1 of that row
  datin = reshape(datin, direction="long", idvar=c("datin.GID_1", "datin.GID_0"), varying = c("datin.share_tier_1_rural", "datin.share_tier_2_rural", "datin.share_tier_3_rural", "datin.share_tier_4_rural"))
  datin2 = reshape(datin, direction="wide", idvar=c("time"), timevar = c("datin.GID_1"))
  datin3 = select(datin2, - matches("GID_0|time"))
  
  #calculate gini indexes
  output = lapply(1:ncol(datin3), function(X){ineq(datin3[, X],type="Gini")})
  output = unlist(output)
  output = as.data.frame(rbind(output, colnames(datin3)))
  output_d_18[[A]] = output
  elrates18 = elrates_BK_18
}

#calculate summary statistics for the gini indexes in each country (mean, max, min, obs...)
lis_18 = 1:length(output_d_18)

fune_18 = function(X){  
  as.data.frame(t(output_d_18[[X]][1, ]))
}

store_18 = lapply(lis_18, fune_18)

#index of number-country to select which to visualise
#View(colist)

#summary statistics for inequality in consumption within provinces
# i.e. here we see the within-province inequality in consumption for those with access
#a distribution of the inequality within each region of the country
functi_18 = function(x){
  summary(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output])
}
distribution_inequality_18 = lapply(c(1:43), functi_18)


#what if we wanted to see the between province inequality in consumption for those with access?
#simply calculate the gini of the last object
#One figures which sums up inequality at the national level
functi2_18= function(x){
  ineq(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output],type="Gini")
}

national_inequality_18 = lapply(c(1:43), functi2_18)


##Column plot split of consumption (RURAL)
data_cons = data.frame(elrates18$GID_0, elrates18$GID_1, elrates18$pop_tier_1_rural, elrates18$pop_tier_2_rural,elrates18$pop_tier_3_rural,elrates18$pop_tier_4_rural)
varnames<-c("GID_0", "GID_1", "t1_18", "t2_18", "t3_18", "t4_18")
setnames(data_cons,names(data_cons),varnames )

dfm <- gather(data_cons, key=tier, value=value, 't1_18','t2_18','t3_18', 't4_18')

dfm_sum = dfm %>% 
  dplyr::group_by(GID_0, tier) %>% 
  dplyr::summarise(value = sum(value))

dfm_sum <- na.omit(dfm_sum)

colist=unique(dfm_sum$GID_0)
gini=list()

for (Z in colist){
  datin=subset(dfm_sum, dfm_sum$GID_0== Z)
  gini_s = sort(datin$value)
  gini[[Z]] = ineq(gini_s,type="Gini")
}  

gini_cons_flat = as.data.frame(gini)
gini_cons_flat = melt(gini_cons_flat)
varnames<-c("ISO3", "Gini_cons")
setnames(gini_cons_flat,names(gini_cons_flat),varnames )

barplot_consumption = ggplot() + 
  theme_classic()+
  geom_bar(data = dfm_sum ,aes(x = GID_0, y = value, fill = tier), position = "fill",stat = "identity") +
  coord_polar(theta = "y") +
  
      theme(axis.text.x = element_text(angle = 90, hjust = 1, size=6))+
  scale_fill_brewer(name = "Tier of consmption", labels = c("Tier 1", "Tier 2", "Tier 3", "Tier 4"), palette="Blues")+
  xlab("Country")+
  ylab("Split of consumption tiers for those with access")

ggsave("Barplot_consumption_rur.pdf", plot = barplot_consumption, device = "pdf", width = 30, height = 12, units = "cm", scale=0.8)


dfm_sum<-dfm_sum[!(dfm_sum$GID_0=="SWZ"),]

##Or Piechart
Pie_consumption_rural = ggplot(data = dfm_sum) + 
  geom_bar(aes(x = "", y = value, fill = tier), stat = "identity", position="fill")+
  facet_wrap(~ GID_0)+
  coord_polar(theta = "y") +
  scale_fill_brewer(name = "Tier of consmption \n (kWh/hh/day)", labels = c("<0.2", "<1", "<3.4", ">3.4"), palette="Blues")+
  xlab('')+
  ylab('')+
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid  = element_blank())

ggsave("Pie_consumption_rural.pdf", plot = Pie_consumption_rural, device = "pdf", width = 28, height = 26, units = "cm", scale=0.8)


####################
#Import urban consumption' tiers for 2018
drive_download("pop18_tier_1_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_1_urban = read.csv("pop18_tier_1_urban.csv")
pop18_tier_1_urban = data.frame(pop18_tier_1_urban$sum, pop18_tier_1_urban$GID_1)
varnames<-c("pop_tier_1_urban", "GID_1")
setnames(pop18_tier_1_urban,names(pop18_tier_1_urban),varnames )

drive_download("pop18_tier_2_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_2_urban = read.csv("pop18_tier_2_urban.csv")
pop18_tier_2_urban = data.frame(pop18_tier_2_urban$sum, pop18_tier_2_urban$GID_1)
varnames<-c("pop_tier_2_urban", "GID_1")
setnames(pop18_tier_2_urban,names(pop18_tier_2_urban),varnames )

drive_download("pop18_tier_3_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_3_urban = read.csv("pop18_tier_3_urban.csv")
pop18_tier_3_urban = data.frame(pop18_tier_3_urban$sum, pop18_tier_3_urban$GID_1)
varnames<-c("pop_tier_3_urban", "GID_1")
setnames(pop18_tier_3_urban,names(pop18_tier_3_urban),varnames )

drive_download("pop18_tier_4_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_4_urban = read.csv("pop18_tier_4_urban.csv")
pop18_tier_4_urban = data.frame(pop18_tier_4_urban$sum, pop18_tier_4_urban$GID_1)
varnames<-c("pop_tier_4_urban", "GID_1")
setnames(pop18_tier_4_urban,names(pop18_tier_4_urban),varnames )

elrates18 = Reduce(function(x,y) merge(x,y,by="GID_1",all=TRUE) ,list(elrates, pop18_tier_1_urban, pop18_tier_2_urban, pop18_tier_3_urban, pop18_tier_4_urban))
elrates_BK_18 = elrates18

elrates18=subset(elrates18, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
elrates18 = dplyr::filter(elrates18,  !is.na(GID_0))

#6) calculate gini index of consumption among those with access within each province
colist=unique(elrates18$GID_0)
output_d_18=list()

for (A in colist){
  datin=subset(elrates18, elrates18$GID_0== A)
  
  datin$share_tier_1_urban=datin$pop_tier_1_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  datin$share_tier_2_urban=datin$pop_tier_2_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  datin$share_tier_3_urban=datin$pop_tier_3_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  datin$share_tier_4_urban=datin$pop_tier_4_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  
  datin=data.frame(datin$GID_0, datin$GID_1, datin$share_tier_1_urban,datin$share_tier_2_urban,datin$share_tier_3_urban,datin$share_tier_4_urban)
  
  #reshape by making rows columns and by naming such columns after GID_1 of that row
  datin = reshape(datin, direction="long", idvar=c("datin.GID_1", "datin.GID_0"), varying = c("datin.share_tier_1_urban", "datin.share_tier_2_urban", "datin.share_tier_3_urban", "datin.share_tier_4_urban"))
  datin2 = reshape(datin, direction="wide", idvar=c("time"), timevar = c("datin.GID_1"))
  datin3 = select(datin2, - matches("GID_0|time"))
  
  #calculate gini indexes
  output = lapply(1:ncol(datin3), function(X){ineq(datin3[, X],type="Gini")})
  output = unlist(output)
  output = as.data.frame(rbind(output, colnames(datin3)))
  output_d_18[[A]] = output
  elrates18 = elrates_BK_18
}

#calculate summary statistics for the gini indexes in each country (mean, max, min, obs...)
lis_18 = 1:length(output_d_18)

fune_18 = function(X){  
  as.data.frame(t(output_d_18[[X]][1, ]))
}

store_18 = lapply(lis_18, fune_18)

#index of number-country to select which to visualise
#View(colist)

#summary statistics for inequality in consumption within provinces
# i.e. here we see the within-province inequality in consumption for those with access
#a distribution of the inequality within each region of the country
functi_18 = function(x){
  summary(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output])
}
distribution_inequality_18 = lapply(c(1:43), functi_18)


#what if we wanted to see the between province inequality in consumption for those with access?
#simply calculate the gini of the last object
#One figures which sums up inequality at the national level
functi2_18= function(x){
  ineq(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output],type="Gini")
}

national_inequality_18 = lapply(c(1:43), functi2_18)

##Column plot split of consumption (urban)
data_cons = data.frame(elrates18$GID_0, elrates18$GID_1, elrates18$pop_tier_1_urban, elrates18$pop_tier_2_urban,elrates18$pop_tier_3_urban,elrates18$pop_tier_4_urban)
varnames<-c("GID_0", "GID_1", "t1_18", "t2_18", "t3_18", "t4_18")
setnames(data_cons,names(data_cons),varnames )

dfm <- gather(data_cons, key=tier, value=value, 't1_18','t2_18','t3_18', 't4_18')

dfm_sum = dfm %>% 
  dplyr::group_by(GID_0, tier) %>% 
  dplyr::summarise(value = sum(value))

dfm_sum <- na.omit(dfm_sum)

colist=unique(dfm_sum$GID_0)
gini=list()

for (Z in colist){
  datin=subset(dfm_sum, dfm_sum$GID_0== Z)
  gini_s = sort(datin$value)
  gini[[Z]] = ineq(gini_s,type="Gini")
}  

gini_cons_flat = as.data.frame(gini)
gini_cons_flat = melt(gini_cons_flat)
varnames<-c("ISO3", "Gini_cons")
setnames(gini_cons_flat,names(gini_cons_flat),varnames )

barplot_consumption = ggplot() + 
  theme_classic()+
  geom_bar(data = dfm_sum ,aes(x = GID_0, y = value, fill = tier), position = "fill",stat = "identity") +
      theme(axis.text.x = element_text(angle = 90, hjust = 1, size=6))+
  scale_fill_brewer(name = "Tier of consmption", labels = c("Tier 1", "Tier 2", "Tier 3", "Tier 4"), palette="Blues")+
  xlab("Country")+
  ylab("Split of consumption tiers for those with access")

ggsave("Barplot_consumption_urb.pdf", plot = barplot_consumption, device = "pdf", width = 30, height = 12, units = "cm", scale=0.8)

dfm_sum<-dfm_sum[!(dfm_sum$GID_0=="SWZ"),]

##Or Piechart
Pie_consumption_urban = ggplot(data = dfm_sum) + 
  geom_bar(aes(x = "", y = value, fill = tier), stat = "identity", position="fill")+
  facet_wrap(~ GID_0)+
  coord_polar(theta = "y") +
  scale_fill_brewer(name = "Tier of consmption \n (kWh/hh/day)", labels = c("<0.2", "<1", "<3.4", ">3.4"), palette="Blues")+
  xlab('')+
  ylab('')+
  theme(axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid  = element_blank())


ggsave("Pie_consumption_urban.pdf", plot = Pie_consumption_urban, device = "pdf", width = 28, height = 26, units = "cm", scale=0.8)


#############################
# Country-level sensitivity analysis
#1) Import data for populaiton and population without access
drive_download("pop17.csv", type = "csv", overwrite = TRUE)
pop17 = read.csv("pop17.csv")

pop17 = pop17 %>% select(GID_0, GID_1, NAME_0, NAME_1, sum)

varnames<-c("GID_0", "GID_1", "NAME_0", "NAME_1", "pop")
setnames(pop17,names(pop17),varnames )

drive_download("no_acc_17_base.csv", type = "csv", overwrite = TRUE)
no_acc_17_base = read.csv("no_acc_17_base.csv")

no_acc_17_base = no_acc_17_base %>% select(GID_1, sum)

varnames<-c("GID_1", "base")
setnames(no_acc_17_base,names(no_acc_17_base),varnames )

drive_download("no_acc_17_minus.csv", type = "csv", overwrite = TRUE)
no_acc_17_minus = read.csv("no_acc_17_minus.csv")

no_acc_17_minus = no_acc_17_minus %>% select(GID_1, sum)

varnames<-c("GID_1", "minus")
setnames(no_acc_17_minus,names(no_acc_17_minus),varnames )

drive_download("no_acc_17_plus.csv", type = "csv", overwrite = TRUE)
no_acc_17_plus = read.csv("no_acc_17_plus.csv")

no_acc_17_plus = no_acc_17_plus %>% select(GID_1, sum)

varnames<-c("GID_1", "plus")
setnames(no_acc_17_plus,names(no_acc_17_plus),varnames )

##############

#merge (with variant of pop)
merged_17 = Reduce(function(x,y) merge(x,y,by="GID_1",all=TRUE) ,list(pop17, no_acc_17_base, no_acc_17_minus, no_acc_17_plus))

merged_17=subset(merged_17, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA" & GID_0 != "SHN" & GID_0 != "DJI" & GID_0 != "STP")

merged_17 = dplyr::filter(merged_17,  !is.na(GID_0))

#2) calculate local elrates 
merged_17$elrate_base=(1-(merged_17$base / merged_17$pop))
merged_17$elrate_plus=(1-(merged_17$plus / merged_17$pop))
merged_17$elrate_minus=(1-(merged_17$minus / merged_17$pop))

elrates = data.frame(merged_17$base, merged_17$plus,  merged_17$minus, merged_17$pop, merged_17$GID_1, merged_17$GID_0)

varnames<-c("base", "plus", "minus", "pop", "GID_1", "GID_0")
setnames(elrates,names(elrates),varnames )


#3) country level analysis
merged_17_countrylevel = merged_17 %>% group_by(GID_0) %>% dplyr::summarize(pop=sum(pop,na.rm = T), base=sum(base,na.rm = T), plus=sum(plus,na.rm = T), minus=sum(minus,na.rm = T)) %>% ungroup()

merged_17_countrylevel$elrate_base = (1-(merged_17_countrylevel$base/merged_17_countrylevel$pop))
merged_17_countrylevel$elrate_plus = (1-(merged_17_countrylevel$plus/merged_17_countrylevel$pop))
merged_17_countrylevel$elrate_minus = (1-(merged_17_countrylevel$minus/merged_17_countrylevel$pop))

elrate_wb <- wb(indicator = "EG.ELC.ACCS.ZS", startdate = 2016, enddate = 2016)

elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)

merged_17_countrylevel = merge(merged_17_countrylevel, elrate_wb, by.x = "GID_0", by.y = "elrate_wb.iso3c")

merged_17_countrylevel$disc_base=(merged_17_countrylevel$elrate_wb.value/100-merged_17_countrylevel$elrate_base)
merged_17_countrylevel$disc_plus=(merged_17_countrylevel$elrate_wb.value/100-merged_17_countrylevel$elrate_plus)
merged_17_countrylevel$disc_minus=(merged_17_countrylevel$elrate_wb.value/100-merged_17_countrylevel$elrate_minus)

DF1 <- merged_17_countrylevel %>% select(GID_0, disc_base, disc_minus, disc_plus) %>% melt(id.var="GID_0")

barplot = ggplot(DF1, aes(x=GID_0, y=value, fill=as.factor(variable)))+
  theme_classic()+
  geom_col(position = "dodge")+
  scale_fill_discrete(name="NTL noise floor", labels=c("Base", "-25%", "+25%"))+
      theme(axis.text.x = element_text(angle = 90, hjust = 1, size=6))+
  xlab("Country")+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  ylab("Discrepancy in NTL vs. WB/SE4ALL electrification rate")

ggsave("Sensitivity_noise.pdf", plot = barplot, device = "pdf", width = 30, height = 12, units = "cm", scale=0.8)

formula = "elrate_wb.value ~ elrate_base"
summary(lm(data= merged_17_countrylevel, formula=formula))

formula = "elrate_wb.value ~ elrate_plus"
summary(lm(data= merged_17_countrylevel, formula=formula))

formula = "elrate_wb.value ~ elrate_minus"
summary(lm(data= merged_17_countrylevel, formula=formula))


#######
#WorldPop vs. LandScan-based electrification rates for baseline
drive_download("pop17_ls.csv", type = "csv", overwrite = TRUE)
pop17_ls = read.csv("pop17_ls.csv")

drive_download("pop17_wp.csv", type = "csv", overwrite = TRUE)
pop17_wp = read.csv("pop17_wp.csv")

drive_download("pop17_noaccess_wp.csv", type = "csv", overwrite = TRUE)
pop17_noaccess_wp = read.csv("pop17_noaccess_wp.csv")

drive_download("pop17_noaccess_ls.csv", type = "csv", overwrite = TRUE)
pop17_noaccess_ls = read.csv("pop17_noaccess_ls.csv")

#merge (with variant of pop)
merged_wp = merge(pop17_wp, pop17_noaccess_wp, by=c("GID_1"), all=TRUE)
merged_ls = merge(pop17_ls, pop17_noaccess_ls, by=c("GID_1"), all=TRUE)

merged_wp=subset(merged_wp, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_ls=subset(merged_ls, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_wp = dplyr::filter(merged_wp,  !is.na(GID_0.x))
merged_ls = dplyr::filter(merged_ls,  !is.na(GID_0.x))

#2) calculate local elrates 
merged_wp$elrate=(1-(merged_wp$sum.y / merged_wp$sum.x))
merged_ls$elrate=(1-(merged_ls$sum.y / merged_ls$sum.x))


elrates = data.frame(merged_wp$elrate, merged_ls$elrate, merged_ls$GID_1, merged_ls$GID_0.x)

varnames<-c("elrate_wp", "elrate_ls", "GID_1", "GID_0")

setnames(elrates,names(elrates),varnames )

#3) country level analysis
merged_wp_countrylevel = merged_wp %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_wp_countrylevel$elrate = (1-(merged_wp_countrylevel$popnoacc/merged_wp_countrylevel$pop))

merged_ls_countrylevel = merged_ls %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_ls_countrylevel$elrate = (1-(merged_ls_countrylevel$popnoacc/merged_ls_countrylevel$pop))

elrate_wb <- wb(indicator = "EG.ELC.ACCS.ZS", startdate = 2016, enddate = 2016)

elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)

merged_ls_countrylevel = merge(merged_ls_countrylevel, elrate_wb, by.x = "GID_0.x", by.y = "elrate_wb.iso3c")
merged_wp_countrylevel = merge(merged_wp_countrylevel, elrate_wb, by.x = "GID_0.x", by.y = "elrate_wb.iso3c")

merged_pops_countrylevel=data.frame(merged_ls_countrylevel$GID_0.x, merged_ls_countrylevel$elrate_wb.value, merged_ls_countrylevel$elrate, merged_wp_countrylevel$elrate)
merged_pops_countrylevel$disc_wp=(merged_pops_countrylevel$merged_wp_countrylevel.elrate-merged_pops_countrylevel$merged_ls_countrylevel.elrate_wb.value/100)
merged_pops_countrylevel$disc_ls=(merged_pops_countrylevel$merged_ls_countrylevel.elrate-merged_pops_countrylevel$merged_ls_countrylevel.elrate_wb.value/100)

DF1 <- merged_pops_countrylevel %>% select(merged_ls_countrylevel.GID_0.x, disc_wp, disc_ls) %>% melt(id.var="merged_ls_countrylevel.GID_0.x")

barplot = ggplot(DF1, aes(x=merged_ls_countrylevel.GID_0.x, y=value, fill=as.factor(variable)))+
  theme_classic()+
  geom_col(position = "dodge")+
  scale_fill_discrete(name="Population dataset", labels=c("WorldPop", "LandScan"))+
      theme(axis.text.x = element_text(angle = 90, hjust = 1, size=6))+
  xlab("Country")+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  ylab("Discrepancy in LS and WP vs. WB electr. rates")

ggsave("Sensitivity_population.pdf", plot = barplot, device = "pdf", width = 30, height = 12, units = "cm", scale=0.8)

formula = "elrate_wb.value ~ elrate"
summary(lm(data= merged_ls_countrylevel, formula=formula))

formula = "elrate_wb.value ~ elrate"
summary(lm(data= merged_wp_countrylevel, formula=formula))

##
#Consumption tiers validation 

geovars = read.csv('validation/HouseholdGeovariablesIHS4.csv')

cons = read.csv('validation/hh_mod_f.csv')

cons2 = read.csv('validation/IHS4 Consumption Aggregate.csv')

#

#average unit price of electriicty in 2017
# 47 MK per unit
#https://www.meramalawi.mw/


#

merger = merge(cons, geovars, by="case_id")
merger = merge(merger, cons2, by="case_id")

merger = merger %>% dplyr::select(case_id, lat_modified, lon_modified, hh_f25, hh_f26b, urban)

merger$adjexpenditure = merger$hh_f25

merger_urban_mwi = subset(merger, merger$urban==1 & hh_f26b ==5)
merger_rural_mwi = subset(merger, merger$urban==2 & hh_f26b ==5)

merger_rural_mwi=subset(merger_rural_mwi, merger_rural_mwi$adjexpenditure > 0)
merger_urban_mwi=subset(merger_urban_mwi, merger_urban_mwi$adjexpenditure > 0)

merger_urban_mwi$adjexpenditure = (merger_urban_mwi$adjexpenditure/30)/35
merger_rural_mwi$adjexpenditure = (merger_rural_mwi$adjexpenditure/30)/26
vettore = c(0.012, 0.2, 1, 3.4, Inf)

merger_urban_mwi$tier <- as.numeric(cut(merger_urban_mwi$adjexpenditure, breaks = vettore, 
                                        labels = c(1:4), right = FALSE))


merger_rural_mwi$tier <- as.numeric(cut(merger_rural_mwi$adjexpenditure, breaks = vettore, 
                                        labels = c(1:4), right = FALSE))

merger_urban_mwi$tier = merger_urban_mwi$tier 
merger_rural_mwi$tier = merger_rural_mwi$tier 

merger_urban_mwi=subset(merger_urban_mwi, merger_urban_mwi$tier > 0)
merger_rural_mwi=subset(merger_rural_mwi, merger_rural_mwi$tier > 0)


#average unit price of electriicty in 2016
#https://infoguidenigeria.com/electricity-tariff-structure/

merger = read.csv('validation/sect11_plantingw3.csv')

merger = merger %>% dplyr::select(hhid, s11q25a, s11q25b, sector)
merger$urban = merger$sector

merger_urban_nga = subset(merger, merger$urban==1 & s11q25b ==3)
merger_rural_nga = subset(merger, merger$urban==2 & s11q25b ==3)

merger_rural_nga=subset(merger_rural_nga, merger_rural_nga$s11q25a > 0)
merger_urban_nga=subset(merger_urban_nga, merger_urban_nga$s11q25a > 0)

merger_urban_nga$s11q25a = merger_urban_nga$s11q25a/30/12
merger_rural_nga$s11q25a = merger_rural_nga$s11q25a/30/7
vettore = c(0.012, 0.2, 1, 3.4, Inf)

merger_urban_nga$tier <- as.numeric(cut(merger_urban_nga$s11q25a, breaks = vettore, 
                                        labels = c(1:4), right = FALSE))

merger_rural_nga$tier <- as.numeric(cut(merger_rural_nga$s11q25a, breaks = vettore, 
                                        labels = c(1:4), right = FALSE))


merger_urban_nga$tier = merger_urban_nga$tier 
merger_rural_nga$tier = merger_rural_nga$tier 

merger_urban_nga=subset(merger_urban_nga, merger_urban_nga$tier > 0)
merger_rural_nga=subset(merger_rural_nga, merger_rural_nga$tier > 0)

#
geovars = read.csv('validation/GSEC10_1.csv')

cons = read.csv('validation/unps 2013-14 consumption aggregate.csv')

merger = merge(cons, geovars, by="HHID")

merger = merger %>% dplyr::select(HHID, h10q4, h10q5a, urban)

merger_urban_uga = subset(merger, merger$urban==1)
merger_rural_uga = subset(merger, merger$urban==0)

merger_rural_uga=subset(merger_rural_uga, merger_rural_uga$h10q4 > 0)
merger_urban_uga=subset(merger_urban_uga, merger_urban_uga$h10q4 > 0)

merger_urban_uga$h10q4 = merger_urban_uga$h10q4/30
merger_rural_uga$h10q4 = merger_rural_uga$h10q4/30
vettore = c(0.012, 0.2, 1, 3.4, Inf)


merger_urban_uga$tier <- as.numeric(cut(merger_urban_uga$h10q4, breaks = vettore, 
                                        labels = c(1:4), right = FALSE))

merger_rural_uga$tier <- as.numeric(cut(merger_rural_uga$h10q4, breaks = vettore, 
                                        labels = c(1:4), right = FALSE))

merger_urban_uga$tier = merger_urban_uga$tier 
merger_rural_uga$tier = merger_rural_uga$tier 

merger_urban_uga=subset(merger_urban_uga, merger_urban_uga$tier > 0)
merger_rural_uga=subset(merger_rural_uga, merger_rural_uga$tier > 0)


#
#1) Import data for populaiton and population without access
##
#rural

#1) Import data for populaiton and population without access
pop18 = read.csv("pop18.csv")
pop16 = read.csv("pop16.csv")
pop14 = read.csv("pop14.csv")

no_acc_18 = read.csv("no_acc_18.csv")
no_acc_16 = read.csv("no_acc_16.csv")
no_acc_14 = read.csv("no_acc_14.csv")

#1.1) Merge different years, remove non Sub-Saharan countries and other misc provinces
merged_14 = merge(pop14, no_acc_14, by=c("GID_1"), all=TRUE)
merged_16 = merge(pop16, no_acc_16, by=c("GID_1"), all=TRUE)
merged_18 = merge(pop18, no_acc_18, by=c("GID_1"), all=TRUE)

merged_14=subset(merged_14, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_16=subset(merged_16, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_18=subset(merged_18, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_14 = dplyr::filter(merged_14,  !is.na(GID_0.x))
merged_16 = dplyr::filter(merged_16,  !is.na(GID_0.x))
merged_18 = dplyr::filter(merged_18,  !is.na(GID_0.x))

#2) Calculate province-level electrification rates and merge them into a single dataframe 
merged_18$elrate=(1-(merged_18$sum.y / merged_18$sum.x))
merged_16$elrate=(1-(merged_16$sum.y / merged_16$sum.x))
merged_14$elrate=(1-(merged_14$sum.y / merged_14$sum.x))

elrates = data.frame(merged_18$elrate, merged_16$elrate, merged_14$elrate, merged_14$GID_1, merged_14$GID_0.x)

varnames<-c("elrate18", "elrate16", "elrate14", "GID_1", "GID_0")

setnames(elrates,names(elrates),varnames )

#2.1) Calculate the change in electrification rates over the two years considered
elrates$eldiff = elrates$elrate18 - elrates$elrate14 
elrates$eldiffpc = (elrates$elrate18 - elrates$elrate14) / elrates$elrate14

#3) Calculate national electrification rates
merged_14_countrylevel = merged_14 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_14_countrylevel$elrate = (1-(merged_14_countrylevel$popnoacc/merged_14_countrylevel$pop))

merged_16_countrylevel = merged_16 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_16_countrylevel$elrate = (1-(merged_16_countrylevel$popnoacc/merged_16_countrylevel$pop))

merged_18_countrylevel = merged_18 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_18_countrylevel$elrate = (1-(merged_18_countrylevel$popnoacc/merged_18_countrylevel$pop))

merged_diff=data.frame(merged_18_countrylevel$GID_0.x, (merged_18_countrylevel$elrate-merged_14_countrylevel$elrate), merged_18_countrylevel$elrate, merged_16_countrylevel$elrate, merged_14_countrylevel$elrate)
merged_diff <- na.omit(merged_diff)
varnames<-c("GID_0", "elrate_diff", "elrate18", "elrate16","elrate14")
setnames(merged_diff,names(merged_diff),varnames )

drive_download("pop18_tier_1_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_1_rural = read.csv("pop18_tier_1_rural.csv")
pop18_tier_1_rural = data.frame(pop18_tier_1_rural$sum, pop18_tier_1_rural$GID_1)
varnames<-c("pop_tier_1_rural", "GID_1")
setnames(pop18_tier_1_rural,names(pop18_tier_1_rural),varnames )

drive_download("pop18_tier_2_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_2_rural = read.csv("pop18_tier_2_rural.csv")
pop18_tier_2_rural = data.frame(pop18_tier_2_rural$sum, pop18_tier_2_rural$GID_1)
varnames<-c("pop_tier_2_rural", "GID_1")
setnames(pop18_tier_2_rural,names(pop18_tier_2_rural),varnames )

drive_download("pop18_tier_3_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_3_rural = read.csv("pop18_tier_3_rural.csv")
pop18_tier_3_rural = data.frame(pop18_tier_3_rural$sum, pop18_tier_3_rural$GID_1)
varnames<-c("pop_tier_3_rural", "GID_1")
setnames(pop18_tier_3_rural,names(pop18_tier_3_rural),varnames )

drive_download("pop18_tier_4_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_4_rural = read.csv("pop18_tier_4_rural.csv")
pop18_tier_4_rural = data.frame(pop18_tier_4_rural$sum, pop18_tier_4_rural$GID_1)
varnames<-c("pop_tier_4_rural", "GID_1")
setnames(pop18_tier_4_rural,names(pop18_tier_4_rural),varnames )

elrates18 = Reduce(function(x,y) merge(x,y,by="GID_1",all=TRUE) ,list(elrates, pop18_tier_1_rural, pop18_tier_2_rural, pop18_tier_3_rural, pop18_tier_4_rural))
elrates_BK_18 = elrates18

elrates18=subset(elrates18, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
elrates18 = dplyr::filter(elrates18,  !is.na(GID_0))

#6) calculate gini index of consumption among those with access within each province
colist=unique(elrates18$GID_0)
output_d_18=list()

for (A in colist){
  datin=subset(elrates18, elrates18$GID_0== A)
  
  datin$share_tier_1_rural=datin$pop_tier_1_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  datin$share_tier_2_rural=datin$pop_tier_2_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  datin$share_tier_3_rural=datin$pop_tier_3_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  datin$share_tier_4_rural=datin$pop_tier_4_rural/(datin$pop_tier_1_rural+datin$pop_tier_2_rural+datin$pop_tier_3_rural+datin$pop_tier_4_rural)
  
  datin=data.frame(datin$GID_0, datin$GID_1, datin$share_tier_1_rural,datin$share_tier_2_rural,datin$share_tier_3_rural,datin$share_tier_4_rural)
  
  #reshape by making rows columns and by naming such columns after GID_1 of that row
  datin = reshape(datin, direction="long", idvar=c("datin.GID_1", "datin.GID_0"), varying = c("datin.share_tier_1_rural", "datin.share_tier_2_rural", "datin.share_tier_3_rural", "datin.share_tier_4_rural"))
  datin2 = reshape(datin, direction="wide", idvar=c("time"), timevar = c("datin.GID_1"))
  datin3 = select(datin2, - matches("GID_0|time"))
  
  #calculate gini indexes
  output = lapply(1:ncol(datin3), function(X){ineq(datin3[, X],type="Gini")})
  output = unlist(output)
  output = as.data.frame(rbind(output, colnames(datin3)))
  output_d_18[[A]] = output
  elrates18 = elrates_BK_18
}

#calculate summary statistics for the gini indexes in each country (mean, max, min, obs...)
lis_18 = 1:length(output_d_18)

fune_18 = function(X){  
  as.data.frame(t(output_d_18[[X]][1, ]))
}

store_18 = lapply(lis_18, fune_18)

#index of number-country to select which to visualise
#View(colist)

#summary statistics for inequality in consumption within provinces
# i.e. here we see the within-province inequality in consumption for those with access
#a distribution of the inequality within each region of the country
functi_18 = function(x){
  summary(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output])
}
distribution_inequality_18 = lapply(c(1:43), functi_18)


#what if we wanted to see the between province inequality in consumption for those with access?
#simply calculate the gini of the last object
#One figures which sums up inequality at the national level
functi2_18= function(x){
  ineq(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output],type="Gini")
}

national_inequality_18 = lapply(c(1:43), functi2_18)

##Column plot split of consumption (rural)
data_cons = data.frame(elrates18$GID_0, elrates18$GID_1, elrates18$pop_tier_1_rural, elrates18$pop_tier_2_rural,elrates18$pop_tier_3_rural,elrates18$pop_tier_4_rural)
varnames<-c("GID_0", "GID_1", "t1_18", "t2_18", "t3_18", "t4_18")
setnames(data_cons,names(data_cons),varnames )

dfm <- gather(data_cons, key=tier, value=value, 't1_18','t2_18','t3_18', 't4_18')


dfm_sum = dfm %>% 
  dplyr::group_by(GID_0, tier) %>% 
  dplyr::summarise(value = sum(value))

dfm_sum <- na.omit(dfm_sum)

merger_rural_mwi$GID_0 = "MWI"
merger_rural_nga$GID_0 = "NGA"
merger_rural_uga$GID_0 = "UGA"

merger_rural_mwi = merger_rural_mwi %>%
  dplyr::mutate(tier = as.numeric(as.character(tier))) %>%  
  dplyr::group_by(GID_0, tier) %>%
  dplyr::summarise(value=n())

merger_rural_mwi$value = merger_rural_mwi$value/sum(merger_rural_mwi$value)

merger_rural_nga = merger_rural_nga %>%
  dplyr::mutate(tier = as.numeric(as.character(tier))) %>%  
  dplyr::group_by(GID_0, tier) %>%
  dplyr::summarise(value=n())

merger_rural_nga$value = merger_rural_nga$value/sum(merger_rural_nga$value)


merger_rural_uga = merger_rural_uga %>%
  dplyr::mutate(tier = as.numeric(as.character(tier))) %>%  
  dplyr::group_by(GID_0, tier) %>%
  dplyr::summarise(value=n())

merger_rural_uga$value = merger_rural_uga$value/sum(merger_rural_uga$value)

all_real_rural = rbind(merger_rural_mwi, merger_rural_nga, merger_rural_uga)
all_real_rural$type = "Surveyed"
all_real_rural$tier = as.factor(all_real_rural$tier)


dfm_sum = subset(dfm_sum, dfm_sum$GID_0 == "MWI" | dfm_sum$GID_0 == "NGA" | dfm_sum$GID_0 == "UGA")

dfm_sum$type = "Estimated"


dfm_sum = data.table(dfm_sum)
dfm_sum[, value := prop.table(value), by=GID_0]


dfm_sum$tier = plyr::mapvalues(dfm_sum$tier, unique(dfm_sum$tier), c("1", "2", "3", "4"))

dfm_sum = as.data.frame(dfm_sum)


merger = dplyr::bind_rows(dfm_sum, all_real_rural)

##

merger = merger[complete.cases(merger), ]

merger_r = merger

valid_rural = ggplot(merger, aes(x=as.factor(tier), y=value, group=type, fill=type)) +
  geom_bar(stat="identity", position = position_dodge(preserve = "single")) +
  theme_classic()+
  facet_grid(rows = vars(GID_0))+
  scale_y_continuous(labels=percent, limits = c(0,1))+
  scale_fill_discrete(name="Value")+
  xlab("kWh/day/household")+
  ylab("Share of rural populaiton")+
  scale_x_discrete(labels = c("<0.2 ", "<1", "<3.4", ">3.4"))

##
#Urban

#1) Import data for populaiton and population without access
pop18 = read.csv("pop18.csv")
pop16 = read.csv("pop16.csv")
pop14 = read.csv("pop14.csv")
no_acc_18 = read.csv("no_acc_18.csv")
no_acc_16 = read.csv("no_acc_16.csv")
no_acc_14 = read.csv("no_acc_14.csv")

#1.1) Merge different years, remove non Sub-Saharan countries and other misc provinces
merged_14 = merge(pop14, no_acc_14, by=c("GID_1"), all=TRUE)
merged_16 = merge(pop16, no_acc_16, by=c("GID_1"), all=TRUE)
merged_18 = merge(pop18, no_acc_18, by=c("GID_1"), all=TRUE)

merged_14=subset(merged_14, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_16=subset(merged_16, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_18=subset(merged_18, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_14 = dplyr::filter(merged_14,  !is.na(GID_0.x))
merged_16 = dplyr::filter(merged_16,  !is.na(GID_0.x))
merged_18 = dplyr::filter(merged_18,  !is.na(GID_0.x))

#2) Calculate province-level electrification rates and merge them into a single dataframe 
merged_18$elrate=(1-(merged_18$sum.y / merged_18$sum.x))
merged_16$elrate=(1-(merged_16$sum.y / merged_16$sum.x))
merged_14$elrate=(1-(merged_14$sum.y / merged_14$sum.x))

elrates = data.frame(merged_18$elrate, merged_16$elrate, merged_14$elrate, merged_14$GID_1, merged_14$GID_0.x)

varnames<-c("elrate18", "elrate16", "elrate14", "GID_1", "GID_0")

setnames(elrates,names(elrates),varnames )

#2.1) Calculate the change in electrification rates over the two years considered
elrates$eldiff = elrates$elrate18 - elrates$elrate14 
elrates$eldiffpc = (elrates$elrate18 - elrates$elrate14) / elrates$elrate14

#3) Calculate national electrification rates
merged_14_countrylevel = merged_14 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_14_countrylevel$elrate = (1-(merged_14_countrylevel$popnoacc/merged_14_countrylevel$pop))

merged_16_countrylevel = merged_16 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_16_countrylevel$elrate = (1-(merged_16_countrylevel$popnoacc/merged_16_countrylevel$pop))

merged_18_countrylevel = merged_18 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_18_countrylevel$elrate = (1-(merged_18_countrylevel$popnoacc/merged_18_countrylevel$pop))

merged_diff=data.frame(merged_18_countrylevel$GID_0.x, (merged_18_countrylevel$elrate-merged_14_countrylevel$elrate), merged_18_countrylevel$elrate, merged_16_countrylevel$elrate, merged_14_countrylevel$elrate)
merged_diff <- na.omit(merged_diff)
varnames<-c("GID_0", "elrate_diff", "elrate18", "elrate16","elrate14")
setnames(merged_diff,names(merged_diff),varnames )


drive_download("pop18_tier_1_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_1_urban = read.csv("pop18_tier_1_urban.csv")
pop18_tier_1_urban = data.frame(pop18_tier_1_urban$sum, pop18_tier_1_urban$GID_1)
varnames<-c("pop_tier_1_urban", "GID_1")
setnames(pop18_tier_1_urban,names(pop18_tier_1_urban),varnames )

drive_download("pop18_tier_2_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_2_urban = read.csv("pop18_tier_2_urban.csv")
pop18_tier_2_urban = data.frame(pop18_tier_2_urban$sum, pop18_tier_2_urban$GID_1)
varnames<-c("pop_tier_2_urban", "GID_1")
setnames(pop18_tier_2_urban,names(pop18_tier_2_urban),varnames )

drive_download("pop18_tier_3_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_3_urban = read.csv("pop18_tier_3_urban.csv")
pop18_tier_3_urban = data.frame(pop18_tier_3_urban$sum, pop18_tier_3_urban$GID_1)
varnames<-c("pop_tier_3_urban", "GID_1")
setnames(pop18_tier_3_urban,names(pop18_tier_3_urban),varnames )

drive_download("pop18_tier_4_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_4_urban = read.csv("pop18_tier_4_urban.csv")
pop18_tier_4_urban = data.frame(pop18_tier_4_urban$sum, pop18_tier_4_urban$GID_1)
varnames<-c("pop_tier_4_urban", "GID_1")
setnames(pop18_tier_4_urban,names(pop18_tier_4_urban),varnames )

elrates18 = Reduce(function(x,y) merge(x,y,by="GID_1",all=TRUE) ,list(elrates, pop18_tier_1_urban, pop18_tier_2_urban, pop18_tier_3_urban, pop18_tier_4_urban))
elrates_BK_18 = elrates18

elrates18=subset(elrates18, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
elrates18 = dplyr::filter(elrates18,  !is.na(GID_0))

#6) calculate gini index of consumption among those with access within each province
colist=unique(elrates18$GID_0)
output_d_18=list()

for (A in colist){
  datin=subset(elrates18, elrates18$GID_0== A)
  
  datin$share_tier_1_urban=datin$pop_tier_1_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  datin$share_tier_2_urban=datin$pop_tier_2_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  datin$share_tier_3_urban=datin$pop_tier_3_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  datin$share_tier_4_urban=datin$pop_tier_4_urban/(datin$pop_tier_1_urban+datin$pop_tier_2_urban+datin$pop_tier_3_urban+datin$pop_tier_4_urban)
  
  datin=data.frame(datin$GID_0, datin$GID_1, datin$share_tier_1_urban,datin$share_tier_2_urban,datin$share_tier_3_urban,datin$share_tier_4_urban)
  
  #reshape by making rows columns and by naming such columns after GID_1 of that row
  datin = reshape(datin, direction="long", idvar=c("datin.GID_1", "datin.GID_0"), varying = c("datin.share_tier_1_urban", "datin.share_tier_2_urban", "datin.share_tier_3_urban", "datin.share_tier_4_urban"))
  datin2 = reshape(datin, direction="wide", idvar=c("time"), timevar = c("datin.GID_1"))
  datin3 = select(datin2, - matches("GID_0|time"))
  
  #calculate gini indexes
  output = lapply(1:ncol(datin3), function(X){ineq(datin3[, X],type="Gini")})
  output = unlist(output)
  output = as.data.frame(rbind(output, colnames(datin3)))
  output_d_18[[A]] = output
  elrates18 = elrates_BK_18
}

#calculate summary statistics for the gini indexes in each country (mean, max, min, obs...)
lis_18 = 1:length(output_d_18)

fune_18 = function(X){  
  as.data.frame(t(output_d_18[[X]][1, ]))
}

store_18 = lapply(lis_18, fune_18)

#index of number-country to select which to visualise
#View(colist)

#summary statistics for inequality in consumption within provinces
# i.e. here we see the within-province inequality in consumption for those with access
#a distribution of the inequality within each region of the country
functi_18 = function(x){
  summary(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output])
}
distribution_inequality_18 = lapply(c(1:43), functi_18)


#what if we wanted to see the between province inequality in consumption for those with access?
#simply calculate the gini of the last object
#One figures which sums up inequality at the national level
functi2_18= function(x){
  ineq(as.numeric(levels(store_18[[x]]$output))[store_18[[x]]$output],type="Gini")
}

national_inequality_18 = lapply(c(1:43), functi2_18)

##Column plot split of consumption (urban)
data_cons = data.frame(elrates18$GID_0, elrates18$GID_1, elrates18$pop_tier_1_urban, elrates18$pop_tier_2_urban,elrates18$pop_tier_3_urban,elrates18$pop_tier_4_urban)
varnames<-c("GID_0", "GID_1", "t1_18", "t2_18", "t3_18", "t4_18")
setnames(data_cons,names(data_cons),varnames )

dfm <- gather(data_cons, key=tier, value=value, 't1_18','t2_18','t3_18', 't4_18')


dfm_sum = dfm %>% 
  dplyr::group_by(GID_0, tier) %>% 
  dplyr::summarise(value = sum(value))

dfm_sum <- na.omit(dfm_sum)

merger_urban_mwi$GID_0 = "MWI"
merger_urban_nga$GID_0 = "NGA"
merger_urban_uga$GID_0 = "UGA"

merger_urban_mwi = merger_urban_mwi %>%
  dplyr::mutate(tier = as.numeric(as.character(tier))) %>%  
  dplyr::group_by(GID_0, tier) %>%
  dplyr::summarise(value=n())

merger_urban_mwi$value = merger_urban_mwi$value/sum(merger_urban_mwi$value)

merger_urban_nga = merger_urban_nga %>%
  dplyr::mutate(tier = as.numeric(as.character(tier))) %>%  
  dplyr::group_by(GID_0, tier) %>%
  dplyr::summarise(value=n())

merger_urban_nga$value = merger_urban_nga$value/sum(merger_urban_nga$value)


merger_urban_uga = merger_urban_uga %>%
  dplyr::mutate(tier = as.numeric(as.character(tier))) %>%  
  dplyr::group_by(GID_0, tier) %>%
  dplyr::summarise(value=n())

merger_urban_uga$value = merger_urban_uga$value/sum(merger_urban_uga$value)

all_real_urban = rbind(merger_urban_mwi, merger_urban_nga, merger_urban_uga)
all_real_urban$type = "Surveyed"
all_real_urban$tier = as.factor(all_real_urban$tier)


dfm_sum = subset(dfm_sum, dfm_sum$GID_0 == "MWI" | dfm_sum$GID_0 == "NGA" | dfm_sum$GID_0 == "UGA")

dfm_sum$type = "Estimated"


dfm_sum = data.table(dfm_sum)
dfm_sum[, value := prop.table(value), by=GID_0]


dfm_sum$tier = plyr::mapvalues(dfm_sum$tier, unique(dfm_sum$tier), c("1", "2", "3", "4"))

dfm_sum = as.data.frame(dfm_sum)


merger = dplyr::bind_rows(dfm_sum, all_real_urban)

##

merger = merger[complete.cases(merger), ]

merger_u = merger

valid_urban = ggplot(merger, aes(x=as.factor(tier), y=value, group=type, fill=type)) +
  geom_bar(stat="identity", position = position_dodge(preserve = "single")) +
  theme_classic()+
  facet_grid(rows = vars(GID_0))+
  scale_y_continuous(labels=percent, limits = c(0,1))+
  scale_fill_discrete(name="Legend")+
  xlab("kWh/day/household")+
  ylab("Share of urban populaiton")+
  scale_x_discrete(labels = c("<0.2 ", "<1", "<3.4", ">3.4"))

pgrid = plot_grid(valid_urban + theme(legend.position="none"), valid_rural + theme(legend.position="none"), label_size = 10, label_x = c(0.25, 0.25),  hjust= 0, ncol=2, labels = c("Urban", "Rural"))
legend <- get_legend(valid_urban)
p <- plot_grid(pgrid, legend, ncol = 2, rel_widths = c(0.4, .1))
ggsave("Valid_cons.pdf", p, device = "pdf", width = 39, height = 17, units = "cm", scale=0.5)

prova = rbind(merge((head(merger_u,12)), (tail(merger_u, 11)), by=c("GID_0", "tier"), all=TRUE), merge((head(merger_r,12)), (tail(merger_u, 11)), by=c("GID_0", "tier"), all=TRUE))