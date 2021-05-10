##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: May 3, 2021
## Script purpose: Explore combined crop yield data to determine how much is missing
## Input data: crop_returns.csv - the combined crop data set
##################################################

library(tidyverse)
library("ggplot2")
theme_set(theme_bw())
install.packages("sf")
library("sf")
install.packages("rnaturalearth")
library("rnaturalearth")
install.packages("rnaturalearthdata")
library("rnaturalearthdata")
install.packages("maps")
library("maps")
install.packages("tidycensus")
library(tidycensus)
install.packages("tm")
library(tm)
library('reshape2')

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

world <- ne_countries(scale = "medium", returnclass = "sf") # load world data
class(world)
counties <- st_as_sf(map("county", plot = FALSE, fill = TRUE)) # load county data

##################################################
## plot missing data from crop_returns
##################################################

crop = c("corn", "sorghum", "soybeans", "winter wheat", "durum wheat", "spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops
year = c(2002:2020)
rm(i)
rm(j)
for(i in crop) {
  for(j in year) {
    c <- crop_returns[crop_returns$year == j & crop_returns$crop == i,]
    c <- c[, c("county_fips", "price", "cost", "yield", "acres")]
    c <- melt(c, id.vars = c('county_fips'))  # melt data
    c <- c[!is.na(c$value), ]                  # remove NA
    c <- with(c, aggregate(c, by = list(variable), FUN = length )) # compute length by grouping variable
    
    ggplot(c, aes( x = Group.1, y = value/3112, fill = Group.1 )) + 
      geom_bar(stat="identity") + ggtitle(sprintf("Data for crop %s in year %s", i, toString(j))) +
      xlab("Returns data") + ylab("Portion of total counties with data") + ylim(0,1)
    
    ggsave(sprintf("results/initial_descriptive/net_returns/crops/plots/%s_%s.png", i, toString(j)))
  }
}
  
##################################################
## map missing data from crop_returns
##################################################

# create FIPS and county ID variables from tidycensus data

data(fips_codes) # load FIPS county data
fips_codes$county_fips = paste(fips_codes$state_code, fips_codes$county_code, sep="") # add a 5-digit FIPS code
fips_codes$county <- removePunctuation(fips_codes$county) # remove punctuation
fips_codes$county <- sub("District of Columbia", "Washington", fips_codes$county) # handle washington d.c.
fips_codes$ID <- paste(fips_codes$state_name, fips_codes$county, sep=",") # append state and county name
fips_codes$ID <- str_remove(fips_codes$ID, " County") # remove designation that don't appear in geographic ID data
fips_codes$ID <- str_remove(fips_codes$ID, " Parish")
fips_codes$ID <- str_remove(fips_codes$ID, " District")
fips_codes$ID <- str_remove(fips_codes$ID, " City")
fips_codes <- mutate_all(fips_codes, .funs=tolower) # change to lowercase

# join crop_returns and geographic data

rm(new_crop_returns)
crop_returns <- read_csv("processing/net_returns/crop_returns.csv")
new_crop_returns <- left_join(x = crop_returns, y = fips_codes, by = "county_fips") # join crop returns data to state IDs
new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "price", "cost", "yield", "acres", "ID")] # trim columns
df = subset(new_crop_returns, select = -c(crop, price, cost, yield, county_fips, state_fips, frr)) # trim to only year, ID, and acres
df1 <- df %>% # count rows with acres data in same year and ID group
  group_by(ID, year) %>%
  summarise_each(funs(sum(!is.na(.))))
new_counties <- left_join(x = counties, y = df1, by = "ID") # join acres data to geographic state IDs

# loop through years to map counties with acres data

rm(j)
for(j in year) {
  df_subset <- new_counties[new_counties$year == j,] # subset data by each year
  
  ggplot(data = world) + # map US counties
    geom_sf() +
    geom_sf(data = df_subset, aes(fill = acres)) + # fill with number of acres
    scale_fill_viridis_c() + ggtitle(sprintf("Counties with acres data in %s", toString(j))) + # set color scale and title
    coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) # set coordinates to continental U.S.
  
  ggsave(sprintf("results/initial_descriptive/net_returns/crops/maps/map_%s_acres.png", toString(j)), width = 20, height = 12, dpi=96) # save map
}

# loop through crops and years to map each
#
# rm(i)
# rm(j)
# for(i in crop) {
#   for(j in year) {
#     counties_subset = new_counties[new_counties$year == j & new_counties$crop == i,] # subset to year and crop
#     
#     ggplot(data = world) + # map US counties
#       geom_sf() +
#       geom_sf(data = counties_subset, aes(fill = acres)) +
#       scale_fill_viridis_c() + ggtitle(sprintf("Acres of %s in %s", i, toString(j))) +
#       coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE)
#     
#     ggsave(sprintf("results/initial_descriptive/net_returns/crops/maps/map_%s_%s_acres.png", i, toString(j)), width = 20, height = 12) # save map
#   }
# }

