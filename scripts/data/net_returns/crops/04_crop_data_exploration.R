##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: May 3, 2021
## Script purpose: Explore combined crop yield data to determine how much is missing
## Input data: crop_returns.csv - the combined crop dataset
##################################################

library(tidyverse)
library("ggplot2")
theme_set(theme_bw())
library("sf")
library("rnaturalearth")
library("rnaturalearthdata")
install.packages("tidycensus")
library(tidycensus)
install.packages("tm")
library(tm)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

world <- ne_countries(scale = "medium", returnclass = "sf") # load world data
class(world)
counties <- st_as_sf(map("county", plot = FALSE, fill = TRUE)) # load county data

# create FIPS and county ID variables from tidycensus data

data(fips_codes) # load FIPS county data
fips_codes$county_fips = paste(fips_codes$state_code, fips_codes$county_code, sep="") # add a 5-digit FIPS code
fips_codes$county <- removePunctuation(fips_codes$county) # remove punctuation
fips_codes$county <- sub("District of Columbia", "Washington", fips_codes$county) # handle washington d.c.
fips_codes$ID <- paste(fips_codes$state_name, fips_codes$county, sep=",") # append state and county name
fips_codes$ID <- str_remove(fips_codes$ID, " County")
fips_codes$ID <- str_remove(fips_codes$ID, " Parish")
fips_codes$ID <- str_remove(fips_codes$ID, " District")
fips_codes$ID <- str_remove(fips_codes$ID, " City")
fips_codes <- mutate_all(fips_codes, .funs=tolower)

# join all data together

rm(new_crop_returns)
new_crop_returns <- left_join(x = crop_returns, y = fips_codes, by = "county_fips") # join crop returns data to state IDs
new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "price", "cost", "yield", "acres", "ID")] # trim columns

new_counties <- left_join(x = counties, y = new_crop_returns, by = "ID") # join crop returns data to state IDs

counties_2020 = new_counties[new_counties$year == 2020,] # subset to year 2020

ggplot(data = world) + # map US counties
  geom_sf() +
  geom_sf(data = counties_2020, aes(fill = yield)) +
  scale_fill_viridis_c() +
  coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE)

ggsave("processing/net_returns/crops/map.png", width = 20, height = 12) # save map


