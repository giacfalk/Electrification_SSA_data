////Script from: A High-Resolution, Updatable, Fully-ReproducibleGridded Dataset to Assess Recent Progress towardsElectrification in Sub-Saharan Africa
///Giacomo Falchetta
// Version: 17/12/18

//Import VIIRS nighttime lights for 2018 and 2014
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG");
var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad').median()
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad').median()

//Visualise them raw
Map.addLayer(nl18)
Map.addLayer(nl14)

//Import Landscan population for both years
var pop14 = ee.Image('users/giacomofalchetta/landscan2014');
var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');

// Apply noise floor and select populated cells
var pop14_noaccess = pop14.mask(pop14.gt(0).and(nl14.lt(0.25)))
var pop18_noaccess = pop18.mask(pop18.gt(0).and(nl18.lt(0.30)))

// Import provinces Shapefile
var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1')

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
  fileFormat: 'CSV'
});   

var no_acc_18 = no_acc_18.select(['.*'],null,false);

Export.table.toDrive({
  collection: no_acc_18,
  description: 'no_acc_18',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


//Calculate total population by province
var pop14 = pop14.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})

var pop18 = pop18.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries,
})


//Export to Google Drive
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

////Identify urban and rural areas and define tiers of consumption

//Import lights, province and country shapefiles, and land cover
var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG")
var table = ee.Geometry("users/giacomofalchetta/gadm36_1")
var table2 = ee.Geometry("users/giacomofalchetta/gadm")
var modis14 = ee.Image("MODIS/006/MCD12Q1/2014_01_01")
var modis17 = ee.Image("MODIS/006/MCD12Q1/2017_01_01")
var modis14 = modis14.select('LC_Type2')
var modis17 = modis17.select('LC_Type2')


// apply lights noise floor
var nl14 =  imageCollection.filterDate('2017-01-01', '2018-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.30), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median()

var nl14 = nl14.mask(nl14.gt(0.1))


var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.and(ee.Filter.neq('SUBREGION', 15), ee.Filter.eq('REGION', 2)))


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita14 = (nl14.divide(pop14)).multiply(100)

var lightcapita14 = lightcapita14.mask(modis17.eq(10).or(modis17.eq(12)).or(modis17.eq(14)).and(lightcapita14.gt(0)))

var lightsum = lightcapita14.reduceRegions({
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


//

var modis14 = modis14.select('LC_Type2')
var modis17 = modis17.select('LC_Type2')

var nl14 =  imageCollection.filterDate('2017-01-01', '2018-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.30), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median()

var nl14 = nl14.mask(nl14.gt(0.1))

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.and(ee.Filter.neq('SUBREGION', 15), ee.Filter.eq('REGION', 2)))


var pop14 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita14 = (nl14.divide(pop14)).multiply(100)

var lightcapita14 = lightcapita14.mask(modis17.eq(13).and(lightcapita14.gt(0)))

Map.addLayer(lightcapita14)

var lightsum = lightcapita14.reduceRegions({
  collection: Countries,
  reducer: ee.Reducer.percentile([25, 50, 75]),
  scale: 5000
});

print(lightsum)

Export.table.toDrive({
  collection: lightsum,
  description:'pctiles_pc_urban',
  fileFormat: 'CSV',
  selectors : ['p25', 'p50', 'p75','ISO3']
});


////

var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG"),
    imageCollection2 = ee.ImageCollection("JRC/GHSL/P2016/SMOD_POP_GLOBE_V1"),
    image = ee.Image("JRC/GHSL/P2016/SMOD_POP_GLOBE_V1/2015"),
    imageCollection3 = ee.ImageCollection("MODIS/006/MCD12Q1"),
    modis14 = ee.Image("MODIS/006/MCD12Q1/2014_01_01"),
    modis17 = ee.Image("MODIS/006/MCD12Q1/2017_01_01");

//2014

var urbanrural = ee.Image(image)
var modis14 = modis14.select('LC_Type2')
var modis17 = modis17.select('LC_Type2')

var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var pop14 = ee.Image('users/giacomofalchetta/landscan2014').select('b1');

var lightcapita14 = (nl14.divide(pop14)).multiply(100)

var lightcapita14 = lightcapita14.mask(modis14.eq(10).or(modis14.eq(12)).or(modis14.eq(14)).and(lightcapita14.gt(0)))

var pop14_tier_1 = pop14.mask(pop14.gt(0).and(lightcapita14.gt(0)).and(lightcapita14.lt(0.23)))
var pop14_tier_2 = pop14.mask(pop14.gt(0).and(lightcapita14.gte(0.23)).and(lightcapita14.lt(0.36)))
var pop14_tier_3 = pop14.mask(pop14.gt(0).and(lightcapita14.gte(0.36)).and(lightcapita14.lt(0.85)))
var pop14_tier_4 = pop14.mask(pop14.gt(0).and(lightcapita14.gte(0.85)))

// number of people 'with access' in that tier
var pop14_tier_1 = pop14_tier_1.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop14_tier_1 = pop14_tier_1.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_1,
  description: 'pop14_tier_1_rural',
  folder: 'Inequality',
  fileFormat: 'CSV'
}); 


var pop14_tier_2 = pop14_tier_2.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
    })

var pop14_tier_2 = pop14_tier_2.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_2,
  description: 'pop14_tier_2_rural',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var pop14_tier_3 = pop14_tier_3.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop14_tier_3 = pop14_tier_3.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_3,
  description: 'pop14_tier_3_rural',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var pop14_tier_4 = pop14_tier_4.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop14_tier_4 = pop14_tier_4.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_4,
  description: 'pop14_tier_4_rural',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

///urban

var nl14 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl14.map(conditional);

var nl14 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var pop14 = ee.Image('users/giacomofalchetta/landscan2014').select('b1');

var lightcapita14 = (nl14.divide(pop14)).multiply(100)

var lightcapita14 = lightcapita14.mask(modis14.eq(13).and(lightcapita14.gt(0)))

var pop14_tier_1 = pop14.mask(pop14.gt(0).and(lightcapita14.gt(0)).and(lightcapita14.lt(0.096)))
var pop14_tier_2 = pop14.mask(pop14.gt(0).and(lightcapita14.gte(0.096)).and(lightcapita14.lt(0.13)))
var pop14_tier_3 = pop14.mask(pop14.gt(0).and(lightcapita14.gte(0.13)).and(lightcapita14.lt(0.22)))
var pop14_tier_4 = pop14.mask(pop14.gt(0).and(lightcapita14.gte(0.22)))

// number of people 'with access' in that tier
var pop14_tier_1 = pop14_tier_1.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop14_tier_1 = pop14_tier_1.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_1,
  description: 'pop14_tier_1_urban',
  folder: 'Inequality',
  fileFormat: 'CSV'
}); 


var pop14_tier_2 = pop14_tier_2.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop14_tier_2 = pop14_tier_2.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_2,
  description: 'pop14_tier_2_urban',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var pop14_tier_3 = pop14_tier_3.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop14_tier_3 = pop14_tier_3.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_3,
  description: 'pop14_tier_3_urban',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   

var pop14_tier_4 = pop14_tier_4.reduceRegions({
    reducer: ee.Reducer.sum(),
    collection: Countries, scale: 5000,
})

var pop14_tier_4 = pop14_tier_4.select(['.*'],null,false);

// Table to Drive Export Example
Export.table.toDrive({
  collection: pop14_tier_4,
  description: 'pop14_tier_4_urban',
  folder: 'Inequality',
  fileFormat: 'CSV'
});   


///
//2017

var urbanrural = ee.Image(image)

var nl18 =  imageCollection.filterDate('2017-01-01', '2018-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.30), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita18 = (nl18.divide(pop18)).multiply(100)

var lightcapita18 = lightcapita18.mask(modis17.eq(10).or(modis17.eq(12)).or(modis17.eq(14)).and(lightcapita18.gt(0)))

var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.23)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.23)).and(lightcapita18.lt(0.36)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.36)).and(lightcapita18.lt(0.85)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.85)))


// number of people 'with access' in that tier
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

//urban

var nl18 =  imageCollection.filterDate('2017-01-01', '2018-01-01').select('avg_rad')

var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.30), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1');

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017').select('b1');

var lightcapita18 = (nl18.divide(pop18)).multiply(100)

var lightcapita18 = lightcapita18.mask(modis17.eq(13).and(lightcapita18.gt(0)))

var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.096)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.096)).and(lightcapita18.lt(0.13)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.13)).and(lightcapita18.lt(0.22)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.22)))

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

