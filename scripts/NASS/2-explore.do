/* Programmer: Alexandra Thompson
Start Date: November 25, 2020
Objective: Explore NASS data
Variable of interest: survey-economics-expenses-rent: rent, cash, pastureland, expense, measured in $/acre
*/

********************************************************************************
************SETUP************
********************************************************************************
set more off
clear

* working dir
global workingdir "M:\GitRepos\land-use"
cd $workingdir

********************************************************************************
************EXPLORE************
********************************************************************************
use processing\NASS\pasturerents, clear
ta pasture_nr_level, sort

/** tag years of intersest
gen tag = year == 1991 ///
		| year == 1992 ///
		| year == 1993 ///
		| year == 1996 ///
		| year == 1997 ///
		| year == 1998 ///
		| year == 2001 ///
		| year == 2002 ///
		| year == 2003 ///
		| year == 2006 ///
		| year == 2007 ///
		| year == 2008 ///
		| year == 2011 ///
		| year == 2012 ///
		| year == 2013 ///
		| year == 2016 ///
		| year == 2017 ///
		| year == 2018
*/
* pie graphs
	use processing\NASS\pasturerents, clear
	/*graph pie, over(pasture_nr_level) sort(pasture_nr_level) by(, title(test) subtitle(test) caption(test) note(test)) by(year, total)*/
	graph pie, over(pasture_nr_level) ///
		sort(pasture_nr_level) ///
		by(, title(County pasture_nr Value Data Level) ///
		caption(Precision: county > Ag.StatisticsDistrict(asd)/othercombcounties > state > multistate > nodata)) ///
		by(year, total)
		gr_edit legend.Edit , style(cols(3)) style(rows(0)) style(key_ysize(small)) keepstyles 
		gr_edit legend.Edit, style(labelstyle(size(small)))
		gr_edit note.draw_view.setstyle, style(no)
		gr_edit note.fill_if_undrawn.setstyle, style(no)
		gr_edit caption.style.editstyle size(small) editcopy
		gr_edit title.style.editstyle size(medium) editcopy
		gr_edit subtitle.style.editstyle size(small) editcopy
		qui graph export results\initial_descriptives\NASS\pasturenr_datalevel_year_pie.png, replace

* box plots
	use processing\NASS\pasturerents, clear
	graph box pasture_nr, by(year, total)

* maps
	* mapping setup
	ssc install maptile
	ssc install spmap
	ssc install shp2dta
	maptile_install using "http://files.michaelstepner.com/geo_county2010.zip"
	capture net install grc1leg2.pkg
	* load dataset
	use processing\NASS\pasturerents, clear
	replace fips = 46113 if fips == 46102 // spmap package does not reflect this change (2015, Shannon County (46113) was renamed Oglala Lakota (46102))
	rename fips county
	keep county pasture_nr_level year
	encode pasture_nr_level, gen(level)
	gen leveln = level
	* map
	levelsof year, local(levels)
	foreach y of local levels {
	maptile level if year == `y', geo(county2010) cutvalues(1(1)6) fcolor(Rainbow)
	gr_edit title.text.Arrpush "`y'"
	* pause
	graph save processing\NASS\tempgraphs\pasturenr_datalevel_`y'_map, replace
	}

grc1leg2 ///
		processing\NASS\tempgraphs\pasturenr_datalevel_1994_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_1995_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_1996_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_1997_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_1998_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_1999_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2000_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2001_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2002_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2003_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2004_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2005_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2006_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2007_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2008_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2009_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2010_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2011_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2012_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2013_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2014_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2015_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2016_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2017_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2018_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2019_map.gph ///
		processing\NASS\tempgraphs\pasturenr_datalevel_2020_map.gph, ///
		title(County pasture_nr Value Data Level)
		gr_edit legend.Edit , style(rows(1)) style(cols(0)) keepstyles 
		gr_edit style.editstyle boxstyle(shadestyle(color(white))) editcopy
		gr_edit style.editstyle boxstyle(linestyle(color(white))) editcopy
		* pause
		graph export "results\initial_descriptives\NASS\pasturenr_datalevel_year_map.png", replace
	
keep *level*
duplicates drop
drop level
order leveln pasture*
sort leveln
export delimited results\initial_descriptives\NASS\pasturenr_datalevel_year_map_LEGEND.csv, replace
