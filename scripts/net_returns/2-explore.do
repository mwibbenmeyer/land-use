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

* calculate percentile breaks for year with widest range
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
drop *max *min

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




* fin.
