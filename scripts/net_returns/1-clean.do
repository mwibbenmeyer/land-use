cd "M:\GitRepos\land-use"

* load returns data
import delimited raw_data\net_returns\lewis-mihiar\landuse_net_returns.csv, clear

* destring
local valuevars crop_nr forest_nr urban_nr
foreach v of local valuevars {
	replace `v' = "." if `v' == "NA"
	destring `v', replace
	}
	
* save
compress
save processing\net_returns\clean, replace
