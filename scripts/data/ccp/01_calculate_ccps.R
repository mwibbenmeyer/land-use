####################################################
# Matt Wibbenmeyer
# May 3, 2021 
# Script to measure distances between counties
####################################################

## Load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               data.table,
               sf,
               tidycensus,
               haven
               )

# Set working directory to land-use 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")

`%ni%` <- Negate(`%in%`)
options(tigris_use_cache = TRUE) #Tell tidycensus to cache shapefiles for future sessions

census_api_key("7acead4fef8dc8abc2e3181bd361db4a2df9caa7", overwrite = TRUE, install = TRUE) # set API key

#Function to measure distances between counties
measure_dists <- function(shp) {
  
  county_centroid <- st_centroid(shp)
  dists <- st_distance(county_centroid)
  
  return(dists)
  
}


# Import data -------------------------------------------------------------

points <- read_dta("processing_output/pointpanel_estimation_unb.dta") %>% as.data.table()

#Collapse points data set to county-year-lcc-land use conversion level data set
df <- points[ , total_acres := sum(acresk) , by = c('fips','year','lcc','initial_use')] %>% #Total acres in initial use in county-lcc-year
  .[ , final_use_acres := sum(acresk), by = c('fips','year','lcc','initial_use','final_use')] %>% #Total acres in final use
  .[ , lapply(.SD, mean, na.rm = TRUE), #Collapse by county-lcc-year-initial use-final-use
     .SDcols = c('total_acres','final_use_acres'), by = c('fips','year','lcc','initial_use','final_use')] %>%
  merge(., points[ , .(stateAbbrev = first(stateAbbrev)), by = 'fips'], by = "fips") #Merge state abbreviation back in



# Function to calculate smoothed conditional choice probabilities ---------

smooth_ccps <- function(state,yr,lcc_value,initial,final) {
  
  #Subset to a single initial-final use pair and by county-lcc-year. Will have one record for each county in state
  df_sub <- df[stateAbbrev == state & year == yr & lcc == lcc_value & initial_use == initial & final_use == final]
  
  #Import county shapefile using tidycensus - b19013_001 is arbitrarily chosen
  counties <- get_acs(state = state, geography = "county", year = 2010, variables = "B19013_001", geometry = TRUE)
  #Merge with conversion data frame, add NA records for missing counties
  df_sub <- merge(df_sub, counties, by.x = 'fips', by.y = 'GEOID', all.y = TRUE)
  df_sub <- df_sub[is.na(final_use_acres), ':=' (final_use_acres = 0,
                                                 total_acres = 0,
                                                 year = yr,
                                                 initial_use = initial,
                                                 final_use = final), ]
  
  #Create weighting matrix based on distances among counties
  dists <- measure_dists(counties) #Distances among county centroids
  weights <- apply(dists, c(1,2), function(x) (1+1*x/1000)^(-2)) #Weights based on Scott (2014)
  
  #Calculate smoothed CCPs using weighting matrix
  df_sub$final_use_acres.w <- df_sub$final_use_acres %*% weights
  df_sub$total_acres.w <- df_sub$total_acres %*% weights
  df_sub <- df_sub[ , weighted_ccp := final_use_acres.w/total_acres.w] %>%
                .[ , c('fips','year','lcc','initial_use','final_use','weighted_ccp')]
  
  return(df_sub)
}


# Run function over states, years, and transitions ------------------------

states <- state.abb[state.abb %ni% c("AK","HI")]
years <- unique(df$year)[unique(df$year) >= 2002]
lcc_values <- unique(df$lcc)[unique(df$lcc)!="0"] #Remove 0 which denotes federal use
initial_uses <- c("Crop","Forest","Pasture","Range","Urban","CRP")
final_uses <- c("Crop","Forest","Pasture","Range","Urban","CRP")

#This will take a while to run so test on a single state-year combination
result <- do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind,  #Row bind to unnest results
          lapply(states, function(s)
            lapply(years, function(y)
              lapply(lcc_values, function(l)
                lapply(initial_uses, function(i)
                  lapply(final_uses, function(f) smooth_ccps(state = s, yr = y, lcc_value = l, initial = i, final = f)))))))))))


write.csv(result, "processing/ccps.csv") # write csv
