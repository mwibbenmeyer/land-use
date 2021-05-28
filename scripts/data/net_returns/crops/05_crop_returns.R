##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: May 13, 2021
## Script purpose: Construct returns for each crop/state/year as a function of price/cost/yield/government_payments
## Input data: new_crop_returns.csv - the combined crop data set with FIPS info
##################################################

## Load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               data.table,
               haven)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

new_crop_returns <- read_csv("processing/net_returns/new_crop_returns.csv") # load crop returns data

##################################################
## returns equation
##################################################

# calculate distance dependent weighting of crop yields

#Function to measure distances between counties
# measure_dists <- function(shp) {
#   
#   county_centroid <- st_centroid(shp)
#   dists <- st_distance(county_centroid)
#   
#   return(dists)
#   
# }
# 
# # function to calculate smoothed yields
# 
# smooth_yields <- function(state,yr,lcc_value,initial,final) {
#   
#   #Subset to a single initial-final use pair and by county-lcc-year. Will have one record for each county in state
#   df_sub <- df[stateAbbrev == state & year == yr & lcc == lcc_value & initial_use == initial & final_use == final]
#   
#   #Import county shapefile using tidycensus - b19013_001 is arbitrarily chosen
#   counties <- get_acs(state = state, geography = "county", year = 2010, variables = "B19013_001", geometry = TRUE)
#   #Merge with conversion data frame, add NA records for missing counties
#   df_sub <- merge(df_sub, counties, by.x = 'fips', by.y = 'GEOID', all.y = TRUE)
#   df_sub <- df_sub[is.na(final_use_acres), ':=' (final_use_acres = 0,
#                                                  total_acres = 0,
#                                                  year = yr,
#                                                  initial_use = initial,
#                                                  final_use = final), ]
#   
#   #Create weighting matrix based on distances among counties
#   dists <- measure_dists(counties) #Distances among county centroids
#   weights <- apply(dists, c(1,2), function(x) (1+1*x/1000)^(-2)) #Weights based on Scott (2014)
#   
#   #Calculate smoothed CCPs using weighting matrix
#   df_sub$final_use_acres.w <- df_sub$final_use_acres %*% weights
#   df_sub$total_acres.w <- df_sub$total_acres %*% weights
#   df_sub <- df_sub[ , weighted_ccp := final_use_acres.w/total_acres.w] %>%
#     .[ , c('fips','year','lcc','initial_use','final_use','weighted_ccp')]
#   
#   return(df_sub)
# }

# load NRI acres planted data to calculate government payments per acre

govt_acres <- read_dta("processing_output/pointpanel_estimation_unb.dta") %>% as.data.table() # load NRI data
govt_acres <- govt_acres[, c("fips", "year", "acresk")] # trim to relevant columns
govt_acres <- aggregate( . ~ fips + year , data = govt_acres, sum) # sum for total acres planted per county
new_crop_returns3 <- new_crop_returns[, c("county_fips", "year", "govt_payments")] # trim
new_crop_returns3 <- aggregate( . ~ county_fips + year , data = new_crop_returns3, sum) # sum for total government payments per county
new_crop_returns3 <- left_join(x = new_crop_returns3, y = govt_acres, by = c("county_fips" = "fips", "year")) # merge acres and payments data
new_crop_returns3$payments_acres <- new_crop_returns3$govt_payments/new_crop_returns3$acresk # calculate govt payments per acre of planted crops
new_crop_returns3 <- new_crop_returns3[, c("county_fips", "year", "payments_acres")] # trim to relevant columns
new_crop_returns <- left_join(x = new_crop_returns, y = new_crop_returns3, by = c("county_fips", "year")) # merge with main data


new_crop_returns$returns <- (new_crop_returns$price - new_crop_returns$cost)*new_crop_returns$yield # calculate returns
new_crop_returns$actual_returns <- pmax(new_crop_returns$payments_acres, new_crop_returns$returns, na.rm = TRUE) # find the returns value from the price vs. govt payments



##################################################
## weighted average of acres planted for each crop in a farm resource region/state for a given year
##################################################

# create a data frame with ALL acres planted data by state, including data previously omitted because of no specified counties (i.e. "other counties" data)

# create data frame with state codes, crops and years
state_fips <- na.omit(data.frame(state_code = unique(new_crop_returns[c("state_code")])))
state_acres <- data.frame(state_fips = rep(state_fips$state_code, each = 209)) # 11 crops x 19 years of data = 209 rows of each county
crop = c("corn", "sorghum", "soybeans", "winter wheat", "durum wheat", "spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops
state_acres$crop <- rep(crop, each = 19, times = 49) # repeat crops 19 times for each state code
year = c(2002:2020) # list of years
state_acres$year <- rep(year, times = 539) # repeat sequence of years for each crop in each FIPS code

# load and join acres data
cropf = c("corn", "sorghum", "soybeans", "winter_wheat", "durum_wheat", "spring_wheat", "barley", "oats", "rice", "upland_cotton", "pima_cotton") # list of formatted crops
rm(i)
for(i in cropf) {
  acres <- paste(i, "acres", sep = "_") # create an acres planted variable for each crop
  acres <- read_csv(sprintf("processing/net_returns/crops/acres/%s.csv", toString(acres))) # load acres data
  acres <- mutate_all(acres, .funs=tolower) # change all character entries to lowercase
  acres$Year <- as.numeric(acres$Year) # convert year to numeric
  acres$Value <- as.numeric(acres$Value) # convert value to numeric
  names(acres)[names(acres) == "Value"] <- "acres" # rename column
  
  crop_acres <- aggregate(acres$acres, by=list(state_fips=acres$`State ANSI`, year=acres$`Year`, crop=acres$`Commodity`), FUN=sum) # aggregate and sum acres data by state, year, crop
  names(crop_acres)[names(crop_acres) == "x"] <- "state_acres" # rename column
  crop_acres[crop_acres == "8"] <- "08" # fix unusual FIPS codes from spring wheat
  
  state_acres <- left_join(x = state_acres, y = crop_acres, by = c("state_fips", "year", "crop")) # merge crop data with acres
  if("state_acres.y" %in% colnames(state_acres)) {
    state_acres$state_acres <- rowSums(cbind(state_acres$state_acres.x,state_acres$state_acres.y), na.rm=TRUE) # if not the first iteration, bind the two acres columns together
    state_acres <- state_acres[, c("state_fips", "crop", "year", "state_acres")] # trim columns
  }
}

# calculate weights from states where possible

total_acres <- aggregate(state_acres$state_acres, by=list(state_fips=state_acres$state_fips, year=state_acres$year), FUN=sum) # aggregate and sum acres data by state and year
names(total_acres)[names(total_acres) == "x"] <- "total_acres" # rename column
state_acres <- left_join(x = state_acres, y = total_acres, by = c("state_fips", "year")) # merge state totals data with crop specific data
state_acres$weight <- state_acres$state_acres/state_acres$total_acres # calculate weights
new_crop_returns <- left_join(x = new_crop_returns, y = state_acres, by = c("state_fips", "year", "crop")) # merge crop data frame with weights
new_crop_returns[new_crop_returns == 0.0000000000] <- NA # remove weights for counties with none
new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "price", "cost", "yield", "acres", "acres_c", "govt_payments", "state", "state_name", "county", "ID", "returns", "payments_acres", "weight")] # trim columns

# add weights from FRR where no state weighting data exists

frr_total_acres <- new_crop_returns[, c("frr", "year", "acres")] # trim
frr_total_acres <- aggregate( . ~ frr + year , data = frr_total_acres, sum) # aggregate acres of all crops for frr and year
names(frr_total_acres)[names(frr_total_acres) == "acres"] <- "frr_acres" # rename column
frr_state_acres <- new_crop_returns[, c("frr", "year", "crop", "acres")] # trim
frr_state_acres <- aggregate( . ~ frr + year + crop, data = frr_state_acres, sum) # aggregate acres of all crops for frr and year
frr_state_acres <- left_join(x = frr_state_acres, y = frr_total_acres, by = c("frr", "year")) # merge
frr_state_acres$frr_weight <- frr_state_acres$acres/frr_state_acres$frr_acres # calculate weights
frr_state_acres <- frr_state_acres[, c("frr", "year", "crop", "frr_weight")] # trim

new_crop_returns <- left_join(x = new_crop_returns, y = frr_state_acres, by = c("frr", "year", "crop")) # merge crop data frame with weights
new_crop_returns1 <- new_crop_returns[is.na(new_crop_returns$weight),] # subset to missing weight values
new_crop_returns1$new_weight <- new_crop_returns1$frr_weight # add frr_weight to missing state weight
new_crop_returns1 <- new_crop_returns1[, c("county_fips", "year", "crop", "new_weight")] # trim
new_crop_returns <- left_join(x = new_crop_returns, y = new_crop_returns1, by = c("county_fips", "year", "crop")) # merge crop data frame with frr weights
new_crop_returns$weight <- rowSums(cbind(new_crop_returns$weight, new_crop_returns$new_weight), na.rm=TRUE) # bind
new_crop_returns = subset(new_crop_returns, select = -c(frr_weight,new_weight)) # remove extra columns
new_crop_returns[new_crop_returns == 0.0000000000] <- NA # add back in NAs

# calculate weighted returns

new_crop_returns$weighted_av <- new_crop_returns$returns*new_crop_returns$weight # calculate weighted returns
new_crop_returns2 <- new_crop_returns[, c("county_fips", "year", "weighted_av")] # trim to aggregate
new_crop_returns2 <- aggregate( . ~ county_fips + year , data = new_crop_returns2, sum) # aggregate weighted returns over counties and years
names(new_crop_returns2)[names(new_crop_returns2) == "weighted_av"] <- "weighted_returns" # rename column
new_crop_returns <- left_join(x = new_crop_returns, y = new_crop_returns2, by = c("county_fips", "year")) # merge crop data frame with weights
new_crop_returns = subset(new_crop_returns, select = -c(weighted_av)) # remove extra columns


