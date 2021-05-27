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
             #  foreign,
               haven#,
              # lwgeom
               )
theme_set(theme_bw())

list.functions.in.file(rstudioapi::getSourceEditorContext()$path, alphabetic = TRUE)

# Set working directory to land-use 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")

world <- ne_countries(scale = "medium", returnclass = "sf") # load world data
class(world)
counties <- st_as_sf(map("county", plot = FALSE, fill = TRUE)) # load county data
#counties <- as_tibble(counties)

#Load CCPs data
result <- read.csv("processing/ccps.csv") # load CCP data
result$fips <- toString(result$fips)
if (nchar(result$fips) == 4){
  paste0("0", result$fips)
}


#Combine results and geographic data to plot

fips_codes <- read_csv("processing/fips_codes.csv") # load fips / geographic data
ccps <- left_join(x = result, y = fips_codes, by = c("fips" = "county_fips")) # join crop returns data to state IDs
ccps <- merge(counties, ccps, by = "ID") # join by geo ID
ccps$ccp_weights <- cut(ccps$weighted_ccp, breaks=c(-1, 0, 0.999999999, Inf)) # cut the data into levels
levels(ccps$ccp_weights) = c("0","between 0 and 1","1") # create a factor for counties with and without acres

#Iterate and create graphs

rm(i, j, k, l)

for(i in years){
  for(j in lcc_values){
    for(k in initial_uses){
      for(l in final_uses){
        
        #Subset data by each combination
        ccps1 <- ccps[ccps$year %in% i,] # subset data by each year
        ccps1 <- ccps1[ccps1$lcc %in% j,] # subset data by lcc values
        ccps1 <- ccps1[ccps1$initial_use %in% k,] # subset data by initial use
        ccps1 <- ccps1[ccps1$final_use %in% l,] # subset data by final use
        
        #Plot results
        ggplot(data = world) + # map US counties
          geom_sf(data=counties, aes(geometry=geom)) + geom_sf(data=ccps1, aes(fill=ccp_weights, geometry=geom)) + # fill ccp weights
          scale_fill_manual(values=c("0" = "#184d47", "between 0 and 1" = "#96bb7c", "1" = "#fad586")) + # set manual color scale
          ggtitle(sprintf("All states in %s with LCC %s from %s to %s", toString(i), j, k, l)) + # change title
          coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) # set coordinates to continental U.S.
        
        ggsave(sprintf("results/initial_descriptives/combined/maps_ccp/ccp_%s_%s_%s_%s.png", toString(i), j, k, l), width = 15, height = 8.33, dpi=96) # save map
      }
    }
  }
}
  
# Plot results ------------

# ggplot(data = world) + # map US counties
#   geom_sf() + geom_sf(data=ccps, aes(fill=ccp_weights, geometry=geom)) + # fill with number of acres
#   scale_fill_manual(values=c("0" = "#ffc996", "between 0 and 1" = "#ff8474", "1" = "#9f5f80")) +
#   #scale_color_manual(values = c("0" = "#999999", "between 0 and 1" = "#E69F00", "1" = "#33F6FF")) +
#   #scale_fill_discrete(name = "Has acres-planted data") + # change legend labels and colors
#   ggtitle("Counties with CENSUS crop acres-planted data in any year (%s%%)") + # set color scale and title
#   coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE) # set coordinates to continental U.S.
# 
# ggsave("results/initial_descriptives/combined/maps_ccp/ccp_2002_factor.png", width = 18, height = 10, dpi=96) # save map


 # ggplot(data = world) + # map US counties
 #   geom_sf() + geom_sf(data = ccps, aes(fill = weighted_ccp, geometry=geom)) +
 #   scale_fill_viridis_c() + ggtitle("All states in 2002 with LCC 7_8 from crop to crop") +
 #   coord_sf(xlim = c(-125, -66), ylim = c(24, 50), expand = FALSE)
