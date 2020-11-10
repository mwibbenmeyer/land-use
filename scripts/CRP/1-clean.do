/* Programmer: Alexandra Thompson
Start Date: November 6, 2020
Objective: Import, clean Conservation Reserve Program (CRP) data
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

* IMPORT, MANAGE, SAVE
* acres
	import excel raw_data\CRP\HistoryCounty86-19.xlsx, sheet("ACRES") cellrange(A2:AK3083) firstrow allstring clear
	do scripts\CRP\1-clean_sub1.do
	ren y CRPacres
	gen CRPacresk = CRPacres/1000
	drop CRPacres
	label variable CRPacresk "Thousand acres in CRP (USDA County Stats)"
	compress
	save processing\CRP\acres, replace

* rent
	import excel raw_data\CRP\HistoryCounty86-19.xlsx, sheet("RENT") cellrange(A2:AJ3083) firstrow allstring clear
	do scripts\CRP\1-clean_sub1.do
	ren y CRPrent
	label variable CRPrent "CRP Contract-based FY rental payments (not actuals) (USDA County Stats)"
	compress
	save processing\CRP\rent, replace

* average
	import excel raw_data\CRP\HistoryCounty86-19.xlsx, sheet("AVERAGE") cellrange(A2:AK3083) firstrow allstring clear
	do scripts\CRP\1-clean_sub1.do
	ren y CRP_nr
	label variable CRP_nr "avg per-CRPacre contract-based FY rent payments (not actuals) (USDA County Stats)"
	save processing\CRP\avg, replace

* MERGE
use processing\CRP\acres, clear
merge 1:1 fips year state county using processing\CRP\rent
assert _merge != 2 // check no unmatched from rent data
assert year == 1986 if _merge == 1 // check that only unmatched acres data is from 1986
drop _merge
merge 1:1 fips year state county using processing\CRP\avg
assert _merge == 3
drop _merge

* FINALIZE
ren county CRPcounty
ren state CRPstate

* save
compress
save processing\CRP\CRPmerged, replace
use processing\CRP\CRPmerged, clear
