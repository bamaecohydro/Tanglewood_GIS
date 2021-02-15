#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Title: Sampling Points
#Coder: Nate Jones
#Date: 2/15/2021
#Purpose: Programatically create sampling points for 2021 Synopitc
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

#Read flow net
streams<-st_read(paste0(output_dir,"streams.shp"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 2: Estimate sampling point locations--------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Define distance between cross sections
dist<- 100 #m

#Estimate number of cross sections to create based on distance
n_points<-sum(st_length(streams))/dist 
n_points<-n_points %>% as.numeric(.) %>% round()

#Create points along flow lines
stream_pnts<-st_union(streams)
stream_pnts<-st_line_merge(stream_pnts)
stream_pnts<-as_Spatial(stream_pnts, cast=FALSE)
stream_pnts<-spsample(stream_pnts, n = n_points, type="regular")
stream_pnts<-st_as_sf(stream_pnts)

#plot for funzies
streams %>% st_geometry() %>% plot()
stream_pnts %>% st_geometry() %>% plot(., add=T)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#Step 3: Export samplign points ------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
st_write(stream_pnts, paste0(output_dir, "sampling_pnts.shp"))
