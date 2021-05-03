####################################################
# Matt Wibbenmeyer
# May 3, 2021
# Script to measure distances between counties
####################################################

## Load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               data.table,
               readxl,
               data.table,
               sf,
               tidycensus,
               ggplot2
               )

# Set working directory to land-use 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")

`%ni%` <- Negate(`%in%`)

states <- state.abb[state.abb %ni% c("AK","HI")]


#Function to measure distances between counties
measure_dists <- function(state) {

  counties <- get_acs(state = state, geography = "county", variables = "B19013_001", geometry = TRUE)
  county_centroid <- st_centroid(counties)
  dists <- st_distance(county_centroid)

  return(dists)
  
}

dists <- measure_dists("CA")


#Import data and plot 
counties <- get_acs(state = "CA", geography = "county", variables = "B19013_001", geometry = TRUE)
county_centroid <- st_centroid(counties)

ggplot() + geom_sf(data = counties) + geom_sf(data = county_centroid)
