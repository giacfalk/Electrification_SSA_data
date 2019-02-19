// Interactive exploration of the electrification dataset

// Set up the overall structure of the app, with a control panel to the left
// of a full-screen map.
ui.root.clear();
var panel = ui.Panel({style: {width: '250px'}});
var map = ui.Map();
ui.root.add(panel).add(map);
map.setCenter(27, 3, 5);

// Define some constants.
var POPULATION = 'Population without access';
var TIERS = 'Tier';
var GREATER_THAN = 'Greater than';
var LESS_THAN = 'Less than';
var quattordici = '2014'
var quindici = '2015'
var sedici = '2016'
var diciassette = '2017'
var diciotto = '2018'
var ELRATES = 'Electrification rates'

// Create an empty list of filter constraints.
var constraints = [];

var imageCollection = ee.ImageCollection("NOAA/VIIRS/DNB/MONTHLY_V1/VCMSLCFG");
var nl18 =  imageCollection.filterDate('2018-01-01', '2019-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop18 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop18_noaccess = pop18.mask(pop18.gt(25).and(nl18.lt(0.01))).clip(Countries)


var nl18 =  imageCollection.filterDate('2017-01-01', '2018-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.35), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop17 = ee.Image('users/giacomofalchetta/LandScanGlobal2017');

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop17_noaccess = pop17.mask(pop17.gt(25).and(nl18.lt(0.01))).clip(Countries)

var nl18 =  imageCollection.filterDate('2016-01-01', '2017-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop16 = ee.Image('users/giacomofalchetta/LandScanGlobal2016');

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop16_noaccess = pop16.mask(pop16.gt(25).and(nl18.lt(0.01))).clip(Countries)

var nl18 =  imageCollection.filterDate('2015-01-01', '2016-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop15 = ee.Image('users/giacomofalchetta/LandScanGlobal2015');

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop15_noaccess = pop18.mask(pop15.gt(25).and(nl18.lt(0.01))).clip(Countries)

var nl18 =  imageCollection.filterDate('2014-01-01', '2015-01-01').select('avg_rad')
var replacement = ee.Image(0);
    
var conditional = function(image) {
  return image.where(image.lt(0.25), replacement);
};

var output = nl18.map(conditional);

var nl18 = ee.ImageCollection(output).median()

var pop14 = ee.Image('users/giacomofalchetta/landscan2014');

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm').filter(ee.Filter.or(ee.Filter.eq('REGION', 2)));

var pop14_noaccess = pop14.mask(pop14.gt(25).and(nl18.lt(0.01))).clip(Countries)

// include also province and national level electrification layers

var Countries = ee.FeatureCollection('users/giacomofalchetta/gadm36_1')

var no_acc_14 = pop14_noaccess.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['noacc']),
    collection: Countries,
})

var no_acc_15 = pop15_noaccess.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['noacc']),
    collection: Countries,
})

var no_acc_16 = pop16_noaccess.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['noacc']),
    collection: Countries,
})

var no_acc_17 = pop17_noaccess.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['noacc']),
    collection: Countries,
})

var no_acc_18 = pop18_noaccess.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['noacc']),
    collection: Countries,
})

var no_acc_14 = pop14.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['pop']),
    collection: no_acc_14,
})

var no_acc_15 = pop15.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['pop']),
    collection: no_acc_15,
})

var no_acc_16 = pop16.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['pop']),
    collection: no_acc_16,
})

var no_acc_17 = pop17.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['pop']),
    collection: no_acc_17,
})

var no_acc_18 = pop18.reduceRegions({
    reducer: ee.Reducer.sum().setOutputs(['pop']),
    collection: no_acc_18,
})


function computeelrate(feature) {
  var uno = ee.Number(1)
  var na = ee.Number(feature.get('noacc'));
  var pop = ee.Number(feature.get('pop'));

  return feature.set({ elrate: uno.subtract(na.divide(pop)) });
}

// generate a new property for all features
var elrate18 = no_acc_18.map(computeelrate);
var elrate17 = no_acc_17.map(computeelrate);
var elrate16 = no_acc_16.map(computeelrate);
var elrate15 = no_acc_15.map(computeelrate);
var elrate14 = no_acc_14.map(computeelrate);

var elrate18 = elrate18.reduceToImage({
    properties: ['elrate'],
    reducer: ee.Reducer.first()
});

var elrate17 = elrate17.reduceToImage({
    properties: ['elrate'],
    reducer: ee.Reducer.first()
});

var elrate16 = elrate16.reduceToImage({
    properties: ['elrate'],
    reducer: ee.Reducer.first()
});

var elrate15 = elrate15.reduceToImage({
    properties: ['elrate'],
    reducer: ee.Reducer.first()
});

var elrate14 = elrate14.reduceToImage({
    properties: ['elrate'],
    reducer: ee.Reducer.first()
});

var image02 = elrate14.gte(0);
var image04 = elrate14.gte(0.25);
var image06 = elrate14.gte(0.5);
var image08 = elrate14.gte(0.75);
var elrate14 = image02.add(image04).add(image06).add(image08)
var elrate14 = elrate14.visualize(({bands: ['first'], min:1, max: 4, palette: ['05668D', '00A896', '02C39A', 'F0F3BD'], opacity: 0.8}));

var image02 = elrate15.gte(0);
var image04 = elrate15.gte(0.25);
var image06 = elrate15.gte(0.5);
var image08 = elrate15.gte(0.75);
var elrate15 = image02.add(image04).add(image06).add(image08)
var elrate15 = elrate15.visualize(({bands: ['first'], min:1, max: 4, palette: ['05668D', '00A896', '02C39A', 'F0F3BD'], opacity: 0.8}));

var image02 = elrate16.gte(0);
var image04 = elrate16.gte(0.25);
var image06 = elrate16.gte(0.5);
var image08 = elrate16.gte(0.75);
var elrate16 = image02.add(image04).add(image06).add(image08)
var elrate16 = elrate16.visualize(({bands: ['first'], min:1, max: 4, palette: ['05668D', '00A896', '02C39A', 'F0F3BD'], opacity: 0.8}));

var image02 = elrate17.gte(0);
var image04 = elrate17.gte(0.25);
var image06 = elrate17.gte(0.5);
var image08 = elrate17.gte(0.75);
var elrate17 = image02.add(image04).add(image06).add(image08)
var elrate17 = elrate17.visualize(({bands: ['first'], min:1, max: 4, palette: ['05668D', '00A896', '02C39A', 'F0F3BD'], opacity: 0.8}));

var image02 = elrate18.gte(0);
var image04 = elrate18.gte(0.25);
var image06 = elrate18.gte(0.5);
var image08 = elrate18.gte(0.75);
var elrate18 = image02.add(image04).add(image06).add(image08)
var elrate18 = elrate18.visualize(({bands: ['first'], min:1, max: 4, palette: ['05668D', '00A896', '02C39A', 'F0F3BD'], opacity: 0.8}));


// Load the WorldPop 2015 UN-adjusted population density estimates.
// (Note that these are only available for some countries, e.g. not the US.)
var replacement = ee.Image(4);
var pop14_noaccess = pop14_noaccess.where(pop14_noaccess.gt(250), replacement)
var replacement = ee.Image(3);
var pop14_noaccess = pop14_noaccess.where(pop14_noaccess.gt(100), replacement)
var replacement = ee.Image(2);
var pop14_noaccess = pop14_noaccess.where(pop14_noaccess.gt(50), replacement)
var replacement = ee.Image(1)
var pop14_noaccess = pop14_noaccess.where(pop14_noaccess.gt(25), replacement)
var popVis14 = pop14_noaccess.visualize(({min:1, max: 4, palette: ['FFCDB2', 'E5989B', 'B5838D', '6D6875'], opacity: 0.8}));

var replacement = ee.Image(4);
var pop15_noaccess = pop15_noaccess.where(pop15_noaccess.gt(250), replacement)
var replacement = ee.Image(3);
var pop15_noaccess = pop15_noaccess.where(pop15_noaccess.gt(100), replacement)
var replacement = ee.Image(2);
var pop15_noaccess = pop15_noaccess.where(pop15_noaccess.gt(50), replacement)
var replacement = ee.Image(1)
var pop15_noaccess = pop15_noaccess.where(pop15_noaccess.gt(25), replacement)

var popVis15 = pop15_noaccess.visualize(({bands: ['b1'], min:1, max: 4, palette: ['FFCDB2', 'E5989B', 'B5838D', '6D6875'], opacity: 0.8}));

var replacement = ee.Image(4);
var pop16_noaccess = pop16_noaccess.where(pop16_noaccess.gt(250), replacement)
var replacement = ee.Image(3);
var pop16_noaccess = pop16_noaccess.where(pop16_noaccess.gt(100), replacement)
var replacement = ee.Image(2);
var pop16_noaccess = pop16_noaccess.where(pop16_noaccess.gt(50), replacement)
var replacement = ee.Image(1)
var pop16_noaccess = pop16_noaccess.where(pop16_noaccess.gt(25), replacement)

var popVis16 = pop16_noaccess.visualize(({bands: ['b1'], min:1, max: 4, palette: ['FFCDB2', 'E5989B', 'B5838D', '6D6875'], opacity: 0.8}));

var replacement = ee.Image(4);
var pop17_noaccess = pop17_noaccess.where(pop17_noaccess.gt(250), replacement)
var replacement = ee.Image(3);
var pop17_noaccess = pop17_noaccess.where(pop17_noaccess.gt(100), replacement)
var replacement = ee.Image(2);
var pop17_noaccess = pop17_noaccess.where(pop17_noaccess.gt(50), replacement)
var replacement = ee.Image(1)
var pop17_noaccess = pop17_noaccess.where(pop17_noaccess.gt(25), replacement)
var popVis17 = pop17_noaccess.visualize(({bands: ['b1'], min:1, max: 4, palette: ['FFCDB2', 'E5989B', 'B5838D', '6D6875'], opacity: 0.8}));

var replacement = ee.Image(4);
var pop18_noaccess = pop18_noaccess.where(pop18_noaccess.gt(250), replacement)
var replacement = ee.Image(3);
var pop18_noaccess = pop18_noaccess.where(pop18_noaccess.gt(100), replacement)
var replacement = ee.Image(2);
var pop18_noaccess = pop18_noaccess.where(pop18_noaccess.gt(50), replacement)
var replacement = ee.Image(1)
var pop18_noaccess = pop18_noaccess.where(pop18_noaccess.gt(25), replacement)
var popVis18 = pop18_noaccess.visualize(({bands: ['b1'], min:1, max: 4, palette: ['FFCDB2', 'E5989B', 'B5838D', '6D6875'], opacity: 0.8}));


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
var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.38)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.38)).and(lightcapita18.lt(0.45)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.45)).and(lightcapita18.lt(0.68)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.68)))

var replacement = ee.Image(1);
    
var pop18_tier_1 =pop18_tier_2.where(pop18_tier_1.gt(1), replacement);

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

var pop18_tier_1 = pop18.mask(pop18.gt(0).and(lightcapita18.gt(0)).and(lightcapita18.lt(0.40)))
var pop18_tier_2 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.40)).and(lightcapita18.lt(0.48)))
var pop18_tier_3 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.48)).and(lightcapita18.lt(0.88)))
var pop18_tier_4 = pop18.mask(pop18.gt(0).and(lightcapita18.gte(0.88)))

var replacement = ee.Image(1);
    
var pop18_tier_1 =pop18_tier_2.where(pop18_tier_1.gt(1), replacement);

var replacement = ee.Image(2);

var pop18_tier_2 =pop18_tier_2.where(pop18_tier_2.gt(1), replacement);

var replacement = ee.Image(3);

var pop18_tier_3 =pop18_tier_3.where(pop18_tier_3.gt(1), replacement);

var replacement = ee.Image(4);

var pop18_tier_4 =pop18_tier_4.where(pop18_tier_4.gt(1), replacement);

var tiers_joint_urban = ee.ImageCollection([pop18_tier_1, pop18_tier_2, pop18_tier_3, pop18_tier_4]).mosaic()

var tiers = ee.ImageCollection([tiers_joint_rural, tiers_joint_urban]).mosaic()

var tiersVis = tiers.visualize({min: 1, max: 4, palette: ['29088A', '088A29', 'FFFF00', 'FF8000'], opacity: 0.65});

// Create a layer selector that dictates which layer is visible on the map.
var select = ui.Select({
  items: [POPULATION, TIERS, ELRATES],
  value: POPULATION,
  onChange: redraw,
});
panel.add(ui.Label('Select variable:')).add(select);

var select2 = ui.Select({
  items: [quattordici, quindici, sedici, diciassette, diciotto],
  value: diciotto,
  onChange: redraw,
});
panel.add(ui.Label('Year:')).add(select2);

var legendtiers = ui.Panel({
  style: {
    position: 'bottom-right',
    padding: '8px 15px'
  }
});
 
// Create legend title
var legendTitletiers = ui.Label({
  value: 'Tiers legend',
  style: {
    fontWeight: 'bold',
    fontSize: '18px',
    margin: '0 0 4px 0',
    padding: '0'
    }
});
 
// Add the title to the panel
legendtiers.add(legendTitletiers);
 
// Creates and styles 1 row of the legend.
var makeRow = function(color, name) {
 
      // Create the label that is actually the colored box.
      var colorBox = ui.Label({
        style: {
          backgroundColor: '#' + color,
          // Use padding to give the box height and width.
          padding: '8px',
          margin: '0 0 4px 0'
        }
      });
 
      // Create the label filled with the description text.
      var description = ui.Label({
        value: name,
        style: {margin: '0 0 4px 6px'}
      });
 
      // return the panel
      return ui.Panel({
        widgets: [colorBox, description],
        layout: ui.Panel.Layout.Flow('horizontal')
      });
};
 
//  Palette with the colors
var palettetiers =['29088A', '088A29', 'FFFF00', 'FF8000'];
 
// name of the legend
var namestiers = ['<0.2 KWh/hh/day','<1 KWh/hh/day','<3.4 KWh/hh/day', '>3.4 KWh/hh/day'];
 
// Add color and and names
for (var i = 0; i < 4; i++) {
  legendtiers.add(makeRow(palettetiers[i], namestiers[i]));
  }  
 
 var legendpop = ui.Panel({
  style: {
    position: 'bottom-right',
    padding: '14px 15px'
  }
});
 
// Create legend title
var legendTitlepop = ui.Label({
  value: 'Pop. legend',
  style: {
    fontWeight: 'bold',
    fontSize: '18px',
    margin: '0 0 4px 0',
    padding: '0'
    }
});
 
// Add the title to the panel
legendpop.add(legendTitlepop);
 
// Creates and styles 1 row of the legend.
var makeRow = function(color, name) {
 
      // Create the label that is actually the colored box.
      var colorBox = ui.Label({
        style: {
          backgroundColor: '#' + color,
          // Use padding to give the box height and width.
          padding: '8px',
          margin: '0 0 4px 0'
        }
      });
 
      // Create the label filled with the description text.
      var description = ui.Label({
        value: name,
        style: {margin: '0 0 4px 6px'}
      });
 
      // return the panel
      return ui.Panel({
        widgets: [colorBox, description],
        layout: ui.Panel.Layout.Flow('horizontal')
      });
};
 
//  Palette with the colors
var palettepop =['FFCDB2', 'E5989B', 'B5838D', '6D6875'];
 
// name of the legend
var namespop = ['>25', '>50', '>100', '>250'];
 
// Add color and and names
for (var i = 0; i < 4; i++) {
  legendpop.add(makeRow(palettepop[i], namespop[i]));
  } 


 var legendelrates = ui.Panel({
  style: {
    position: 'bottom-right',
    padding: '14px 15px'
  }
});
 
// Create legend title
var legendTitleelrates = ui.Label({
  value: 'El. rates legend',
  style: {
    fontWeight: 'bold',
    fontSize: '18px',
    margin: '0 0 4px 0',
    padding: '0'
    }
});
 
// Add the title to the panel
legendelrates.add(legendTitleelrates);
 
// Creates and styles 1 row of the legend.
var makeRow = function(color, name) {
 
      // Create the label that is actually the colored box.
      var colorBox = ui.Label({
        style: {
          backgroundColor: '#' + color,
          // Use padding to give the box height and width.
          padding: '8px',
          margin: '0 0 4px 0'
        }
      });
 
      // Create the label filled with the description text.
      var description = ui.Label({
        value: name,
        style: {margin: '0 0 4px 6px'}
      });
 
      // return the panel
      return ui.Panel({
        widgets: [colorBox, description],
        layout: ui.Panel.Layout.Flow('horizontal')
      });
};
 
//  Palette with the colors
var paletteelrates =['05668D', '00A896', '02C39A', 'F0F3BD'];
 
// name of the legend
var nameselrates = ['<25%', '>25%', '>50%', '>75%'];
 
// Add color and and names
for (var i = 0; i < 4; i++) {
  legendelrates.add(makeRow(paletteelrates[i], nameselrates[i]));
  } 

  
// Create a function to render a map layer configured by the user inputs.
function redraw() {
  map.remove(legendtiers)
  map.remove(legendpop)
  map.remove(legendelrates)
  map.layers().reset();
  var layer = select.getValue();
  var layer2 = select2.getValue();
  var image;
  if (layer == TIERS & layer2 == diciotto) {
    image = tiersVis;
  } else if (layer == POPULATION & layer2 == quattordici) {
    image = popVis14;
  } else if (layer == POPULATION & layer2 == quindici) {
    image = popVis15;
  } else if (layer == POPULATION & layer2 == sedici) {
    image = popVis16;
  } else if (layer == POPULATION & layer2 == diciassette) {
    image = popVis17;
  } else if (layer == POPULATION & layer2 == diciotto) {
    image = popVis18;
  } else if (layer == ELRATES & layer2 == diciotto) {
    image = elrate18;
  } else if (layer == ELRATES & layer2 == diciassette) {
    image = elrate17;
  } else if (layer == ELRATES & layer2 == sedici) {
    image = elrate16;
  } else if (layer == ELRATES & layer2 == quindici) {
    image = elrate15;
  } else if (layer == ELRATES & layer2 == quattordici) {
    image = elrate14;
  }
  
  for (var i = 0; i < constraints.length; ++i) {
    var constraint = constraints[i];
    var mode = constraint.mode.getValue();
    var value = parseFloat(constraint.value.getValue());
    if (mode == GREATER_THAN) {
      image = image.updateMask(constraint.image.gt(value));
    } else {
      image = image.updateMask(constraint.image.lt(value));
    }
  }
  map.addLayer(image, {}, layer)
  
  var layer = select.getValue();
  var layer2 = select2.getValue();
  var legend;
  if (layer == TIERS & layer2 == diciotto) {
    legend = legendtiers;
  } else if (layer == POPULATION & layer2 == quattordici) {
    legend = legendpop;
  } else if (layer == POPULATION & layer2 == quindici) {
    legend = legendpop;
  } else if (layer == POPULATION & layer2 == sedici) {
    legend = legendpop;
  } else if (layer == POPULATION & layer2 == diciassette) {
    legend = legendpop;
  } else if (layer == POPULATION & layer2 == diciotto) {
    legend = legendpop;
  } else if (layer == ELRATES & layer2 == diciotto) {
    legend = legendelrates;
  } else if (layer == ELRATES & layer2 == diciassette) {
    legend = legendelrates;
  } else if (layer == ELRATES & layer2 == sedici) {
    legend = legendelrates;
  } else if (layer == ELRATES & layer2 == quindici) {
    legend = legendelrates;
  } else if (layer == ELRATES & layer2 == quattordici) {
    legend = legendelrates;
  }
  map.add(legend);
}

// Invoke the redraw function once at start up to initialize the map.
redraw();
