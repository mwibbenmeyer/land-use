/* Programmer: Alexandra Thompson
Date: October 5, 2020
Objective: initial exploration of cleaned NRI data
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

********************************************************************************
************TIME TREND GRAPH************
********************************************************************************
use processing\NRI\nri15_county_panel, clear

collapse(mean) *pcnt* *acresk*, by(year)

* percents
twoway (connected CRPland_pcnt year, sort color(lavender)) ///
	(connected Cropland_pcnt year, sort color(orange)) ///
	(connected Forestland_pcnt year, sort color(green)) ///
	(connected Pastureland_pcnt year, sort color(lime)) ///
	(connected Rangeland_pcnt year, sort color(olive_teal)) ///
	(connected Urbanland_pcnt year, sort color(purple))
gr_edit title.text.Arrpush Mean % of County by Year
gr_edit yaxis1.title.text.Arrpush %
graph export results\initial_descriptives\NRI\meanpcnt_year_scatter.png, replace
window manage close graph

* acres
twoway (connected CRPland_acresk year, sort color(lavender)) ///
	(connected Cropland_acresk year, sort color(orange)) ///
	(connected Forestland_acresk year, sort color(green)) ///
	(connected Pastureland_acresk year, sort color(lime)) ///
	(connected Rangeland_acresk year, sort color(olive_teal)) ///
	(connected Urbanland_acresk year, sort color(purple)) ///
	(connected Federalland_acresk year, sort color(stone)) ///
	(connected Waterland_acresk year, sort color(blue)) ///
	(connected Ruralland_acresk year, sort color(pink))
gr_edit title.text.Arrpush Mean Acres by Year
gr_edit yaxis1.title.text.Arrpush Acres (thousands)
graph export results\initial_descriptives\NRI\meanacresk_year_scatter.png, replace
window manage close graph
