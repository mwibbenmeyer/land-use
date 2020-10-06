/* Programmer: Alexandra Thompson
Date: October 5, 2020
Objective: initial exploration of cleaned NRI data
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* processing data dir
global workingdir "M:\GitRepos\land-use"

********************************************************************************
************TIME TREND GRAPH************
********************************************************************************
use "$workingdir\processing\NRI\nri15_cleanpanel", clear

collapse(mean) *pcnt* *acresk*, by(year)
drop fips*acresk

* percents
twoway (connected CRP_pcnt year, sort color(lavender)) ///
	(connected Cropland_pcnt year, sort color(orange)) ///
	(connected Forestland_pcnt year, sort color(green)) ///
	(connected Pastureland_pcnt year, sort color(lime)) ///
	(connected Rangeland_pcnt year, sort color(olive_teal)) ///
	(connected UrbanLand_pcnt year, sort color(purple)) ///
	(connected Other_pcnt year, sort color(stone))
gr_edit title.text.Arrpush Mean % of County by Year
gr_edit yaxis1.title.text.Arrpush %
graph export "$workingdir\results\initial_descriptives\NRI\meanpcnt_year_scatter.png", replace
window manage close graph

* acres
twoway (connected CRP_acresk year, sort color(lavender)) ///
	(connected Cropland_acresk year, sort color(orange)) ///
	(connected Forestland_acresk year, sort color(green)) ///
	(connected Pastureland_acresk year, sort color(lime)) ///
	(connected Rangeland_acresk year, sort color(olive_teal)) ///
	(connected UrbanLand_acresk year, sort color(purple)) ///
	(connected Other_acresk year, sort color(stone))
gr_edit title.text.Arrpush Mean Acres by Year
gr_edit yaxis1.title.text.Arrpush Acres (thousands)
graph export "$workingdir\results\initial_descriptives\NRI\meanacresk_year_scatter.png", replace
window manage close graph
