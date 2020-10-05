/* Programmer: Alexandra Thompson
Date: October 5, 2020
Objective: transform raw NRI data into panel format
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* source data dir (dropbox)
global user = "thompson"
global sourcedir "C:\Users\\$user\Dropbox\NRI 2015\data"

* processing data dir
global workingdir "M:\GitRepos\land-use\processing\NRI"

********************************************************************************
***********IMPORT, SAVE RAW DATASETS*************
********************************************************************************
* load dataset, save version with reduced n variables (reduced size from ~1,500 MB to ~ 200 MB)

import delimited "$sourcedir\nri15_cty_082019.csv", clear
keep state county fips lcc* xfact crp9* crp0* crp1* broad* landu* riad_id // keep vars of interest
order riad_id
* rename variables with years from 2 digits to 4 to facilitate reshape
local prefix lcc crp landu broad
foreach var of local prefix {
rename `var'1* `var'201*
capture rename `var'7* `var'197*
capture rename `var'8* `var'198*
rename `var'9* `var'199*
rename `var'0* `var'200*
}
save "$workingdir\nri15_reduced.dta", replace

* import, save, trim classification table
import delimited "$sourcedir\replicated table\processed\classification.csv", clear
replace class2 = "UrbanLand" if class2 == "Urban land"
replace class2 = trim(class2)
save "$workingdir\classification.dta", replace

********************************************************************************
*************RESHAPE NRI DATA**********************
********************************************************************************
* load, reduce/manage dataset for land use, all years
use "$workingdir\nri15_reduced.dta", clear
gen acres = xfact * 100
gen acresk = acres / 1000
drop acres xfact
* keep only 48 contiguous US states
drop if state == 72 // PR
drop if state == 15 // HI

keep state county fips riad_id acresk landu* // keep vars of interest

collapse(sum) acresk, by(landu* state county fips) // collapse by fips

* merge with land use classification table, quality check that only classes intentionally omitted are omitted
foreach landuvar of varlist landu* {
rename `landuvar' landu
replace landu = 0 if landu == . // in 1979, missing data are missing, not zero. replace with zero for consistency.
merge m:1 landu using "$workingdir\classification.dta"

/* assert that unmatched from NRI data are those exluded from Lubowski et al. 2003 (Determinants of Land-Use Change in the United States 1982-1997) (RFF):
"We exclude from our analysis lands under rural roads and transportation as these land uses are likely to change through a
different decision-making process than profit maximization by private landowners. We also exclude
streams and water bodies, marshlands, and "barren lands" such as sand dunes, permanent snow
fields, and bare rock, as these are unlikely to respond to economic incentives. Finally, we exclude
other private lands which the NRI classifies under unspecified "miscellaneous" uses." 
401: "other farmland/other land"
611-620: "barren"
640: "other rural/marshland"
650: "all other land"
800: "rural transportation"
900: "water body <= 40 acresk"
910: streams <= 660 ft wide
920: Census water */

* tag landuses that ought to be omitted
gen omittedtag = landu == 401 | (landu >= 611 & landu <= 620) | landu == 640 | ///
	landu == 650 | landu == 800 | landu == 900 | landu == 910 | landu == 920

* check that only omitted land uses are unmerged
assert omittedtag == 1 if _merge == 1
* replace with missing
replace class2 = "Other" if omittedtag == 1 & _merge == 1

drop if _merge == 2

drop _merge omittedtag landu
rename class2 `landuvar'
}
collapse(sum) acresk, by (fips landu*) // collapse by fips

* generate variable for each land use (using 1997 classes)
levelsof landu1997, local(levels)
foreach l of local levels {
	gen lu_landu_`l' = .
	}

* generate variables for total acresk for each landuse-year combo
foreach landuvar of varlist landu* {
levelsof `landuvar', local(levels)
	foreach l of local levels{
	gen _`l'_`landuvar' = acresk if `landuvar' == "`l'"
	}
drop `landuvar'
}

collapse(sum) _*, by (fips) // collapse

* reshape
reshape long _CRP_landu _Cropland_landu _Forestland_landu _NA_landu _Pastureland_landu _Rangeland_landu _UrbanLand_landu _Other_landu, i(fips) j(year)
rename _*_landu *_acresk

* keep only years with data ["1982, 1987, 1992, 1997, and annually from 2000 through 2017" (https://www.nrcs.usda.gov/wps/portal/nrcs/main/national/technical/nra/nri/)]
keep if year == 1982 | year == 1987 | year == 1992 | year == 1997 | year == 2002 | year == 2007 | year == 2012
compress

********************************************************************************
*************CALCULATE ADDITIONAL VARIABLES AND FINALIZE**********************
********************************************************************************
* generate state fips
tostring fips, gen(fipsstring)
gen statefips = substr(fipsstring, 1, 2)
replace statefips = substr(fipsstring, 1, 1) if length(fipsstring)==4
destring statefips, replace
merge m:1 statefips using processing_output\stateFips
assert statefips == 11 if _merge == 1
drop if _merge == 2
drop _merge
replace stateName = "District of Columbia" if statefips == 11
replace stateAbbrev = "DC" if statefips == 11
drop fipsstring 

* calculate county totals
	* total
	egen fipstotal_acresk = rowtotal(*_acresk)
	label variable fipstotal_acresk "NRI total acres (thousands), including N/A and Other"
	* without N/A
	rename NA_acresk NA_acTEMPresk
	rename fipstotal_acresk fipstotal_acTEMPresk
	egen fipsnomi_acresk = rowtotal(*_acresk)
	label variable fipsnomi_acresk "NRI total acres (thousands), excl. N/A, incl. Other"
	* without N/A and without Other
	rename Other_acresk Other_acTEMPresk
	rename fipsnomi_acresk fipsnomi_acTEMPresk
	egen fips_acresk = rowtotal(*_acresk)
	label variable fips_acresk "NRI total acres (thousands), excl. N/A and Other"
	
	rename *TEMP* **

* % county area in each land use (using total area excluding N/A)
local vars CRP Cropland Forestland Pastureland Rangeland UrbanLand Other
foreach var of local vars {
gen `var'_pcnt = `var'_acresk / fipsnomi_acresk * 100
}

* check percents add up to 100
egen test = rowtotal(*_pcnt) 
assert test >= 99.9 & test <= 100.1
drop test

order state* fips year
compress
save "$workingdir\nri15_cleanpanel", replace

********************************************************************************
*************TOTAL AREA CALCULATION**********************
********************************************************************************
use "$workingdir\nri15_cleanpanel", clear
collapse(sum) fips*acresk, by(year)

* for qaqc, compare to results from adaptation of another programmer's code, "replicate_weilun_acres.do"
