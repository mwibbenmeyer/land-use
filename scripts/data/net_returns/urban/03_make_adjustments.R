# garbage collection
gc()

# load or install necessary libraries {
if (!require("pacman")) install.packages("pacman")
pacman::p_load(beepr,
               #cowplot,
               lfe,
               progress,
               tictoc,
               tidyverse,
               utils,
               rvest,
               tidycensus,
               readxl,
               tigris,
               sf,
               ggplot2,
               rvest,
               stringr,
               cdlTools,
               pbapply,
               readxl)

# clear environment and set wd.
rm(list=ls(all=TRUE)) 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("../../../")

#Download Survey of Construction data
download_soc <- function(year) {

  dst = sprintf("raw_data/net_returns/urban/soc/%s/",year)
  dir.create(file.path(dst), showWarnings = FALSE, recursive = TRUE)
  
  yr = substr(toString(year),3,4)
  output = paste0(dst,sprintf("soc%s.zip",yr))
  download.file(sprintf("https://www.census.gov/construction/chars/xls/soc%s.zip",yr),output)

  unzip(sprintf("raw_data/net_returns/urban/soc/%s/soc%s.zip",year,yr),
          exdir = sprintf("raw_data/net_returns/urban/soc/%s/soc%s",year,yr))
  file.remove(sprintf("raw_data/net_returns/urban/soc/%s/soc%s.zip",year,yr))

  }

lapply(c(2007,2012,2015), download_soc)


#Survey of construction data
soc <- read_excel("raw_data/net_returns/urban/soc/2012/soc12/soc12.xls")

#Lot value scaling factors
pctlotv <- soc %>% filter(LOTV != 0) %>%
            mutate(pctlotv = LOTV/SLPR) %>%
            group_by(DIV) %>%
              summarize(pctlotv = median(pctlotv),
                        slpr = median(SLPR, na.rm = TRUE),
                        lotv = median(LOTV, na.rm = TRUE),
                        lotsize_sqft = median(AREA, na.rm = TRUE),
                        lotsize_acres = lotsize_sqft/43560)

year = 2012
sf <- read_sf(sprintf("processing/net_returns/urban/county_valp/%s/county_valp_%s.shp",year,year)) %>%
        mutate(stfips = substr(countyfips,1,2),
               state = fips(stfips, to = "Abbreviation")) %>% 
        #Create Census division column for merge
        mutate(DIV = case_when(state %in% c("CT","MA","ME","NH","RI","VT") ~ 1,
              state %in% c("NJ","NY","PA") ~ 2,
              state %in% c("IL","IN","MI","OH","WI") ~ 3,
              state %in% c("IA","KS","MN","MO","ND","NE","SD") ~ 4,
              state %in% c("DE","FL","GA","MD","NC","SC","VA","WV") ~ 5,
              state %in% c("AL","KY","MS","TN") ~ 6,
              state %in% c("AR","LA","OK","TX") ~ 7,
              state %in% c("AZ","CO","ID","MT","NM","NV","UT","WY") ~ 8,
              state %in% c("CA","OR","WA") ~ 9)) %>%
        merge(pctlotv, by = "DIV") %>% 
        #Scale property value by percent that is attributed to land 
        mutate(landval = 0.05*pctlotv*valp/lotsize_acres)

ggplot() + geom_sf(data = sf, aes(fill = landval))
