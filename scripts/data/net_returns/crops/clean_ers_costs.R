##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: Mar 31, 2021
## Script purpose: Correct units and clean crop cost data
## Input data: ERS Cost Return data
##################################################

install.packages("readxl")
library(readxl)
install.packages("tidyverse")
library(tidyverse)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

# corn ---------------------------------

corn <- read_excel("processing/net_returns/crops/cost/ers_raw/CornCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(corn, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(corn, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
corn_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

dst = "processing/net_returns/crops/cost/" # set destination
dir.create(dst,recursive = TRUE, showWarnings = FALSE) # create folders if they don't exist
write.csv(corn_cost, sprintf("%s/corn_cost.csv", dst)) # write csv

# sorghum ---------------------------------

sorghum <- read_excel("processing/net_returns/crops/cost/ers_raw/SorghumCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(sorghum, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(sorghum, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
sorghum_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(sorghum_cost, sprintf("%s/sorghum_cost.csv", dst)) # write csv

# soybeans ---------------------------------

soybeans <- read_excel("processing/net_returns/crops/cost/ers_raw/SoybeansCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(soybeans, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(soybeans, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
soybeans_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(soybeans_cost, sprintf("%s/soybeans_cost.csv", dst)) # write csv

# wheat ---------------------------------

wheat <- read_excel("processing/net_returns/crops/cost/ers_raw/WheatCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(wheat, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(wheat, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
wheat_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(wheat_cost, sprintf("%s/wheat_cost.csv", dst)) # write csv

# barley ---------------------------------

barley <- read_excel("processing/net_returns/crops/cost/ers_raw/BarleyCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(barley, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(barley, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
barley_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(barley_cost, sprintf("%s/barley_cost.csv", dst)) # write csv

# oats ---------------------------------

oats <- read_excel("processing/net_returns/crops/cost/ers_raw/OatsCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(oats, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(oats, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
oats_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(oats_cost, sprintf("%s/oats_cost.csv", dst)) # write csv

# rice ---------------------------------

rice <- read_excel("processing/net_returns/crops/cost/ers_raw/RiceCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(rice, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(rice, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
rice_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(rice_cost, sprintf("%s/rice_cost.csv", dst)) # write csv

# cotton ---------------------------------

cotton <- read_excel("processing/net_returns/crops/cost/ers_raw/CottonCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(cotton, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(cotton, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
cotton_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(cotton_cost, sprintf("%s/cotton_cost.csv", dst)) # write csv
