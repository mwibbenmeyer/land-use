/* 
Author: Matt Wibbenmeyer
Date: June 8, 2021
Purpose: Weight other returns by land in final land use
*/ 

* working dir
global workingdir "F:\Projects\land-use"
cd $workingdir

/* Create weights for other returns based on acreage in each 'other' use initially */

use "processing_output/pointpanel_estimation_unb.dta", clear
drop if initial_use == "Federal" | initial_use == "Water" | initial_use == "Rural"
collapse (sum) acresk, by(fips year initial_use)

gen id = fips + string(year)
reshape wide acresk, i(id) j(initial_use) string

foreach var in acreskCRP acreskPasture acreskRange {
	replace `var' = 0 if `var' == .
}

gen total_other = acreskCRP + acreskPasture + acreskRange
gen weightCRP = acreskCRP/total_other
gen weightPasture = acreskPasture/total_other
gen weightRange = acreskRange/total_other

keep fips year weight*

tempfile tmp
save "`tmp'"

/* Merge weights with combined returns panel */

use processing\net_returns\combined_returns_panel, clear

gen str5 fips_str = string(fips,"%05.0f")
drop fips
rename fips_str fips
order fips, before(stateName)

merge 1:1 fips year using "`tmp'"

gen other_nr = weightCRP*CRP_nr + weightPasture*pasture_nr + weightRange*range_nr if CRP_nr != . &  pasture_nr != . & range_nr != .
replace other_nr = CRP_nr if weightCRP == 1
replace other_nr = pasture_nr if weightPasture == 1
replace other_nr = range_nr if weightRange == 1

drop weight* _merge

save processing\net_returns\combined_returns_panel_other, replace
