#------- HEADER --------
# Script name: listing_cleaning
# Script purpose: Process and clean the Mayur Vihar listing data
# Script author: Mihir Bhaskar
# Date created: 13/07/2020

# Input files: 'listing_v1_WIDE.csv' - raw survey data as downloaded from the SurveyCTO server

# Summary of actions

# Output files

# Testing github

# Working on the cleaning for

#------ SETUP --------

# Clear workspace
rm(list = ls(all = TRUE))

# Load packages
if (!require("pacman")) install.packages("pacman") # Pacman package has easy load functions (e.g. installs package and then loads if not available)
pacman::p_load(tidyverse, here, stringr, rgdal, leaflet, RColorBrewer)

# set up paths relative to User's Dropbox
if (Sys.info()[["user"]] == "Mihir_Bhaskar") dbpath <- "D:/"
if (Sys.info()[["user"]] == "Sohaib Nasim") dbpath <- "C:/Users/Sohaib/"

base <- paste0(dbpath,"Dropbox/Mayur Vihar Project/Listing Survey/")
raw <- paste0(base,"Data/Raw/")

# Import raw survey data 
raw <- read.csv(paste0(raw,'listing_v1_WIDE.csv'))

#----- CLEANING ------

# Format dates
raw$survey_date <- as.Date(raw$starttime, '%B %d, %Y')

# Clean out dummy surveys - there may be more, check odd starttimes etc.
raw <- raw[raw$survey_date >= as.Date('2020-07-10') & 
           raw$surveyor_code != 2 &
           raw$phone_num != '2222222222', ]


# Convert bahu to patni on 10th july (patni option wasn't available on this day)

# Flag and convert cases where respondent name = member name but resp relationship is -87 or something else

# Logical checks to clean

## There are two cases in the same HH where respondent relationship is '1'
## 