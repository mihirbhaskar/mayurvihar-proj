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

base <- paste0(dbpath,"Dropbox/Mayur Vihar Project/")
raw <- paste0(base,"Listing Survey/Data/Raw/")

# Import raw survey data 
raw <- read.csv(paste0(raw,'listing_v1_WIDE.csv'))

clean <- raw

#----- CLEANING ------

# Format dates
clean$survey_date <- as.Date(raw$starttime, '%B %d, %Y')

# Clean out dummy surveys - there may be more, check odd starttimes etc.
clean <- clean %>%
            filter(survey_date >= as.Date('2020-07-10'), surveyor_code != 2,
                   phone_num != '2222222222')

# Create unique hhid
clean <- clean %>% arrange(block, KEY) %>%
            group_by(block) %>% mutate(count = 1:n()) %>%
            ungroup() %>%
            mutate(hhid = paste0(block, count))
  

  
  
# Convert bahu to patni on 10th july (patni option wasn't available on this day)

# Flag and convert cases where respondent name = member name but resp relationship is -87 or something else

# Logical checks to clean

## There are two cases in the same HH where respondent relationship is '1'
## 

# Collapse the two age variables for each member into one

# One case with 8 hh members and age = 0 for a lot (check for age = 0 as a flag)

# Merge split households into one

# Export prefill list for mosquito net distribution
clean <- clean %>% mutate(need_net = ifelse(block == 'E', 1, 0))

net_prefill <- clean %>% filter(need_net == 1) %>% select(hhid, resp_name, resp_father_husband_name, phone_num, hh_size,
                                name_1, aadhaar_num_1, ration_card_num_1, name_2, aadhaar_num_2,
                                ration_card_num_2) 

write.csv(net_prefill, paste0(base, 'Mosquito Net Distribution/Beneficiary Prefills/prefill.csv' ))



