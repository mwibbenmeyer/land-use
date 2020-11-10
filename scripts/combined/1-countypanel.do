/* Programmer: Alexandra Thompson
Start Date: October 5, 2020
Objective: Merge cleaned net_returns and NRI county-year panel datasets
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

**************************************COUNTY PANEL**************************************

********************************************************************************
************ASSESS NRI-NR MERGE ISSUES************
********************************************************************************
* determine which fips do merge, regardless of year
* resources: 
	* https://www.nrcs.usda.gov/wps/portal/nrcs/detail/national/technical/nra/nri/results/?cid=nrcs143_013710
	* https://www.ddorn.net/data/FIPS_County_Code_Changes.pdf
use processing\NRI\nri15_county_panel, clear
keep fips state*
duplicates drop
merge 1:m fips using processing\net_returns\clean
keep fips _merge state*
duplicates drop
keep if _merge != 3
ta _merge
* notes
gen NRI_nr_mergenote = "999"
* unmatched from master
replace NRI_nr_mergenote = "NRI drop, no counterpart in nr" if fips == 56047 & _merge == 1 // "parts of 56029 & 56039 were used to create 56047" (but both 56029 & 56039 exist in both datasets)
replace NRI_nr_mergenote = "NRI leave, merged with adjacent counties (30031 and 30067) in 1997" if fips == 30113 & _merge == 1 // Yellowstone National Park territory (FIPS 30113) is merged into Gallantin (FIPS 30031) and Park (FIPS 30067) counties. Action: no adjustment of the source data required since all three territories map to the same CZ 34402.
replace NRI_nr_mergenote = "NRI leave, addressed in nr" if fips == 12025 & _merge == 1 // fips replaced in nr data to match
* unmatched from using
replace NRI_nr_mergenote = "nr replace 12086 with 12025 to match NRI" if fips == 12086  & _merge == 2 // 12025 (Dade County) renamed as 12086 (Miami-Dade), rev. to match NRI data
replace NRI_nr_mergenote = "nr drop, no counterpart in NRI" if fips == 8014 & _merge == 2 // Broomfield county created in 2001, doesn't exist in NRI data
replace NRI_nr_mergenote = "nr drop, no counterpart" if fips == 8031 & _merge == 2 // Denver county, small so not in NRI
replace NRI_nr_mergenote = "nr drop, no counterpart" if fips == 29510 & _merge == 2 // 29510 was collapsed into 29189 in NRI
replace NRI_nr_mergenote = "nr drop, DC not in NRI" if stateAbbrev == "DC"
assert stateAbbrev != "VA" if _merge == 1 // check no potential Virginia counterparts in NRI data
replace NRI_nr_mergenote = "nr drop, Virginia, no counterpart in NRI" if stateAbbrev == "VA" & _merge == 2
* check no others
assert NRI_nr_mergenote != "999"
drop _merge
compress
drop state
save processing\combined\nri_nr_mergenotes, replace

********************************************************************************
************IMPLEMENT NR-NRI MERGE************
********************************************************************************
* load and make changes to nr data
use processing\net_returns\clean, clear
merge m:1 fips using processing\combined\nri_nr_mergenotes
drop if _merge == 2 // drop if notes only relevant to NRI data
ta NRI_nr_mergenote // list notes
* implement notes changes ONLY IF INCREASE MERGE RATE, NO DROPS
	replace fips = 12025 if fips == 12086
drop NRI_nr_mergenote _merge
gen NRdata = 1 // tag if NR data (all obs in this dataset)

* merge to NRI data
merge 1:1 fips year using processing\NRI\nri15_county_panel
drop state county
gen NRIdata = _merge != 1 // tag if NRI data (all obs other than MASTER ONLY)
ren _merge NRI2_nr1_merge
merge m:1 fips using processing\combined\nri_nr_mergenotes
* drop if notes no longer relevant
	drop if _merge == 2 & fips == 12086
drop _merge

* drop years not in nri data
	gen tag = year == 1982 ///
			| year == 1987 ///
			| year == 1992 ///
			| year == 1997 ///
			| year == 2002 ///
			| year == 2007 ///
			| year == 2012
	drop if tag == 0
	drop tag

ta NRI_nr_mergenote // list notes
replace NRdata = 0 if NRdata == .
* save
compress
save processing\combined\nri_nr_county_panel, replace

********************************************************************************
************ASSESS NR/NRI-CRP MERGE ISSUES************
********************************************************************************
use processing\combined\nri_nr_county_panel, clear
keep fips state* NRI_nr_mergenote
duplicates drop
merge 1:m fips using processing\CRP\CRPmerged
keep fips _merge *state* *county* year NRI_nr_mergenote
keep if _merge != 3 // only make notes if unmatched from CRP
drop if year == 1982
drop year
duplicates drop
compress
sort fips
* notes
gen NRInr_CRP_mergenote = "999"
* unmatched from master
replace NRInr_CRP_mergenote = "CRP data explicitly exclude VA cities" if _merge == 1 & stateAbbrev == "VA"
replace NRInr_CRP_mergenote = "CRP data exclude DC" if _merge == 1 & stateAbbrev == "DC"
replace NRInr_CRP_mergenote = "nr drop, no counterpart in CRP" if fips == 8014 & _merge == 1 // Broomfield county created in 2001, doesn't exist in NRI data
replace NRInr_CRP_mergenote = "nr drop, no counterpart in CRP" if fips == 56047 & _merge == 1 // "parts of 56029 & 56039 were used to create 56047" (but both 56029 & 56039 exist in both datasets)
* unmatched from using (CRP)
drop if CRPstate == "PUERTO RICO" | CRPstate == "ALASKA" | CRPstate == "HAWAII"
assert _merge != 2
* check no others
assert NRInr_CRP_mergenote != "999"
drop _merge
compress
save processing\combined\nrinr_crp_mergenotes, replace

********************************************************************************
************IMPLEMENT NR/NRI-CRP MERGE************
********************************************************************************
use processing\CRP\CRPmerged, clear // load CRP panel
	gen CRPdata = 1 // tag CRP data
merge 1:1 fips year using processing\combined\nri_nr_county_panel // merge to NRI/NR panel
	ren _merge NRInr2_CRP1_merge
	* drop years/states not in nri data
	gen tag = year == 1982 ///
			| year == 1987 ///
			| year == 1992 ///
			| year == 1997 ///
			| year == 2002 ///
			| year == 2007 ///
			| year == 2012
	drop if tag == 0
	drop tag
	drop if CRPstate == "PUERTO RICO" | CRPstate == "ALASKA" | CRPstate == "HAWAII"
merge m:1 fips using  processing\combined\nrinr_crp_mergenotes // merge to mergenotes
	assert _merge != 2
	drop _merge
	ta NRInr_CRP_mergenote
drop CRPstate CRPcounty

* FINALIZE
local datavars NRdata NRIdata CRPdata
foreach var in `datavars' {
	replace `var' = 0 if `var' == .
	}
order state* fips year acresk* *data
compress
save processing\combined\nri_nr_crp_countypanel, replace
use processing\combined\nri_nr_crp_countypanel, clear
