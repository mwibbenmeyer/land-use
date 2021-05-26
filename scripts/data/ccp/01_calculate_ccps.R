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
               maps,
               rnaturalearth,
               rnaturalearthdata,
               tidycensus,
               ggplot2,
               foreign,
               haven,
               lwgeom
               )
theme_set(theme_bw())

# Set working directory to land-use 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")
getwd()

`%ni%` <- Negate(`%in%`)
options(tigris_use_cache = TRUE) #Tell tidycensus to cache shapefiles for future sessions

census_api_key("7acead4fef8dc8abc2e3181bd361db4a2df9caa7", overwrite = TRUE, install = TRUE) # set API key
world <- ne_countries(scale = "medium", returnclass = "sf") # load world data
class(world)
counties <- st_as_sf(map("county", plot = FALSE, fill = TRUE)) # load county data
counties <- as_tibble(counties)

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
  
  #Import county shapefile using tidycensus
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
result<- do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind,  #Row bind to unnest results
          lapply(states, function(s)
            lapply(years, function(y)
              lapply(lcc_values, function(l)
                lapply(initial_uses, function(i)
                  lapply(final_uses, function(f) smooth_ccps(state = s, yr = y, lcc_value = l, initial = i, final = f)))))))))))

#Combine results and geographic data to plot

fips_codes <- read_csv("processing/fips_codes.csv") # load fips / geographic data
ccps <- left_join(x = result, y = fips_codes, by = c("fips" = "county_fips")) # join crop returns data to state IDs
ccps <- merge(counties, ccps, by = "ID") # join by geo ID
ccps$ccp_weights <- cut(ccps$weighted_ccp, breaks=c(-1, 0, 0.999999999, Inf)) # cut the data into levels
levels(ccps$ccp_weights) = c("0","between 0 and 1","1") # create a factor for counties with and without acres

#Iterate and create graphs

rm(i, j, k, l)

for(i in years){
  for(j in lcc_values){
    for(k in initial_uses){
      for(l in final_uses){
        
        #Subset data by each combination
        ccps1 <- ccps[ccps$year %in% i,] # subset data by each year
        ccps1 <- ccps1[ccps1$lcc %in% j,] # subset data by lcc values
        ccps1 <- ccps1[ccps1$initial_use %in% k,] # subset data by initial use
        ccps1 <- ccps1[ccps1$final_use %in% l,] # subset data by final use
        
        #Plot results
        ggplot(data = world) + # map US counties
          geom_sf(data=counties, aes(geometry=geom)) + geom_sf(data=ccps1, aes(fill=ccp_weights, geometry=geom)) + # fill ccp weights
          scale_fill_manual(values=c("0" = "#184d47", "between 0 and 1" = "#96bb7c", "1" = "#fad586")) + # set manual color scale
          ggtitle(sprintf("All states in %s with LCC %s from %s to %s", toString(i), j, k, l)) + # change title
          coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) # set coordinates to continental U.S.
        
        ggsave(sprintf("results/initial_descriptives/combined/maps_ccp/ccp_%s_%s_%s_%s.png", toString(i), j, k, l), width = 15, height = 8.33, dpi=96) # save map
      }
    }
  }
}
  
# Plot results ------------

# ggplot(data = world) + # map US counties
#   geom_sf() + geom_sf(data=ccps, aes(fill=ccp_weights, geometry=geom)) + # fill with number of acres
#   scale_fill_manual(values=c("0" = "#ffc996", "between 0 and 1" = "#ff8474", "1" = "#9f5f80")) +
#   #scale_color_manual(values = c("0" = "#999999", "between 0 and 1" = "#E69F00", "1" = "#33F6FF")) +
#   #scale_fill_discrete(name = "Has acres-planted data") + # change legend labels and colors
#   ggtitle("Counties with CENSUS crop acres-planted data in any year (%s%%)") + # set color scale and title
#   coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) # set coordinates to continental U.S.
# 
# ggsave("results/initial_descriptives/combined/maps_ccp/ccp_2002_factor.png", width = 18, height = 10, dpi=96) # save map


 # ggplot(data = world) + # map US counties
 #   geom_sf() + geom_sf(data = ccps, aes(fill = weighted_ccp, geometry=geom)) +
 #   scale_fill_viridis_c() + ggtitle("All states in 2002 with LCC 7_8 from crop to crop") +
 #   coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE)
