//Earth Engine Script for: 
//A High-Resolution, Updatable, Fully-Reproducible Gridded Dataset to Assess Recent Progress towardsElectrification in Sub-Saharan Africa
//Giacomo Falchetta
// Version: 04/01/18

//Import VIIRS nighttime lights for 2018 and 2014
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')

// Apply noise floors and select populated cells
//2014
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median()

//2018
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

//Visualise data on the map 
Map.addLayer(nl18)
Map.addLayer(nl14)

//Import population for both years (change these two line to change the population dataset)
var pop14 = ee.Image('users/giacomofalchetta/landscan2014');
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');


// Generate data for population without access for both years
var pop14_noaccess = pop14.mask(pop14.gt(0).and(nl14.lt(0.05)))
var pop18_noaccess = pop18.mask(pop18.gt(0).and(nl18.lt(0.05)))

// Import provinces shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

//Calculate sum of people without access by province
var no_acc_14 = pop14_noaccess.reduceRegions({
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
  folder: 'Inequality',
  fileFormat: 'CSV',
});   

var no_acc_18 = no_acc_18.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_18,
  description: 'no_acc_18',
  folder: 'Inequality',
  fileFormat: 'CSV',
});   


//Calculate total population by province
var pop14 = pop14.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop18 = pop18.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop14 = pop14.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop14,
  description: 'pop14',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var pop18 = pop18.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop18,
  description: 'pop18',
  folder: 'Inequality',
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
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop0 = pop18.mask(modis17.eq(13).or(pop18.gt(175)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop1 = pop18.mask(modis17.eq(13).or(pop18.gt(650)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop2 = pop18.mask(modis17.eq(13).or(pop18.gt(800)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop3 = pop18.mask(modis17.eq(13).or(pop18.gt(1200)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop4 = pop18.mask(modis17.eq(13).or(pop18.gt(1500)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var urbpop5 = pop18.mask(modis17.eq(13).or(pop18.gt(2500)))

//unify urban areas data
var urbpop = ee.ImageCollection([urbpop0, urbpop1, urbpop2, urbpop3, urbpop4, urbpop5]).mosaic()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'BWA'),  ee.Filter.eq('ISO3', 'GAB'), ee.Filter.eq('ISO3', 'AGO')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop0 = pop18.mask(pop18.lte(175).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop1 = pop18.mask(pop18.lte(650).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop2 = pop18.mask(pop18.lte(800).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop3 = pop18.mask(pop18.lte(1200).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop4 = pop18.mask(pop18.lte(1500).and(pop18.gt(0)))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1').clip(Countries)
var rurpop5 = pop18.mask(pop18.lte(2500).and(pop18.gt(0)))

//unify rural areas data
var rurpop = ee.ImageCollection([rurpop0, rurpop1, rurpop2, rurpop3, rurpop4, rurpop5]).mosaic()

//Validate urbanisation rates estimated at the grid cell level
var modis17 = ee.Image("MODIS/006/MCD12Q1/2017_01_01")
var modis17 = modis17.select('LC_Type2')

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'BWA'),  ee.Filter.eq('ISO3', 'GAB'), ee.Filter.eq('ISO3', 'AGO')));
var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')
var pop14 = pop14.mask(modis17.eq(13).or(pop14.gt(175)))

var popu = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popu = popu.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: popu,
  description: 'popu0',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')

var popt = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt0',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'NAM'), ee.Filter.eq('ISO3', 'ZMB'), ee.Filter.eq('ISO3', 'MRT'), ee.Filter.eq('ISO3', 'ZWE'), ee.Filter.eq('ISO3', 'MOZ'), ee.Filter.eq('ISO3', 'SOM'), ee.Filter.eq('ISO3', 'ZAF'), ee.Filter.eq('ISO3', 'CPV'), ee.Filter.eq('ISO3', 'SWZ')));
var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')
var pop14 = pop14.mask(modis17.eq(13).or(pop14.gt(650)))

var popu = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu1',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')

var popt = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt1',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'LSO'), ee.Filter.eq('ISO3', 'CMR'), ee.Filter.eq('ISO3', 'MDG'), ee.Filter.eq('ISO3', 'CAF'), ee.Filter.eq('ISO3', 'MLI'),ee.Filter.eq('ISO3', 'TZA')));
var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')
var pop14 = pop14.mask(modis17.eq(13).or(pop14.gt(800)))

var popu = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu2',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')

var popt = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt2',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'GMB'), ee.Filter.eq('ISO3', 'GNB'), ee.Filter.eq('ISO3', 'LBR'), ee.Filter.eq('ISO3', 'BFA'), ee.Filter.eq('ISO3', 'CIV'), ee.Filter.eq('ISO3', 'SLE'), ee.Filter.eq('ISO3', 'GHA'),  ee.Filter.eq('ISO3', 'GIN')));
var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')
var pop14 = pop14.mask(modis17.eq(13).or(pop14.gt(1200)))

var popu = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu3',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')

var popt = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt3',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'ETH'), ee.Filter.eq('ISO3', 'UGA'), ee.Filter.eq('ISO3', 'BDI'), ee.Filter.eq('ISO3', 'RWA'), ee.Filter.eq('ISO3', 'BEN'), ee.Filter.eq('ISO3', 'SDN')));
var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')
var pop14 = pop14.mask(modis17.eq(13).or(pop14.gt(1500)))

var popu = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu4',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')

var popt = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt4',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('ISO3', 'KEN'), ee.Filter.eq('ISO3', 'MWI'), ee.Filter.eq('ISO3', 'COD'), ee.Filter.eq('ISO3', 'TGO'), ee.Filter.eq('ISO3', 'NGA'), ee.Filter.eq('ISO3', 'TCD'), ee.Filter.eq('ISO3', 'SEN'), ee.Filter.eq('ISO3', 'NER'), ee.Filter.eq('ISO3', 'COG')));
var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')
var pop14 = pop14.mask(modis17.eq(13).or(pop14.gt(2500)))

var popu = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});


var popu = popu.select(['.*'],null,false);

Export.table.toDrive({
  collection: popu,
  description: 'popu5',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1')

var popt = pop14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.sum(),
  scale: 1000
});

var popt = popt.select(['.*'],null,false);

Export.table.toDrive({
  collection: popt,
  description: 'popt5',
  folder: 'Inequality',
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

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita18 = (nl18.divide(pop18)).multiply(100)

var lightcapita18_rur = lightcapita18.mask(rurpop.gt(0).and(lightcapita18.gt(0)))

var lightsum = lightcapita18_rur.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.percentile([25, 50, 75]),
  scale: 5000
});

Export.table.toDrive({
  collection: lightsum,
  description:'pctiles_pc_rural',
  fileFormat: 'CSV',
  selectors : ['p25', 'p50', 'p75','ISO3']
});

var lightcapita18_urb = lightcapita18.mask(urbpop.gt(0).and(lightcapita18.gt(0)))

var lightsum = lightcapita18_urb.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.percentile([25, 50, 75]),
  scale: 5000
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

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita18 = (nl18.divide(pop18)).multiply(100)

var lightcapita18 = lightcapita18.mask(rurpop.gt(0).and(lightcapita18.gt(0)))

//Input values defined in R as quartiles 
var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.38)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.38)).and(lightcapita18.lt(0.66)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.66)).and(lightcapita18.lt(1.63)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(1.63)))

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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
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

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita18 = (nl18.divide(pop18)).multiply(100)

var lightcapita18 = lightcapita18.mask(urbpop.gt(0).and(lightcapita18.gt(0)))

//Input values defined in R as quartiles 
var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.06)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.06)).and(lightcapita18.lt(0.11)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.11)).and(lightcapita18.lt(0.16)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.16)))

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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
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
  folder: 'Inequality',
  fileFormat: 'CSV',
});   


//Carry out sensitivity analysis for noise floor
//Export pop
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');
var pop17 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');

var pop17 = pop17.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop17 = pop17.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop17,
  description: 'pop17',
  folder: 'Inequality',
  fileFormat: 'CSV'
});  

// Export NL
var pop17 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');
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
  folder: 'Inequality',
  fileFormat: 'CSV',
});   

//
var pop17 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');
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
  folder: 'Inequality',
  fileFormat: 'CSV',
});   

//
var pop17 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');
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
  folder: 'Inequality',
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


//

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');


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
  description: 'no_acc_14',
  folder: 'Inequality',
  fileFormat: 'CSV',
});   

var no_acc_15 = no_acc_15.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_15,
  description: 'no_acc_15',
  folder: 'Inequality',
  fileFormat: 'CSV',
});  

var no_acc_16 = no_acc_16.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_16,
  description: 'no_acc_16',
  folder: 'Inequality',
  fileFormat: 'CSV',
});  

var no_acc_17 = no_acc_17.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_17,
  description: 'no_acc_17',
  folder: 'Inequality',
  fileFormat: 'CSV',
});  


var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

//Calculate total population by province
var pop18 = pop18.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
});

var pop18 = pop18.select(['.*'],null,false);

Export.table.toDrive({
  collection: pop18,
  description: 'pop18',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

// Hotspots identification
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1')

var replacement = ee.Image(0);
    
var conditional = function(imm) {
  return imm.where(imm.lt(0.35), replacement);
};

var lights18 = ee.ImageCollection('NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG').filterDate('2018-01-01', '2019-01-01').select('avg_rad');
var lights18 = lights18.map(conditional);
var lights18 = ee.ImageCollection(lights18).median()

//
var conditional = function(imm) {
  return imm.where(imm.lt(0.25), replacement);
};

var lights14 = ee.ImageCollection('NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG').filterDate('2014-01-01', '2015-01-01').select('avg_rad');
var lights14 = lights14.map(conditional);
var lights14 = ee.ImageCollection(lights14).median()

//

var popnoaccess14 = pop14.mask(lights14.eq(0))
var popnoaccess17 = pop17.mask(lights18.eq(0))

var changeinpopnoaccess = popnoaccess17.subtract(popnoaccess14)

var changeinpopnoaccess = changeinpopnoaccess.mask(changeinpopnoaccess.gt(25))

Map.addLayer(changeinpopnoaccess)

var changeinpopnoaccess = changeinpopnoaccess.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var changeinpopnoaccess = changeinpopnoaccess.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: changeinpopnoaccess,
  description: 'changeinpopnoaccess1418',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var areas = function(feature) {
// Compute area from the geometry.
  var area = feature.geometry().area();
  return feature.set('area', area);
};

// Map the difference function over the collection.
var allAreas = Countries.map(areas)

var allAreas = allAreas.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: allAreas,
  description: 'allAreas',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


////

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1')

var replacement = ee.Image(0);
    
var conditional = function(imm) {
  return imm.where(imm.lt(0.30), replacement);
};

var lights18 = ee.ImageCollection('NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG').filterDate('2018-01-01', '2019-01-01').select('avg_rad');
var lights18 = lights18.map(conditional);
var lights18 = ee.ImageCollection(lights18).median()

//
var conditional = function(imm) {
  return imm.where(imm.lt(0.25), replacement);
};

var lights14 = ee.ImageCollection('NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG').filterDate('2014-01-01', '2015-01-01').select('avg_rad');
var lights14 = lights14.map(conditional);
var lights14 = ee.ImageCollection(lights14).median()

var changeinlight = (lights18.subtract(lights14)).divide(lights14)

Map.addLayer(changeinlight)

var changeinlight = changeinlight.reduceRegions({
    reducer: ee.Reducer.mean(),
    collection: Countries,
    scale: 450
})

var changeinlight = changeinlight.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: changeinlight,
  description: 'changeinlight',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

///

var modis17 = ee.Image("MODIS/006/MCD12Q1/2017_01_01")
var modis17 = modis17.select('LC_Type2')

var isrural = modis17.neq(13).and(pop14.lt(250))

var isrural = isrural.reduceRegions({
    reducer: ee.Reducer.mean(),
    collection: Countries,
    scale: 450
})

var isrural = isrural.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: isrural,
  description: 'isrural',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

//

var lights18 = lights18.divide(pop17)

var lights18 = lights18.mask(lights18.gt(0))


var meanpercapitanonzero = lights18.reduceRegions({
    reducer: ee.Reducer.mean(),
    collection: Countries,
    scale: 450
})

var meanpercapitanonzero = meanpercapitanonzero.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: meanpercapitanonzero,
  description: 'meanpercapitanonzero',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   
