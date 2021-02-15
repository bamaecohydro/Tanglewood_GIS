#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Flow Net
#Coder: Nate Jones
#Date: 2/15/2021
#Purpose: Delineate Tanglewood Research Watersheds Flow Network
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 1: Setup Workspace -------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Clear Memory
remove(list=ls())

#Load libraries of interest
library(tidyverse) #join the cult!
library(raster)
library(sf)
library(whitebox)
library(stars)
library(fasterize)
library(mapview)
library(parallel)

#Define dir of interest
data_dir<-"data/I_data/"
scratch_dir<-"data/II_scratch/"
output_dir<-"data/III_output/"

#DEM
dem<-raster(paste0(output_dir,"dem.tif"))

#Define watershed area threshold
threshold_m2=2500

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Create flow net -------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Export DEM to scratch workspace
writeRaster(dem, paste0(scratch_dir,"dem.tif"), overwrite=T)

#Smooth DEM
wbt_gaussian_filter(
  input = "dem.tif", 
  output = "dem_smoothed.tif",
  wd = scratch_dir)

#breach depressions
wbt_breach_depressions(
  dem =    "dem_smoothed.tif",
  output = "dem_breached.tif",
  fill_pits = F,
  wd = scratch_dir)

#Flow direction raster
wbt_d8_pointer(
  dem= "dem_breached.tif",
  output ="fdr.tif",
  wd = scratch_dir
)

#Flow accumulation raster
wbt_d8_flow_accumulation(
  input = "dem_breached.tif",
  output = "fac.tif",
  wd = scratch_dir
)

#Create Stream Layer
stream<-raster(paste0(scratch_dir,"fac.tif"))
stream[stream<threshold_m2]<-NA
writeRaster(stream, paste0(scratch_dir,"stream.tif"), overwrite=T)

#Convert stream to vector
wbt_raster_streams_to_vector(
  streams = "stream.tif",
  d8_pntr = "fdr.tif",
  output = "streams.shp",
  wd = scratch_dir)

#Read streams layer in 
streams<-st_read(paste0(scratch_dir,"streams.shp"), crs=st_crs(dem@crs))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 3: Export ----------------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
st_write(streams, paste0(output_dir,"streams.shp"))

