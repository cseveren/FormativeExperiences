clear
import 	excel using "./data/driver_license_requirements/assembled_panel.xlsx", firstrow

drop 	source notes d_c min_int_age_alt min_age_fullalt min_age_nogdl_nodrivered

replace m_c=1 if mi(m_c)==1 & (year==1967 | year==2017)
replace m_c=1 if mi(m_c)==1 & (year==1972) /* Will not effect if not using min_age_fullalt min_age_nogdl_nodrivered */
replace	m_c=1 if mi(m_c)==1 /* This may not be defensible */
	/* 19 changes made
		CO: 2 (2 have no effect)
		HI: 1 (1 has no effect)
		IL: 4 (2 have no effect) (2 are troubling)
		IN: 1 (1 has no effect, except r_drivered)
		IA: 1 (1 has no effect, except r_drivered)
		LA: 1 (1 has an effect) (1 is troubling)
		ME: 1 (1 has an effect) (1 is troubling)
		MD: 3 (3 have no effect)
		MN: 1 (1 has an effect) (1 is troubling)
		VA: 2 (2 have no effect) 	*/

gen 	moyr = ym(year, m_c) 
format 	moyr %tm 
drop	m_c	year		
		
xtset	stfip moyr	
order 	state code stfip moyr, first
tsfill, full	

by stfip (moyr): carryforward state code min_int_age r_drivered r_night r_pass ///
			gdl min_age_full min_age_nonightres min_age_nopassres, replace

gen 	month = month(dofm(moyr))
gen	 	year = year(dofm(moyr))

/* To match to CENSUS data, use 4/1/XXXX as reference day for year */
keep if month==4	
drop	moyr month	
xtset 	stfip year	

gen		yr_at16 = year

save	"./output/dlpanel_prepped.dta", replace
clear
