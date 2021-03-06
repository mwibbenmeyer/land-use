/* 
Author: Alexandra Thompson (RFF)
Date: March 6, 2021
Purpose: Merge all cleaned Net Returns Data
*/ 

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

use processing\net_returns\temp_lewismihiar_netreturns, clear
replace fips = 12025 if fips == 12086

* merge to new urban_nr data
	merge 1:1 fips year using processing\net_returns\countylevel_urban_net_returns
	drop _merge
	save processing\net_returns\temp_lewismihiar_urban_netreturns, replace

* merge CRP
	use processing\CRP\CRPmerged, clear
	replace fips = 12025 if fips == 12086
	merge 1:1 fips year using processing\net_returns\temp_lewismihiar_urban_netreturns // merge to NR panel
		* drop years/states not in nri data
		gen tag = year == 1982 ///
				| year == 1987 ///
				| year == 1992 ///
				| year == 1997 ///
				| year == 2002 ///
				| year == 2007 ///
				| year == 2012 ///
				| year == 2015
		drop if tag == 0
		drop tag
		drop if CRPstate == "PUERTO RICO" | CRPstate == "ALASKA" | CRPstate == "HAWAII"
	drop CRPstate CRPcounty
	drop _merge
	* save
	compress
	save processing\net_returns\temp_lewismihiar_urban_CRP_netreturns, replace

* merge pasture/range
	use processing\NASS\pasturerents, clear
	* drop unnecessary vars
	drop asd_* county* state* multistate*
	* implement notes changes ONLY IF INCREASE MERGE RATE, NO DROPS
		replace fips = 12025 if fips == 12086
	* use 2008 as 2007 data. it is substantially more detailed than 2007.
		drop if year == 2007
		replace year = 2007 if year == 2008
		replace pasture_nr_level = pasture_nr_level + "_2008" if year == 2007
	merge 1:1 fips year using processing\net_returns\temp_lewismihiar_urban_CRP_netreturns // merge to NR/CRP panel
		drop _merge
		* drop years/states not in nri data
		gen tag = year == 1982 ///
				| year == 1987 ///
				| year == 1992 ///
				| year == 1997 ///
				| year == 2002 ///
				| year == 2007 ///
				| year == 2012 ///
				| year == 2015
		drop if tag == 0
		drop tag
	
	* generate rangeland net returns, which are captured in pasture net returns
	gen range_nr = pasture_nr
	label variable range_nr "= pasture_nr"

* generate state fips
tostring fips, gen(fipsstring)
gen statefips = substr(fipsstring, 1, 2)
replace statefips = substr(fipsstring, 1, 1) if length(fipsstring)==4
destring statefips, replace
* drop states outside of conus (alaska/hawaii)
drop if statefips == 2 | statefips == 15
merge m:1 statefips using processing\stateFips
assert statefips == 11 if _merge == 1
drop if _merge == 2
drop _merge
replace stateName = "District of Columbia" if statefips == 11
replace stateAbbrev = "DC" if statefips == 11
drop fipsstring 

* save
order state* fips year
compress
save processing\net_returns\combined_returns_panel, replace
use processing\net_returns\combined_returns_panel, clear

erase processing\net_returns\temp_lewismihiar_urban_netreturns.dta
erase processing\net_returns\temp_lewismihiar_urban_CRP_netreturns.dta
