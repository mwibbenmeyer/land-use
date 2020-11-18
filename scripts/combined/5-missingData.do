/* Programmer: Alexandra Thompson
Start Date: October 15, 2020
Objective: For each net return variable and year, kernel density of land use percent in 
	counties with and without missing data value
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear
pause on
net install grc1leg.pkg

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

* globals
global luvars Crop Urban Pasture Range Forest CRP Federal Rural Water
global nrvars urban crop forest CRP

********************************************************************************
************GRAPHS************
********************************************************************************
/* forest nr example for debugging:
*use processing\combined\nri_nr_crp_countypanel, clear
keep if data_NRI6classes == 1
gen datami_NRCRP = CRP_nr == . // temporary CRP_nr binary variable
gen missing = Forest if datami_NRforest == 1
gen nonmissing = forest if data_NRforest == 1
count if datami_NRforest == 1
twoway (kdensity missing, lcolor(red)) (kdensity nonmissing, lcolor(blue)), ///
	caption(`r(N)' / 3072 missing) ///
	xtitle(% Forest) ///
	title(Missing Forest Net Returns)
*/

use processing\combined\nri_nr_crp_countypanel, clear
levelsof year, local(years)
foreach y of local years {
foreach nr in $nrvars  {
global graphnames
foreach lu in $luvars {
	* load
	cd $workingdir
	use processing\combined\nri_nr_crp_countypanel, clear
	keep if year == `y'
	keep if data_NRI6classes == 1
	* temporary CRP_nr binary variables
	gen datami_NRCRP = CRP_nr == .
	gen data_NRCRP = CRP_nr != .
	* generate percent land use vars by data availability
	gen missing = `lu'land_pcnt2 if datami_NR`nr' == 1
	gen nonmissing = `lu'land_pcnt2 if data_NR`nr' == 1
	* graph
	twoway (kdensity missing if missing!=., lcolor(red)) (kdensity nonmissing if nonmissing != ., lcolor(blue)), ///
		xtitle(% `lu')
	gr_edit xaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(vsmall)))) editcopy
	gr_edit yaxis1.style.editstyle majorstyle(tickstyle(textstyle(size(vsmall)))) editcopy
	 pause
	* save
	local graphname "kdens_`y'_`nr'nr_`lu'.gph"
	qui graph save "processing\combined\tempgraphs\\`graphname'", replace
	qui graph export "processing\combined\tempgraphs\\kdens_`y'_`nr'nr_`lu'.png", replace
	global graphnames $graphnames `graphname'
	}
* combine
count if datami_NR`nr' == 1
cd processing\combined\tempgraphs
grc1leg $graphnames, ///
	title(Land Use Distributions - counties missing `nr' net returns) ///
	subtitle(`y') ///
	caption(`r(N)' / 3072 missing)
	gr_edit title.style.editstyle size(medium) editcopy
	gr_edit subtitle.style.editstyle size(medsmall) editcopy
	gr_edit caption.style.editstyle size(small) editcopy
	gr_edit legend.Edit, style(labelstyle(size(small)))
	gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
	gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
* save
cd $workingdir
qui graph export "results\initial_descriptives\combined\graphs_missingNR_by_LU\kdensLU_`nr'nr_`y'.png", replace
}
}

* CLEANUP (.gph files only)
use processing\combined\nri_nr_crp_countypanel, clear
levelsof year, local(years)
foreach y of local years {
foreach nr in $nrvars  {
foreach lu in $luvars {
capture erase processing\combined\tempgraphs\kdens_`y'_`nr'nr_`lu'.gph
}
}
}

********************************************************************************
************MAPS************
********************************************************************************

* mapping setup
ssc install maptile
ssc install spmap
ssc install shp2dta
maptile_install using "http://files.michaelstepner.com/geo_county2010.zip"
capture net install grc1leg2.pkg

* load, setup
use processing\combined\nri_nr_crp_countypanel, clear
collapse(mean) *pcnt* *acresk*, by(year fips)
keep year *_pcnt2 fips
rename fips county


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
use processing\combined\nri_nr_crp_countypanel, clear
local vars Federal CRP Crop Forest Pasture Range Urban Water Rural
levelsof year, local(levels)
foreach v of local vars {
	foreach l of local levels {
	foreach nr in $nrvars  {
		* load
		use processing\combined\nri_nr_crp_countypanel, clear
		keep if data_NRI6classes == 1
		* temporary CRP_nr binary variables
		gen datami_NRCRP = CRP_nr == .
		gen data_NRCRP = CRP_nr != .
		qui keep if year == `l'
		collapse(mean) *pcnt*, by(fips datami_NR`nr' data_NR`nr')
		rename fips county
		* calculate percentile breaks for all values
		pctile `v'_nq5breaks = `v'land_pcnt2, nq(5)
		* missing
		maptile `v'land_pcnt2 if datami_NR`nr' == 1, geo(county2010) cutp(`v'_nq5breaks) fcolor(``v'_colors')
		*gr_edit subtitle.text.Arrpush "`nr' net returns missing"
		gr_edit title.text.Arrpush "Percent `v'"
		gr_edit legend.Edit , style(rows(1)) style(cols(0)) keepstyles 
		gr_edit legend.Edit, style(labelstyle(size(tiny)))
		gr_edit legend.style.editstyle box_alignment(south) editcopy
		* pause
		graph save "processing\combined\tempgraphs/`v'_pcnt_`nr'nrMiss_`l'", replace
		* nonmissing
		maptile `v'land_pcnt2 if data_NR`nr' == 1, geo(county2010) cutp(`v'_nq5breaks) fcolor(``v'_colors')
		*gr_edit subtitle.text.Arrpush "`nr' net returns nonmissing"
		gr_edit title.text.Arrpush "Percent `v'"
		gr_edit legend.Edit , style(rows(1)) style(cols(0)) keepstyles 
		gr_edit legend.Edit, style(labelstyle(size(tiny)))
		gr_edit legend.style.editstyle box_alignment(south) editcopy
		* pause
		graph save "processing\combined\tempgraphs/`v'_pcnt_`nr'nrNonmiss_`l'", replace
	}
	}
	}

* combine
cd $workingdir
use processing\combined\nri_nr_crp_countypanel, clear
levelsof year, local(levels)
foreach l of local levels {
foreach nr in $nrvars  {
graph combine ///
		processing\combined\tempgraphs\Crop_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\Urban_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\Pasture_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\Range_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\Forest_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\CRP_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\Federal_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\Rural_pcnt_`nr'nrMiss_`l'.gph ///
		processing\combined\tempgraphs\Water_pcnt_`nr'nrMiss_`l'.gph, ///
		subtitle("`l'")
		gr_edit subtitle.text.Arrpush "`nr' net returns missing"
		gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
		* pause
		graph export "results\initial_descriptives\combined\maps_missingNR_by_LU\LUpcnt_`l'_`nr'nr_missing.png", replace
		
	graph combine ///
		processing\combined\tempgraphs\Crop_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\Urban_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\Pasture_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\Range_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\Forest_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\CRP_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\Federal_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\Rural_pcnt_`nr'nrNonmiss_`l'.gph ///
		processing\combined\tempgraphs\Water_pcnt_`nr'nrNonmiss_`l'.gph, ///
		subtitle("`l'")
		gr_edit subtitle.text.Arrpush "`nr' net returns nonmissing"
		gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
		* pause
		graph export "results\initial_descriptives\combined\maps_missingNR_by_LU\LUpcnt_`l'_`nr'nr_nonmissing.png", replace
}
}

* cleanup
use processing\combined\nri_nr_crp_countypanel, clear
local vars Federal CRP Crop Forest Pasture Range Urban Water Rural
levelsof year, local(levels)
foreach nr in $nrvars  {
foreach lu of $luvars {
	foreach l of local levels {
		erase "processing\combined\tempgraphs/`v'_pcnt_`nr'nrMiss_`l'"
		erase "processing\combined\tempgraphs/`v'_pcnt_`nr'nrNonmiss_`l'""
		}
	}
