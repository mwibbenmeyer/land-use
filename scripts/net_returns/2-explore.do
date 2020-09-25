/* 
Author: Alexandra Thompson (RFF)
Date: September 21, 2020
Purpose: Initial Summary Statistics of Net Returns Values
Input data source(s): Dave Lewis and Chris Mihiar (Oregon State)
*/ 
global dir = "M:\GitRepos\land-use"
cd $dir

**********
********** 1: YEAR-LEVEL MEANS **************
**********
cd $dir
use processing\net_returns\clean, clear

* generate year-level means
local vars crop_nr forest_nr urban_nr
foreach v of local vars {
	bysort year: egen `v'_mean = mean(`v')
}

* line graphs of means by year
twoway (connected crop_nr_mean year, sort color(orange)) ///
	(connected forest_nr_mean year, sort color(green)) ///
	(connected urban_nr_mean year, sort color(purple) yaxis(2))
graph export results\initial_descriptives\net_returns\mean_year_scatter.png, replace
window manage close graph

**********
*********** 2: YEARS OF INTEREST SUMMARY STATISTICS ***********
**********
cd $dir
use processing\net_returns\clean, clear

* keep only years of interest for sum stat tables / maps
keep if 	year == 1987 ///
			| year == 1992 ///
			| year == 1997 ///
			| year == 2002 ///
			| year == 2007 ///
			| year == 2012
compress

* generate year-level values
local vars crop_nr forest_nr urban_nr
levelsof year, local(levels)
foreach v of local vars {
	foreach l of local levels {
		gen `v'_`l' = `v' if year == `l'
	}
}

* summary statistics tables
local vars crop_nr forest_nr urban_nr
foreach v of local vars {
	estpost summarize `v'*
	esttab using "results\initial_descriptives\net_returns\\`v'.rtf", cells("count(fmt(%12.0fc)) mean(fmt(%12.1fc)) sd(fmt(%12.1fc)) min(fmt(%12.1fc)) max(fmt(%12.1fc))") replace	
	}
	
**********
*********** 3: YEARS OF INTEREST MAPS ***********
**********
/* map layout:
for each category (n = 3), for each year (n = 6)
same scale for each category
code help:
	maptile_geohelp county2010
	maptile_geolist // list of installed geographies
*/

cd $dir
use processing\net_returns\clean, clear

* mapping setup
rename fips county
ssc install maptile
ssc install spmap
ssc install shp2dta
maptile_install using "http://files.michaelstepner.com/geo_county2010.zip"
capture net install grc1leg2.pkg

* keep only years of interest for sum stat tables / maps
keep if 	year == 1987 ///
			| year == 1992 ///
			| year == 1997 ///
			| year == 2002 ///
			| year == 2007 ///
			| year == 2012
compress

* calculate percentile breaks for all values
local vars crop_nr forest_nr urban_nr
foreach v of local vars {
	pctile `v'_nq5breaks = `v', nq(5)
	pctile `v'_nq6breaks = `v', nq(6)
}

* generate temp min & max values for legend: year is arbitrary. just want values that capture full range of values.
local vars crop_nr forest_nr urban_nr
foreach v of local vars {
egen `v'_min = min(`v')
egen `v'_max = max(`v')
gen `v'_display = `v' if year == 2012
egen `v'_min_2012 = min(`v') if year == 2012
replace `v'_display = `v'_min if `v'_display == `v'_min_2012 & year == 2012
egen `v'_max_2012 = max(`v') if year == 2012
replace `v'_display = `v'_max if `v'_display == `v'_max_2012 & year == 2012
}
drop *max* *min*

* generate, save individual graphs
cd $dir
cd processing\net_returns\graphs_temp

* colors
local crop_nr_colors = "Oranges"
local forest_nr_colors = "Greens"
local urban_nr_colors = "Purples"

local vars crop_nr forest_nr urban_nr
levelsof year, local(levels)
foreach v of local vars {
	foreach l of local levels {
		maptile `v' if year == `l', geo(county2010) cutp(`v'_nq6breaks) fcolor(``v'_colors')
		gr_edit subtitle.text.Arrpush "`l'"
		graph save "`v'_`l'", replace
	}
maptile `v'_display if year == 2012, geo(county2010) cutp(`v'_nq6breaks) fcolor(``v'_colors') // mean county-level value map for legend
graph save "`v'", replace
}

* combine, save graphs
local vars crop_nr forest_nr urban_nr
foreach v of local vars {
	cd $dir
	cd processing\net_returns\graphs_temp
	
	grc1leg2 `v'_1987.gph `v'_1992.gph `v'_1997.gph `v'_2002.gph `v'_2007.gph `v'_2012.gph `v'.gph, legendfrom(`v'.gph)
	gr_edit title.text.Arrpush "`v'"
	gr_edit plotregion1.graph7.draw_view.setstyle, style(no) // hide map created for legend only
	gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
	gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
	gr_edit legend.Edit, style(labelstyle(size(vsmall)))
	
	cd $dir
	cd results\initial_descriptives\net_returns
	graph export `v'_maps.png, replace
	}
window manage close graph

**********
*********** 4: YEARS OF INTEREST MAPS OF URBAN_NR IN WESTERN STATES ***********
**********
cd $dir
use processing\net_returns\clean, clear

* mapping setup
rename fips county
ssc install maptile
ssc install spmap
ssc install shp2dta
maptile_install using "http://files.michaelstepner.com/geo_county2010.zip"
capture net install grc1leg2.pkg

* generate state fips
tostring county, gen(fipsstring)
gen statefips = substr(fipsstring, 1, 2)
replace statefips = substr(fipsstring, 1, 1) if length(fipsstring)==4
destring statefips, replace
merge m:1 statefips using processing_output\stateFips
assert statefips == 11 if _merge == 1
drop if _merge == 2
drop _merge
replace stateName = "District of Columbia" if statefips == 11
replace stateAbbrev = "DC" if statefips == 11
* tag western states
gen western_us = stateAbbrev == "NV" | stateAbbrev == "MT" | stateAbbrev == "WY" ///
				| stateAbbrev == "CO" | stateAbbrev == "NM"| stateAbbrev == "ID" ///
				| stateAbbrev == "UT" | stateAbbrev == "AZ" | stateAbbrev == "WA" ///
				| stateAbbrev == "OR" | stateAbbrev == "CA"
keep if western_us == 1
compress
				
* keep only years of interest for sum stat tables / maps
/*keep if 	year == 1987 ///
			| year == 1992 ///
			| year == 1997 ///
			| year == 2002 ///
			| year == 2007 ///
			| year == 2012
compress
*/

* calculate percentile breaks for all values
pctile urban_nr_nq9breaks = urban_nr, nq(9)

* generate temp min & max values for legend: year is arbitrary. just want values that capture full range of values.
egen urban_nr_min = min(urban_nr)
egen urban_nr_max = max(urban_nr)
gen urban_nr_display = urban_nr if year == 2012
egen urban_nr_min_2012 = min(urban_nr) if year == 2012
replace urban_nr_display = urban_nr_min if urban_nr_display == urban_nr_min_2012 & year == 2012
egen urban_nr_max_2012 = max(urban_nr) if year == 2012
replace urban_nr_display = urban_nr_max if urban_nr_display == urban_nr_max_2012 & year == 2012
drop *max* *min*

* generate, save individual graphs
cd $dir
cd processing\net_returns\graphs_temp

* colors
local urban_nr_colors = "Purples"

levelsof year, local(levels)
foreach l of local levels {
	maptile urban_nr if year == `l', geo(county2010) cutp(urban_nr_nq9breaks) fcolor(`urban_nr_colors')
	gr_edit subtitle.text.Arrpush "`l'"
	graph save "urban_nr_western_`l'", replace
}
maptile urban_nr_display if year == 2012, geo(county2010) cutp(urban_nr_nq9breaks) fcolor(`urban_nr_colors') // mean county-level value map for legend
graph save "urban_nr_western", replace

* combine, save graphs

* 1997-2000
cd $dir
cd processing\net_returns\graphs_temp
grc1leg2 urban_nr_western_1997.gph ///
		urban_nr_western_1998.gph ///
		urban_nr_western_1999.gph ///
		urban_nr_western_2000.gph ///
		urban_nr_western.gph, legendfrom(urban_nr_western.gph)
gr_edit title.text.Arrpush "urban_nr West 1997-2000"
gr_edit plotregion1.graph5.draw_view.setstyle, style(no) // hide map created for legend only
gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
gr_edit legend.Edit, style(labelstyle(size(vsmall)))
gr_edit legend.Edit , style(cols(2)) style(rows(0)) keepstyles 
cd $dir
cd results\initial_descriptives\net_returns
graph export urban_nr_western_maps_1997-2000.png, replace
window manage close graph

* 2001-2007
cd $dir
cd processing\net_returns\graphs_temp
grc1leg2 urban_nr_western_2001.gph ///
		urban_nr_western_2002.gph ///
		urban_nr_western_2003.gph ///
		urban_nr_western_2004.gph ///
		urban_nr_western_2005.gph ///
		urban_nr_western_2006.gph ///
		urban_nr_western_2007.gph ///
		urban_nr_western.gph, legendfrom(urban_nr_western.gph)
gr_edit title.text.Arrpush "urban_nr West 2001-2007"
gr_edit plotregion1.graph8.draw_view.setstyle, style(no) // hide map created for legend only
gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
gr_edit legend.Edit, style(labelstyle(size(vsmall)))
gr_edit legend.Edit , style(cols(2)) style(rows(0)) keepstyles 
cd $dir
cd results\initial_descriptives\net_returns
graph export urban_nr_western_maps_2001-2007.png, replace
window manage close graph

* 2008-2013
cd $dir
cd processing\net_returns\graphs_temp
grc1leg2 urban_nr_western_2008.gph ///
		urban_nr_western_2009.gph ///
		urban_nr_western_2010.gph ///
		urban_nr_western_2011.gph ///
		urban_nr_western_2012.gph ///
		urban_nr_western_2013.gph ///
		urban_nr_western.gph, legendfrom(urban_nr_western.gph)
gr_edit title.text.Arrpush "urban_nr West 2008-2013"
gr_edit plotregion1.graph7.draw_view.setstyle, style(no) // hide map created for legend only
gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
gr_edit legend.Edit, style(labelstyle(size(vsmall)))
gr_edit legend.Edit , style(cols(2)) style(rows(0)) keepstyles 
cd $dir
cd results\initial_descriptives\net_returns
graph export urban_nr_western_maps_2008-2013.png, replace
window manage close graph











* fin.
