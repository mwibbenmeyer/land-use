local vars CRP NRI NRI6classes NRcrop NRforest NRurban 
foreach var in `vars' {
	gen datapcnt_`var' = data_`var' / n * 100
	gen datamipcnt_`var' = datami_`var' / n * 100
	}
gen datapcnt_NRNRICRP = data_NRNRICRP / n * 100

* order
order data_NRNRICRP datapcnt_NRNRICRP ///
			data_NRI datapcnt_NRI datami_NRI datamipcnt_NRI ///
			data_NRI* datapcnt_NRI* datami_NRI* datamipcnt_NRI* ///
			data_NRcrop datapcnt_NRcrop datami_NRcrop datamipcnt_NRcrop ///
			data_NRforest datapcnt_NRforest datami_NRforest datamipcnt_NRforest ///
			data_NRurban datapcnt_NRurban datami_NRurban datamipcnt_NRurban ///
			data_CRP datapcnt_CRP datami_CRP datamipcnt_CRP
			
compress
