/* Programmer: Alexandra Thompson
Start Date: October 15, 2020
Objective: 
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear
ssc inst _gwtmean

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

********************************************************************************
************GENERATE SUMMARY TABLES************
*******mean percent county area & mean net return value*****************************
* by year
	use processing\combined\nri_nr, clear
	* summarize
		* su landu
		su *land_pcnt
		* su LCC
		su lcc*pcnt
		* su nr
		su *_nr
	* create table
	collapse(mean) *pcnt* *_nr, by(year)
	sort year 
	order year Cropland* CRPland* Forestland* Otherland* Pastureland* Rangeland* Urbanland* lccL* *nr
	xpose, varname clear
	order _varname
	export excel using results\initial_descriptives\combined\sumtable_countymeans.xlsx, replace
	
* weighed by measured county area, by year
	use processing\combined\nri_nr, clear
	* summarize 
		* su landu, weighed by measured land use area
		local vars Crop Forest Pasture Range Other CRP
		levelsof year, local(years)
		foreach var in `vars' {
			foreach y of local years {
			di `y'
			su `var'land_pcnt [w=`var'land_acresk] if year == `y'
			}
		}
		* su LCC, weighed by measured LCC area 
		forvalues x = 1/8 {
		levelsof year, local(years)
			foreach y of local years {
			di `y'
			su lccL`x'_pcnt [w=lccL`x'_acresk] if year == `y'
			}
		}
		* net returns, weighed by county acreage in each land use
		levelsof year, local(years)
		foreach y of local years {
		di `y'
		su crop_nr [w=Cropland_acresk] if year == `y'
		su forest_nr [w=Forestland_acresk] if year == `y'
		su urban_nr [w=Urbanland_acresk] if year == `y'
		}
	* generate weighted means
		* landu
		local vars Crop Forest Pasture Range Other CRP Urban
		foreach var in `vars' {
		egen wtmean_`var'land_pcnt = wtmean(`var'land_pcnt), weight(`var'land_acresk) by(year)
		}
		* LCC
		forvalues x = 1/8 {
		egen wtmean_lccL`x'_pcnt = wtmean(lccL`x'_pcnt), weight(lccL`x'_acresk) by(year)
		}
		* net returns
		egen wtmean_crop_nr = wtmean(crop_nr), weight(Cropland_acresk) by(year)
		egen wtmean_forest_nr = wtmean(forest_nr), weight(Forestland_acresk) by(year)
		egen wtmean_urban_nr = wtmean(urban_nr), weight(Urbanland_acresk) by(year)
	* create table
	keep year wtmean*
	duplicates drop
	rename wtmean_* *
	sort year 
	order year Cropland* CRPland* Forestland* Otherland* Pastureland* Rangeland* Urbanland* lccL* *nr
	xpose, varname clear
	order _varname
	export excel using results\initial_descriptives\combined\sumtable_countymeans_weighted.xlsx, replace


