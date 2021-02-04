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

est clear

** TEST AGES **

** Table A.17 (partial, old draft Table 6) **

eststo dle_1:	reghdfe t_drive min_age_full											if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo dle_2:	reghdfe t_drive min_int_age												if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)

eststo dle_3:	reghdfe t_drive min_age_full min_int_age 								if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_4:	reghdfe t_drive min_age_full min_int_age 								                  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_5:	reghdfe t_drive min_age_full min_int_age d_* 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_6:	reghdfe t_drive min_age_full min_int_age d_* lhhi 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_7:	reghdfe t_drive min_age_full min_int_age d_* lhhi 						if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_8:	reghdfe t_drive min_age_full min_int_age d_* lhhi c.birthyr##c.birthyr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)	
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)
	
local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N F_diff p_diff, fmt(%9.4f %9.0g %9.3f %9.3f) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	dle_* using "./results/table6/census_dl.tex", booktabs replace `tabprefs' 

eststo clear

**********************************
** Close out

capture noisily log close
clear
