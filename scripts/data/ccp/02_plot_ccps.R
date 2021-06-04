####################################################
# Sophie Pesek
# May 27, 2021
# Script to plot ccps on a U.S. map
####################################################

## Load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               sf,
               maps,
               rnaturalearth,
               rnaturalearthdata,
               tidycensus,
               ggplot2,
               foreign,
               haven,
               lwgeom,
               RColorBrewer
               )
theme_set(theme_bw())

# Set working directory to land-use
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")

#Load CCPs and world data
result <- read.csv("processing/ccps_new.csv") # load CCP data 
result$fips <- str_pad(result$fips, 5, pad = "0") # retain leading zeros in FIPS codes
world <- ne_countries(scale = "medium", returnclass = "sf") # load world data
class(world)
counties <- st_as_sf(map("county", plot = FALSE, fill = TRUE)) # load county data

#Combine results and geographic data to plot
fips_codes <- read_csv("processing/fips_codes.csv") # load fips / geographic data
ccps <- left_join(x = result, y = fips_codes, by = c("fips" = "county_fips")) # join crop returns data to state IDs
ccps <- merge(counties, ccps, by = "ID") # join by geo ID

#Split into discrete and continuous values
cont <- ccps[!(ccps$weighted_ccp == 1 | is.nan(ccps$weighted_ccp)) ,] # separate continuous values
cont$ccp_weights <- cut((cont$weighted_ccp), breaks=c(0, 0.111, 0.222, 0.333, 0.444, 0.556, 0.667, 0.778, 0.889, 1)) # cut the data into levels
levels(cont$ccp_weights) = c("(0, 0.111)", "(0.111, 0.222)", "(0.222, 0.333)", "(0.333, 0.444)", "(0.444, 0.556)", "(0.556, 0.667)", "(0.667, 0.778)", "(0.778, 0.889)", "(0.889, 0.999)") # create new scale

disc <- ccps[ccps$weighted_ccp == 1 | is.nan(ccps$weighted_ccp),] # separate discrete values
disc$ccp_weights <- as.character(disc$weighted_ccp)
new_ccps <- rbind(cont, disc) # bind values back together

#Iterate and create graphs
years <- c(2002, 2007, 2012)
lcc_values <- c("1_2", "3_4", "5_6", "7_8")
initial_uses <- c("Crop", "Forest", "Urban", "Other")
final_uses <- c("Crop", "Forest", "Urban", "Other")
  
rm(i, j, k, l)
for(i in years){
  for(j in lcc_values){
    for(k in initial_uses){
      for(l in final_uses){
        
        #Subset data by each combination
        ccps1 <- new_ccps[new_ccps$year %in% i,] # subset data by each year
        ccps1 <- ccps1[ccps1$lcc %in% j,] # subset data by lcc values
        ccps1 <- ccps1[ccps1$initial_use %in% k,] # subset data by initial use
        ccps1 <- ccps1[ccps1$final_use %in% l,] # subset data by final use
        
        #Plot results
        ggplot(data = world) + # map US counties
          geom_sf(data=counties, aes(geometry=geom)) + geom_sf(data=ccps1, aes(fill=ccp_weights, geometry=geometry)) + # fill ccp weights
          scale_fill_manual("CCP", values=c("(0, 0.111)" = "#91d885", "(0.111, 0.222)" = "#7fc374", "(0.222, 0.333)" = "#6eae64", "(0.333, 0.444)" = "#5c9954", "(0.444, 0.556)" = "#4c8544", "(0.556, 0.667)" = "#3b7235", "(0.667, 0.778)" = "#2b5f26", "(0.778, 0.889)" = "#1b4d18", "(0.889, 0.999)" = "#093b09", "1" = "#d29b00", "NaN" = "#B8B8B8")) + # set manual color scale
          ggtitle(sprintf("All states in %s with LCC %s from %s to %s", toString(i), j, k, l)) + # change title
          coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) # set coordinates to continental U.S.
        
        ggsave(sprintf("results/initial_descriptives/combined/maps_ccp/ccp_%s_%s_%s_%s.png", toString(i), j, k, l), width = 15, height = 8.33, dpi=96) # save map
      }
    }
  }
}
