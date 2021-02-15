#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Watershed Delineation
#Coder: Nate Jones
#Date: 2/15/2021
#Purpose: Delineate Tanglewood Research Watersheds
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

#define dem
outlet<-st_read(paste0(data_dir,"tanglewood_south_outlet.shp"))
dem<-raster(paste0(data_dir, "USGS_one_meter_x43y364_AL_ADECA_B1_2016.tif"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Delineate Watershed ---------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#2.1 Create function to create watershed shape~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
stream[stream<10000]<-NA
writeRaster(stream, paste0(scratch_dir,"stream.tif"), overwrite=T)

#Paste point points in scratch dir
st_write(outlet, paste0(scratch_dir,"pp.shp"), delete_dsn = T)

#Snap pour point
wbt_jenson_snap_pour_points(
  pour_pts = "pp.shp", 
  streams = "stream.tif",
  snap_dist = 100,
  output =  "snap.shp",
  wd= scratch_dir)

#2.4 Delineat watersheds~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
wbt_watershed(
  d8_pntr = "fdr.tif",
  pour_pts = "snap.shp", 
  output = "sheds.tif" ,
  wd=scratch_dir)

#load watershed raster into R env
sheds<-raster(paste0(scratch_dir,"sheds.tif"))
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 3: Export Data -----------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Create bianary raster
sheds<-sheds*0+1

#Multiply bianary raster towards output objects
dem<-dem*sheds
dem<-crop(dem, sheds)
dem<-clip(dem, sheds)
stream<-stream*sheds

#Convert shed to polygong
sheds<-sheds %>% st_as_stars() %>% st_as_sf(., merge = TRUE)

#Export
st_write(sheds, paste0(output_dir, "south_shed.shp"))
writeRaster(dem, paste0(output_dir,"dem.tif"), overwrite=T)


