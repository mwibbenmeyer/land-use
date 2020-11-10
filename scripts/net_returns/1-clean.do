/* 
Author: Alexandra Thompson (RFF)
Date: September 21, 2020
Purpose: Initial Data Clean of Net Returns Data
Input data source(s): Dave Lewis and Chris Mihiar (Oregon State)
*/ 

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

* load returns data
import delimited raw_data\net_returns\lewis-mihiar\landuse_net_returns.csv, clear

* destring
local valuevars crop_nr forest_nr urban_nr
foreach v of local valuevars {
	replace `v' = "." if `v' == "NA"
	destring `v', replace
	}

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
* drop states outside of conus
drop if stateAbbrev == "AK"
drop if stateAbbrev == "HI"

* save
compress
save processing\net_returns\clean, replace
use processing\net_returns\clean, clear
