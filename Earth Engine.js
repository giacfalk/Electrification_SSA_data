//Earth Engine Script for: 
//A Gridded Dataset to Assess Electrification in Sub-Saharan Africa
//Giacomo Falchetta, Shonali Pachauri, Simon Parkinson, Edward Byers
// Version: 29/04/18

//Import VIIRS nighttime lights provinces shapefile
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var nl16 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

//
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

//Import Landscan population (change these lines to change the population dataset to WorldPop)
var pop14 = ee.Image('users/giacomofalchetta/landscan2014');
//var pop14 = ee.Image('users/giacomofalchetta/AFR_PPP_2015_adj_v2') 
var pop15 = ee.Image('users/giacomofalchetta/LandScanGlobal2015')
//var pop15 = ee.Image('users/giacomofalchetta/AFR_PPP_2015_adj_v2') 
var pop16 = ee.Image('users/giacomofalchetta/LandScanGlobal2016');
//var pop16 = ee.Image('users/giacomofalchetta/AFR_PPP_2015_adj_v2')
var pop17 = ee.Image('users/giacomofalchetta/LandScanGlobal2017')
//var pop14 = ee.Image('users/giacomofalchetta/AFR_PPP_2020_adj_v2') 
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');
//var pop18 = ee.Image('users/giacomofalchetta/AFR_PPP_2020_adj_v2') 

// Apply NTL noise floors
//2014
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median()

//2016
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl16.map(conditional);

var nl16 = ee.ImageCollection(output).median()


//2018
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()


// Generate data for population without access for both years

var pop14_noaccess = pop14.mask(pop14.gt(0).and(nl14.lt(0.05)))
var pop16_noaccess = pop14.mask(pop16.gt(0).and(nl16.lt(0.05)))
var pop18_noaccess = pop18.mask(pop18.gt(0).and(nl18.lt(0.05)))

//Calculate sum of people without access by province

var no_acc_14 = pop14_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_16 = pop16_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_18 = pop18_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

//Export to Google Drive
var no_acc_14 = no_acc_14.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_14,
  description: 'no_acc_14',
  fileFormat: 'CSV',
});   

var no_acc_16 = no_acc_16.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_16,
  description: 'no_acc_16',
  fileFormat: 'CSV',
});   

var no_acc_18 = no_acc_18.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_18,
  description: 'no_acc_18',
  fileFormat: 'CSV',
});   


//Calculate total population by province
var pop14_exp = pop14.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop16_exp = pop16.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop18_exp = pop18.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop14_exp = pop14_exp.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop14_exp,
  description: 'pop14',
  fileFormat: 'CSV'
});   

var pop16_exp = pop16_exp.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop16_exp,
  description: 'pop16',
  fileFormat: 'CSV'
});   

var pop18_exp = pop18_exp.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop18_exp,
  description: 'pop18',
  fileFormat: 'CSV'
});   


//2) Urban / rural distinction
///Identify urban and rural areas and define tiers of consumption

//Import land cover data
var modis14 = ee.Image("MODIS/006/MCD12Q1/2014_01_01")
var modis17 = ee.Image("MODIS/006/MCD12Q1/2017_01_01")
var modis14 = modis14.select('LC_Type2')
var modis17 = modis17.select('LC_Type2')

//Define thresholds of density and select urban areas for each cluster
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'BWA'),  ee.Filter.eq('ISO3', 'GAB'), ee.Filter.eq('ISO3', 'AGO')));
var pop18_cut = pop18.select('b1').clip(Countries)
var urbpop0 = pop18_cut.mask(modis17.eq(13).or(pop18_cut.gt(175)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop18_cut = pop18.select('b1').clip(Countries)
var urbpop1 = pop18_cut.mask(modis17.eq(13).or(pop18_cut.gt(650)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop18_cut = pop18.select('b1').clip(Countries)
var urbpop2 = pop18_cut.mask(modis17.eq(13).or(pop18_cut.gt(800)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN'), ee.Filter.eq('ISO3', 'GNQ')));
var pop18_cut = pop18.select('b1').clip(Countries)
var urbpop3 = pop18_cut.mask(modis17.eq(13).or(pop18_cut.gt(1200)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN'), ee.Filter.eq('ISO3', 'ERI')));
var pop18_cut = pop18.select('b1').clip(Countries)
var urbpop4 = pop18_cut.mask(modis17.eq(13).or(pop18_cut.gt(1500)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop18_cut = pop18.select('b1').clip(Countries)
var urbpop5 = pop18_cut.mask(modis17.eq(13).or(pop18_cut.gt(2500)))

//unify urban areas data
var urbpop = ee.ImageCollection([urbpop0, urbpop1, urbpop2, urbpop3, urbpop4, urbpop5]).mosaic()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'BWA'),  ee.Filter.eq('ISO3', 'GAB'), ee.Filter.eq('ISO3', 'AGO')));
var pop18_cut = pop18.select('b1').clip(Countries)
var rurpop0 = pop18_cut.mask(pop18_cut.lte(175).and(pop18_cut.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop18_cut = pop18.select('b1').clip(Countries)
var rurpop1 = pop18_cut.mask(pop18_cut.lte(650).and(pop18_cut.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop18_cut = pop18.select('b1').clip(Countries)
var rurpop2 = pop18_cut.mask(pop18_cut.lte(800).and(pop18_cut.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN'), ee.Filter.eq('ISO3', 'GNQ')));
var pop18_cut = pop18.select('b1').clip(Countries)
var rurpop3 = pop18_cut.mask(pop18_cut.lte(1200).and(pop18_cut.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN'),  ee.Filter.eq('ISO3', 'ERI')));
var pop18_cut = pop18.select('b1').clip(Countries)
var rurpop4 = pop18_cut.mask(pop18_cut.lte(1500).and(pop18_cut.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop18_cut = pop18.select('b1').clip(Countries)
var rurpop5 = pop18_cut.mask(pop18_cut.lte(2500).and(pop18_cut.gt(0)))

//unify rural areas data
var rurpop = ee.ImageCollection([rurpop0, rurpop1, rurpop2, rurpop3, rurpop4, rurpop5]).mosaic()

//Validate urbanisation rates estimated at the grid cell level

var modis17 = ee.Image("MODIS/006/MCD12Q1/2017_01_01")
var modis17 = modis17.select('LC_Type2')

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'BWA'),  ee.Filter.eq('ISO3', 'GAB'), ee.Filter.eq('ISO3', 'AGO')));
var pop17_val = pop17.select('b1')
var pop17_val = pop17_val.mask(modis17.eq(13).or(pop17_val.gt(175)))

var popu = pop17_val.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popu = popu.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: popu,
  description: 'popu0',
  fileFormat: 'CSV'
});   

var popt = pop17.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt0',
  fileFormat: 'CSV'
});   


var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop17_val = pop17.select('b1')
var pop17_val = pop17_val.mask(modis17.eq(13).or(pop17_val.gt(650)))

var popu = pop17_val.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu1',
  fileFormat: 'CSV'
});   

var popt = pop17.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt1',
  fileFormat: 'CSV'
});   


var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop17_val = pop17.select('b1')
var pop17_val = pop17_val.mask(modis17.eq(13).or(pop17_val.gt(800)))

var popu = pop17_val.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu2',
  
  fileFormat: 'CSV'
});   

var popt = pop17.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt2',
  
  fileFormat: 'CSV'
});   

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN'), ee.Filter.eq('ISO3', 'GNQ')));
var pop17_val = pop17.select('b1')
var pop17_val = pop17_val.mask(modis17.eq(13).or(pop17_val.gt(1200)))

var popu = pop17_val.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu3',
  fileFormat: 'CSV'
});   

var popt = pop17.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt3',
  fileFormat: 'CSV'
});   

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN'), ee.Filter.eq('ISO3', 'ERI')));
var pop17_val = pop17.select('b1')
var pop17_val = pop17_val.mask(modis17.eq(13).or(pop17_val.gt(1500)))

var popu = pop17_val.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu4',
  fileFormat: 'CSV'
});   

var popt = pop17.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt4',
  fileFormat: 'CSV'
});   

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop17_val = pop17.select('b1')
var pop17_val = pop17_val.mask(modis17.eq(13).or(pop17_val.gt(2500)))

var popu = pop17_val.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu5',
  fileFormat: 'CSV'
});   

var popt = pop17.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt5',
  fileFormat: 'CSV'
});   

//3) extract quartiles of light per-capita for urban and rural areas to determine thresholds for tiers of consumption

// apply lights noise floor
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var nl18 = nl18.mask(nl18.gt(0.1))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.and(ee.Filter.neq('SUBREGION', 15), ee.Filter.eq('REGION', 2)))

var lightcapita18 = nl18

var lightcapita18_rur = lightcapita18.mask(rurpop.gt(0).and(lightcapita18.gt(0)))

var lightsum = lightcapita18_rur.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.percentile([25, 50, 75]),
  scale: 1000
});

Export.table.toDrive({
  collection: lightsum,
  description:'pctiles_pc_rural',
  fileFormat: 'CSV',
  selectors : ['p25', 'p50', 'p75','ISO3']
});

var lightcapita18_urb = nl18

var lightsum = lightcapita18_urb.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.percentile([25, 50, 75]),
  scale: 1000
});

Export.table.toDrive({
  collection: lightsum,
  description:'pctiles_pc_urban',
  fileFormat: 'CSV',
  selectors : ['p25', 'p50', 'p75','ISO3']
});


//4) Produce counts of tiers of consumption 
//A) Rural areas
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var lightcapita18 = nl18

var lightcapita18 = lightcapita18.mask(rurpop.gt(0).and(lightcapita18.gt(0)))

//Input values defined in R as quartiles 
var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.38)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.38)).and(lightcapita18.lt(0.45)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.45)).and(lightcapita18.lt(0.68)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.68)))

// number of people 'with access' in each tier
var pop18_tier_1 = pop18_tier_1.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_1 = pop18_tier_1.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_1,
  description: 'pop18_tier_1_rural',
  fileFormat: 'CSV'
}); 


var pop18_tier_2 = pop18_tier_2.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_2 = pop18_tier_2.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_2,
  description: 'pop18_tier_2_rural',
  fileFormat: 'CSV'
});   

var pop18_tier_3 = pop18_tier_3.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_3 = pop18_tier_3.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_3,
  description: 'pop18_tier_3_rural',
  fileFormat: 'CSV'
});   

var pop18_tier_4 = pop18_tier_4.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_4 = pop18_tier_4.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_4,
  description: 'pop18_tier_4_rural',
  fileFormat: 'CSV'
});   

//Urban areas
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var lightcapita18 = nl18

var lightcapita18 = lightcapita18.mask(urbpop.gt(0).and(lightcapita18.gt(0)))

//Input values defined in R as quartiles 
var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.40)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.40)).and(lightcapita18.lt(0.48)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.48)).and(lightcapita18.lt(0.88)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.88)))

// number of people 'with access' in that tier
var pop18_tier_1 = pop18_tier_1.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_1 = pop18_tier_1.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_1,
  description: 'pop18_tier_1_urban',
  fileFormat: 'CSV'
}); 


var pop18_tier_2 = pop18_tier_2.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_2 = pop18_tier_2.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_2,
  description: 'pop18_tier_2_urban',
  fileFormat: 'CSV'
});   

var pop18_tier_3 = pop18_tier_3.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_3 = pop18_tier_3.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_3,
  description: 'pop18_tier_3_urban',
  fileFormat: 'CSV'
});   

var pop18_tier_4 = pop18_tier_4.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop18_tier_4 = pop18_tier_4.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop18_tier_4,
  description: 'pop18_tier_4_urban',
  fileFormat: 'CSV'
});   

// Carry out sensitivity analysis for population datasets
//Import VIIRS nighttime lights for 2017 and 2014
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');
var pop17_ls = ee.Image('users/giacomofalchetta/LandScanGlobal2017');
var pop17_wp = ee.Image('users/giacomofalchetta/AFR_PPP_2015_adj_v2')

var pop17_ls = pop17_ls.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop17_ls = pop17_ls.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop17_ls,
  description: 'pop17_ls',
  fileFormat: 'CSV'
});  

var pop17_wp = pop17_wp.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop17_wp = pop17_wp.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop17_wp,
  description: 'pop17_wp',
  fileFormat: 'CSV'
}); 

///
var pop17_ls = ee.Image('users/giacomofalchetta/LandScanGlobal2017');
var pop17_wp = ee.Image('users/giacomofalchetta/AFR_PPP_2015_adj_v2')
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl17 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl17.map(conditional);

var nl17 = ee.ImageCollection(output).median()

// Apply noise floor and select populated cells
var pop17_noaccess_ls = pop17_ls.mask(pop17_ls.gt(0).and(nl17.lt(0.05)))

var pop17_noaccess_ls = pop17_noaccess_ls.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var pop17_noaccess_ls = pop17_noaccess_ls.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop17_noaccess_ls,
  description: 'pop17_noaccess_ls',
  fileFormat: 'CSV',
});   

//
var pop17_ls = ee.Image('users/giacomofalchetta/LandScanGlobal2017');
var pop17_wp = ee.Image('users/giacomofalchetta/AFR_PPP_2015_adj_v2')
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl17 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl17.map(conditional);

var nl17 = ee.ImageCollection(output).median()

// Apply noise floor and select populated cells
var pop17_noaccess_wp = pop17_wp.mask(pop17_wp.gt(0).and(nl17.lt(0.05)))

var pop17_noaccess_wp = pop17_noaccess_wp.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var pop17_noaccess_wp = pop17_noaccess_wp.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop17_noaccess_wp,
  description: 'pop17_noaccess_wp',
  fileFormat: 'CSV',
});   


//Carry out sensitivity analysis for noise floor
//Export pop
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var pop17_sa = pop17.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop17_sa = pop17_sa.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop17_sa,
  description: 'pop17',
  fileFormat: 'CSV'
});  

// Export NL
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl17 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl17.map(conditional);

var nl17 = ee.ImageCollection(output).median()

// Apply noise floor and select populated cells
var pop17_noaccess = pop17.mask(pop17.gt(0).and(nl17.lt(0.05)))

// Import provinces Shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var no_acc_17 = pop17_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_17 = no_acc_17.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_17,
  description: 'no_acc_17_base',
  fileFormat: 'CSV',
});   

//
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl17 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.1875), replacement);
};

var output = nl17.map(conditional);

var nl17 = ee.ImageCollection(output).median()

// Apply noise floor and select populated cells
var pop17_noaccess = pop17.mask(pop17.gt(0).and(nl17.lt(0.05)))

// Import provinces Shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var no_acc_17 = pop17_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_17 = no_acc_17.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_17,
  description: 'no_acc_17_minus',
  fileFormat: 'CSV',
});   

//
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl17 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.3125), replacement);
};

var output = nl17.map(conditional);

var nl17 = ee.ImageCollection(output).median()

// Apply noise floor and select populated cells
var pop17_noaccess = pop17.mask(pop17.gt(0).and(nl17.lt(0.05)))

// Import provinces Shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var no_acc_17 = pop17_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_17 = no_acc_17.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_17,
  description: 'no_acc_17_plus',
  fileFormat: 'CSV',
});   


/// Validate province-level estimates
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var nl15 =  imageCollection.filterDate('2015-01-01', '2016-01-01').select('avg_rad')
var nl16 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')
var nl17 =  imageCollection.filterDate('2017-01-01', '2018-01-01').select('avg_rad')

// Apply noise floor and select populated cells
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median()

//
// Apply noise floor and select populated cells
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl15.map(conditional);

var nl15 = ee.ImageCollection(output).median()

//

// Apply noise floor and select populated cells
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl16.map(conditional);

var nl16 = ee.ImageCollection(output).median()

//

// Apply noise floor and select populated cells
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl17.map(conditional);

var nl17 = ee.ImageCollection(output).median()

// Apply noise floor and select populated cells
var pop14_noaccess = pop18.mask(pop18.gt(0).and(nl14.lt(0.05)))
var pop15_noaccess = pop18.mask(pop18.gt(0).and(nl15.lt(0.05)))
var pop16_noaccess = pop18.mask(pop18.gt(0).and(nl16.lt(0.05)))
var pop17_noaccess = pop18.mask(pop18.gt(0).and(nl17.lt(0.05)))

// Import provinces Shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1').filter(ee.Filter.or(ee.Filter.eq('GID_0', 'COD'), ee.Filter.eq('GID_0', 'ZMB'), ee.Filter.eq('GID_0', 'BFA')))

//Calculate sum of people without access by province
var no_acc_14 = pop14_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1').filter(ee.Filter.or(ee.Filter.eq('GID_0', 'MOZ'), ee.Filter.eq('GID_0', 'AGO'), ee.Filter.eq('GID_0', 'MWI'), ee.Filter.eq('GID_0', 'ZWE'), ee.Filter.eq('GID_0', 'NGA'), ee.Filter.eq('GID_0', 'MLI')))


var no_acc_15 = pop15_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1').filter(ee.Filter.or(ee.Filter.eq('GID_0', 'BDI'), ee.Filter.eq('GID_0', 'ETH'), ee.Filter.eq('GID_0', 'GHA'), ee.Filter.eq('GID_0', 'SLE')))


var no_acc_16 = pop16_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1').filter(ee.Filter.or(ee.Filter.eq('GID_0', 'SEN'), ee.Filter.eq('GID_0', 'TOG'), ee.Filter.eq('GID_0', 'TZA')))
var no_acc_17 = pop17_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

//Export to Google Drive
var no_acc_14 = no_acc_14.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_14,
  description: 'no_acc_14_valid',
  fileFormat: 'CSV',
});   

var no_acc_15 = no_acc_15.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_15,
  description: 'no_acc_15_valid',
  fileFormat: 'CSV',
});  

var no_acc_16 = no_acc_16.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_16,
  description: 'no_acc_16_valid',
  fileFormat: 'CSV',
});  

var no_acc_17 = no_acc_17.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_17,
  description: 'no_acc_17_valid',
  fileFormat: 'CSV',
});  


var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');

//Calculate total population by province
var pop18_exp = pop18.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop18_exp = pop18_exp.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop18_exp,
  description: 'pop18_valid',
  fileFormat: 'CSV'
});   


//Calculate electrification rate in urban and rural areas, respectively 
//Urban
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var nl16 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

// Apply noise floors and select populated cells
//2014
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median().mask(urbpop)

//2016
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl16.map(conditional);

var nl16 = ee.ImageCollection(output).median().mask(urbpop)


//2018
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median().mask(urbpop)

//Import population for both years (change these two line to change the population dataset)
var pop14_u = pop14.mask(urbpop);
var pop16_u = pop16.mask(urbpop);
var pop18_u = pop18.mask(urbpop);


// Generate data for population without access for both years
var pop14_noaccess = pop14_u.mask(pop14_u.gt(0).and(nl14.lt(0.05)))
var pop16_noaccess = pop16_u.mask(pop16_u.gt(0).and(nl16.lt(0.05)))
var pop18_noaccess = pop18_u.mask(pop18_u.gt(0).and(nl18.lt(0.05)))

// Import provinces shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

//Calculate sum of people without access by province
var no_acc_14 = pop14_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_16 = pop16_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_18 = pop18_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

//Export to Google Drive
var no_acc_14 = no_acc_14.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_14,
  description: 'no_acc_14_urb',
  fileFormat: 'CSV',
});   

var no_acc_16 = no_acc_16.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_16,
  description: 'no_acc_16_urb',
  fileFormat: 'CSV',
});   

var no_acc_18 = no_acc_18.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_18,
  description: 'no_acc_18_urb',
  fileFormat: 'CSV',
});   


//Calculate total population by province
var pop14_t= pop14_u.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop16_t = pop16_u.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop18_t = pop18_u.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop14_t = pop14_t.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop14_t,
  description: 'pop14_urb',
  fileFormat: 'CSV'
});   

var pop16_t = pop16_t.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop16_t,
  description: 'pop16_urb',
  fileFormat: 'CSV'
});   

var pop18_t = pop18_t.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop18_t,
  description: 'pop18_urb',
  fileFormat: 'CSV'
});   

//Rural
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var nl16 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

// Apply noise floors and select populated cells
//2014
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median().mask(rurpop)

//2016
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl16.map(conditional);

var nl16 = ee.ImageCollection(output).median().mask(rurpop)


//2018
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median().mask(rurpop)

//Import population for both years (change these two line to change the population dataset)
var pop14_r = pop14.mask(rurpop);
var pop16_r = pop16.mask(rurpop);
var pop18_r = pop18.mask(rurpop);


// Generate data for population without access for both years
var pop14_noaccess = pop14_r.mask(pop14_r.gt(0).and(nl14.lt(0.05)))
var pop16_noaccess = pop16_r.mask(pop16_r.gt(0).and(nl16.lt(0.05)))
var pop18_noaccess = pop18_r.mask(pop18_r.gt(0).and(nl18.lt(0.05)))

// Import provinces shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

//Calculate sum of people without access by province
var no_acc_14 = pop14_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_16 = pop16_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var no_acc_18 = pop18_noaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

//Export to Google Drive
var no_acc_14 = no_acc_14.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_14,
  description: 'no_acc_14_rur',
  fileFormat: 'CSV',
});   

var no_acc_16 = no_acc_16.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_16,
  description: 'no_acc_16_rur',
  fileFormat: 'CSV',
});   

var no_acc_18 = no_acc_18.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_18,
  description: 'no_acc_18_rur',
  fileFormat: 'CSV',
});   


//Calculate total population by province
var pop14_t = pop14_r.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop16_t = pop16_r.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop18_t = pop18_r.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop14_t = pop14_t.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop14_t,
  description: 'pop14_rur',
  fileFormat: 'CSV'
});   

var pop16_t = pop16_t.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop16_t,
  description: 'pop16_rur',
  fileFormat: 'CSV'
});   

var pop18_t = pop18_t.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop18_t,
  description: 'pop18_rur',
  fileFormat: 'CSV'
}); 

// Export dataset 2014-2018
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop18_noaccess = pop18.mask(pop18.gt(0).and(nl18.lt(0.01))).clip(Countries)


var nl18 =  imageCollection.filterDate('2017-01-01', '2018-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop17_noaccess = pop18.mask(pop18.gt(0).and(nl18.lt(0.01))).clip(Countries)

var nl18 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop16_noaccess = pop16.mask(pop16.gt(0).and(nl18.lt(0.01))).clip(Countries)

var nl18 =  imageCollection.filterDate('2015-01-01', '2016-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop15_noaccess = pop15.mask(pop15.gt(0).and(nl18.lt(0.01))).clip(Countries)

var nl18 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop14_noaccess = pop14.mask(pop14.gt(0).and(nl18.lt(0.01))).clip(Countries)

var pop_noaccess = ee.ImageCollection([pop14_noaccess, pop15_noaccess, pop16_noaccess, pop17_noaccess, pop18_noaccess])

var stackCollection = function(collection) {
  // Create an initial image.
  var first = ee.Image(collection.first()).select([]);
  // Write a function that appends a band to an image.
  var appendBands = function(image, previous) {
    return ee.Image(previous).addBands(image);
  };
  return ee.Image(collection.iterate(appendBands, first));
};

var stacked = stackCollection(pop_noaccess);

Export.image.toDrive({
  image: stacked,
  description: 'pop_noaccess',
  scale: 1000,
  maxPixels: 10e12, 
  fileFormat: 'GeoTIFF',
  crs : 'EPSG:4326'
});

//export tiers to single image

var modis17 = ee.Image("MODIS/006/MCD12Q1/2017_01_01")
var modis17 = modis17.select('LC_Type2')

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'BWA'),  ee.Filter.eq('ISO3', 'GAB'), ee.Filter.eq('ISO3', 'AGO')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop0 = pop18.mask(pop18.lte(175).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop1 = pop18.mask(pop18.lte(650).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop2 = pop18.mask(pop18.lte(800).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN'), ee.Filter.eq('ISO3', 'GNQ')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop3 = pop18.mask(pop18.lte(1200).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN'),  ee.Filter.eq('ISO3', 'ERI')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop4 = pop18.mask(pop18.lte(1500).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop5 = pop18.mask(pop18.lte(2500).and(pop18.gt(0)))

//unify rural areas data
var rurpop = ee.ImageCollection([rurpop0, rurpop1, rurpop2, rurpop3, rurpop4, rurpop5]).mosaic()

var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita18 = nl18

var lightcapita18 = lightcapita18.mask(rurpop.gt(0).and(lightcapita18.gt(0)))

//Input values defined in R as quartiles 
var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.39)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.39)).and(lightcapita18.lt(0.51)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.51)).and(lightcapita18.lt(0.77)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.77)))

var replacement = ee.Image(1);
    
var pop18_tier_1 =pop18_tier_1.where(pop18_tier_1.gt(1), replacement);

var replacement = ee.Image(2);

var pop18_tier_2 =pop18_tier_2.where(pop18_tier_2.gt(1), replacement);

var replacement = ee.Image(3);

var pop18_tier_3 =pop18_tier_3.where(pop18_tier_3.gt(1), replacement);

var replacement = ee.Image(4);

var pop18_tier_4 =pop18_tier_4.where(pop18_tier_4.gt(1), replacement);

var tiers_joint_rural = ee.ImageCollection([pop18_tier_1, pop18_tier_2, pop18_tier_3, pop18_tier_4]).mosaic()

///

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'BWA'),  ee.Filter.eq('ISO3', 'GAB'), ee.Filter.eq('ISO3', 'AGO')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop0 = pop18.mask(modis17.eq(13).or(pop18.gt(175)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop1 = pop18.mask(modis17.eq(13).or(pop18.gt(650)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop2 = pop18.mask(modis17.eq(13).or(pop18.gt(800)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN'), ee.Filter.eq('ISO3', 'GNQ')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop3 = pop18.mask(modis17.eq(13).or(pop18.gt(1200)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN'), ee.Filter.eq('ISO3', 'ERI')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop4 = pop18.mask(modis17.eq(13).or(pop18.gt(1500)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop5 = pop18.mask(modis17.eq(13).or(pop18.gt(2500)))

//unify urban areas data
var urbpop = ee.ImageCollection([urbpop0, urbpop1, urbpop2, urbpop3, urbpop4, urbpop5]).mosaic()

var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita18 = nl18

var lightcapita18 = lightcapita18.mask(urbpop.gt(0).and(lightcapita18.gt(0)))

var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.41)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.41)).and(lightcapita18.lt(0.56)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.56)).and(lightcapita18.lt(1.05)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(1.05)))

var replacement = ee.Image(1);
    
var pop18_tier_1 =pop18_tier_1.where(pop18_tier_1.gt(1), replacement);

var replacement = ee.Image(2);

var pop18_tier_2 =pop18_tier_2.where(pop18_tier_2.gt(1), replacement);

var replacement = ee.Image(3);

var pop18_tier_3 =pop18_tier_3.where(pop18_tier_3.gt(1), replacement);

var replacement = ee.Image(4);

var pop18_tier_4 =pop18_tier_4.where(pop18_tier_4.gt(1), replacement);

var tiers_joint_urban = ee.ImageCollection([pop18_tier_1, pop18_tier_2, pop18_tier_3, pop18_tier_4]).mosaic()

var tiers_joint = ee.ImageCollection([tiers_joint_rural, tiers_joint_urban]).mosaic()

Export.image.toDrive({
  image: tiers_joint,
  description: 'tiers',
  scale: 1000,
  maxPixels: 543641321, 
  fileFormat: 'GeoTIFF',
  crs : 'EPSG:4326'
});


/// Hotspot analysis
var grid10km = ee.FeatureCollection('users/giacomofalchetta/grid10km')

var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median().clip(grid10km)

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median().clip(grid10km)

var popnoaccess14 = pop14.mask(pop14.gt(0).and(nl14.lt(0.05)))
var popnoaccess18 = pop18.mask(pop18.gt(0).and(nl18.lt(0.05)))

var popnoaccess14 = popnoaccess14.clip(grid10km)
var popnoaccess18 = popnoaccess18.clip(grid10km)


var changeinpopnoaccess = popnoaccess18.subtract(popnoaccess14)
var changeinpopnoaccess = changeinpopnoaccess.clip(grid10km).toDouble()

var grid10km = changeinpopnoaccess.reduceRegions({
  reducer: ee.Reducer.sum(),
  collection: grid10km,
  scale: 1000,
});

var grid10km = popnoaccess18.reduceRegions({
  reducer: ee.Reducer.sum(),
  collection: grid10km,
  scale: 1000,
});

var grid10km = tiers_joint.reduceRegions({
  reducer: ee.Reducer.mean(),
  collection: grid10km,
  scale: 1000,
});

var grid10km = grid10km.select(['.*'],null,false);

Export.table.toDrive({
  collection: grid10km,
  description: 'grid_wdata',
  fileFormat: 'SHP'
}); 