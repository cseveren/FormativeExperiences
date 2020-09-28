*************************************************************
** This file makes performs panel analyses from all census 
** data years.
*************************************************************

local 	logf "`1'" 
log using "`logf'", replace text

use 	"./output/censusall_prepped.dta", clear

********************************
** Ensure Sample Restrictions

keep if bpl<100
drop if farm==2

drop if age<=24
drop if age>54

********************************
********************************
** DL Merge	 		****
********************************
********************************

tab 	year multyear

gen 	year_all = year
replace year_all = multyear if year==2010 | year==2015
tab		year_all

drop 	year 
rename 	year_all censusyear_all

/*
rename 	statefip stfip
rename 	bpl statefip
*/
gen		yr_at16 = birthyr + 16
rename 	bpl stfip

merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year

rename 	stfip bpl
rename	statefip stfip
compress

********************************
********************************
** Panel Regressions 		 ***
********************************
********************************

gen 	age2 = age*age
gen 	lhhi = ln(w_hhi)

egen	stcenyr_fe = group(stfip censusyear_all)	
egen 	bplcohort = group(bpl yr_at16)

drop if perwt==0

drop if age<=24
drop if age>54

egen 	age_f_grps=cut(min_age_full), at(15(1)19)
replace age_f_grps=16 if age_f_grps==15

egen 	age_i_grps=cut(min_int_age), at(14(1)17)
replace age_i_grps=15 if age_i_grps==14
	
/* Test different ages */
/*
eststo dla_1:	reghdfe t_drive min_age_full if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dla_2:	reghdfe t_drive min_age_full [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dla_3:	reghdfe t_drive min_age_full d_* if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo dla_4:	reghdfe t_drive min_age_full d_* lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dla_5:	reghdfe t_drive min_age_full d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	

eststo dlb_1:	reghdfe t_drive i.age_f_grps if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dlb_2:	reghdfe t_drive i.age_f_grps [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dlb_3:	reghdfe t_drive i.age_f_grps d_* if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo dlb_4:	reghdfe t_drive i.age_f_grps d_* lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dlb_5:	reghdfe t_drive i.age_f_grps d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	

eststo dlc_1:	reghdfe t_drive min_int_age if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dlc_2:	reghdfe t_drive min_int_age [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dlc_3:	reghdfe t_drive min_int_age d_* if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo dlc_4:	reghdfe t_drive min_int_age d_* lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dlc_5:	reghdfe t_drive min_int_age d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	

eststo dld_1:	reghdfe t_drive i.age_i_grps if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dld_2:	reghdfe t_drive i.age_i_grps [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dld_3:	reghdfe t_drive i.age_i_grps d_* if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo dld_4:	reghdfe t_drive i.age_i_grps d_* lhhi if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dld_5:	reghdfe t_drive i.age_i_grps d_* lhhi if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	
*/	
eststo dle_1:	reghdfe t_drive min_age_full min_int_age 								if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dle_2:	reghdfe t_drive min_age_full min_int_age 								                  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dle_3:	reghdfe t_drive min_age_full min_int_age d_* 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo dle_4:	reghdfe t_drive min_age_full min_int_age d_* lhhi 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dle_5:	reghdfe t_drive min_age_full min_int_age d_* lhhi 						if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	
eststo dle_6:	reghdfe t_drive min_age_full min_int_age d_* lhhi c.birthyr##c.birthyr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	
	
local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

*esttab 	dla_* using "./results/panel_census_dl/fullage_cont.tex", booktabs replace `tabprefs' 
*esttab 	dlb_* using "./results/panel_census_dl/fullage_int.tex", booktabs replace `tabprefs' 
*esttab 	dlc_* using "./results/panel_census_dl/intage_cont.tex", booktabs replace `tabprefs' 
*esttab 	dld_* using "./results/panel_census_dl/intage_int.tex", booktabs replace `tabprefs' 
esttab 	dle_* using "./results/panel_census_dl/both_cont.tex", booktabs replace `tabprefs' 

eststo clear

**********************************
** Close out

reghdfe t_drive min_age_full min_int_age 								if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
reghdfe t_drive i.age_f_grps age age2					if m_samestate==1 [aw=perwt], a(stcenyr_fe birthyr) cluster(bpl)


capture noisily log close
clear
