  ## Inequality calculations
    
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
    
    #merge (with variant of pop)
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
    
    #2c) print summary statistics 
    summary(elrates$eldiff)
    summary(elrates$elrate18)
    summary(elrates$elrate14)
    
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
    
    barplot

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
  geom_point(data=merged_14_countrylevel, aes(x=elrate, y=elrate_wb.value/100), size=2.5)+
  geom_label_repel(data=merged_14_countrylevel, aes(x=elrate, y=elrate_wb.value/100, label = GID_0.x),
                   box.padding   = 0.2, 
                   point.padding = 0.3,
                   segment.color = 'grey50') +
  theme_classic()+
  geom_abline()+
  ylab("Electrficiation rate (IEA World Bank 2014)")+
  xlab("Electrification rate (NTL estimate 2014)")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))

library(readxl)
weo2018 <- read_excel("D:/Dropbox (FEEM)/Current papers/INEQUALITY ASSESSMENT/Recent electrification/weo2018.xlsx", 
                      col_types = c("text", "numeric", "numeric", 
                                    "numeric", "numeric", "numeric", 
                                    "numeric", "blank"))

library(countrycode)
weo2018$ISO3 = countrycode(weo2018$X__1, "country.name", "iso3c", warn = TRUE, nomatch = NULL)


merger = merge(merged_diff, weo2018, by.x="GID_0", by.y="ISO3")

comparisoniea = ggplot(merger, aes(x=elrate18, y=`2017`))+
  geom_point(data=merger, aes(x=elrate18, y=`2017`))+
    geom_label_repel(data=merger, aes(x=elrate18, y=`2017`, label = GID_0),
                   box.padding   = 0.2, 
                   point.padding = 0.3,
                   segment.color = 'grey50') +
  theme_classic()+
  geom_abline()+
  ylab("Electrficiation rate (IEA WEO 2018)")+
  xlab("Electrification rate (NTL estimate 2017)")+
  scale_x_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))+
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), limits = c(0,1))

ggsave("comparisonwb.png", plot = comparisonwb, device = "png", width = 24, height = 12, units = "cm", scale=1.1)
ggsave("comparisoniea.png", plot = comparisoniea, device = "png", width = 30, height = 12, units = "cm", scale=1.1)

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


lorenz[[Z]] = ggplot() +
  theme_classic()+
  geom_line(data = out_df14, aes(x=p14, y=L14, colour="red"), size=2, alpha=0.8) +
  geom_line(data = out_df18, aes(x=p18, y=L18, color="darkblue"), size=2, alpha=0.8)+
  scale_color_discrete(name = "Year", labels = c("2018", "2014"))+
  scale_x_continuous(name="Cumulative share of provinces", limits=c(0,1)) + 
  scale_y_continuous(name="Electricity access rate", limits=c(0,1)) +
  geom_abline()+
  geom_point(data = out_df18, aes(x=p18, y=L18), size=0.5)+
  geom_point(data = out_df14, aes(x=p14, y=L14), size=0.5)+
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
##define percentiles and plot histogram

#drive_download("pctiles_pc_urban.csv", type = "csv", overwrite = TRUE)
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

#drive_download("pctiles_pc_rural.csv", type = "csv", overwrite = TRUE)
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


###
#5a) import rural 'consumption' tiers for 2014
library(data.table)
#drive_download("pop14_tier_1_rural.csv", type = "csv", overwrite = TRUE)
pop14_tier_1_rural = read.csv("pop14_tier_1_rural.csv")
pop14_tier_1_rural = data.frame(pop14_tier_1_rural$sum, pop14_tier_1_rural$GID_1)
varnames<-c("pop_tier_1_rural", "GID_1")
setnames(pop14_tier_1_rural,names(pop14_tier_1_rural),varnames )

#drive_download("pop14_tier_2_rural.csv", type = "csv", overwrite = TRUE)
pop14_tier_2_rural = read.csv("pop14_tier_2_rural.csv")
pop14_tier_2_rural = data.frame(pop14_tier_2_rural$sum, pop14_tier_2_rural$GID_1)
varnames<-c("pop_tier_2_rural", "GID_1")
setnames(pop14_tier_2_rural,names(pop14_tier_2_rural),varnames )

#drive_download("pop14_tier_3_rural.csv", type = "csv", overwrite = TRUE)
pop14_tier_3_rural = read.csv("pop14_tier_3_rural.csv")
pop14_tier_3_rural = data.frame(pop14_tier_3_rural$sum, pop14_tier_3_rural$GID_1)
varnames<-c("pop_tier_3_rural", "GID_1")
setnames(pop14_tier_3_rural,names(pop14_tier_3_rural),varnames )

#drive_download("pop14_tier_4_rural.csv", type = "csv", overwrite = TRUE)
pop14_tier_4_rural = read.csv("pop14_tier_4_rural.csv")
pop14_tier_4_rural = data.frame(pop14_tier_4_rural$sum, pop14_tier_4_rural$GID_1)
varnames<-c("pop_tier_4_rural", "GID_1")
setnames(pop14_tier_4_rural,names(pop14_tier_4_rural),varnames )

elrates14 = Reduce(function(x,y) merge(x,y,by="GID_1",all=TRUE) ,list(elrates, pop14_tier_1_rural, pop14_tier_2_rural, pop14_tier_3_rural, pop14_tier_4_rural))
elrates_BK_14 = elrates14

elrates14=subset(elrates14, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
elrates14 = dplyr::filter(elrates14,  !is.na(GID_0))

#6) calculate gini index of consumption among those with access within each province
colist=unique(elrates14$GID_0)
output_d_14=list()

for (A in colist){
  datin=subset(elrates14, elrates14$GID_0== A)
  
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
  output_d_14[[A]] = output
  elrates14 = elrates_BK_14
}

#calculate summary statistics for the gini indexes in each country (mean, max, min, obs...)
lis_14 = 1:length(output_d_14)

fune_14 = function(X){  
  as.data.frame(t(output_d_14[[X]][1, ]))
}

store_14 = lapply(lis_14, fune_14)

#index of number-country to select which to visualise
#View(colist)

#summary statistics for inequality in consumption within provinces
# i.e. here we see the within-province inequality in consumption for those with access
#a distribution of the inequality within each region of the country
functi_14 = function(X){
  summary(as.numeric(levels(store_14[[X]]$output))[store_14[[X]]$output])
}
distribution_inequality_14 = lapply(c(1:43), functi_14)


#what if we wanted to see the between province inequality in consumption for those with access?
#simply calculate the gini of the last object
#One figures which sums up inequality at the national level
functi2_14= function(x){
  ineq(as.numeric(levels(store_14[[x]]$output))[store_14[[x]]$output],type="Gini")
}

national_inequality_14 = lapply(c(1:43), functi2_14)


####################
#5b) import rural 'consumption' tiers for 2018
library(data.table)
#drive_download("pop18_tier_1_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_1_rural = read.csv("pop18_tier_1_rural.csv")
pop18_tier_1_rural = data.frame(pop18_tier_1_rural$sum, pop18_tier_1_rural$GID_1)
varnames<-c("pop_tier_1_rural", "GID_1")
setnames(pop18_tier_1_rural,names(pop18_tier_1_rural),varnames )

#drive_download("pop18_tier_2_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_2_rural = read.csv("pop18_tier_2_rural.csv")
pop18_tier_2_rural = data.frame(pop18_tier_2_rural$sum, pop18_tier_2_rural$GID_1)
varnames<-c("pop_tier_2_rural", "GID_1")
setnames(pop18_tier_2_rural,names(pop18_tier_2_rural),varnames )

#drive_download("pop18_tier_3_rural.csv", type = "csv", overwrite = TRUE)
pop18_tier_3_rural = read.csv("pop18_tier_3_rural.csv")
pop18_tier_3_rural = data.frame(pop18_tier_3_rural$sum, pop18_tier_3_rural$GID_1)
varnames<-c("pop_tier_3_rural", "GID_1")
setnames(pop18_tier_3_rural,names(pop18_tier_3_rural),varnames )

#drive_download("pop18_tier_4_rural.csv", type = "csv", overwrite = TRUE)
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


#########
#LAST STEP:
#calculate change in inequality 
diff_national_inequality = mapply('-',national_inequality_18,national_inequality_14,SIMPLIFY=FALSE)

library(reshape2)
diff_national_inequality = melt(diff_national_inequality)
diff_national_inequality = data.frame(diff_national_inequality$value)

####YOU SHOULD CALCULATE LORENZ CURVES OF CONSUMPTION just like you did with access
#i.e. y = dominant tier, x=regions within the country

elrates18$popwithrobustaccess = ((elrates18$pop_tier_3_rural + elrates18$pop_tier_4_rural) / (elrates18$pop_tier_1_rural + elrates18$pop_tier_2_rural +elrates18$pop_tier_3_rural + elrates18$pop_tier_4_rural))

elrates14$popwithrobustaccess = ((elrates14$pop_tier_3_rural + elrates14$pop_tier_4_rural) / (elrates14$pop_tier_1_rural + elrates14$pop_tier_2_rural +elrates14$pop_tier_3_rural + elrates14$pop_tier_4_rural))

data_cons = data.frame(elrates14$GID_0, elrates14$GID_1, elrates14$popwithrobustaccess, elrates18$popwithrobustaccess)
varnames<-c("GID_0", "GID_1", "robaccess14", "robaccess18")
setnames(data_cons,names(data_cons),varnames )

data_cons=subset(data_cons, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
data_cons = dplyr::filter(data_cons,  !is.na(GID_0))

colist=unique(elrates$GID_0)
ine_cons14=list()
ine_cons18=list()
lorenz_cons=list()

for (Z in colist){
  datin=subset(data_cons, data_cons$GID_0 == Z)
  #sort data 
  out_cons14 = sort(datin$robaccess14)
  out_cons18 = sort(datin$robaccess18)
  
  #plot and store Lorenz curve
  Lorenz=Lc(out_cons14, plot =F)
  p_c14 <- Lorenz$p
  L_c14 <- Lorenz$L
  out_df_c14 <- data.frame(p_c14,L_c14)
  
  Lorenz=Lc(out_cons18, plot =F)
  p_c18 <- Lorenz$p
  L_c18 <- Lorenz$L
  out_df_c18 <- data.frame(p_c18,L_c18)
  
  lorenz_cons[[Z]] = ggplot() +
    theme_classic()+
    geom_line(data = out_df_c14, aes(x=p_c14, y=L_c14, colour="red"), size=2, alpha=0.8) +
    geom_line(data = out_df_c18, aes(x=p_c18, y=L_c18, color="darkblue"), size=2, alpha=0.8)+
    scale_color_discrete(name = "Year", labels = c("2018", "2014"))+
    scale_x_continuous(name="Cumulative share of provinces", limits=c(0,1)) + 
    scale_y_continuous(name="Share of those with access with robust access", limits=c(0,1)) +
    geom_abline()+
    geom_point(data = out_df_c18, aes(x=p_c18, y=L_c18), size=0.5)+
    geom_point(data = out_df_c14, aes(x=p_c14, y=L_c14), size=0.5)+
    theme(axis.text=element_text(size=6),
          axis.title=element_text(size=6))
  
}

ggsave("lorenz_cons_cons.png", plot_grid(lorenz_cons[['BDI']], lorenz_cons[['KEN']], lorenz_cons[['ETH']], lorenz_cons[['TZA']], lorenz_cons[['NGA']], lorenz_cons[['COD']], labels=c("BDI", "KEN", "ETH", "TZA", "NGA", "COD"), label_size = 6, hjust= 0, ncol=2)
       , device = "png", width = 35, height = 30, units = "cm", scale=0.5)


##column plot split of consumption (RURAL)
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


#########
#URBAN tiers for 2014

library(data.table)
#drive_download("pop14_tier_1_urban.csv", type = "csv", overwrite = TRUE)
pop14_tier_1_urban = read.csv("pop14_tier_1_urban.csv")
pop14_tier_1_urban = data.frame(pop14_tier_1_urban$sum, pop14_tier_1_urban$GID_1)
varnames<-c("pop_tier_1_urban", "GID_1")
setnames(pop14_tier_1_urban,names(pop14_tier_1_urban),varnames )

#drive_download("pop14_tier_2_urban.csv", type = "csv", overwrite = TRUE)
pop14_tier_2_urban = read.csv("pop14_tier_2_urban.csv")
pop14_tier_2_urban = data.frame(pop14_tier_2_urban$sum, pop14_tier_2_urban$GID_1)
varnames<-c("pop_tier_2_urban", "GID_1")
setnames(pop14_tier_2_urban,names(pop14_tier_2_urban),varnames )

#drive_download("pop14_tier_3_urban.csv", type = "csv", overwrite = TRUE)
pop14_tier_3_urban = read.csv("pop14_tier_3_urban.csv")
pop14_tier_3_urban = data.frame(pop14_tier_3_urban$sum, pop14_tier_3_urban$GID_1)
varnames<-c("pop_tier_3_urban", "GID_1")
setnames(pop14_tier_3_urban,names(pop14_tier_3_urban),varnames )

#drive_download("pop14_tier_4_urban.csv", type = "csv", overwrite = TRUE)
pop14_tier_4_urban = read.csv("pop14_tier_4_urban.csv")
pop14_tier_4_urban = data.frame(pop14_tier_4_urban$sum, pop14_tier_4_urban$GID_1)
varnames<-c("pop_tier_4_urban", "GID_1")
setnames(pop14_tier_4_urban,names(pop14_tier_4_urban),varnames )

elrates14 = Reduce(function(x,y) merge(x,y,by="GID_1",all=TRUE) ,list(elrates, pop14_tier_1_urban, pop14_tier_2_urban, pop14_tier_3_urban, pop14_tier_4_urban))
elrates_BK_14 = elrates14

elrates14=subset(elrates14, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
elrates14 = dplyr::filter(elrates14,  !is.na(GID_0))

#6) calculate gini index of consumption among those with access within each province
colist=unique(elrates14$GID_0)
output_d_14=list()

for (A in colist){
  datin=subset(elrates14, elrates14$GID_0== A)
  
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
  output_d_14[[A]] = output
  elrates14 = elrates_BK_14
}

#calculate summary statistics for the gini indexes in each country (mean, max, min, obs...)
lis_14 = 1:length(output_d_14)

fune_14 = function(X){  
  as.data.frame(t(output_d_14[[X]][1, ]))
}

store_14 = lapply(lis_14, fune_14)

#index of number-country to select which to visualise
#View(colist)

#summary statistics for inequality in consumption within provinces
# i.e. here we see the within-province inequality in consumption for those with access
#a distribution of the inequality within each region of the country
functi_14 = function(X){
  summary(as.numeric(levels(store_14[[X]]$output))[store_14[[X]]$output])
}
distribution_inequality_14 = lapply(c(1:43), functi_14)


#what if we wanted to see the between province inequality in consumption for those with access?
#simply calculate the gini of the last object
#One figures which sums up inequality at the national level
functi2_14= function(x){
  ineq(as.numeric(levels(store_14[[x]]$output))[store_14[[x]]$output],type="Gini")
}

national_inequality_14 = lapply(c(1:43), functi2_14)


####################
#5b) import urban consumption' tiers for 2018
library(data.table)
#drive_download("pop18_tier_1_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_1_urban = read.csv("pop18_tier_1_urban.csv")
pop18_tier_1_urban = data.frame(pop18_tier_1_urban$sum, pop18_tier_1_urban$GID_1)
varnames<-c("pop_tier_1_urban", "GID_1")
setnames(pop18_tier_1_urban,names(pop18_tier_1_urban),varnames )

#drive_download("pop18_tier_2_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_2_urban = read.csv("pop18_tier_2_urban.csv")
pop18_tier_2_urban = data.frame(pop18_tier_2_urban$sum, pop18_tier_2_urban$GID_1)
varnames<-c("pop_tier_2_urban", "GID_1")
setnames(pop18_tier_2_urban,names(pop18_tier_2_urban),varnames )

#drive_download("pop18_tier_3_urban.csv", type = "csv", overwrite = TRUE)
pop18_tier_3_urban = read.csv("pop18_tier_3_urban.csv")
pop18_tier_3_urban = data.frame(pop18_tier_3_urban$sum, pop18_tier_3_urban$GID_1)
varnames<-c("pop_tier_3_urban", "GID_1")
setnames(pop18_tier_3_urban,names(pop18_tier_3_urban),varnames )

#drive_download("pop18_tier_4_urban.csv", type = "csv", overwrite = TRUE)
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


#########
#LAST STEP:
#calculate change in inequality 
diff_national_inequality = mapply('-',national_inequality_18,national_inequality_14,SIMPLIFY=FALSE)

library(reshape2)
diff_national_inequality = melt(diff_national_inequality)
diff_national_inequality = data.frame(diff_national_inequality$value)

####YOU SHOULD CALCULATE LORENZ CURVES OF CONSUMPTION just like you did with access
#i.e. y = dominant tier, x=regions within the country

elrates18$popwithrobustaccess = ((elrates18$pop_tier_3_urban + elrates18$pop_tier_4_urban) / (elrates18$pop_tier_1_urban + elrates18$pop_tier_2_urban +elrates18$pop_tier_3_urban + elrates18$pop_tier_4_urban))

elrates14$popwithrobustaccess = ((elrates14$pop_tier_3_urban + elrates14$pop_tier_4_urban) / (elrates14$pop_tier_1_urban + elrates14$pop_tier_2_urban +elrates14$pop_tier_3_urban + elrates14$pop_tier_4_urban))

data_cons = data.frame(elrates14$GID_0, elrates14$GID_1, elrates14$popwithrobustaccess, elrates18$popwithrobustaccess)
varnames<-c("GID_0", "GID_1", "robaccess14", "robaccess18")
setnames(data_cons,names(data_cons),varnames )

data_cons=subset(data_cons, GID_0 != "ATF" & GID_0 != "EGY" & GID_0 != "ESH"& GID_0 != "ESP" & GID_0 != "LBY" & GID_0 != "MAR" & GID_0 != "MYT" & GID_0 != "SYC" & GID_0 != "COM" & GID_0 != "YEM" & GID_0 != "TUN" & GID_0 != "DZA")
data_cons = dplyr::filter(data_cons,  !is.na(GID_0))

colist=unique(elrates$GID_0)
ine_cons14=list()
ine_cons18=list()
lorenz_cons=list()

for (Z in colist){
  datin=subset(data_cons, data_cons$GID_0 == Z)
  #sort data 
  out_cons14 = sort(datin$robaccess14)
  out_cons18 = sort(datin$robaccess18)
  
  #plot and store Lorenz curve
  Lorenz=Lc(out_cons14, plot =F)
  p_c14 <- Lorenz$p
  L_c14 <- Lorenz$L
  out_df_c14 <- data.frame(p_c14,L_c14)
  
  Lorenz=Lc(out_cons18, plot =F)
  p_c18 <- Lorenz$p
  L_c18 <- Lorenz$L
  out_df_c18 <- data.frame(p_c18,L_c18)
  
  lorenz_cons[[Z]] = ggplot() +
    theme_classic()+
    geom_line(data = out_df_c14, aes(x=p_c14, y=L_c14, colour="red"), size=2, alpha=0.8) +
    geom_line(data = out_df_c18, aes(x=p_c18, y=L_c18, color="darkblue"), size=2, alpha=0.8)+
    scale_color_discrete(name = "Year", labels = c("2018", "2014"))+
    scale_x_continuous(name="Cumulative share of provinces", limits=c(0,1)) + 
    scale_y_continuous(name="Share of those with access with robust access", limits=c(0,1)) +
    geom_abline()+
    geom_point(data = out_df_c18, aes(x=p_c18, y=L_c18), size=0.5)+
    geom_point(data = out_df_c14, aes(x=p_c14, y=L_c14), size=0.5)+
    theme(axis.text=element_text(size=6),
          axis.title=element_text(size=6))
  
}

ggsave("lorenz_cons_cons.png", plot_grid(lorenz_cons[['BDI']], lorenz_cons[['KEN']], lorenz_cons[['ETH']], lorenz_cons[['TZA']], lorenz_cons[['NGA']], lorenz_cons[['COD']], labels=c("BDI", "KEN", "ETH", "TZA", "NGA", "COD"), label_size = 6, hjust= 0, ncol=2)
       , device = "png", width = 35, height = 30, units = "cm", scale=0.5)


##column plot split of consumption (urban)
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

#map plot gini consumption
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

#change in per--capita
elrates18$poptier1change = elrates18$pop_tier_1-elrates14$pop_tier_1
elrates18$poptier2change = elrates18$pop_tier_2-elrates14$pop_tier_2
elrates18$poptier3change = elrates18$pop_tier_3-elrates14$pop_tier_3
elrates18$poptier4change = elrates18$pop_tier_4-elrates14$pop_tier_4

#############################
##Hotspots identification
library(googledrive)
setwd("D:\\Dropbox (FEEM)\\Current papers\\INEQUALITY ASSESSMENT")

#drive_download("changeinpopnoaccess1418.csv", type = "csv", overwrite = TRUE)
changeinpopnoaccess = read.csv("changeinpopnoaccess1418.csv")

#drive_download("allAreas.csv", type = "csv", overwrite = TRUE)
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

map1

ggsave("map1.png", plot = map1, device = "png", width = 20, height = 30, units = "cm", scale=0.6, dpi = 600)


##
#drive_download("isrural.csv", type = "csv", overwrite = TRUE)
isrural= read.csv("isrural.csv")

#drive_download("changeinlight.csv", type = "csv", overwrite = TRUE)
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
#drive_download("pop18.csv", type = "csv", overwrite = TRUE)
pop18 = read.csv("pop18.csv")

#drive_download("no_acc_18.csv", type = "csv", overwrite = TRUE)
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
#drive_download("meanpercapitanonzero.csv", type = "csv", overwrite = TRUE)
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
