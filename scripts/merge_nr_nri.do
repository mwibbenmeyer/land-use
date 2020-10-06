/* Programmer: Alexandra Thompson
Date: October 5, 2020
Objective: Merge cleaned net_returns and NRI county-year panel datasets
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* processing data dir
global workingdir "M:\GitRepos\land-use"

********************************************************************************
************ASSESS MERGE ISSUES************
********************************************************************************
* determine which fips do merge, regardless of year
* resources: 
	* https://www.nrcs.usda.gov/wps/portal/nrcs/detail/national/technical/nra/nri/results/?cid=nrcs143_013710
	* https://www.ddorn.net/data/FIPS_County_Code_Changes.pdf
use "$workingdir\processing\NRI\nri15_cleanpanel", clear
keep fips state*
duplicates drop
merge 1:m fips using "$workingdir\processing\net_returns\clean"
keep fips _merge state*
duplicates drop
keep if _merge != 3
ta _merge
* notes
gen note = "999"
* unmatched from master
replace note = "NRI drop, no counterpart" if fips == 56047 & _merge == 1 // "parts of 56029 & 56039 were used to create 56047" (but both 56029 & 56039 exist in both datasets)
replace note = "NRI replace with 12086" if fips == 12025 & _merge == 1 // 12025 (Dade County) renamed as 12086 (Miami-Dade)
replace note = "NRI drop, merged with adjacent" if fips == 30113 & _merge == 1
* unmatched from using
replace note = "nr drop, no counterpart" if fips == 8014 & _merge == 2 // Broomfield county created in 2001, doesn't exist in NRI data
replace note = "nr drop, no counterpart" if fips == 8031 & _merge == 2 // Denver county, small so not in NRI
replace note = "nr keep, addressed in NRI" if fips == 12086 & _merge == 2
replace note = "nr drop" if fips == 29510 & _merge == 2 // 29510 was collapsed into 29189 in NRI
replace note = "nr drop" if stateAbbrev == "DC"
assert stateAbbrev != "VA" if _merge == 1 // check no potential Virginia counterparts in NRI data
replace note = "nr drop, no counterpart" if stateAbbrev == "VA" & _merge == 2
* check no others
assert note != "999"
drop _merge
compress
save "$workingdir\processing\NRI\nri_nr_mergenotes", replace

********************************************************************************
************IMPLEMENT MERGE************
********************************************************************************
* make changes to NRI data
use "$workingdir\processing\NRI\nri15_cleanpanel", clear
merge m:1 fips using "$workingdir\processing\NRI\nri_nr_mergenotes"
drop if note == "NRI drop, no counterpart"
drop if note == "NRI drop, merged with adjacent"
replace fips = 12086 if fips == 12025 & note == "NRI replace with 12086"
drop _merge note

* merge
merge 1:1 fips year using "$workingdir\processing\net_returns\clean"
rename _merge merge
* drop years not in nri data
gen tag = year == 1982 | year == 1987 | year == 1992 | year == 1997 | year == 2002 ///
	| year == 2007 | year == 2012
drop if tag == 0
drop tag

* make changes to nr data
merge m:1 fips using "$workingdir\processing\NRI\nri_nr_mergenotes"
drop if _merge == 2
drop if note == "nr drop, no counterpart"
drop if note == "nr drop"
drop _merge note

ta merge
assert merge != 2 // check no unmatched from net returns. only unmatched should be years in NRI data.
drop merge

* save
compress
save "$workingdir\processing\NRI\nri_nr", replace
