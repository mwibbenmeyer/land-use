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

df <- read_excel("processing/net_returns/crops/FRR_FIPS.xls") # load country code (FIPS) and farm resource region (FRR) data
crop_returns <- data.frame(county_fips = rep(df$`County FIPS`, each = 209), state_fips = rep(df$`State`, each = 209), frr = as.character(rep(df$`ERS resource region`, each = 209))) # 11 crops x 19 years of data = 209 rows of each county
crop = c("corn", "sorghum", "soybeans", "winter wheat", "durum wheat", "other spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops
crop_returns$crop <- rep(crop, each = 19, times = 3112) # repeat crops 19 times for each FIPS code
year = c(2002:2020) # list of years
crop_returns$year <- rep(year, times = 34232) # repeat sequence of years for each crop in each FIPS code

##################################################
## join new data frame with crop price, cost, yield, and acres data
##################################################

# corn ---------------------------------

# load data

corn_price <- read_csv("processing/net_returns/crops/price/corn_price.csv") # load price data
corn_price <- mutate_all(corn_price, .funs=tolower) # change all character entries to lowercase
corn_price$Year = as.numeric(corn_price$Year) # convert year to numeric

corn_cost <- read_csv("processing/net_returns/crops/cost/corn_cost.csv") # load cost data
corn_cost <- mutate_all(corn_cost, .funs=tolower) # change all character entries to lowercase
corn_cost$Year = as.numeric(corn_cost$Year) # convert year to numeric

corn_yield <- read_csv("processing/net_returns/crops/yield/corn_yield.csv") # load price data
corn_yield <- mutate_all(corn_yield, .funs=tolower) # change all character entries to lowercase
corn_yield$Year = as.numeric(corn_yield$Year) # convert year to numeric
corn_yield$county_fips = paste(corn_yield$`State ANSI`, corn_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

corn_acres <- read_csv("processing/net_returns/crops/acres/corn_acres.csv") # load cost data
corn_acres <- mutate_all(corn_acres, .funs=tolower) # change all character entries to lowercase
corn_acres$Year = as.numeric(corn_acres$Year) # convert year to numeric
corn_acres$county_fips = paste(corn_acres$`State ANSI`, corn_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = corn_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = corn_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = corn_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = corn_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

# sorghum ---------------------------------

# load data

sorghum_price <- read_csv("processing/net_returns/crops/price/sorghum_price.csv") # load price data
sorghum_price <- mutate_all(sorghum_price, .funs=tolower) # change all character entries to lowercase
sorghum_price$Year = as.numeric(sorghum_price$Year) # convert year to numeric

sorghum_cost <- read_csv("processing/net_returns/crops/cost/sorghum_cost.csv") # load cost data
sorghum_cost <- mutate_all(sorghum_cost, .funs=tolower) # change all character entries to lowercase
sorghum_cost$Year = as.numeric(sorghum_cost$Year) # convert year to numeric

sorghum_yield <- read_csv("processing/net_returns/crops/yield/sorghum_yield.csv") # load price data
sorghum_yield <- mutate_all(sorghum_yield, .funs=tolower) # change all character entries to lowercase
sorghum_yield$Year = as.numeric(sorghum_yield$Year) # convert year to numeric
sorghum_yield$county_fips = paste(sorghum_yield$`State ANSI`, sorghum_yield$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

sorghum_acres <- read_csv("processing/net_returns/crops/acres/sorghum_acres.csv") # load cost data
sorghum_acres <- mutate_all(sorghum_acres, .funs=tolower) # change all character entries to lowercase
sorghum_acres$Year = as.numeric(sorghum_acres$Year) # convert year to numeric
sorghum_acres$county_fips = paste(sorghum_acres$`State ANSI`, sorghum_acres$`County ANSI`, sep="") # concatenate state and county ANSI codes to create a FIPS code

# merge with geographic data frame

new_crop_returns <- left_join(x = crop_returns, y = sorghum_price, by = c("state_fips" = "State ANSI", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "price" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_cost, by = c("frr" = "RegionId", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "cost" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_yield, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn price
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "yield" # rename column

new_crop_returns <- left_join(x = new_crop_returns, y = sorghum_acres, by = c("county_fips" = "county_fips", "year" = "Year", "crop"= "Commodity")) # merge crop data with corn cost
names(new_crop_returns)[names(new_crop_returns) == "Value"] <- "acres" # rename column

# trim to relevant data

new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "State.x", "price", "cost", "yield", "acres")] # trim
names(new_crop_returns)[names(new_crop_returns) == "State.x"] <- "state"

