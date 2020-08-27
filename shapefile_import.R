# Clearing workspace

rm(list = ls(all = TRUE))

# Installing / loading packages

if (!require("pacman")) install.packages("pacman") # Pacman package has easy load functions (e.g. installs package and then loads if not available)

pacman::p_load(tidyverse, sp, leaflet, rgdal, maptools, tmap, stringr)

# Reading in Google Maps KML
boundaries <- readOGR("D:/Dropbox/Mayur Vihar Project/Listing Survey/Data/Raw/Blocks for listing.kml")

# Prepping and merging on survey data

boundaries@data <- left_join(boundaries@data, survey, by = 'block_name') 


leaflet() %>% addTiles() %>% addPolygons(data = boundaries)