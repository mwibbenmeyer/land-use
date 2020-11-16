/* Programmer: Alexandra Thompson
Start Date: October 15, 2020
Objective: Generate summary tables
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear
pause on

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir


********************************************************************************
************TABLES************
********************************************************************************
/*use processing\combined\nri_nr_crp_countypanel, clear
keep if data_NRI6classes == 1
gen datami_NRCRP = CRP_nr == . // temporary CRP_nr binary variable

*local nrvars 
foreach nrvar in `nrvars' crop urban forest CRP {
* count up missing & nonmissing obs by year
bysort year: egen total_`nrvar'nr_nonmi = sum(data_NR`nrvar' == 1)
bysort year: egen total_`nrvar'nr_mi = sum(datami_NR`nrvar' == 1)
* mean landuse % 



bysort year: egen total_cropnr_nonmi = sum(data_NRcrop == 1)
bysort year: egen total_cropnr_mi = sum(datami_NRcrop == 1)

local vars Crop 
bysort year: egen Crop_cropnr_nonmi = mean(Cropland_pcnt2) if data_NRcrop == 1
bysort year: egen Crop_cropnr_mi = mean(Cropland_pcnt2) if datami_NRcrop == 1


collapse(mean) *nr_nonmi *nr_mi, by(year)
order total*
*/

********************************************************************************
************GRAPHS************
********************************************************************************
use processing\combined\nri_nr_crp_countypanel, clear
keep if data_NRI6classes == 1
gen datami_NRCRP = CRP_nr == . // temporary CRP_nr binary variable

* rename vars for simple legends
foreach var in `renvars' Crop Urban Pasture Range Forest CRP {
ren `var'land_pcnt `var'
}

* gen kernel density graphs for obs w/ missing data and obs w/ nonmissing data
levelsof year, local(years)
foreach y of local years {
local vars urban crop forest CRP
foreach var in `vars' {
	* if missing
		qui count if datami_NR`var' == 1 & year == `y'
		twoway (kdensity Crop, lcolor(orange)) (kdensity Urban, lcolor(purple)) (kdensity Forest, lcolor(green)) (kdensity Pasture, lcolor(lime)) (kdensity Range, lcolor(teal)) (kdensity CRP, lcolor(magenta)) ///
			if datami_NR`var' == 1 & year == `y', ///
			subtitle("`var' net returns missing") ///
			caption(`r(N)' / 3072) xtitle("%") ///
			legend(rows(1))
			gr_edit legend.Edit, style(labelstyle(size(vsmall)))
			gr_edit legend.Edit , style(stacked(yes)) keepstyles 
			qui graph save "processing\combined\tempgraphs\mi_`var'_`y'.gph", replace
		*pause
	* if nonmissing
		qui count if datami_NR`var' == 0 & year == `y'
		twoway (kdensity Crop, lcolor(orange)) (kdensity Urban, lcolor(purple)) (kdensity Forest, lcolor(green)) (kdensity Pasture, lcolor(lime)) (kdensity Range, lcolor(teal)) (kdensity CRP, lcolor(magenta)) ///
			if datami_NR`var' == 0 & year == `y', ///
			subtitle("`var' net returns not missing") ///
			caption(`r(N)' / 3072) xtitle("%")
			qui graph save "processing\combined\tempgraphs\nomi_`var'_`y'.gph", replace
		*pause
	}
}

* combined graphs, export
local vars urban crop forest CRP
foreach var in `vars' {
levelsof year, local(years)
foreach y of local years {
	grc1leg ///
	"processing\combined\tempgraphs\mi_`var'_`y'.gph" ///
	"processing\combined\tempgraphs\nomi_`var'_`y'.gph", ///
	ycommon rows(1) ///
	title("`y'")
	* qui graph save "processing\combined\tempgraphs\allgraphs_`var'_`y'.gph", replace			
	graph export "results\initial_descriptives\combined\graphs_missingNR_by_LU\kerneldensityoverlay_`var'_`y'.png", replace
	*pause
	}
	}
* a mess, don't export these:
local vars urban crop forest CRP
foreach var in `vars' {
	grc1leg ///
	"processing\combined\tempgraphs\allgraphs_`var'_1982.gph" ///
	"processing\combined\tempgraphs\allgraphs_`var'_1987.gph" ///
	"processing\combined\tempgraphs\allgraphs_`var'_1992.gph" ///
	"processing\combined\tempgraphs\allgraphs_`var'_1997.gph" ///
	"processing\combined\tempgraphs\allgraphs_`var'_2002.gph" ///
	"processing\combined\tempgraphs\allgraphs_`var'_2007.gph" ///
	"processing\combined\tempgraphs\allgraphs_`var'_2012.gph"
	pause
	}


* CLEANUP
levelsof year, local(years)
foreach y of local years {
	capture erase processing\combined\tempgraphs\all_`y'.gph
	capture erase processing\combined\tempgraphs\allgraphs_`y'.gph
local vars urban crop forest CRP
foreach var in `vars' {
	capture erase processing\combined\tempgraphs\allgraphs_`var'_`y'.gph
	capture erase processing\combined\tempgraphs\mi_`var'_`y'.gph
	capture erase processing\combined\tempgraphs\nomi_`var'_`y'.gph
}
}

