##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: Mar 31, 2021
## Script purpose: Correct units and clean crop cost data
## Input data: ERS Cost Return data
##################################################

library(readxl)
install.packages("tidyverse")
library(tidyverse)


# corn ---------------------------------

corn <- read_excel("CornCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(corn, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(corn, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
corn_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(corn_cost, "corn_cost.csv") # write csv

# sorghum ---------------------------------

sorghum <- read_excel("SorghumCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(sorghum, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(sorghum, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
sorghum_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(sorghum_cost, "sorghum_cost.csv") # write csv

# soybeans ---------------------------------

soybeans <- read_excel("SoybeansCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(soybeans, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(soybeans, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
soybeans_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(soybeans_cost, "soybeans_cost.csv") # write csv

# wheat ---------------------------------

wheat <- read_excel("WheatCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(wheat, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(wheat, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
wheat_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(wheat_cost, "wheat_cost.csv") # write csv

# barley ---------------------------------

barley <- read_excel("BarleyCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(barley, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(barley, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
barley_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(barley_cost, "barley_cost.csv") # write csv

# oats ---------------------------------

oats <- read_excel("OatsCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(oats, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(oats, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
oats_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(oats_cost, "oats_cost.csv") # write csv

# rice ---------------------------------

rice <- read_excel("RiceCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(rice, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(rice, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
rice_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(rice_cost, "rice_cost.csv") # write csv

# cotton ---------------------------------

cotton <- read_excel("CottonCostReturn.xlsx", sheet = "Data Sheet (machine readable)") # load data

cost <- filter(cotton, Item == "Total, costs listed") # select only costs ($/planted acre)
yield <- filter(cotton, Item == "Yield") # select only yield (bushels/planted acre)
new_value <- select(cost, Value)*(1/select(yield, Value)) # multiply to get new cost ($/bushel)
cost <- cbind(cost, new_col = new_value) # add new column to data frame
cotton_cost = select(cost, 1:3, 11:12, 15, 17, 22) # select only relevant columns

write.csv(cotton_cost, "cotton_cost.csv") # write csv
 
