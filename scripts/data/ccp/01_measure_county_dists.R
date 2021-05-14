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
               ggplot2,
               foreign,
               haven
               )

# Set working directory to land-use 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")

`%ni%` <- Negate(`%in%`)

#Function to measure distances between counties
measure_dists <- function(shp) {
  
  county_centroid <- st_centroid(shp)
  dists <- st_distance(county_centroid)
  
  return(dists)
  
}

states <- state.abb[state.abb %ni% c("AK","HI")]


points <- read_dta("processing_output/pointpanel_estimation_unb.dta") %>% as.data.table()

df <- points[ , total_acres := sum(acresk) , by = c('fips','year','lcc','initial_use')] %>%
              .[ , final_use_acres := sum(acresk), by = c('fips','year','lcc','initial_use','final_use')] %>%
              .[ , lapply(.SD, mean, na.rm = TRUE),
                   .SDcols = c('total_acres','final_use_acres'), by = c('fips','year','lcc','initial_use','final_use')] %>%
              merge(., points[ , .(stateAbbrev = first(stateAbbrev)), by = 'fips'], by = "fips")

df_sub <- df[stateAbbrev == 'AL' & year == 2002 & lcc == '3_4' & initial_use == "Crop" & final_use == "Crop"]

counties <- get_acs(state = 'AL', geography = "county", year = 2010, variables = "B19013_001", geometry = TRUE)
df_sub <- merge(df_sub, counties, by.x = 'fips', by.y = 'GEOID', all.y = TRUE)
df_sub <- df_sub[is.na(final_use_acres), final_use_acres := 0] %>%
              .[is.na(total_acres), total_acres := 0]

#Create weighting matrix
dists <- measure_dists(counties)
weights <- apply(dists, c(1,2), function(x) (1+x/1000)^(-2))
weights[is.na(weights)] <- 0

df_sub$final_use_acres.w <- df_sub$final_use_acres%*%weights
df_sub$total_acres.w <- df_sub$total_acres%*%weights
df_sub <- df_sub[ , pct_acres.w := final_use_acres.w/total_acres.w]

#NEED TO MAKE SURE RIGHT THING IS HAPPENIGN WITH COUNTIES WE DON'T HAVE DATA FOR (NAs). SEEMS LIKE IT IS BUT NEED TO VERIFY

ggplot() + geom_sf(data = df_sub, aes(fill = pct_acres.w, geometry = geometry ))
dists <- measure_dists("CA")






#Import data and plot 
counties <- get_acs(state = "CA", geography = "county", variables = "B19013_001", geometry = TRUE)
county_centroid <- st_centroid(counties)

ggplot() + geom_sf(data = counties) + geom_sf(data = county_centroid)
