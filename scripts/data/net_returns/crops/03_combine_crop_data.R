##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: April 27, 2021
## Script purpose: Combine crop price, cost, yield, and acres data
## Input data: ERS cost data, NASS price, yield, and acres data
##################################################

install.packages("readxl")
library(readxl)
install.packages("tidyverse")
library(tidyverse)
install.packages("dplyr")
library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

##################################################
## create data frame with each county FIPS code, crop, and year
##################################################

crop_returns <- read_excel("processing/net_returns/crops/FRR_FIPS.xls") # load country code (FIPS) and farm resource region (FRR) data
crop_returns <- data.frame(county_fips = rep(crop_returns$`County FIPS`, each = 209), state_fips = rep(crop_returns$`State`, each = 209), frr = as.character(rep(crop_returns$`ERS resource region`, each = 209))) # 11 crops x 19 years of data = 209 rows of each county
crop = c("corn", "sorghum", "soybeans", "winter wheat", "durum wheat", "spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops
crop_returns$crop <- rep(crop, each = 19, times = 3113) # repeat crops 19 times for each FIPS code
year = c(2002:2020) # list of years
crop_returns$year <- rep(year, times = 34243) # repeat sequence of years for each crop in each FIPS code
ag_regions <- read_excel("processing/net_returns/crops/AG_FIPS.xlsx") %>% # load FIPS and agricultural data for rice
  rename(., ag_regions = "Ag region")
crop_returns <- left_join(crop_returns, ag_regions, by = c("county_fips" = "County FIPS", "state_fips" = "State")) # join data frame with rice agricultural regions
crop_returns$region <- ifelse(crop_returns$crop == "rice", crop_returns$ag_regions, ifelse(crop_returns != "rice", crop_returns$frr, crop_returns$ag_regions)) # make a column to help join rice regions and FRR for costs

##################################################
## join new data frame with crop price, cost, yield, and acres data
##################################################

# load data

cropf = c("corn", "sorghum", "soybeans", "winter_wheat", "durum_wheat", "spring_wheat", "barley", "oats", "rice", "upland_cotton", "pima_cotton") # list of formatted crops
rm(i)
for(i in cropf) {

  price <- paste(i, "price", sep = "_") # create a price variable for each crop
  price <- read_csv(sprintf("processing/net_returns/crops/price/%s.csv", toString(price))) # load price data
  price <- mutate_all(price, .funs=tolower) # change all character entries to lowercase
  price$Year = as.numeric(price$Year) # convert year to numeric
  price$Value = as.numeric(price$Value) # convert value to numeric
  price <- price[!is.na(as.numeric(as.character(price$Value))),] # remove rows without price values
  names(price)[names(price) == "Value"] <- "price" # rename column
  
  cost <- paste(i, "cost", sep = "_")  # create a cost variable for each crop
  cost <- read_csv(sprintf("processing/net_returns/crops/cost/%s.csv", toString(cost))) # load cost data
  cost <- mutate_all(cost, .funs=tolower) # change all character entries to lowercase
  cost$Year = as.numeric(cost$Year) # convert year to numeric
  cost$Value = as.numeric(cost$Value) # convert value to numeric
  names(cost)[names(cost) == "Value"] <- "cost" # rename column

  yield <- paste(i, "yield", sep = "_")  # create a yield variable for each crop
  yield <- read_csv(sprintf("processing/net_returns/crops/yield/%s.csv", toString(yield))) # load yield data
  yield <- mutate_all(yield, .funs=tolower) # change all character entries to lowercase
  yield$Year = as.numeric(yield$Year) # convert year to numeric
  yield$Value = as.numeric(yield$Value) # convert value to numeric
  yield$FIPS = paste(yield$`State ANSI`, yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code
  names(yield)[names(yield) == "Value"] <- "yield" # rename column

  acres <- paste(i, "acres", sep = "_")  # create an acres planted variable for each crop
  acres <- read_csv(sprintf("processing/net_returns/crops/acres/%s.csv", toString(acres))) # load acres data
  acres <- mutate_all(acres, .funs=tolower) # change all character entries to lowercase
  acres$Year = as.numeric(acres$Year) # convert year to numeric
  acres$Value = as.numeric(acres$Value) # convert value to numeric
  acres$FIPS = paste(acres$`State ANSI`, acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code
  names(acres)[names(acres) == "Value"] <- "acres" # rename column
  
  acres_c <- paste(i, "acres_c", sep = "_")  # create an acres planted (from census) variable for each crop
  acres_c <- read_csv(sprintf("processing/net_returns/crops/acres_census/%s.csv", toString(acres_c))) # load acres data
  acres_c <- mutate_all(acres_c, .funs=tolower) # change all character entries to lowercase
  acres_c$Year = as.numeric(acres_c$Year) # convert year to numeric
  acres_c$Value = as.numeric(acres_c$Value) # convert value to numeric
  acres_c$FIPS = paste(acres_c$`State ANSI`, acres_c$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code
  names(acres_c)[names(acres_c) == "Value"] <- "acres_c" # rename column

# merge with geographic data frame

  new_crop_returns <- left_join(x = crop_returns, y = price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop" = "Commodity")) # merge crop data with price
  if("price.y" %in% colnames(new_crop_returns)) {
    new_crop_returns$price <- rowSums(cbind(new_crop_returns$price.x,new_crop_returns$price.y), na.rm=TRUE) # if not the first iteration, bind the two price columns together
    new_crop_returns <- subset(new_crop_returns, select = c(county_fips, state_fips, frr, region, crop, year, price, cost, yield, acres, acres_c)) # trim to only relevant columns
  }
  
  new_crop_returns <- left_join(x = new_crop_returns, y = cost, by = c("region" = "RegionId", "year" = "Year", "crop" = "Commodity")) # merge crop data with cost
  if("cost.y" %in% colnames(new_crop_returns)) {
    new_crop_returns$cost <- rowSums(cbind(new_crop_returns$cost.x,new_crop_returns$cost.y), na.rm=TRUE) # if not the first iteration, bind the two cost columns together
    new_crop_returns <- subset(new_crop_returns, select = c(county_fips, state_fips, frr, region, crop, year, price, cost, yield, acres, acres_c)) # trim to only relevant columns
  }

  new_crop_returns <- left_join(x = new_crop_returns, y = yield, by = c("county_fips" = "FIPS", "year" = "Year", "crop" = "Commodity")) # merge crop data with yield
  if("yield.y" %in% colnames(new_crop_returns)) {
    new_crop_returns$yield <- rowSums(cbind(new_crop_returns$yield.x,new_crop_returns$yield.y), na.rm=TRUE) # if not the first iteration, bind the two yield columns together
    new_crop_returns <- subset(new_crop_returns, select = c(county_fips, state_fips, frr, region, crop, year, price, cost, yield, acres, acres_c)) # trim to only relevant columns
  }

  new_crop_returns <- left_join(x = new_crop_returns, y = acres, by = c("county_fips" = "FIPS", "year" = "Year", "crop" = "Commodity")) # merge crop data with acres
  if("acres.y" %in% colnames(new_crop_returns)) {
    new_crop_returns$acres <- rowSums(cbind(new_crop_returns$acres.x,new_crop_returns$acres.y), na.rm=TRUE) # if not the first iteration, bind the two acres columns together
    new_crop_returns <- subset(new_crop_returns, select = c(county_fips, state_fips, frr, region, crop, year, price, cost, yield, acres, acres_c)) # trim to only relevant columns
  }
  
  new_crop_returns <- left_join(x = new_crop_returns, y = acres_c, by = c("county_fips" = "FIPS", "year" = "Year", "crop" = "Commodity")) # merge crop data with acres
  if("acres_c.y" %in% colnames(new_crop_returns)) {
    new_crop_returns$acres_c <- rowSums(cbind(new_crop_returns$acres_c.x,new_crop_returns$acres_c.y), na.rm=TRUE) # if not the first iteration, bind the two acres columns together
    new_crop_returns <- subset(new_crop_returns, select = c(county_fips, state_fips, frr, crop, region, year, price, cost, yield, acres, acres_c)) # trim to only relevant columns
  }
  
  crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "region", "crop", "year", "price", "cost", "yield", "acres", "acres_c")] # trim columns

}

# add government payments data

govt_payments <- read_csv("processing/net_returns/crops/government_payments.csv") # load government payments data
govt_payments <- mutate_all(govt_payments, .funs=tolower) # change all character entries to lowercase
govt_payments$Year = as.numeric(govt_payments$Year) # convert year to numeric
govt_payments$Value[govt_payments$Value == "(d)" | govt_payments$Value == "(z)"] <- NA # remove missing values
govt_payments$Value <- as.numeric(gsub(",", "", govt_payments$Value)) # remove commas
govt_payments <- govt_payments[!is.na(as.numeric(as.character(govt_payments$Value))),] # remove rows without price values
names(govt_payments)[names(govt_payments) == "Value"] <- "govt_payments" # rename column
govt_payments$FIPS = paste(govt_payments$`State ANSI`, govt_payments$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

new_crop_returns <- left_join(x = crop_returns, y = govt_payments, by = c("county_fips" = "FIPS", "year" = "Year")) # merge crop data with acres
crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "price", "cost", "yield", "acres", "acres_c", "govt_payments")] # trim columns

#crop_returns$price <- round(crop_returns$price, 2) # tidy up data by trimming decimals and replacing auto-generated 0s with NAs
#crop_returns$cost <- round(crop_returns$cost, 2)
crop_returns[crop_returns == 0] <- NA 

write.csv(crop_returns, "processing/net_returns/crop_returns.csv") # write csv
