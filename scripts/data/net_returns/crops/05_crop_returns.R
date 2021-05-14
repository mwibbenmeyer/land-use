##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: May 13, 2021
## Script purpose: Construct returns for each crop/state/year as a function of price/cost/yield/government_payments
## Input data: new_crop_returns.csv - the combined crop data set with FIPS info
##################################################

install.packages("tidyverse")
library(tidyverse)
install.packages("dplyr")
library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

new_crop_returns <- read_csv("processing/net_returns/new_crop_returns.csv") # load crop returns data
#crop = c("corn", "sorghum", "soybeans", "winter wheat", "durum wheat", "spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops

##################################################
## returns equation
##################################################

# write returns function

returns <- function(crop, year, state) { # pass in full crop name, year, and 2-letter state abbreviation (all lowercase!)
  # return a new data frame containing the original data subset constructed as a returns function
  state_returns <- new_crop_returns[new_crop_returns$year == year  & new_crop_returns$crop == crop & new_crop_returns$state == state,] # subset data
  state_returns <- state_returns[!is.na(state_returns$yield),] # remove counties missing yield data
  calc <- vector() # initialize vector
  for (i in 1:length(state_returns$county_fips)) { # perform return function calculation on entire subset
    calc[i] <- (state_returns$price[i] - state_returns$cost[i])*state_returns$yield[i]
  }
  return(calc)
}

result <- returns("corn", 2010, "al")
result

##################################################
## weighted average of acres planted for each crop in a farm resource region/state for a given year
##################################################

# weighted average function

weighted_av <- function(crop, year, county_fips) { # pass in full crop name, year, and FIPS code as a string (all lowercase!)
  # return the weight of that county's acres over all acres in the same state/fips code
  subset <- new_crop_returns[new_crop_returns$county_fips == county_fips,]
  frr <- subset$frr[1] # isolate state and farm resource region for crop
  state <- subset$state_fips[1]
  num <- new_crop_returns[new_crop_returns$county_fips == county_fips & new_crop_returns$year == year & new_crop_returns$crop == crop,] # denominator = all data with matching 
  denom <- new_crop_returns[new_crop_returns$frr == frr  & new_crop_returns$state_fips == state & new_crop_returns$year == year & new_crop_returns$crop == crop,] # denominator = all data with matching
  denom <- denom[!is.na(denom$acres),] # remove missing acres data
  calc <- sum(num$acres)/sum(denom$acres)
  return(calc)
}

result <- weighted_av("corn", 2017, "01001")
result
