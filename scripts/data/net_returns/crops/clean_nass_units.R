##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: April 26, 2021
## Script purpose: Correct units of sorghum price and rice yield
## Input data: NASS price and yield data
##################################################

install.packages("tidyverse")
library(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

# sorghum price ---------------------------------

sorghum_price <- read_csv("processing/net_returns/crops/price/nass_raw/sorghum_price_raw.csv") # load data

sorghum_price$Value <- as.integer(sorghum_price$Value)*0.56 # multiply $/cwt by 0.56 cwt/bu to get $/bu and replace column
sorghum_price$`Data Item` <- "SORGHUM, GRAIN - PRICE RECEIVED, MEASURED IN $ / BU" # change unit labels

dst = "processing/net_returns/crops/price/" # set destination
dir.create(dst,recursive = TRUE, showWarnings = FALSE) # create folders if they don't exist
write.csv(sorghum_price, sprintf("%s/sorghum_price.csv", dst)) # write csv

# rice yield ---------------------------------

rice_yield <- read_csv("processing/net_returns/crops/yield/nass_raw/rice_yield_raw.csv") # load data

rice_yield$Value <- as.integer(rice_yield$Value)*0.01 # multiply lb/acre by 0.01 cwt/lb to get cwt/acre and replace column
rice_yield$`Data Item` <- "RICE - YIELD, MEASURED IN CWT / ACRE" # change unit labels

dst = "processing/net_returns/crops/yield/" # set destination
dir.create(dst,recursive = TRUE, showWarnings = FALSE) # create folders if they don't exist
write.csv(rice_yield, sprintf("%s/rice_yield.csv", dst)) # write csv
