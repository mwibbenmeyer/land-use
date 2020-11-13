/* Programmer: Alexandra Thompson
Start Date: November 9, 2020
Objective: Create point-level panel
*/
clear all

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

* load county-level panel
use processing\combined\nri_nr_crp_countypanel, clear
* drop non-NRI data
drop *land_* lcc*_*
* rename vars
ren acresk county_acresk
* ren acresk_6classes county_acresk6classes
drop acresk_6classes 
* merge to point-level NRI dataset by county
merge 1:m fips year using processing\NRI\nri15_point_panel
	assert _merge != 2 // check no unmatched from NRI point data
	assert data_NRI == 0 if _merge == 1 // check that unmatched from county panel are only those with no NRI data
	drop _merge
ren acresk point_acresk
order state* county* fips riad_id year point_acresk *data*
sort stateName fips riad_id year
* save
compress
save processing\combined\nri_nr_crp_pointpanel, replace
use processing\combined\nri_nr_crp_pointpanel, clear
