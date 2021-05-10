clear

cd F:/Projects/land-use/

/*** GET COUNTY RENTS ***/

/* Dummy rents */
set obs 5
gen k = _n

/* Set prices in $1000s USD because otherwise exp(vcond) gets too big for Stata*/
gen P = .
replace P = .080 if k == 1 /* Crops */
replace P = .012 if k == 2 /* Pasture */
replace P = .017 if k == 3 /* Forest */
replace P = 4 if k == 4 /* Urban */
replace P = .010 if k == 5 /* Range */
tempfile returns
save `returns'


/*** SET UP DATA SET FOR ITERATION ***/

/* Data set for value function iteration */

clear
set obs 5
gen v = 0 
gen vnext = v
gen k = _n

merge 1:1 k using `returns', nogen

/* Set coefficients and constants */
gen theta_0 = 0.2
gen theta_q1 = 0.05 /*Use appropriate theta_q for *market* */
gen beta = 0.90
gen gamma = 0.577216


/*** VALUE FUNCTION ITERATION ***/

/*First iteration*/
gen vcond = theta_0*P + theta_q1*P + beta*v
egen sum = sum(exp(vcond))
gen lnsum = ln(sum)
replace vnext = lnsum + gamma
gen diff = v - vnext
summ diff
local maxdiff = `r(max)'
di "`maxdiff'"

/*Iterate until convergence*/
while abs(`maxdiff') > 0.00001 {

	replace v = vnext
	replace vcond = theta_0*P + theta_q1*P + beta*v
	drop sum
	pause
	egen sum = sum(exp(vcond))
	replace lnsum = ln(sum)
	replace vnext = lnsum + gamma
	replace diff = v - vnext
	summ diff
	local maxdiff = `r(max)'
	di "`maxdiff'"

}


/*** CALCULATE IMPLIED PROBABILITIES ***/

gen num = exp(vcond)
egen denom = sum(exp(vcond))

gen p = num/denom

