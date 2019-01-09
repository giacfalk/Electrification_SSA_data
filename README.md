# Script and data from: "A High-Resolution, Updatable, Reproducible Gridded Dataset to Assess Progress towards Electrification inSub-Saharan Africa"

This repository hosts:

 - A JavaScript file to be imported into Google Earth Engine (step 1)
 - A R script to be run after having run the JavaScript file in Earth Engine (step 2)
 - Supporting files to run the analysis (e.g. a shapefile of provinces)
 - Two ncdf4 files containg the data output of the analyis
      - One reporting the number of people without access in each grid cell between 2014 and 2018
      - The other reporting the consumption tier in each populated, electrified cell in 2018
      
 In order to replicate the analysis, the following steps are required:
 
 - Create a Google account if you do not have one, and request to have Earth Engine enables (https://signup.earthengine.google.com/#!/)
 - Make sure your Google Drive works and has enough free cloud storage space
 - Either obtain access to the LandScan population data by applying for an account (https://landscan.ornl.gov/user/apply), or use the WorldPop data, which is already accessible from the script in this repository without further steps.
 - Run the JavaScript file in Earth Engine
 - Download the supporting files along with the R script
 - Run the R script, which will produce the analysis, plots contained in the paper, and the output ncdf4 file

Giacomo Falchetta, 2019

