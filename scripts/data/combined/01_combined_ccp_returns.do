cd "F:/Projects/land-use/"

*log using "C:/Users/Matt/Downloads/ddc_test.log", replace

global beta_annual = 0.9

/* Import and format returns data */
use "processing/net_returns/combined_returns_panel_other.dta", clear
tostring fips, replace
tempfile tmp
save "`tmp'"

/* Import CCPs */
import delimited "processing/ccp/ccps.csv", clear

*Convert fips to string
gen str5 fips_str = string(fips,"%05.0f")
drop fips
rename fips_str fips
order fips, before(year)

*Correct county code fips code change
replace fips = "12025" if fips == "12086"

/* Merge CCPs with returns data */
merge m:1 fips year using "`tmp'"
drop if _merge == 2 /*Drop obs for years we don't have CCPs*/

/* Format and organize data set */

local varlist fips year lcc initial_use final_use weighted_ccp statefips stateName stateAbbrev crop_nr forest_nr urban_nr other_nr
keep `varlist'
order `varlist'

save "processing/combined/combined_ccp_returns.dta", replace 
