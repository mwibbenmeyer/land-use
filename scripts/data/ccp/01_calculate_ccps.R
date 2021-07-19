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


# Import data ------------------------------------------------------------------

points <- read_dta("processing_output/pointpanel_estimation_unb.dta") %>% as.data.table()
frr_data <- read_excel("processing/net_returns/crops/FRR_FIPS.xls") %>%
  rename(., resource_region = 'ERS resource region')

#Collapse points data set to county-year-lcc-land use conversion level data set
df <- points[ , initial_acres := sum(acresk) , by = c('fips','year','lcc','initial_use')] %>% #Total acres in initial use in county-lcc-year
  .[ , final_acres := sum(acresk), by = c('fips','year','lcc','initial_use','final_use')] %>% #Total acres in final use
  .[ , lapply(.SD, mean, na.rm = TRUE), #Collapse by county-lcc-year-initial use-final-use
     .SDcols = c('initial_acres','final_acres'), by = c('fips','year','lcc','initial_use','final_use')] %>%
  merge(., points[ , .(stateAbbrev = first(stateAbbrev)), by = 'fips'], by = "fips") #Merge state abbreviation back in

#Group some variables
df$initial_use[df$initial_use == "Pasture" | df$initial_use == "Range" | df$initial_use == "CRP"] <- "Other" # group together uncommon uses
df$final_use[df$final_use == "Pasture" | df$final_use == "Range" | df$final_use == "CRP"] <- "Other"
df <- df[ , initial_acres := sum(initial_acres), by = list(fips, year, lcc, initial_use)]
df$transition <- paste(df$initial_use, df$final_use, sep="_") # concatenate initial and final uses to create transition class
df1 <- df[, c("initial_use","final_use"):=NULL] #%>% # aggregate total acres and final use acres for other land uses
df1 <- df1[, .(final_acres = sum(final_acres)), by = list(fips, year, lcc, transition, initial_acres, stateAbbrev)]
df1$initial_use <- sapply(strsplit(as.character(df1$transition),'_'), "[", 1) # split concatenated transition
df1$final_use <- sapply(strsplit(as.character(df1$transition),'_'), "[", 2) 
df1[,transition:=NULL]
df1 <- as.data.table(df1)
df2 <- left_join(df1, frr_data, by = c("fips" = "County FIPS")) %>%
  select(-c(State, stateAbbrev)) %>%
  as.data.table()

# Function to calculate smoothed conditional choice probabilities within states ---------

smooth_ccps_state <- function(state,yr,lcc_value,initial,final) {

<<<<<<< HEAD
  # state = "AZ"
  # yr = 2002
  # lcc_value = "3_4"
  # initial = "Other"
  # final = "Other"
=======
  state = "AZ"
  yr = 2002
  lcc_value = "3_4"
  initial = "Other"
  final = "Other"
>>>>>>> 973af964963b19a03fb2878a8b115835d3d5dba8

  #Subset to a single initial-final use pair and by county-lcc-year. Will have one record for each county in state
  df_sub <- df1[stateAbbrev == state & year == yr & lcc == lcc_value & initial_use == initial & final_use == final]
  
  #Calculate initial acres in each fips (even those with no transition to final use)
  df_initial <- df1[stateAbbrev == state & year == yr & lcc == lcc_value & initial_use == initial, 
                    .(initial_acres = mean(initial_acres)),
                    fips]
  
  #Import county shapefile using tidycensus - b19013_001 is arbitrarily chosen
  counties <- get_acs(state = state, geography = "county", year = 2010, variables = "B19013_001", geometry = TRUE) %>%
                select(-c("variable","estimate","moe"))
  #Merge with conversion data frame, add NA records for missing counties
  df_sub <- merge(df_sub, counties, by.x = 'fips', by.y = 'GEOID', all.y = TRUE)
  #Merge with conversion data frame, add NA records for counties with no initial acres
  df_sub <- merge(df_sub[,"initial_acres" := NULL], df_initial, by = 'fips', all.x = TRUE)
  #Replace NA values from merged missing counties
  df_sub <- df_sub[is.na(final_acres), ':=' (final_acres = 0,
                                               year = yr,
                                               stateAbbrev = state,
                                               lcc = lcc_value,
                                               initial_use = initial,
                                               final_use = final), ]
  df_sub <- df_sub[is.na(initial_acres), ':=' (initial_acres = 0)]
  
  
  #Create weighting matrix based on distances among counties
  dists <- measure_dists(counties) #Distances among county centroids
  weights <- apply(dists, c(1,2), function(x) (1+1*x/1000)^(-2)) #Weights based on Scott (2014)
  
  #Calculate smoothed CCPs using weighting matrix
  df_sub$final_acres.w <- df_sub$final_acres %*% weights
  df_sub$initial_acres.w <- df_sub$initial_acres %*% weights
  df_sub <- df_sub[ , weighted_ccp := final_acres.w/initial_acres.w]  %>%
    .[ , c('fips','year','lcc','initial_use','final_use','weighted_ccp')]
  
  return(df_sub)
}

# shp <- merge(df_sub %>% as_tibble(), counties, by.x = "fips", by.y = "GEOID")
# ggplot() + geom_sf(data = shp, aes(geometry = geometry, fill = weighted_ccp))

# Function to calculate smoothed conditional choice probabilities across FRR ---------

smooth_ccps_frr <- function(frr,yr,lcc_value,initial,final) {

  # frr = 40
  # yr = 2002
  # lcc_value = "1_2"
  # initial = "Crop"
  # final = "Forest"
  
  #Subset to a single initial-final use pair and by county-lcc-year. Will have one record for each county in state
  df_sub <- df2[resource_region == frr & year == yr & lcc == lcc_value & initial_use == initial & final_use == final]
  
  #Calculate initial acres in each fips (even those with no transition to final use)
  df_initial <- df2[resource_region == frr & year == yr & lcc == lcc_value & initial_use == initial, 
                    .(initial_acres = mean(initial_acres)),
                    fips]
  
  #Import county shapefile using tidycensus - b19013_001 is arbitrarily chosen
  counties1 <- get_acs(geography = "county", year = 2010, variables = "B19013_001", geometry = TRUE) %>%
    select(-c("variable","estimate","moe"))
  counties1 <- left_join(counties1, frr_data, by = c("GEOID" = "County FIPS")) %>%
    filter(resource_region == frr) %>%
    select(-c(State, resource_region))
  
  #Merge with conversion data frame, add NA records for missing counties
  df_sub <- left_join(counties1, df_sub, by = c("GEOID" = "fips")) %>%
    rename(., fips = GEOID) %>%
    as.data.table()
  #Merge with conversion data frame, add NA records for counties with no initial acres
  df_sub <- merge(df_sub[,"initial_acres" := NULL], df_initial, by = 'fips', all.x = TRUE)
  #Replace NA values from merged missing counties
  df_sub <- df_sub[is.na(final_acres), ':=' (final_acres = 0,
                                             year = yr,
                                             resource_region = frr,
                                             lcc = lcc_value,
                                             initial_use = initial,
                                             final_use = final), ]
  df_sub <- df_sub[is.na(initial_acres), ':=' (initial_acres = 0)]
  
  #Create weighting matrix based on distances among counties
  dists <- measure_dists(counties1) #Distances among county centroids
  weights <- apply(dists, c(1,2), function(x) (1+1*x/1000)^(-2)) #Weights based on Scott (2014)
  
  #Calculate smoothed CCPs using weighting matrix
  df_sub$final_acres.w <- df_sub$final_acres %*% weights
  df_sub$initial_acres.w <- df_sub$initial_acres %*% weights
  df_sub <- df_sub[ , weighted_ccp := final_acres.w/initial_acres.w]  %>%
    .[ , c('fips','year','lcc','initial_use','final_use','weighted_ccp')]
  
  return(df_sub)
}

# shp <- merge(df_sub %>% as_tibble(), counties1, by.x = "fips", by.y = "GEOID")
# ggplot() + geom_sf(data = shp, aes(geometry = geometry, fill = weighted_ccp))

# Run function over states, years, and transitions -----------------------------

states <- state.abb[state.abb %ni% c("AK","HI")]
frrs <- unique(frr_data$resource_region)
years <- unique(df1$year)[unique(df1$year) >= 2002]
lcc_values <- unique(df1$lcc)[unique(df1$lcc)!="0"] #Remove 0 which denotes federal use
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

# Add original and smoothed CCPs together and label the data source ------------

result_frr1 <- result_state[is.nan(result_state$weighted_ccp),] %>% # trim to NaNs from state smoothing - NAs after loading data
  left_join(., result_frr, by = c("fips", "year", "lcc", "initial_use", "final_use")) %>% # join with new frr smoothed data
  rename(., weighted_ccp = weighted_ccp.y) %>%
  select(-c(weighted_ccp.x)) %>%
  add_column(data_source = "FRR") #%>% # add indicator variable for data from FRR smoothing
  #mutate(data_source = replace(data_source, is.na(weighted_ccp), "NA")) # add indicator for data with NAs
df3 <- df2 %>%
  filter(year >= 2002) # trim original data to years since 2002
result_own <- result_state %>%
  right_join(., df3, by = c("fips", "year", "lcc", "initial_use", "final_use")) %>% # trim state smoothing to intitial data observed
  select(-c(initial_acres, final_acres, resource_region)) %>%
  add_column(data_source = "Own") %>% # indicator variable for observed data
  filter(!is.na(weighted_ccp))
result_state1 <- anti_join(result_state, result_own, by= c("fips", "year", "lcc", "initial_use", "final_use"))
result_state1 <- result_state1[!is.nan(result_state1$weighted_ccp),] %>%
  add_column(data_source = "State") # indicator variable for data from state smoothing

result <- rbind(result_own, result_state1, result_frr1) # bind results together

# write csv's

write.csv(result_state, "processing/ccp/ccps_state.csv") # write csv
write.csv(result_frr, "processing/ccp/ccps_frr.csv") # write csv
write.csv(result, "processing/ccp/ccps.csv") # write csv
