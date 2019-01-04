##R Script for: 
##A High-Resolution, Updatable, Fully-Reproducible Gridded Dataset to Assess Recent Progress towardsElectrification in Sub-Saharan Africa
##Giacomo Falchetta
## Version: 04/01/18

#1) Import data for populaiton and population without access
library(googledrive)
setwd("D:\\Dropbox (FEEM)\\Current papers\\INEQUALITY ASSESSMENT")
    
drive_download("pop18.csv", type = "csv", overwrite = TRUE)
pop18 = read.csv("pop18.csv")
    
drive_download("pop14.csv", type = "csv", overwrite = TRUE)
pop14 = read.csv("pop14.csv")
    
drive_download("no_acc_18.csv", type = "csv", overwrite = TRUE)
no_acc_18 = read.csv("no_acc_18.csv")
    
drive_download("no_acc_14.csv", type = "csv", overwrite = TRUE)
no_acc_14 = read.csv("no_acc_14.csv")
    
#merge
merged_14 = merge(pop14, no_acc_14, by=c("GID_1"), all=TRUE)
merged_18 = merge(pop18, no_acc_18, by=c("GID_1"), all=TRUE)
    
merged_14=subset(merged_14, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
merged_18=subset(merged_18, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")
    
merged_14 = dplyr::filter(merged_14,  !is.na(GID_0.x))
merged_18 = dplyr::filter(merged_18,  !is.na(GID_0.x))
    
#2) calculate local elrates 
merged_18$elrate=(1-(merged_18$sum.y / merged_18$sum.x))
merged_14$elrate=(1-(merged_14$sum.y / merged_14$sum.x))
    
elrates = data.frame(merged_18$elrate, merged_14$elrate, merged_14$GID_1, merged_14$GID_0.x)
    
varnames<-c("elrate18", "elrate14", "GID_1", "GID_0")
library(data.table)
setnames(elrates,names(elrates),varnames )
    
#2b) difference between periods
elrates$eldiff = elrates$elrate18 - elrates$elrate14 
elrates$eldiffpc = (elrates$elrate18 - elrates$elrate14) / elrates$elrate14
    
#3) country level analysis
library(dplyr)
merged_14_countrylevel = merged_14 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_14_countrylevel$elrate = (1-(merged_14_countrylevel$popnoacc/merged_14_countrylevel$pop))
    
merged_18_countrylevel = merged_18 %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_18_countrylevel$elrate = (1-(merged_18_countrylevel$popnoacc/merged_18_countrylevel$pop))
    
merged_diff=data.frame(merged_18_countrylevel$GID_0.x, (merged_18_countrylevel$elrate-merged_14_countrylevel$elrate), merged_18_countrylevel$elrate, merged_14_countrylevel$elrate)
    
merged_diff <- na.omit(merged_diff)
    
varnames<-c("GID_0", "elrate_diff", "elrate18", "elrate14")
setnames(merged_diff,names(merged_diff),varnames )
    
#plot change in national electricity access level
library(ggplot2)
library(plotly)
library(scales)
barplot = ggplot(merged_diff, aes(x=reorder(GID_0, -elrate_diff), y=elrate_diff))+
      theme_classic()+
      scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
      geom_bar(stat="identity", aes(fill=elrate18))+
      scale_fill_gradient2(low="firebrick2", mid="gold", midpoint = 0.5, high="forestgreen", name="Electr. rate in 2018",  labels = scales::percent_format(accuracy = 1))+
      theme(axis.text.x = element_text(angle = 45, hjust = 1))+
      xlab("Country")+
      ylab("Change in electrificaiton rate (2014-2018)")
    
ggsave("barplot.png", plot = barplot, device = "png", width = 30, height = 12, units = "cm", scale=0.8)

#number of people without access
merged_noaccess = data.frame(merged_14_countrylevel$GID_0.x, merged_14_countrylevel$popnoacc,  merged_18_countrylevel$popnoacc)
merged_noaccess$difference = merged_noaccess$merged_18_countrylevel.popnoacc-merged_noaccess$merged_14_countrylevel.popnoacc

###
library(wbstats)
elrate_wb <- wb(indicator = "EG.ELC.ACCS.ZS", startdate = 2016, enddate = 2016)

elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)

merged_14_countrylevel = merge(merged_14_countrylevel, elrate_wb, by.x = "GID_0.x", by.y = "elrate_wb.iso3c")

merged_14_countrylevel$discrepancy = merged_14_countrylevel$elrate - merged_14_countrylevel$elrate_wb.value/100


# show that electrification rate calculated at the pixel level matches well elrates at the national level
library(ggrepel)
library(ggplot2)
comparisonwb = ggplot(merged_14_countrylevel, aes(x=elrate, y=elrate_wb.value/100))+
  geom_point(data=merged_14_countrylevel, aes(x=elrate, y=elrate_wb.value/100, size=pop/1e06))+
  geom_label_repel(data=merged_14_countrylevel, aes(x=elrate, y=elrate_wb.value/100, label = GID_0.x),
                   box.padding   = 0.2, 
                   point.padding = 0.3,
                   segment.color = 'grey50') +
  scale_size_continuous(range = c(3, 9), name = "Total pop. (million)")+
  theme_classic()+
  geom_abline()+
  ylab("Electrficiation rate (IEA World Bank 2014)")+
  xlab("Electrification rate (NTL estimate 2014)")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))

ggsave("comparisonwb.png", plot = comparisonwb, device = "png", width = 24, height = 12, units = "cm", scale=1.1)

##########
#Create plot for province-level electrification validation
province = read.csv("D:\\Dropbox (FEEM)\\Current papers\\INEQUALITY ASSESSMENT\\Comparison StatsCompiler\\Parsing.csv")

#DRC, Zambia, Burkina Faso 2014
#Mozambique, Angola, Malawi, Zimbabwe, Nigeria 2015
#Burundi, Ethiopia, Ghana, Sierra Leone 2016
# Senegal, Togo, Tanzania 2017

library(googledrive)
setwd("D:\\Dropbox (FEEM)\\Current papers\\INEQUALITY ASSESSMENT")

drive_download("pop18.csv", type = "csv", overwrite = TRUE)
pop18 = read.csv("pop18.csv")

drive_download("no_acc_14.csv", type = "csv", overwrite = TRUE)
no_acc_14 = read.csv("no_acc_14.csv")

drive_download("no_acc_15.csv", type = "csv", overwrite = TRUE)
no_acc_15 = read.csv("no_acc_15.csv")

drive_download("no_acc_16.csv", type = "csv", overwrite = TRUE)
no_acc_16 = read.csv("no_acc_16.csv")

drive_download("no_acc_17.csv", type = "csv", overwrite = TRUE)
no_acc_17 = read.csv("no_acc_17.csv")


#merge (with variant of pop)
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


#2) calculate local elrates 
merged_14$elrate=(1-(merged_14$sum.x / merged_14$sum.y))
merged_15$elrate=(1-(merged_15$sum.x / merged_15$sum.y))
merged_16$elrate=(1-(merged_16$sum.x / merged_16$sum.y))
merged_17$elrate=(1-(merged_17$sum.x / merged_17$sum.y))

prova = rbind(merged_14, merged_15, merged_16, merged_17)

prova = merge(province, prova, by="GID_1")

ggplot()+
  geom_point(data=prova, aes(x=elrate, y=as.numeric((elaccess/100)), color=GID_0.x, size=sum.y/1e06), alpha=0.7)+
  theme_classic()+
  geom_abline()+
  scale_x_continuous(limits=c(0,1))+
  scale_y_continuous(limits=c(0,1))+
  scale_size_continuous(range = c(3, 9), name = "Total pop. (million)")+
  ylab("Province-level electrification rate - Surveys data")+
  xlab("Province-level electrification rate - (VIIRS DNB light)")+
  scale_colour_discrete(name = "Country")+
  theme(axis.title=element_text(size=8))

ggsave("comparisontanzaniazoom.png", device = "png", width = 30, height = 20, units = "cm", scale=0.75)

#4) inequality in ACCESS (binary): calculate indexes and produce lorenz curve graphs
library(ineq)
library(sf)
shapefile = st_read("C:\\Users\\GIACOMO\\Downloads\\gadm36_1.shp")
shapefile = merge(shapefile, elrates, by=c("GID_1"), all=TRUE)
data = shapefile

#loop for graphs
colist=unique(elrates$GID_0)
ine14=list()
ine18=list()
lorenz=list()

for (Z in colist){
datin=subset(data, data$GID_0.x== Z)
#sort data 
out14 = sort(datin$elrate14)
out18 = sort(datin$elrate18)

#calculate within-country Gini-index in access rate ineqaulity
ine14[[Z]] = ineq(out14,type="Gini")
ine18[[Z]] = ineq(out18,type="Gini")
#plot and store Lorenz curve
Lorenz=Lc(out14, plot =F)
p14 <- Lorenz$p
L14 <- Lorenz$L
out_df14 <- data.frame(p14,L14)

Lorenz=Lc(out18, plot =F)
p18 <- Lorenz$p
L18 <- Lorenz$L
out_df18 <- data.frame(p18,L18)


databoth = merge(out_df18, out_df14, by.x="p18", by.y="p14")
databoth$difference = databoth$L18 - databoth$L14

lorenz[[Z]] = ggplot() +
  theme_classic()+
  geom_line(data = out_df14, aes(x=p14, y=L14, colour="red"), size=1, alpha=0.8) +
  geom_line(data = out_df18, aes(x=p18, y=L18, color="darkblue"), size=1, alpha=0.8)+
  geom_line(data = databoth, aes(x=p18, y=difference, color="black"), size=1, alpha=0.8)+
  scale_color_discrete(name = "Legend", labels = c("Difference", "2018", "2014"))+
  geom_hline(yintercept = 0, alpha=0.5)+
  scale_x_continuous(name="Cumulative share of provinces", limits=c(0,1)) + 
  scale_y_continuous(name="Electricity access rate", limits=c(-0.1,1), sec.axis = sec_axis(trans= ~ .)) +
  geom_abline()+
  geom_point(data = out_df18, aes(x=p18, y=L18), size=0.3)+
  geom_point(data = out_df14, aes(x=p14, y=L14), size=0.3)+
  theme(axis.text=element_text(size=6),
        axis.title=element_text(size=6))

data = as.data.frame(shapefile)

}

library(cowplot)
ggsave("Lorenz.png", plot_grid(lorenz[['BDI']], lorenz[['KEN']], lorenz[['ETH']], lorenz[['TZA']], lorenz[['NGA']], lorenz[['COD']], labels=c("BDI", "KEN", "ETH", "TZA", "NGA", "COD"), label_size = 6, hjust= 0, ncol=2)
, device = "png", width = 35, height = 30, units = "cm", scale=0.5)

ginis14 = as.data.frame(ine14)
library(reshape2)
ginis14 = melt(ginis14)
ginis18 = as.data.frame(ine18)
ginis18 = melt(ginis18)
ginis = data.frame(ginis14$variable, ginis14$value, ginis18$value, (ginis18$value-ginis14$value))
varnames<-c("ISO3", "Gini14", "Gini18", "DiffGini")
setnames(ginis,names(ginis),varnames )

library(rworldmap)

ginis_access <- joinCountryData2Map(ginis, joinCode = "ISO3",
                                       nameJoinColumn = "ISO3")

ginis_access@data=data.frame(ginis_access@data$ISO3, ginis_access@data$Gini14, ginis_access@data$Gini18, ginis_access@data$DiffGini)
writeOGR(layer="ginis_access2", obj =ginis_access,  driver = "ESRI Shapefile", dsn=getwd())

ginis_access = readOGR("ginis_access2.shp")

ginis_access@data$id = rownames(ginis_access@data)
poly_rgn_df <- fortify(ginis_access, region = 'id')

poly_rgn_df <- poly_rgn_df %>%
  left_join(ginis_access@data, by = 'id')


cnames <- aggregate(cbind(long, lat) ~ g___ISO, data=poly_rgn_df, 
                    FUN=function(x)mean(range(x))) 

theme_clean <- function(base_size = 12) {
  require(grid)
  theme_grey(base_size) %+replace%
    theme(
      axis.title = element_blank(),
      axis.text = element_blank(),
      panel.background = element_blank(),
      panel.grid = element_blank(),
      axis.ticks.length = unit(0,"cm"), 
      axis.ticks.margin = unit(0,"cm"),
      panel.margin = unit(0,"lines"),
      plot.margin = unit(c(0, 0, 0, 0), "lines"),
      complete = TRUE
    )}

poly_rgn_df = poly_rgn_df[complete.cases(poly_rgn_df), ]

#EDIT: labels, colour, legend
mapginiaccess = ggplot(data = poly_rgn_df, aes(long, lat, group=group, fill=g___G17)) +
  geom_polygon(colour = "white") +
  coord_map(projection = "mercator") +
  theme_clean()+
  scale_fill_gradient2(high = "darkred", midpoint = 0.5, mid="gold", low = "forestgreen", na.value = "grey50", guide = "colorbar",  name="Electr. acc. Gini")

mapginiaccess

ggsave("mapginiaccess.png", plot = mapginiaccess, device = "png", width = 15, height = 20, units = "cm", scale=0.8)


#######
##Define and validate rural/urban distinction
library(googledrive)
setwd("D:\\Dropbox (FEEM)\\Current papers\\INEQUALITY ASSESSMENT")

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

merged_14 = merge(popu, popt, by=c("ISO3"), all=TRUE)

merged_14$urbrate = merged_14$sum.x / merged_14$sum.y

library(wbstats)
elrate_wb <- wb(indicator = "SP.URB.TOTL.IN.ZS", startdate = 2017, enddate = 2017)

elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)

merged_14_countrylevel = merge(merged_14, elrate_wb, by.x = "ISO3", by.y = "elrate_wb.iso3c")

merged_14_countrylevel$discrepancy = merged_14_countrylevel$elrate_wb.value / 100 - merged_14_countrylevel$urbrate

formula = "elrate_wb.value/100 ~ urbrate"
summary(lm(data= merged_14_countrylevel, formula=formula))

library(ggrepel)
library(ggplot2)
ggsave("ruralvalid.png", ggplot(merged_14_countrylevel, aes(x=urbrate, y = elrate_wb.value/100))+
         geom_point(data=merged_14_countrylevel, aes(x=urbrate, y = elrate_wb.value/100))+
         geom_label_repel(data=merged_14_countrylevel, aes(x=urbrate, y = elrate_wb.value/100, label = ISO3),
                          box.padding   = 0.2, 
                          point.padding = 0.3,
                          segment.color = 'grey50') +
         theme_classic()+
         geom_abline()+
         xlab("Estimated urban population share")+
         scale_x_continuous(limits = c(0.1, 0.7))+
         scale_y_continuous(limits = c(0.1, 0.7))+
         ylab("World Bank reported urban population share"), device = "png", width = 20, height = 12, units = "cm", scale=1)

##Define percentiles and thresholds of light per capita in urban and rural areas and plot histogram
drive_download("pctiles_pc_urban.csv", type = "csv", overwrite = TRUE)
histogram = read.csv("pctiles_pc_urban.csv")

histogram = histogram %>% gather(percentile, value, -c(ISO3))

histogram = histogram[complete.cases(histogram$value), ]

library(plyr)
cdat <- ddply(histogram, "percentile", summarise, value.mean=median(value))


histogram = ggplot(subset(histogram, value < 2), aes(x=value, fill=percentile)) +
  theme_classic()+
  geom_density(alpha=.4) +
  geom_vline(data=cdat, aes(xintercept=value.mean,  colour=percentile),
             linetype="dashed", size=1)+
  xlab("Per-capita light level")+
  ylab("Density")+
  scale_color_discrete(name="Median")+
  scale_fill_discrete(name="Percentile")

histogram

ggsave("histogram_urban.png", plot = histogram, device = "png", width = 20, height = 12, units = "cm", scale=0.8)

drive_download("pctiles_pc_rural.csv", type = "csv", overwrite = TRUE)
histogram = read.csv("pctiles_pc_rural.csv")

histogram = histogram %>% gather(percentile, value, -c(ISO3))

histogram = histogram[complete.cases(histogram$value), ]

library(plyr)
cdat <- ddply(histogram, "percentile", summarise, value.mean=median(value))


histogram = ggplot(subset(histogram, value < 4), aes(x=value, fill=percentile)) +
  theme_classic()+
  geom_density(alpha=.4) +
  geom_vline(data=cdat, aes(xintercept=value.mean,  colour=percentile),
             linetype="dashed", size=1)+
  xlab("Per-capita light level")+
  ylab("Density")+
  scale_color_discrete(name="Median")+
  scale_fill_discrete(name="Percentile")

histogram

ggsave("histogram_rural.png", plot = histogram, device = "png", width = 20, height = 12, units = "cm", scale=0.8)

####################
#5a) import rural 'consumption' tiers for 2018
library(data.table)
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
  library(dplyr)
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

library(tidyr)
dfm <- gather(data_cons, key=tier, value=value, 't1_18','t2_18','t3_18', 't4_18')

library(dplyr)
dfm_sum = dfm %>% 
  group_by(GID_0, tier) %>% 
  summarise(value = sum(value))

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

library(scales)
barplot_consumption = ggplot() + 
  theme_classic()+
  geom_bar(data = dfm_sum ,aes(x = GID_0, y = value, fill = tier), position = "fill",stat = "identity") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  scale_fill_brewer(name = "Tier of consmption", labels = c("Tier 1", "Tier 2", "Tier 3", "Tier 4"), palette="Greens")+
  xlab("Country")+
  ylab("Split of consumption tiers for those with access")

barplot_consumption

ggsave("barplot_consumption_rur.png", plot = barplot_consumption, device = "png", width = 30, height = 12, units = "cm", scale=0.8)



####################
#5b) import urban consumption' tiers for 2018
library(data.table)
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
  library(dplyr)
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

library(tidyr)
dfm <- gather(data_cons, key=tier, value=value, 't1_18','t2_18','t3_18', 't4_18')

library(dplyr)
dfm_sum = dfm %>% 
  group_by(GID_0, tier) %>% 
  summarise(value = sum(value))

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

library(scales)
barplot_consumption = ggplot() + 
  theme_classic()+
  geom_bar(data = dfm_sum ,aes(x = GID_0, y = value, fill = tier), position = "fill",stat = "identity") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))+
  scale_fill_brewer(name = "Tier of consmption", labels = c("Tier 1", "Tier 2", "Tier 3", "Tier 4"), palette="Greens")+
  xlab("Country")+
  ylab("Split of consumption tiers for those with access")

barplot_consumption

ggsave("barplot_consumption_urb.png", plot = barplot_consumption, device = "png", width = 30, height = 12, units = "cm", scale=0.8)

###########

#Map plot gini consumption
library(rworldmap)

ginis_consumption <- joinCountryData2Map(gini_cons_flat, joinCode = "ISO3",
                                    nameJoinColumn = "ISO3")

ginis_consumption@data=data.frame(ginis_consumption@data$ISO3, ginis_consumption@data$Gini_cons)
writeOGR(layer="ginis_consumption", obj =ginis_consumption,  driver = "ESRI Shapefile", dsn=getwd())

ginis_consumption = readOGR("ginis_consumption.shp")

ginis_consumption@data$id = rownames(ginis_consumption@data)
poly_rgn_df <- fortify(ginis_consumption, region = 'id')

poly_rgn_df <- poly_rgn_df %>%
  left_join(ginis_consumption@data, by = 'id')


cnames <- aggregate(cbind(long, lat) ~ gn___G_, data=poly_rgn_df, 
                    FUN=function(x)mean(range(x))) 

poly_rgn_df = poly_rgn_df[complete.cases(poly_rgn_df), ]

#EDIT: labels, colour, legend
mapginicons = ggplot(data = poly_rgn_df, aes(long, lat, group=group, fill=gn___G_)) +
  geom_polygon(colour = "white") +
  coord_map(projection = "mercator") +
  theme_clean()+
  scale_fill_gradient2(high = "darkred", midpoint = 0.5, mid="gold", low = "forestgreen", na.value = "grey50", guide = "colorbar",  name="Electr. cons Gini")

mapginicons

ggsave("mapginicons.png", plot = mapginicons, device = "png", width = 15, height = 20, units = "cm", scale=0.8)

#############################
##Hotspots identification
library(googledrive)
setwd("D:\\Dropbox (FEEM)\\Current papers\\INEQUALITY ASSESSMENT")

##drive_download("changeinpopnoaccess1418.csv", type = "csv", overwrite = TRUE)
changeinpopnoaccess = read.csv("changeinpopnoaccess1418.csv")

##drive_download("allAreas.csv", type = "csv", overwrite = TRUE)
allAreas = read.csv("allAreas.csv")

pops = merge(changeinpopnoaccess, allAreas, by = "GID_1")

pops$changeweighted = pops$sum / (pops$area/1000000)

library(sf)
shapefile = st_read("C:\\Users\\GIACOMO\\Downloads\\gadm36_1.shp")
shapefile = merge(shapefile, pops, by=c("GID_1"), all=TRUE)
shapefile$gr50 = as.numeric(shapefile$changeweighted > 25)

shapefile = st_simplify(shapefile, dTolerance = 0.05)

library(ggthemes)
map1 = ggplot() +
  ggthemes::theme_map()+
  geom_sf(data = shapefile, aes(fill = as.factor(gr50)), alpha = 0.5)+
  scale_fill_manual(values = c("grey", "red"), labels=c("below +25 inhab without access / km^2", "above +25 inhab without access / km^2"), name="Legend \n")+
  theme(plot.margin=grid::unit(c(0,0,0,0), "mm"), panel.grid.major = element_line(colour = 'transparent'))

ggsave("map1.png", plot = map1, device = "png", width = 20, height = 30, units = "cm", scale=0.6, dpi = 600)


##
##drive_download("isrural.csv", type = "csv", overwrite = TRUE)
isrural= read.csv("isrural.csv")

##drive_download("changeinlight.csv", type = "csv", overwrite = TRUE)
changeinlight= read.csv("changeinlight.csv")

changeinlight=subset(changeinlight, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA" & GID_0 != "SHN" & GID_0 != "DJI" & GID_0 != "STP")
changeinlight = dplyr::filter(changeinlight,  !is.na(GID_0))

pops = merge(changeinlight, isrural, by = "GID_1")

pops.urban = subset(pops, pops$mean.y < 0.42)

changeurban = ggplot(data=pops.urban, aes(x=reorder(NAME_1.x, -mean.x), y = mean.x))+
  geom_bar(stat="identity", position = "dodge",  fill = "#E69F00", colour="black")+
  theme_classic()+
  geom_text(aes(label = GID_0.x), position=position_dodge(width=0.9), vjust=-1, size=2)+
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6), axis.text.y = element_text(size = 6),text = element_text(size=7))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  xlab("Province and country")+
  ylab("Average change in light intensity (2014-2018)")

ggsave("change_urban.png", plot = changeurban, device = "png", width = 20, height = 12, units = "cm", scale=0.65, dpi = 300)

###############
pops.rural = subset(pops, pops$mean.y > 0.8)
pops.rural = subset(pops.rural, pops.rural$mean.x > 0.1)

changerural = ggplot(data=pops.rural, aes(x=reorder(NAME_1.x, -mean.x), y = mean.x))+
  geom_bar(stat="identity", position = "dodge",  fill = "#56B4E9", colour="black")+
  theme_classic()+
  geom_text(aes(label = GID_0.x), position=position_dodge(width=0.9), vjust=-1, size=2)+
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 6), axis.text.y = element_text(size = 6),text = element_text(size=7))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  xlab("Province and country")+
  ylab("Average change in light intensity (2014-2018)")

ggsave("change_rural.png", plot = changerural, device = "png", width = 20, height = 12, units = "cm", scale=0.65, dpi = 300)


###Hotspots with low consumption: provinces where electricity access is quite high but measured intensity is low

#1) take elrate 18
##drive_download("pop18.csv", type = "csv", overwrite = TRUE)
pop18 = read.csv("pop18.csv")

##drive_download("no_acc_18.csv", type = "csv", overwrite = TRUE)
no_acc_18 = read.csv("no_acc_18.csv")

merged_18 = merge(pop18, no_acc_18, by=c("GID_1"), all=TRUE)

merged_18=subset(merged_18, GID_0.x != "ATF" & GID_0.x != "EGY" & GID_0.x != "ESH"& GID_0.x != "ESP" & GID_0.x != "LBY" & GID_0.x != "MAR" & GID_0.x != "MYT" & GID_0.x != "SYC" & GID_0.x != "COM" & GID_0.x != "YEM" & GID_0.x != "TUN" & GID_0.x != "DZA" & GID_0.x != "SHN" & GID_0.x != "DJI" & GID_0.x != "STP")

merged_18 = dplyr::filter(merged_18,  !is.na(GID_0.x))

merged_18$elrate=(1-(merged_18$sum.y / merged_18$sum.x))

elrates = data.frame(merged_18$elrate, merged_18$GID_1, merged_18$GID_0.x)

varnames<-c("elrate18", "GID_1", "GID_0")
library(data.table)
setnames(elrates,names(elrates),varnames )

#2 calculate mean, non-zero per-capita sum of light
##drive_download("meanpercapitanonzero.csv", type = "csv", overwrite = TRUE)
meanpercapitanonzero = read.csv("meanpercapitanonzero.csv")

meanpercapitanonzero=subset(meanpercapitanonzero, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA" & GID_0 != "SHN" & GID_0 != "DJI" & GID_0 != "STP")
meanpercapitanonzero = dplyr::filter(meanpercapitanonzero,  !is.na(GID_0))

merger = merge(meanpercapitanonzero, elrates, by="GID_1")
merger$elrate18 = round(merger$elrate18, digits = 2)
merger = subset(merger, merger$elrate18 > 0.75)

pops = merge(merger, isrural, by = "GID_1")

library(sf)
shapefile = st_read("C:\\Users\\GIACOMO\\Downloads\\gadm36_1.shp")
shape = merge(shapefile, pops, by=c("GID_1"))

shape = st_simplify(shape, dTolerance = 0.05)
shapefile = st_simplify(shapefile, dTolerance = 0.05)


library(ggthemes)
map1 = ggplot() +
  ggthemes::theme_map()+
  geom_sf(data = shapefile)+
  geom_sf(data = shape, aes(fill = "red"))+
  scale_fill_discrete(labels=c("High access, low per-capita consumption"), name = "Legend")+
  theme(plot.margin=grid::unit(c(0,0,0,0), "mm"), panel.grid.major = element_line(colour = 'transparent'))

ggsave("highaccesslowconsumption.png", plot = map1, device = "png", width = 20, height = 30, units = "cm", scale=0.6, dpi = 600)


## 

# Country-level sensitivity analysis
#1) Import data for populaiton and population without access
library(googledrive)
setwd("D:\\Dropbox (FEEM)\\Current papers\\INEQUALITY ASSESSMENT")

drive_download("pop17.csv", type = "csv", overwrite = TRUE)
pop17 = read.csv("pop17.csv")

pop17 = pop17 %>% select(GID_0, GID_1, NAME_0, NAME_1, sum)

varnames<-c("GID_0", "GID_1", "NAME_0", "NAME_1", "pop")
library(data.table)
setnames(pop17,names(pop17),varnames )

drive_download("no_acc_17_base.csv", type = "csv", overwrite = TRUE)
no_acc_17_base = read.csv("no_acc_17_base.csv")

no_acc_17_base = no_acc_17_base %>% select(GID_1, sum)

varnames<-c("GID_1", "base")
library(data.table)
setnames(no_acc_17_base,names(no_acc_17_base),varnames )

drive_download("no_acc_17_minus.csv", type = "csv", overwrite = TRUE)
no_acc_17_minus = read.csv("no_acc_17_minus.csv")

no_acc_17_minus = no_acc_17_minus %>% select(GID_1, sum)

varnames<-c("GID_1", "minus")
library(data.table)
setnames(no_acc_17_minus,names(no_acc_17_minus),varnames )

drive_download("no_acc_17_plus.csv", type = "csv", overwrite = TRUE)
no_acc_17_plus = read.csv("no_acc_17_plus.csv")

no_acc_17_plus = no_acc_17_plus %>% select(GID_1, sum)

varnames<-c("GID_1", "plus")
library(data.table)
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
library(data.table)
setnames(elrates,names(elrates),varnames )


#3) country level analysis
library(dplyr)
merged_17_countrylevel = merged_17 %>% group_by(GID_0) %>% dplyr::summarize(pop=sum(pop,na.rm = T), base=sum(base,na.rm = T), plus=sum(plus,na.rm = T), minus=sum(minus,na.rm = T)) %>% ungroup()

merged_17_countrylevel$elrate_base = (1-(merged_17_countrylevel$base/merged_17_countrylevel$pop))
merged_17_countrylevel$elrate_plus = (1-(merged_17_countrylevel$plus/merged_17_countrylevel$pop))
merged_17_countrylevel$elrate_minus = (1-(merged_17_countrylevel$minus/merged_17_countrylevel$pop))

library(wbstats)
elrate_wb <- wb(indicator = "EG.ELC.ACCS.ZS", startdate = 2016, enddate = 2016)

elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)

merged_17_countrylevel = merge(merged_17_countrylevel, elrate_wb, by.x = "GID_0", by.y = "elrate_wb.iso3c")


# show that electrification rate calculated at the pixel level matches well elrates at the national level
library(ggplot2)
comparisonwb = ggplot()+
  geom_point(data=merged_17_countrylevel, aes(x=elrate_base, y=elrate_wb.value/100, size=pop/1e06, colour="Baseline"), alpha=0.7)+
  geom_point(data=merged_17_countrylevel, aes(x=elrate_plus, y=elrate_wb.value/100, size=pop/1e06, colour="+25%"), alpha=0.7)+
  geom_point(data=merged_17_countrylevel, aes(x=elrate_minus, y=elrate_wb.value/100, size=pop/1e06, colour="-25%"), alpha=0.7)+
  geom_label_repel(data=merged_17_countrylevel, aes(x=elrate_base, y=elrate_wb.value/100, label = GID_0),
                   box.padding   = 0.2, 
                   point.padding = 0.3,
                   segment.color = 'grey50') +
  scale_size_continuous(range = c(3, 9), name = "Total pop. (million)")+
  theme_classic()+
  geom_abline()+
  ylab("Electrficiation rate (World Bank / SE4ALL 2016)")+
  xlab("Electrification rate (NTL estimate 2016)")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_color_discrete(name="NTL noise floor")

ggsave("sensitivity_noise.png", plot = comparisonwb, device = "png", width = 24, height = 12, units = "cm", scale=1.1)

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
library(data.table)
setnames(elrates,names(elrates),varnames )

#3) country level analysis
library(dplyr)
merged_wp_countrylevel = merged_wp %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_wp_countrylevel$elrate = (1-(merged_wp_countrylevel$popnoacc/merged_wp_countrylevel$pop))

merged_ls_countrylevel = merged_ls %>% group_by(GID_0.x) %>% dplyr::summarize(pop=sum(sum.x,na.rm = T), popnoacc=sum(sum.y,na.rm = T)) %>% ungroup()
merged_ls_countrylevel$elrate = (1-(merged_ls_countrylevel$popnoacc/merged_ls_countrylevel$pop))

library(wbstats)
elrate_wb <- wb(indicator = "EG.ELC.ACCS.ZS", startdate = 2016, enddate = 2016)

elrate_wb = data.frame(elrate_wb$iso3c, elrate_wb$value)

merged_ls_countrylevel = merge(merged_ls_countrylevel, elrate_wb, by.x = "GID_0.x", by.y = "elrate_wb.iso3c")
merged_wp_countrylevel = merge(merged_wp_countrylevel, elrate_wb, by.x = "GID_0.x", by.y = "elrate_wb.iso3c")


# show that electrification rate calculated at the pixel level matches well elrates at the national level
library(ggplot2)
comparisonwb = ggplot()+
  geom_point(data=merged_ls_countrylevel, aes(x=elrate, y=elrate_wb.value/100, size=pop/1e06, colour="LandScan"), alpha=0.7)+
  geom_point(data=merged_wp_countrylevel, aes(x=elrate, y=elrate_wb.value/100, size=pop/1e06, colour="WorldPop"), alpha=0.7)+
  scale_size_continuous(range = c(3, 9), name = "Total pop. (million)")+
  theme_classic()+
  geom_abline()+
  ylab("Electrficiation rate (World Bank / SE4ALL 2016)")+
  xlab("Electrification rate (NTL estimate 2016)")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_color_discrete(name="Population dataset")


ggsave("sensitivity_population.png", plot = comparisonwb, device = "png", width = 24, height = 12, units = "cm", scale=1.1)


formula = "elrate_wb.value ~ elrate"
summary(lm(data= merged_ls_countrylevel, formula=formula))

formula = "elrate_wb.value ~ elrate"
summary(lm(data= merged_wp_countrylevel, formula=formula))
