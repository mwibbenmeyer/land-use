/* Programmer: Alexandra Thompson
Start Date: October 5, 2020
Objective: transform raw NRI data into panel format
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
***********IMPORT, SAVE RAW DATASETS*************
********************************************************************************
* load dataset, save version with reduced n variables (reduced size from ~1,500 MB to ~ 200 MB)
import delimited raw_data\NRI\nri15_cty_082019.csv, clear
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
gen acres = xfact * 100
gen acresk = acres / 1000
drop acres xfact
* keep only 48 contiguous US states
drop if state == 72 // PR
drop if state == 15 // HI
save processing\NRI\nri15_reduced.dta, replace

* import, save, trim classification table
import delimited raw_data\NRI\classification.csv, clear
replace class2 = "Urbanland" if class2 == "Urban land"
replace class2 = "CRPland" if class2 == "CRP"
replace class2 = trim(class2)
save processing\NRI\classification.dta, replace

********************************************************************************
*************RESHAPE NRI LAND USE DATA**********************
********************************************************************************
* some area exploration to get a sense of prevalence of landu measurements
use processing\NRI\nri15_reduced.dta, clear
	* overall
	gen landu = landu1982 != . | landu1987 != . | landu1992 != . | landu1997 != . | landu2002 != . | landu2007 != . | landu2012 != . // tag if any landu data
	assert landu == 1 // check that all points have landu data at least 1 year

* manage landu variables
use processing\NRI\nri15_reduced.dta, clear
keep state county fips riad_id acresk landu* // keep vars of interest
collapse(sum) acresk, by(landu* state county fips) // collapse by fips
* merge with land use classification table, quality check that only classes intentionally omitted are omitted
foreach landuvar of varlist landu* {
rename `landuvar' landu
replace landu = 0 if landu == . // in 1979, missing data are missing, not zero. replace with zero for consistency.
merge m:1 landu using processing\NRI\classification.dta

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
* replace with "Other"
replace class2 = "Otherland" if omittedtag == 1 & _merge == 1

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
reshape long _CRPland_landu _Cropland_landu _Forestland_landu _NA_landu _Pastureland_landu _Rangeland_landu _Urbanland_landu _Otherland_landu, i(fips) j(year)
rename _*_landu *_acresk

* keep only years with data ["1982, 1987, 1992, 1997, and annually from 2000 through 2017" (https://www.nrcs.usda.gov/wps/portal/nrcs/main/national/technical/nra/nri/)]
keep if year == 1982 | year == 1987 | year == 1992 | year == 1997 | year == 2002 | year == 2007 | year == 2012

* CRP wasn't established until 1985. replace values prior to then with zero.
replace CRPland_acresk = 0 if year < 1985

compress

********************************************************************************
*************CALCULATE ADDITIONAL LAND USE VARIABLES **********************
********************************************************************************
* generate state fips
tostring fips, gen(fipsstring)
gen statefips = substr(fipsstring, 1, 2)
replace statefips = substr(fipsstring, 1, 1) if length(fipsstring)==4
destring statefips, replace
merge m:1 statefips using raw_data\stateFips
assert statefips == 11 if _merge == 1
drop if _merge == 2
drop _merge
replace stateName = "District of Columbia" if statefips == 11
replace stateAbbrev = "DC" if statefips == 11
drop fipsstring 

* calculate county totals
	* total
	egen fipsacresk_nri = rowtotal(*_acresk)
	label variable fipsacresk_nri "NRI total landu ac. (thousands), including N/A and Other"
	* without N/A
	rename NA_acresk NA_acTEMPresk
	rename fipsacresk_nri fipsacresk_TEMPnri
	egen fipsacresk_landunomi = rowtotal(*_acresk)
	label variable fipsacresk_landunomi "NRI total landu ac. (thousands), excl. N/A, incl. Other"
	* without N/A and without Other
	rename Otherland_acresk Otherland_acTEMPresk
	rename fipsacresk_landunomi fipsacresk_TEMPlandunomi
	egen fipsacresk_landunooth = rowtotal(*_acresk)
	label variable fipsacresk_landunooth "NRI total landu ac. (thousands), excl. N/A and Other"
	
	rename *TEMP* **

* % county area in each land use (using total area excluding N/A)
local vars CRPland Cropland Forestland Pastureland Rangeland Urbanland /*Otherland*/
foreach var of local vars {
gen `var'_pcnt = `var'_acresk / fipsacresk_landunooth * 100
}

* check percents add up to 100 - COMMENTED OUT AFTER REMOVING 'OTHERLAND' FROM PERCENT CALCULATION. 14 rows are entirely missing or otherland and have zero 'test' values.
/*egen test = rowtotal(*_pcnt) 
assert test >= 99.9 & test <= 100.1
drop test */

order state* fips year
compress
save processing\NRI\nri15_landuvars, replace

********************************************************************************
*************TOTAL AREA CALCULATION**********************
********************************************************************************
use processing\NRI\nri15_landuvars, clear
collapse(sum) fipsacresk*, by(year)
* for qaqc, compare to results from adaptation of another programmer's code, "replicate_weilun_acres.do"

********************************************************************************
*************LCC VARIABLES **********************
********************************************************************************
* some area exploration to get a sense of LCC measurement prevalence
use processing\NRI\nri15_reduced.dta, clear
	* overall
	gen lcc = lcc1982 != "" | lcc1987 != "" | lcc1992 != "" | lcc1997 != "" | lcc2002 != "" | lcc2007 != "" | lcc2012 != "" // tag if any LCC data
	ta lcc // n points with any LCC data
	bysort lcc: egen sumlccacresk = sum(acresk) // calculcate area with and without LCC data
	ta sumlccacresk if lcc == 1 // total area with LCC data
	ta sumlccacresk if lcc == 0 // total area without LCC data
	* by county
	bysort fips: egen sumacresk = sum(acresk) // total fips area
	bysort lcc fips: egen sumlccfipsacresk = sum(acresk)
	keep lcc fips sumlccfipsacresk sumacresk
	duplicates drop
	gen pcntarealcc = sumlccfipsacresk/sumacresk * 100
	su pcntarealcc if lcc == 1 // percent of county area with LCC data
	hist pcntarealcc if lcc == 1, freq title(Percent of County Area with LCC Data) subtitle (In Any Year)
	window manage close graph
	
******	
* manage LCC variables (reshape to panel)
use processing\NRI\nri15_reduced.dta, clear
keep state county fips riad_id acresk lcc* // keep vars of interest
collapse(sum) acresk, by(lcc* state county fips) // collapse by fips

* split lcc ("Land Capability Class & Subclass - source: current linked soil mapunit/component (The first character is the soil suitability rating for agriculture, between 1 and 8 - class 1 soil has few restrictions that limit its use, class 8 soil has limitations that nearly preclude its use for commercial crop production. The second character is the chief limitation of the soil: Blank = Not applicable, E = Erosion, W = Water, S = Shallow, drought, or stony, C = Climate))
foreach var of varlist lcc* {
gen `var'A = substr(`var', 1, 1)
drop `var'
rename `var'A `var'
destring `var', replace
	forvalues x = 1/8 {
	gen lccL`x'_`var' = acresk if `var' == `x'
	}
drop `var'
}

collapse(sum) lcc*, by(state county fips)

reshape long lccL1_lcc lccL2_lcc lccL3_lcc lccL4_lcc lccL5_lcc lccL6_lcc lccL7_lcc lccL8_lcc, i(fips) j(year)
ren lccL*_lcc lccL*_acresk

egen fipsacresk_lcc = rowtotal(*_acresk)
label variable fipsacresk_lcc "NRI total LCC ac. (thousands), excl. no data"

* generate combined LCC (as in Lubowski 2006)
gen lccL12_acresk = lccL1_acresk + lccL2_acresk
gen lccL34_acresk = lccL3_acresk + lccL4_acresk
gen lccL56_acresk = lccL5_acresk + lccL6_acresk
gen lccL78_acresk = lccL7_acresk + lccL8_acresk

* % county area in each lcc (using total area with lcc data)
foreach var of varlist lcc* {
gen `var'_pcnt = `var' / fipsacresk_lcc * 100
}
rename lcc*_acresk_pcnt lcc*_pcnt

save processing\NRI\nri15_lccvars, replace

********************************************************************************
*************MERGE LAND USE AND LCC VARIABLES **********************
********************************************************************************
use processing\NRI\nri15_landuvars, clear
merge 1:1 fips year using processing\NRI\nri15_lccvars
drop if _merge == 2 & year == 2015
assert _merge == 3
drop _merge

order state* county fips year fips*acresk*

save processing\NRI\nri15_cleanpanel, replace
use processing\NRI\nri15_cleanpanel, clear
