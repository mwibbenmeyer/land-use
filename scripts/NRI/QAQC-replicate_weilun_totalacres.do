/* Programmer: Alexandra Thompson
Date: October 5, 2020
Objective: replicate Weilun's programming procedure to calculate total acres in 1982.
Code adapted from "replicate table1.do" in dropbox folder.
*/

use "$workingdir\nri15_reduced.dta", clear
keep state county fips xfact landu1982 landu1997
drop if landu1982 == 0 | landu1997 == 0
rename landu1982 landu
merge m:1 landu using "$workingdir\classification.dta"
keep if _merge == 1 | _merge == 3
replace class2 = "Other" if _merge == 1
drop _merge
drop if class2=="Other"



collapse(sum) xfact, by(class2)

collapse(sum) xfact
