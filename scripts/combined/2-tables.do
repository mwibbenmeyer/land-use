/* Programmer: Alexandra Thompson
Start Date: October 15, 2020
Objective: Generate summary tables
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

*******mean percent county area & mean net return value*****************************
* by year
	use processing\combined\nri_nr_county_panel, clear
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
	order year Cropland* CRPland* Forestland* Pastureland* Rangeland* Urbanland* lccNA* lccL* *nr
	xpose, varname clear
	order _varname
	export excel using results\initial_descriptives\combined\sumtable_countymeans.xlsx, replace
	
* weighed by measured county area, by year
ssc inst _gwtmean
	use processing\combined\nri_nr_county_panel, clear
	* summarize 
		* su landu, weighed by measured land use area
		local vars Crop Forest Pasture Range CRP Urban
		levelsof year, local(years)
		foreach var in `vars' {
			foreach y of local years {
			di `y'
			su `var'land_pcnt [w=acresk_6classes] if year == `y'
			}
		}
		* su LCC, weighed by measured LCC area 
		foreach var of varlist lcc*pcnt {
		levelsof year, local(years)
			foreach y of local years {
			di `y'
			su `var' [w=acresk_6classes] if year == `y'
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
		local vars Crop Forest Pasture Range CRP Urban
		foreach var in `vars' {
		egen wtmean_`var'land_pcnt = wtmean(`var'land_pcnt), weight(acresk_6classes) by(year)
		}
		* LCC
		foreach var of varlist lcc*pcnt {
		egen wtmean_`var' = wtmean(`var'), weight(acresk_6classes) by(year)
		}
		* net returns
		egen wtmean_crop_nr = wtmean(crop_nr), weight(acresk_6classes) by(year)
		egen wtmean_forest_nr = wtmean(forest_nr), weight(acresk_6classes) by(year)
		egen wtmean_urban_nr = wtmean(urban_nr), weight(acresk_6classes) by(year)
	* create table
	keep year wtmean*
	duplicates drop
	rename wtmean_* *
	sort year 
	order year Cropland* CRPland* Forestland* Pastureland* Rangeland* Urbanland* lccNA* lccL* *nr
	xpose, varname clear
	order _varname
	export excel using results\initial_descriptives\combined\sumtable_countymeans_weighted.xlsx, replace

*******LAND USE SUMMARY TABLE*****************************
use processing\combined\nri_nr_county_panel, clear
collapse(sum) *_acresk, by (year)
export excel using results\initial_descriptives\combined\landu_lcc_totalarea.xlsx, firstrow(variables) replace

*******LAND USE BY LCC TABLE*****************************
use processing\NRI\nri15_point_panel, clear
	* keep if riad_id < 5 // debugging
* egen total land use by year
bysort year: egen acresk_total = sum(acresk)
* rename lccNA lcc0
ren lccNA_acresk lccL0_acresk
* generate lcc binaries
forvalues x = 0/8 {
gen lccL`x' = lccL`x'_acresk > 0
}
drop lccL*_acresk
compress
* calculate total landu acres by LCC level
* pseudocode/debugging:
	* bysort lccL1 year: egen Cropland_lccL1_acres = sum(Cropland_acresk)
	/*forvalues x = 0/8 {
	bysort lccL`x' year: egen Cropland_lccL`x'_acresk = sum(Cropland_acresk) // calculate total landu acres by year and LCC level
	replace Cropland_lccL`x'_acresk = 0 if lccL`x' == 0 // replace value with zero if LCC level binary is zero
	}*/
foreach landuvar of varlist *land* {
	forvalues x = 0/8 {
		bysort lccL`x' year: egen `landuvar'_lccL`x' = sum(`landuvar') // calculate total landu acres by year and LCC level
		replace `landuvar'_lccL`x' = 0 if lccL`x' == 0 // replace value with zero if LCC level binary is zero
		gen `landuvar'_lccL`x'_pcnt = `landuvar'_lccL`x'/acresk_total*100
		ren *_acresk_lccL*_pcnt *_lccL*_pcnt
		drop `landuvar'_lccL`x'
	}
}
compress
* drop vars & duplicates
foreach landuvar of varlist *land_acresk {
drop `landuvar'
}
forvalues x = 0/8 {
drop lccL`x'
}
drop state* fips county riad acresk acresk_total
duplicates drop
* collapse
collapse(sum) *pcnt, by (year)
* reshape
ren *land_lcc*_pcnt *land_*
reshape long Cropland_L CRPland_L Forestland_L Pastureland_L Rangeland_L Urbanland_L Waterland_L Federalland_L Ruralland_L, i(year) j(lccL)
ren *land_L *land
ren lccL LCC
tostring LCC, replace
replace LCC = "N/A" if LCC == "0"
* finalize
order year LCC Range* Forest* Crop* Pasture* Urban* CRP* Federal* Rural* Water*
sort year LCC*
compress
save processing\NRI\nri15_point_landu_lcc_pcnt, replace
* export tables
use processing\NRI\nri15_point_landu_lcc_pcnt, clear
	* export 1 table for each year
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx if year == 1982, sheet("1982") sheetreplace firstrow(variables)
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx if year == 1987, sheet("1987") sheetreplace firstrow(variables)
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx if year == 1992, sheet("1992") sheetreplace firstrow(variables)
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx if year == 1997, sheet("1997") sheetreplace firstrow(variables)
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx if year == 2002, sheet("2002") sheetreplace firstrow(variables)
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx if year == 2007, sheet("2007") sheetreplace firstrow(variables)
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx if year == 2012, sheet("2012") sheetreplace firstrow(variables)
	* mean
	collapse(mean) *land, by (LCC)
	export excel using results\initial_descriptives\NRI\pcnt_landu_by_lcc.xlsx, sheet("mean") sheetreplace firstrow(variables)
