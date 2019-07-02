# Script and data from: "A High-Resolution Gridded Dataset to Assess Electrification in Sub-Saharan Africa"

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)

![alt text](https://github.com/giacfalk/Electrification_SSA_data/blob/master/logo.PNG?raw=true)

This repository hosts:

 - A JavaScript file to import into Google Earth Engine (step 1)
 - A R script to be run after execution of the JavaScript file in Earth Engine (step 2)
 - Supporting files to run the analysis (e.g. a shapefile of provinces)

To replicate the analysis, the following steps should be followed:
 
- Create a Google account, if you do not have one, and require access to Earth Engine https://signup.earthengine.google.com.
- Make sure your Google Drive has enough cloud storage space available.
- Either obtain access to the LandScan population data by applying for an account (https://landscan.ornl.gov/user/apply), or use the WorldPop data, which is accessible from the script in this repository without further steps.
- Download the JavaScipt and R scripts and the supporitng files
- Run the JavaScript file in Google Earth Engine
- Run the R script, which reproduces the analysis, the validation, the plots contained in the paper, and the output ncdf4 files.

Source code-related issues should be opened directly on GitHub. Broader questions of the methods should be addressed to giacomo.falchetta@feem.it

The original dataset is available at: http://dx.doi.org/10.17632/kn4636mtvg

The data descriptor manuscript, published on Scientific Data, is available at: http://dx.doi.org/10.1038/s41597-019-0122-6

