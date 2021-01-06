********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

use processing\combined\pointpanel.dta, clear
/*
keep riad_id
duplicates drop
sample 1
merge 1:m riad_id using processing\combined\pointpanel.dta
keep if _merge == 3
drop _merge
compress
save processing\combined\pointpanel_sample, replace
use processing\combined\pointpanel_sample, clear
*/
keep riad fips year *acresk fips stateAbbrev countyName
sort riad year

drop CRPacresk

* gen initial use (current)
gen initial_use = "999"
local vars CRP Forest Pasture Range Urban Crop Water Rural Federal
foreach var in `vars' {
	replace initial_use = "`var'" if `var'land_acresk == point_acresk
}
assert initial_use != "999"

* gen final use (next stage)
su year
gen maxyear = r(max)
sort riad year
local vars CRP Forest Pasture Range Urban Crop Water Rural Federal
foreach var in `vars' {
gen final_`var'land_acresk = `var'land_acresk[_n+1]
replace final_`var'land_acresk = . if year == maxyear
}
gen final_use = "999"
local vars CRP Forest Pasture Range Urban Crop Water Rural Federal
foreach var in `vars' {
	replace final_use = "`var'" if final_`var'land_acresk == point_acresk
	}
replace final_use = "." if final_use == "999" & year == maxyear
assert final_use != "999"
drop if year == maxyear
drop maxyear

label variable initial_use "current land use"
label variable final_use "land use in t+5"

* LCC var
gen lcc = "999"
	replace lcc = "1_2" if lccL12_acresk == point_acresk
	replace lcc = "3_4" if lccL34_acresk == point_acresk
	replace lcc = "5_6" if lccL56_acresk == point_acresk
	replace lcc = "7_8" if lccL78_acresk == point_acresk
*	replace lcc = "NA" if lccNA_acresk == point_acresk
* check that only zeros are if lu is water, rural, urban, federal
gen tag = initial_use == "Water" | initial_use == "Federal" | initial_use == "Urban" | initial_use == "Rural"
assert tag == 1 if lcc == "999"
replace lcc = "0" if lcc == "999"
drop tag

label variable lcc "Land Capability Class"

* save point-level
ren point_acresk acresk
keep riad_id year initial_use final_use lcc acresk fips countyName stateAbbrev
order stateAbbrev countyName fips riad_id year acresk initial_use final_use
compress
save processing\combined\pointpanel_estimation, replace
* make a random sample
use processing\combined\pointpanel_estimation, clear
keep riad_id
duplicates drop
sample 1
sample 25
sample 25
sample 25
sample 25
sample 25
merge 1:m riad_id using processing\combined\pointpanel_estimation
keep if _merge == 3
drop _merge
compress
sort riad year
compress
save processing_output\pointpanel_estimation_sample, replace
use processing_output\pointpanel_estimation_sample, clear

* make county-level dataset
use processing\combined\pointpanel_estimation, clear
* gen n = 1 for parcels
gen parcels = 1
* collapse to county
collapse(sum) parcels acresk, by (stateAbbrev countyName fips year initial_use final_use lcc)
* var management
label variable parcels "n parcels in county with these attributes (initial LU, final LU, lcc)"
label variable acresk "thousand acres in county with these attributes (initial LU, final LU, lcc)"
sort fips year
* save county-level
order stateAbbrev countyName fips year parcels acresk initial_use final_use
compress
save processing\combined\countypanel_estimation, replace
* make a random sample
use processing\combined\countypanel_estimation, clear
keep fips
duplicates drop
sample 1
sample 25
merge 1:m fips using processing\combined\countypanel_estimation
keep if _merge == 3
drop _merge
compress
sort fips year
save processing_output\countypanel_estimation_sample, replace
use processing_output\countypanel_estimation_sample, clear
