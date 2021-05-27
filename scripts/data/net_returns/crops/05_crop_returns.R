##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: May 13, 2021
## Script purpose: Construct returns for each crop/state/year as a function of price/cost/yield/government_payments
## Input data: new_crop_returns.csv - the combined crop data set with FIPS info
##################################################

## Load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

new_crop_returns <- read_csv("processing/net_returns/new_crop_returns.csv") # load crop returns data

##################################################
## returns equation
##################################################

new_crop_returns$returns <- (new_crop_returns$price - new_crop_returns$cost)*new_crop_returns$yield # calculate returns

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

# calculate weights

total_acres <- aggregate(state_acres$state_acres, by=list(state_fips=state_acres$state_fips, year=state_acres$year), FUN=sum) # aggregate and sum acres data by state and year
names(total_acres)[names(total_acres) == "x"] <- "total_acres" # rename column
state_acres <- left_join(x = state_acres, y = total_acres, by = c("state_fips", "year")) # merge state totals data with crop specific data
state_acres$weight <- state_acres$state_acres/state_acres1$total_acres # calculate a weighted average

new_crop_returns <- left_join(x = new_crop_returns, y = state_acres, by = c("state_fips", "year", "crop")) # merge crop data frame with weights
new_crop_returns$weighted_av <- new_crop_returns$acres*new_crop_returns$weight # calculated weighted average


