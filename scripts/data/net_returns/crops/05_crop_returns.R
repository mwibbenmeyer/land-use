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
  # return a new data frane containing the original data subset
  # Example: returns("corn", 2010, "al") => c(returns_county1, returns_county2, ...)
  state_returns <- new_crop_returns[new_crop_returns$year == year  & new_crop_returns$crop == crop & new_crop_returns$state == state,]
  state_returns <- state_returns[!is.na(state_returns$yield),] # remove counties missing yield data
  calc <- vector() # initialize vector
  for (i in 1:length(state_returns$county_fips)) {
    calc[i] <- (state_returns$price[i] - state_returns$cost[i])*state_returns$yield[i]
  }
  return(calc)
}
answer <- returns("corn", 2010, "al")
answer


