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

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

# create data frame with each county FIPS code, crop, and year

df <- read_excel("processing/net_returns/crops/FRR_FIPS.xls") # load country code (FIPS) and farm resource region (FRR) data
crop_returns <- data.frame(country_fips = rep(df$`County FIPS`, each = 209), state_fips = rep(df$`State`, each = 209), frr = rep(df$`ERS resource region`, each = 209)) # 11 crops x 19 years of data = 209 rows of each county
crop = c("corn", "soghum", "soybeans", "winter wheat", "durum wheat", "other spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops
crop_returns$crop <- rep(crop, each = 19, times = 3112) # repeat crops 19 times for each FIPS code
year = c(2002:2020) # list of years
crop_returns$year <- rep(year, times = 34232) # repeat sequence of years for each crop in each FIPS code



