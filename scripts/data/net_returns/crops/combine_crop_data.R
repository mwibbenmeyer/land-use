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

# create data frame with each county FIPS code, crop, and year

df <- read_excel("processing/net_returns/crops/FRR_FIPS.xls") # load country code (FIPS) and farm resource region (FRR) data
crop_returns <- data.frame(country_fips = rep(df$`County FIPS`, each = 209), state_fips = rep(df$`State`, each = 209), frr = rep(df$`ERS resource region`, each = 209)) # 11 crops x 19 years of data = 209 rows of each county
crop = c("corn", "soghum", "soybeans", "winter wheat", "durum wheat", "other spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops
crop_returns$crop <- rep(crop, each = 19, times = 3112) # repeat crops 19 times for each FIPS code
year = c(2002:2020) # list of years
crop_returns$year <- rep(year, times = 34232) # repeat sequence of years for each crop in each FIPS code

# join new data frame with crop price, cost, yield, and acres data

# corn ---------------------------------

corn_price <- read_csv("processing/net_returns/crops/price/corn_price.csv") # load price data
corn_price <- mutate_all(corn_price, .funs=tolower) # change all character entries to lowercase

corn_cost <- read_csv("processing/net_returns/crops/cost/corn_cost.csv") # load cost data
corn_cost <- mutate_all(corn_cost, .funs=tolower) # change all character entries to lowercase

corn_yield <- read_csv("processing/net_returns/crops/yield/corn_yield.csv") # load price data
corn_yield <- mutate_all(corn_yield, .funs=tolower) # change all character entries to lowercase

corn_acres <- read_csv("processing/net_returns/crops/acres/corn_acres.csv") # load cost data
corn_acres <- mutate_all(corn_acres, .funs=tolower) # change all character entries to lowercase

# sorghum ---------------------------------

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year)

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase


new_crop_returns <- all_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with sorghum price

new_crop_returns = merge(x = crop_returns, y = sorghum_price, by.x = c("state_fips", "year", "crop"), by.y = c("State ANSI", "Year", "Commodity"), all.x = TRUE) # merge crop data with sorghum price
#names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column
#new_crop_returns = merge(x = crop_returns, y = sorghum_cost, by.x = c("state_fips", "year", "crop"), by.y = c("State ANSI", "Year", "Commodity"), all.x = TRUE) # merge sorghum cost data



