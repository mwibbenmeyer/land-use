##################################################
## Project: Land Use
## Author: Sophie Pesek
## Date: June 14, 2021
## Script purpose: Map weighted returns
## Input data: final_crop_returns.csv - crop dataset with returns
##################################################

# load/install packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse,
               # sf,
               # maps,
               # rnaturalearth,
               # rnaturalearthdata,
               # tidycensus,
               ggplot2,
               usmap,
               scales,
               patchwork)
theme_set(theme_bw())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # sets directory to the current directory
setwd('../../../..') # relative paths to move directory to the root project directory

# load data
final_crop_returns <- read_csv("processing/net_returns/final_crop_returns.csv") %>%
  select(., -X1) %>%
  rename(., fips = county_fips)
final_crop_returns$fips[final_crop_returns$fips == "46113"] <- "46102" # add old FIPS code to Oglala Lakota County

total_returns <- final_crop_returns %>%
  select(fips, return)# remove columns
total_returns1 <- aggregate( . ~ fips, data = total_returns, mean, na.rm = TRUE) #use weighted returns

returns <- final_crop_returns %>%
  filter(., year == 2002) %>% # trim to 2002
  select(fips, return) # remove columns
returns1 <- aggregate( . ~ fips, data = returns, mean, na.rm = TRUE)

total_gov_returns <- final_crop_returns %>%
  select(fips, returns_gov)# remove columns
total_gov_returns1 <- aggregate( . ~ fips, data = total_gov_returns, mean, na.rm = TRUE)

gov_returns <- final_crop_returns %>%
  filter(., year == 2002) %>% # trim to 2002
  select(fips, returns_gov) # remove columns
gov_returns1 <- aggregate( . ~ fips, data = gov_returns, mean, na.rm = TRUE)

gov_only <- final_crop_returns %>%
  filter(., year == 2002) %>% # trim to 2002
  select(fips, payment_acres) # remove columns
gov_only1 <- aggregate( . ~ fips, data = gov_only, mean, na.rm = TRUE)

returns_ac <- final_crop_returns %>%
  select(year, weighted_returns) # remove columns
returns_ac1 <- aggregate( . ~ year, data = returns_ac, mean, na.rm = TRUE)

# maps -----------

# plot map of total returns
plot_usmap(data = total_returns1, values = "return", color = "grey40", size=0.2, regions = "counties", exclude = c("AK","HI")) +
  scale_fill_viridis_c(label = scales::dollar_format()) +
  labs(title = "Mean crop returns without government payments for 2002-2012", fill = "Returns/acre ($)")
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_map_total.jpg") # save map

# plot map of returns
p1 <- plot_usmap(data = returns1, values = "return", color = "black", size=0.3, regions = "counties", exclude = c("AK","HI")) +
  scale_fill_viridis_c(label = scales::dollar_format()) +
  labs(title = "Crop returns without government payments in 2002", fill = "Returns per acre")
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_map_2002.jpg") # save map

# plot map of total returns with gov payments
plot_usmap(data = total_gov_returns1, values = "returns_gov", color = "grey40", size=0.2, regions = "counties", exclude = c("AK","HI")) +
  scale_fill_viridis_c(label = scales::comma) +
  labs(title = "Mean crop returns with government payments", fill = "Returns/acre ($)")
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_gov_map_total.jpg") # save map

# plot map of returns with gov payments
plot_usmap(data = gov_returns1, values = "returns_gov", color = "grey40", size=0.2, regions = "counties", exclude = c("AK","HI")) +
  scale_fill_viridis_c(label = scales::comma) +
  labs(title = "Crop returns with government payments in 2002", fill = "Returns/acre ($)")
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_gov_map_2002.jpg") # save map

# plot map of gov payments
plot_usmap(data = gov_only1, values = "payment_acres", color = "grey40", size=0.2, regions = "counties", exclude = c("AK","HI")) +
  scale_fill_viridis_c(label = scales::comma) +
  labs(title = "Government payments per acre in 2002", fill = "Payments/acre ($)")
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_gov_payments_map_2002.jpg") # save map

# histograms ----------

# plot histogram of returns without government payments in 2002
p2 <- ggplot(returns1, aes(x=return)) + geom_histogram(color="#440d57", fill="#75a3b1") + 
  labs(title= "Crop returns without government payments in 2002", x = "Returns per acre", y = "Count") +
  scale_x_discrete(labels=scales::dollar_format()) + xlim(c(-25,200))
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_hist_2002.jpg")

# plot histogram of returns with government payments in 2002
ggplot(gov_returns1, aes(x=returns_gov)) + geom_histogram(color="#440d57", fill="#75a3b1") +
  labs(title= "Crop returns with government payments in 2002", x = "Returns per acre ($)", y = "Count", subtitle = "4 high outliers trimmed") +
  xlim(c(-25,500))
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_gov_hist_2002.jpg")


# time series ---------

p3 <- ggplot(returns_ac1, aes(x=year, y=weighted_returns)) +
  geom_line(color="#440d57") + scale_x_continuous(breaks=c(2002,2004,2006,2008,2010,2012)) + scale_y_continuous(labels=scales::dollar_format())+
  labs(title= "Crop returns weighted by acre from 2002 to 2012", x = "Year", y = "Returns per acre")
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_timeseries.jpg")


# full figure ----------

layout <- "
AAAAAAABBB
AAAAAAABBB
AAAAAAACCC
AAAAAAACCC
"
p1 + p2 + p3 + 
  plot_layout(design = layout)
ggsave("results/initial_descriptives/net_returns/crops/crop_returns_combined.jpg", width = 18, height = 10)



