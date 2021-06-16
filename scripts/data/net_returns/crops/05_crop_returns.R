##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: May 13, 2021
## Script purpose: Construct returns for each crop/state/year as a function of price/cost/yield/government_payments
## Input data: new_crop_returns.csv - the combined crop data set with FIPS info
##################################################

## Load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               data.table,
               haven,
               dplyr,
               data.table,
               readxl,
               sf,
               tidycensus,
               zoo)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

options(tigris_use_cache = TRUE) #Tell tidycensus to cache shapefiles for future sessions
#census_api_key("", overwrite = TRUE, install = TRUE) # set API key

# load data
new_crop_returns <- read_csv("processing/net_returns/new_crop_returns.csv") %>% # load crop returns data
  select(., -c(X1, X1_1)) %>% # remove added columns
  filter(., year <= 2012) %>% # trim to years 2002-2012
  as.data.table()
frr_data <- read_excel("processing/net_returns/crops/FRR_FIPS.xls") %>% # load farm resource region to FIPS data
  rename(., frr = 'ERS resource region') # renmae column

##################################################
## returns equation
##################################################

# calculate distance dependent weighting of crop yields ------------------------

# function to measure distances between counties

measure_dists <- function(shp) {
  county_centroid <- st_centroid(shp)
  dists <- st_distance(county_centroid)

  return(dists)
}

# function to calculate smoothed yields across FRR -----------------------------

smooth_yields <- function(farm_resource_region, yr, crp) { #FRR, yr, crop
 
  # subset by FRR, year, and crop. Will have one record for each county in FRR
  df_sub <- new_crop_returns[frr == farm_resource_region & year == yr & crop == crp]
  
  # import county shapefile using tidycensus - b19013_001 is arbitrarily chosen
  counties <- get_acs(geography = "county", year = 2010, variables = "B19013_001", geometry = TRUE) %>%
    select(-c("variable","estimate","moe"))
  counties <- left_join(counties, frr_data, by = c("GEOID" = "County FIPS")) %>%
    filter(frr == farm_resource_region) %>%
    select(-c(State, frr))
  # merge with conversion data frame
  df_sub <- merge(df_sub, counties, by.x = 'county_fips', by.y = 'GEOID', all.y = TRUE) %>%
    as.data.table()
  # replace NA values from merged missing counties
  df_sub <- df_sub[is.na(yield), ':=' (yield = 0), ]
  
  # create weighting matrix based on distances among counties
  dists <- measure_dists(counties) # distances among county centroids
  weights <- apply(dists, c(1,2), function(x) (1+1*x/1000)^(-2)) # weights based on Scott (2014)
  
  # calculate smoothed CCPs using weighting matrix
  df_sub$yield.w <- df_sub$yield %*% weights
  df_sub <- df_sub[ , weighted_yield := yield.w]  %>%
    .[ , c('county_fips','state_fips','frr','crop','year','price','cost','yield','weighted_yield','acres','acres_c','govt_payments','state','state_code','state_name','county_code','county','ID')]
  
  return(df_sub)
}

# run function over FRR, years, and crops --------------------------------------

frrs <- unique(frr_data$frr)
years <- unique(new_crop_returns$year)
crops <- c("corn", "sorghum", "soybeans", "winter wheat", "durum wheat", "spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops

yields <- do.call(rbind, do.call(rbind, do.call(rbind,  # row bind to unnest results
                                                   lapply(frrs, function(r)
                                                     lapply(years, function(y)
                                                       lapply(crops, function(c) smooth_yields(farm_resource_region = r, yr = y, crp = c)))))))

# add smoothed yield data to original data frame  ------------------------------

yields1 <- yields %>% # retain original yield data
  filter(yield>0) %>%
  select(., -weighted_yield)
yields2 <- anti_join(yields, yields1, by = c("county_fips", "crop", "year")) %>% # fill in remaining yields with smoothed values
  mutate(yield = weighted_yield) %>%
  select(., -weighted_yield)
yields3 <- rbind(yields1, yields2) # bind original yields and smoothed yields
new_crop_returns <- merge(new_crop_returns, yields3, by=c('county_fips','state_fips','frr','crop','year','price','cost','acres','acres_c','govt_payments','state','state_code','state_name','county_code','county','ID'), all.x = TRUE) %>%
  rename(., yield = yield.y) %>% # add new yields to original dataframe
  select(-c(yield.x))

# load NRI acres planted data to calculate government payments per acre --------

govt_acres <- read_dta("processing_output/pointpanel_estimation_unb.dta") %>% # load NRI data
  as.data.table() %>%
  .[, c("fips", "year", "acresk")] %>% # trim to relevant columns
  group_by(., fips, year) %>% summarise(acresk = sum(acresk)) # sum for total acres planted per county per year
new_crop_returns1 <- new_crop_returns[, c("county_fips", "year", "govt_payments")] # trim
new_crop_returns1 <- aggregate( . ~ county_fips + year , data = new_crop_returns1, sum) %>% # sum for total government payments per county
  left_join(., govt_acres, by = c("county_fips" = "fips", "year")) %>% # merge acres and payments data
  add_column(payments_acres = .$govt_payments/.$acresk) %>% # calculate govt payments per acre of planted crops
  .[, c("county_fips", "year", "payments_acres")] # trim to relevant columns

# linearly interpolate govt payments/acre for years outside census -------------

# create data frame with all years
county_fips <- na.omit(data.frame(county_fips = unique(new_crop_returns[,c("county_fips")])))
new_crop_returns2 <- data.frame(county_fips = rep(county_fips$county_fips, each = 11)) # 11 years of data
years = c(2002:2012) # list of years
new_crop_returns2$year <- rep(years, times = 3112) # repeat sequence of years for each crop in each FIPS code
new_crop_returns2 <- left_join(x = new_crop_returns2, y = new_crop_returns1, by = c("county_fips", "year")) # join complete year dataframe to census year dataframe

# create and join interpolated data
new_crop_returns2 <- new_crop_returns2 %>%
  group_by(county_fips) %>%
  mutate(payment_acres = na.approx(payments_acres, na.rm = FALSE)) # linear interpolation
new_crop_returns <- left_join(x = new_crop_returns, y = new_crop_returns2, by = c("county_fips", "year")) #%>% # merge with main data

# calculate crop returns per acre  ---------------------------------------------

new_crop_returns$return = (new_crop_returns$price - new_crop_returns$cost)*new_crop_returns$yield # (price - cost)*yield = returns/acre
new_crop_returns$returns <- rowSums(cbind(new_crop_returns$return, new_crop_returns$payment_acres), na.rm=TRUE) # add government payments/acre
new_crop_returns = subset(new_crop_returns, select = -c(payments_acres,return))


##################################################
## weighted average of acres planted for each crop in a farm resource region/state for a given year
##################################################

# create a data frame with ALL acres planted data by state, including data previously omitted because of no specified counties (i.e. "other counties" data) -----

# create data frame with state codes, crops and years
state_fips <- na.omit(data.frame(state_code = unique(new_crop_returns[,c("state_code")])))
state_acres <- data.frame(state_fips = rep(state_fips$state_code, each = 121)) # 11 crops x 11 years of data = 121 rows of each county
crop = c("corn", "sorghum", "soybeans", "winter wheat", "durum wheat", "spring wheat", "barley", "oats", "rice", "upland cotton", "pima cotton") # list of crops
state_acres$crop <- rep(crop, each = 11, times = 49) # repeat crops 19 times for each state code
year = c(2002:2012) # list of years
state_acres$year <- rep(year, times = 539) # repeat sequence of years for each crop in each FIPS code

# load and join acres data
cropf = c("corn", "sorghum", "soybeans", "winter_wheat", "durum_wheat", "spring_wheat", "barley", "oats", "rice", "upland_cotton", "pima_cotton") # list of formatted crops
rm(i)
for(i in cropf) {
  acres <- paste(i, "acres", sep = "_") # create an acres planted variable for each crop
  acres <- read_csv(sprintf("processing/net_returns/crops/acres/%s.csv", toString(acres))) # load acres data
  acres <- mutate_all(acres, .funs=tolower) # change all character entries to lowercase
  acres$Year <- as.numeric(acres$Year) # convert year to numeric
  acres$Value <- as.numeric(acres$Value) # convert value to numeric
  names(acres)[names(acres) == "Value"] <- "acres" # rename column
  
  crop_acres <- aggregate(acres$acres, by=list(state_fips=acres$`State ANSI`, year=acres$`Year`, crop=acres$`Commodity`), FUN=sum) # aggregate and sum acres data by state, year, crop
  names(crop_acres)[names(crop_acres) == "x"] <- "state_acres" # rename column
  crop_acres[crop_acres == "8"] <- "08" # fix unusual FIPS codes from spring wheat
  
  state_acres <- left_join(x = state_acres, y = crop_acres, by = c("state_fips", "year", "crop")) # merge crop data with acres
  if("state_acres.y" %in% colnames(state_acres)) {
    state_acres$state_acres <- rowSums(cbind(state_acres$state_acres.x,state_acres$state_acres.y), na.rm=TRUE) # if not the first iteration, bind the two acres columns together
    state_acres <- state_acres[, c("state_fips", "crop", "year", "state_acres")] # trim columns
  }
}

# calculate weights from states where possible ---------------------------------

total_acres <- aggregate(state_acres$state_acres, by=list(state_fips=state_acres$state_fips, year=state_acres$year), FUN=sum) # aggregate and sum acres data by state and year
names(total_acres)[names(total_acres) == "x"] <- "total_acres" # rename column
state_acres <- left_join(x = state_acres, y = total_acres, by = c("state_fips", "year")) # merge state totals data with crop specific data
state_acres$weight <- state_acres$state_acres/state_acres$total_acres # calculate weights
new_crop_returns <- left_join(x = new_crop_returns, y = state_acres, by = c("state_fips", "year", "crop")) # merge crop data frame with weights
new_crop_returns[new_crop_returns == 0.0000000000] <- NA # remove weights for counties with none
new_crop_returns <- new_crop_returns[, c("county_fips", "state_fips", "frr", "crop", "year", "price", "cost", "yield", "acres", "acres_c", "govt_payments", "state", "state_name", "county", "ID", "returns", "payment_acres", "weight")] # trim columns

# add weights from FRR where no state weighting data exists --------------------

frr_total_acres <- new_crop_returns[, c("frr", "year", "acres")] # trim
frr_total_acres <- aggregate( . ~ frr + year , data = frr_total_acres, sum) # aggregate acres of all crops for frr and year
names(frr_total_acres)[names(frr_total_acres) == "acres"] <- "frr_acres" # rename column
frr_state_acres <- new_crop_returns[, c("frr", "year", "crop", "acres")] # trim
frr_state_acres <- aggregate( . ~ frr + year + crop, data = frr_state_acres, sum) # aggregate acres of all crops for frr and year
frr_state_acres <- left_join(x = frr_state_acres, y = frr_total_acres, by = c("frr", "year")) # merge
frr_state_acres$frr_weight <- frr_state_acres$acres/frr_state_acres$frr_acres # calculate weights
frr_state_acres <- frr_state_acres[, c("frr", "year", "crop", "frr_weight")] # trim

# bind state and FRR weighting -------------------------------------------------

new_crop_returns <- left_join(x = new_crop_returns, y = frr_state_acres, by = c("frr", "year", "crop")) # merge crop data frame with weights
new_crop_returns3 <- new_crop_returns[is.na(new_crop_returns$weight),] # subset to missing weight values
new_crop_returns3$new_weight <- new_crop_returns3$frr_weight # add frr_weight to missing state weight
new_crop_returns3 <- new_crop_returns3[, c("county_fips", "year", "crop", "new_weight")] # trim
new_crop_returns <- left_join(x = new_crop_returns, y = new_crop_returns3, by = c("county_fips", "year", "crop")) # merge crop data frame with frr weights
new_crop_returns$weight <- rowSums(cbind(new_crop_returns$weight, new_crop_returns$new_weight), na.rm=TRUE) # bind
new_crop_returns = subset(new_crop_returns, select = -c(frr_weight,new_weight)) # remove extra columns
new_crop_returns[new_crop_returns == 0.0000000000] <- NA # add back in NAs

# calculate acres weighted returns ---------------------------------------------

new_crop_returns$weighted_av <- new_crop_returns$returns*new_crop_returns$weight # calculate weighted returns
new_crop_returns4 <- new_crop_returns[, c("county_fips", "year", "weighted_av")] # trim to aggregate
new_crop_returns4 <- aggregate( . ~ county_fips + year , data = new_crop_returns4, sum) # aggregate weighted returns over counties and years
names(new_crop_returns4)[names(new_crop_returns4) == "weighted_av"] <- "weighted_returns" # rename column
new_crop_returns <- left_join(x = new_crop_returns, y = new_crop_returns4, by = c("county_fips", "year")) # merge crop data frame with weights
new_crop_returns = subset(new_crop_returns, select = -c(weighted_av)) # remove extra columns

write.csv(new_crop_returns, "processing/final_crop_returns.csv") # write csv


