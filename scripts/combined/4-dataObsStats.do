/* Programmer: Alexandra Thompson
Start Date: November 9, 2020
Objective: Generate tables summarizing missing and nonmissing data observations
*/
clear all

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

* county
	* by year
		use processing\combined\nri_nr_crp_countypanel, clear
		keep if data_NRI6classes == 1 // keep if NRIdata w/ any LU other than federal/water/rural
		gen n = 1
		collapse(sum) *data* n, by (year)
		assert n == data_NRI6classes
		do scripts\combined\4-dataObsStats_sub1.do
		drop n
		sort year
		order year
		* export
		export excel using results\initial_descriptives\combined\dataObsStats.xlsx, sheet("county-year") sheetreplace firstrow(variables)
	* overall
		drop *pcnt*
		collapse(sum) data*
		gen n = data_NRI
		do scripts\combined\4-dataObsStats_sub1.do
		drop n
		* export
		export excel using results\initial_descriptives\combined\dataObsStats.xlsx, sheet("county-overall") sheetreplace  firstrow(variables)

* point
		use processing\combined\nri_nr_crp_pointpanel, clear
		keep if data_NRI6classes == 1 // keep if NRIdata w/ any LU other than federal/water/rural
		gen n = 1
		collapse(sum) *data* n, by (year)
		assert n == data_NRI6classes
		do scripts\combined\4-dataObsStats_sub1.do
		drop n
		sort year
		order year
		* export
		export excel using results\initial_descriptives\combined\dataObsStats.xlsx, sheet("point-year") sheetreplace firstrow(variables)
	* overall
		drop *pcnt*
		collapse(sum) data*
		gen n = data_NRI
		do scripts\combined\4-dataObsStats_sub1.do
		drop n
		* export
		export excel using results\initial_descriptives\combined\dataObsStats.xlsx, sheet("point-overall") sheetreplace  firstrow(variables)

	
* var labels
		use processing\combined\nri_nr_crp_countypanel, clear
		keep data*
		drop datami*
		gen pcnt = 0
			label variable pcnt "percent of all observations (data_NRI == 1)"
		gen mi = 0
			label variable mi "obs is missing data value"
		describe, replace clear
		keep name varlab
		export excel using results\initial_descriptives\combined\dataObsStats.xlsx, sheet("variables") sheetreplace  firstrow(variables)
		

