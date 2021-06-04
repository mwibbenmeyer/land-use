####################################################
# Matt Wibbenmeyer
# May 3, 2021 
# Script to measure distances between counties
####################################################

## Load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               readxl,
               sf,
               tidycensus,
               haven,
               stringr,
               data.table
               )


# Set working directory to land-use 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")

`%ni%` <- Negate(`%in%`)
options(tigris_use_cache = TRUE) #Tell tidycensus to cache shapefiles for future sessions

#census_api_key("", overwrite = TRUE, install = TRUE) # set API key

#Function to measure distances between counties
measure_dists <- function(shp) {
  
  county_centroid <- st_centroid(shp)
  dists <- st_distance(county_centroid)
  
  return(dists)
  
}


# Import data -------------------------------------------------------------

points <- read_dta("processing_output/pointpanel_estimation_unb.dta") %>% as.data.table()
frr_data <- read_excel("processing/net_returns/crops/FRR_FIPS.xls")

#Collapse points data set to county-year-lcc-land use conversion level data set
df <- points[ , total_acres := sum(acresk) , by = c('fips','year','lcc','initial_use')] %>% #Total acres in initial use in county-lcc-year
  .[ , final_use_acres := sum(acresk), by = c('fips','year','lcc','initial_use','final_use')] %>% #Total acres in final use
  .[ , lapply(.SD, mean, na.rm = TRUE), #Collapse by county-lcc-year-initial use-final-use
     .SDcols = c('total_acres','final_use_acres'), by = c('fips','year','lcc','initial_use','final_use')] %>%
  merge(., points[ , .(stateAbbrev = first(stateAbbrev)), by = 'fips'], by = "fips") #Merge state abbreviation back in

#Group some variables
df$old_initial_use <- df$initial_use # store old uses
df$old_final_use <- df$final_use
df$initial_use[df$initial_use == "Pasture" | df$initial_use == "Range" | df$initial_use == "CRP"] <- "Other" # group together uncommon uses
df$final_use[df$final_use == "Pasture" | df$final_use == "Range" | df$final_use == "CRP"] <- "Other"
df$transition <- paste(df$initial_use, df$final_use, sep="_") # concatenate initial and final uses to create transition class
df1 <- df[,-c("initial_use", "final_use", "old_initial_use", "old_final_use")]
df1 <- aggregate( . ~ fips + year + lcc + transition + stateAbbrev, data = df1, sum) # aggregate total acres and final use acres for other land uses
df1$initial_use <- sapply(strsplit(as.character(df1$transition),'_'), "[", 1) # split concatenated transition
df1$final_use <- sapply(strsplit(as.character(df1$transition),'_'), "[", 2)
df1$transition <- NULL
df1 <- as.data.table(df1)
df2 <- left_join(df1, frr_data, by = c("fips" = "County FIPS"))
df2 <- df2[,-c("State", "stateAbbrev")]
names(df2)[names(df2) == "ERS resource region"] <- "resource_region"
df2 <- as.data.table(df2)


# Function to calculate smoothed conditional choice probabilities across states ---------

smooth_ccps_state <- function(state,yr,lcc_value,initial,final) {
  
  #Subset to a single initial-final use pair and by county-lcc-year. Will have one record for each county in state
  df_sub <- df1[stateAbbrev == state & year == yr & lcc == lcc_value & initial_use == initial & final_use == final]
  
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
  df_sub$lcc[is.na(df_sub$lcc)] <- lcc_value
  
  return(df_sub)
}

###### Function to calculate smoothed conditional choice probabilities across FRR ---------
frr = 60
state = "AL"
yr = 2002
lcc_value = "1_2"
initial = "Crop"
final = "Other"

smooth_ccps_frr <- function(frr,yr,lcc_value,initial,final) {
  
  #Subset to a single initial-final use pair and by county-lcc-year. Will have one record for each county in state
  df_sub <- df2[resource_region == frr & year == yr & lcc == lcc_value & initial_use == initial & final_use == final]
  
  #Import county shapefile using tidycensus - b19013_001 is arbitrarily chosen
  counties1 <- get_acs(geography = "county", year = 2010, variables = "B19013_001", geometry = TRUE)
  counties2 <- merge(counties1, frr_data, by.x = 'GEOID', by.y = 'County FIPS', all.x = TRUE) #left_join(counties, frr_data, by = c("GEOID" = "ERS resource region"))
  names(counties2)[names(counties2) == "ERS resource region"] <- "resource_region"
  counties2 <- counties2[counties2$resource_region == frr,]
  counties2[['State']] <- NULL
  counties2[['resource_region']] <- NULL
  #counties2 <- counties2[,-c("State", "resource_region")]

  #Merge with conversion data frame, add NA records for missing counties
  df_sub <- merge(df_sub, counties2, by.x = 'fips', by.y = 'GEOID', all.y = TRUE) # ???
  df_sub <- df_sub[is.na(final_use_acres), ':=' (final_use_acres = 0,
                                                 total_acres = 0,
                                                 year = yr,
                                                 initial_use = initial,
                                                 final_use = final), ]
  
  #Create weighting matrix based on distances among counties
  dists <- measure_dists(counties2) #Distances among county centroids
  weights <- apply(dists, c(1,2), function(x) (1+1*x/1000)^(-2)) #Weights based on Scott (2014)
  
  #Calculate smoothed CCPs using weighting matrix
  df_sub$final_use_acres.w <- df_sub$final_use_acres %*% weights
  df_sub$total_acres.w <- df_sub$total_acres %*% weights
  df_sub <- df_sub[ , weighted_ccp := final_use_acres.w/total_acres.w] %>%
    .[ , c('fips','year','lcc','initial_use','final_use','weighted_ccp')]
  df_sub$lcc[is.na(df_sub$lcc)] <- lcc_value
  
  return(df_sub)
}

####

# Run function over states, years, and transitions ------------------------

states <- state.abb[state.abb %ni% c("AK","HI")]
frrs <- unique(frr_data$'ERS resource region')
#years <- unique(df1$year)[unique(df1$year) >= 2002]
years <- 2002
#lcc_values <- unique(df1$lcc)[unique(df1$lcc)!="0"] #Remove 0 which denotes federal use
lcc_values <- "1_2"
initial_uses <- c("Crop","Forest","Urban","Other")
final_uses <- c("Crop","Forest","Urban","Other")

#This will take a while to run so test on a single state-year combination
result_state <- do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind,  #Row bind to unnest results
          lapply(states, function(s)
            lapply(years, function(y)
              lapply(lcc_values, function(l)
                lapply(initial_uses, function(i)
                  lapply(final_uses, function(f) smooth_ccps_state(state = s, yr = y, lcc_value = l, initial = i, final = f)))))))))))


result_frr <- do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind, do.call(rbind,  #Row bind to unnest results
                                                                                  lapply(frrs, function(r)
                                                                                    lapply(years, function(y)
                                                                                      lapply(lcc_values, function(l)
                                                                                        lapply(initial_uses, function(i)
                                                                                          lapply(final_uses, function(f) smooth_ccps_frr(frr = r, yr = y, lcc_value = l, initial = i, final = f)))))))))))

#result_state <- left_join(result_state, frr, by = c("fips" = "County FIPS")) # join state smoothed data with FIPS codes
result_x <- result_state[is.nan(result_state$weighted_ccp),] # trim to NaNs
result_state <= result_state[!is.nan(result_state$weighted_ccp),]
result_x <- left_join(result_x, result_frr, by = c("fips", "year", "lcc", "initial_use", "final_use"))
result <- rbind(result_state, result_x)
result <- result[!is.nan(result$weighted_ccp),]

write.csv(result, "processing/ccps_new.csv") # write csv
