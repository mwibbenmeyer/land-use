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
gr_edit title.text.Arrpush Mean % of County by Year (6 classes)
gr_edit yaxis1.title.text.Arrpush %
graph export results\initial_descriptives\NRI\meanpcnt_6classes_year_scatter.png, replace
window manage close graph

* percents w/ other
twoway (connected CRPland_pcnt2 year, sort color(lavender)) ///
	(connected Cropland_pcnt2 year, sort color(orange)) ///
	(connected Forestland_pcnt2 year, sort color(green)) ///
	(connected Pastureland_pcnt2 year, sort color(lime)) ///
	(connected Rangeland_pcnt2 year, sort color(olive_teal)) ///
	(connected Urbanland_pcnt2 year, sort color(purple)) ///
	(connected Federalland_pcnt2 year, sort color(magenta)) ///
	(connected Waterland_pcnt2 year, sort color(blue)) ///
	(connected Ruralland_pcnt2 year, sort color(cyan))
gr_edit title.text.Arrpush Mean % of County by Year (all classes)
gr_edit yaxis1.title.text.Arrpush %
graph export results\initial_descriptives\NRI\meanpcnt_allclasses_year_scatter.png, replace
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

********************************************************************************
************MAP************
********************************************************************************
* mapping setup
ssc install maptile
ssc install spmap
ssc install shp2dta
maptile_install using "http://files.michaelstepner.com/geo_county2010.zip"
capture net install grc1leg2.pkg

* load, setup
use processing\NRI\nri15_county_panel, clear
collapse(mean) *pcnt* *acresk*, by(year fips)
keep year *_pcnt2 fips
rename fips county

* calculate percentile breaks for all values
local vars Federal CRP Crop Forest Pasture Range Urban Water Rural
foreach v of local vars {
	pctile `v'_nq5breaks = `v'land_pcnt2, nq(5)
	pctile `v'_nq6breaks = `v'land_pcnt2, nq(6)
}

* colors
	local Crop_colors = "Oranges"
	local Forest_colors= "Greens"
	local Urban_colors= "Purples"
	local Federal_colors= "Oranges"
	local Water_colors= "Blues"
	local Range_colors= "Greens"
	local Pasture_colors= "Greens"
	local CRP_colors= "Reds"
	local Rural_colors= "Reds"
* generate, save individual graphs
local vars Federal CRP Crop Forest Pasture Range Urban Water Rural
levelsof year, local(levels)
foreach v of local vars {
	foreach l of local levels {
		maptile `v'land_pcnt2 if year == `l', geo(county2010) cutp(`v'_nq5breaks) fcolor(``v'_colors')
		gr_edit title.text.Arrpush "Percent `v'"
		gr_edit legend.Edit , style(rows(1)) style(cols(0)) keepstyles 
		gr_edit legend.Edit, style(labelstyle(size(tiny)))
		gr_edit legend.style.editstyle box_alignment(south) editcopy
		* pause
		graph save "processing\NRI\graphs_temp/`v'_pcnt_`l'", replace
	}
	}

* combine
cd $workingdir
levelsof year, local(levels)
foreach l of local levels {
graph combine ///
		processing\NRI\graphs_temp\Crop_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\Urban_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\Pasture_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\Range_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\Forest_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\CRP_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\Federal_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\Rural_pcnt_`l'.gph ///
		processing\NRI\graphs_temp\Water_pcnt_`l'.gph, ///
		subtitle("`l'")
		gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
		*pause
		graph export "results\initial_descriptives\NRI\LUpcnt_`l'.png", replace
}

* cleanup
local vars Federal CRP Crop Forest Pasture Range Urban Water Rural
levelsof year, local(levels)
foreach v of local vars {
	foreach l of local levels {
		erase "processing\NRI\graphs_temp/`v'_pcnt_`l'.gph"
		}
	}
