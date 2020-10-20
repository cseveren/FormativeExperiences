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
** Gas Price Merge	 		****
********************************
********************************

tab 	year multyear

gen 	year_all = year
replace year_all = multyear if year==2010 | year==2015
tab		year_all

drop 	year 
rename 	year_all censusyear_all

rename 	statefip stfip
rename 	bpl statefip

local 	agelist 16 17 18 

foreach age of local agelist {
	gen 	year = birthyr + `age'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp) gen(_merge`age')

	rename	gas_price_99 real_gp_at`age'
	rename	d1gp_bp  d1gp_bp_at`age'
	rename	d2gp_bp  d2gp_bp_at`age'

	drop if _merge`age'==2

	rename 	year yr_age`age'
	lab var yr_age`age' "Year Turned `age'" 
}

/* 	_merge==1 are years with older people but no gasoline data
	_merge==2 are years that are not yet adulted
*/

drop if _merge16!=3
drop	_merge*

** Merge to current state prices at age 16 **

rename 	statefip bpl
rename 	stfip statefip

local 	agelist 16 17 18

foreach age of local agelist {
	rename 	yr_age`age' year

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp)
	/* 	_merge==1 are years with older people but no gasoline data
		_merge==2 are years that are not yet adulted
	*/
	drop if _merge==2
	*drop if _merge!=3
	drop 	_merge

	rename 	year yr_age`age' 

	rename	gas_price_99 real_now_at`age'
	rename	d1gp_bp d1gp_now_at`age'
	rename	d2gp_bp d2gp_now_at`age'
}

*********************
** Set up DL Merge **

rename 	bpl stfip

gen		yr_at16 = birthyr + 16

merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename  min_age_full min_age_full_stbirth


rename 	stfip bpl
rename	statefip stfip
compress

** Set up Specify Merge Year **

rename 	bpl statefip

foreach diff of numlist 0/2 {
	gen 	year = round(min_age_full_stbirth) + birthyr + `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp) gen(_mergep`diff')

	rename	gas_price_99 real_gp_atp`diff'
	rename	d1gp_bp  d1gp_bp_atp`diff'
	rename	d2gp_bp  d2gp_bp_atp`diff'

	drop if _mergep`diff'==2

	rename 	year yr_fullp`diff'
	lab var yr_fullp`diff' "Year before/after (`diff') full age" 
}

/* 	_merge==1 are years with older people but no gasoline data
	_merge==2 are years that are not yet adulted
*/

drop	_merge*

** Merge to current state prices at age 16 **

rename 	statefip bpl

gen		yr_at16 = birthyr + 16

merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename  min_age_full min_age_full_stnow

rename 	stfip statefip

foreach diff of numlist 0/2 {
	rename 	yr_fullp`diff' year 

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp) gen(_mergep`diff')
	/* 	_merge==1 are years with older people but no gasoline data
		_merge==2 are years that are not yet adulted
	*/
	drop if _merge==2
	*drop if _merge!=3
	drop 	_merge

	rename	gas_price_99 real_now_atp`diff'
	rename	d1gp_bp d1gp_now_atp`diff'
	rename	d2gp_bp d2gp_now_atp`diff'
	
	rename 	year yr_fullp`diff'
}

rename 	statefip stfip 
compress

********************************
********************************
** Panel Regressions 		 ***
********************************
********************************

gen 	age2 = age*age
gen 	lhhi = ln(w_hhi)

egen	stcenyr_fe = group(stfip censusyear_all)	
egen 	bplcohort = group(bpl yr_age16)

drop if perwt==0
drop if bpl==2
drop if bpl==15
	/* Gas Price panel balanaced except AK HI */

gen 	byr = birthyr-1950

/* Summary Statistics */ 

eststo 	sum1: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 e_emp age d_* w_hhi m_samestate [aw=perwt], s(mean sd count) c(s) 
eststo 	sum2: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 age d_* w_hhi m_samestate if e_emp==1 [aw=perwt], s(mean sd count) c(s) 
eststo 	sum3: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 e_emp age d_* w_hhi if m_samestate==1, s(mean sd count) c(s) 
eststo 	sum4: estpost tabstat t_drive  t_transit  t_vehicle d2gp_bp_at17 age d_* w_hhi if m_samestate==1 & e_emp==1, s(mean sd count) c(s) 
	
esttab sum? using "./results/table_a2/census_summarystats.tex", booktabs replace cells(mean sd count)

eststo 	gsum1: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 d2gp_now_at17  [aw=perwt], s(mean sd min max) c(s) 
eststo 	gsum2: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 d2gp_now_at17 if e_emp==1 [aw=perwt], s(mean sd min max) c(s) 
eststo 	gsum3: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 if m_samestate==1, s(mean sd min max) c(s) 
eststo 	gsum4: estpost tabstat real_gp_at16 real_gp_atp0 d1gp_bp_at16 d1gp_bp_atp0 d1gp_bp_at17 d1gp_bp_atp1 d2gp_bp_at17 d2gp_bp_atp1 if m_samestate==1 & e_emp==1, s(mean sd min max) c(s) 
	
esttab gsum? using "./results/table_a7/census_summarystats_treatment.tex", booktabs replace cells(mean(pattern(1 1 1 1)) sd(pattern(1 1 1 1)) min(pattern(1 1 1 1)) max(pattern(1 1 1 1)))
	
/* Main specifications at different ages */ 

eststo tc2a_1:	reghdfe t_drive d2gp_bp_at18 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_2:	reghdfe t_drive d2gp_bp_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_3:	reghdfe t_drive d2gp_now_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_4:	reghdfe t_drive d2gp_bp_at18 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_5:	reghdfe t_drive d2gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2a_6:	reghdfe t_drive d2gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2a_7:	reghdfe t_drive d2gp_bp_at18 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2b_1:	reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_2:	reghdfe t_drive d2gp_bp_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_3:	reghdfe t_drive d2gp_now_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_4:	reghdfe t_drive d2gp_bp_at17 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_5:	reghdfe t_drive d2gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2b_6:	reghdfe t_drive d2gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2b_7:	reghdfe t_drive d2gp_bp_at17 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2c_1:	reghdfe t_drive d1gp_bp_at18 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_2:	reghdfe t_drive d1gp_bp_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_3:	reghdfe t_drive d1gp_now_at18 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_4:	reghdfe t_drive d1gp_bp_at18 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_5:	reghdfe t_drive d1gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2c_6:	reghdfe t_drive d1gp_bp_at18 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2c_7:	reghdfe t_drive d1gp_bp_at18 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2d_1:	reghdfe t_drive d1gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_2:	reghdfe t_drive d1gp_bp_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_3:	reghdfe t_drive d1gp_now_at17 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_4:	reghdfe t_drive d1gp_bp_at17 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_5:	reghdfe t_drive d1gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2d_6:	reghdfe t_drive d1gp_bp_at17 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2d_7:	reghdfe t_drive d1gp_bp_at17 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2e_1:	reghdfe t_drive d1gp_bp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_2:	reghdfe t_drive d1gp_bp_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_3:	reghdfe t_drive d1gp_now_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_4:	reghdfe t_drive d1gp_bp_at16 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_5:	reghdfe t_drive d1gp_bp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2e_6:	reghdfe t_drive d1gp_bp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2e_7:	reghdfe t_drive d1gp_bp_at16 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tc2f_1:	reghdfe t_drive real_gp_at16 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_2:	reghdfe t_drive real_gp_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_3:	reghdfe t_drive real_now_at16 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_4:	reghdfe t_drive real_gp_at16 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_5:	reghdfe t_drive real_gp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc2f_6:	reghdfe t_drive real_gp_at16 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tc2f_7:	reghdfe t_drive real_gp_at16 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rnme2a "d2gp_bp_at18 d2gp18 d2gp_now_at18 d2gp18" 
local 	rnme2b "d2gp_bp_at17 d2gp17 d2gp_now_at17 d2gp17"
local 	rnme2c "d1gp_bp_at18 d1gp18 d1gp_now_at18 d1gp18" 
local 	rnme2d "d1gp_bp_at17 d1gp17 d1gp_now_at17 d1gp17"
local 	rnme2e "d1gp_bp_at16 d1gp16 d1gp_now_at16 d1gp16"   
local 	rnme2f "real_gp_at16 real16 real_now_at16 real16" 

esttab 	tc2a_* using "./results/table_a8/census_mainspecs_d2_18.tex", rename(`rnme2a') booktabs replace `tabprefs'
esttab 	tc2b_* using "./results/table1/census_mainspecs_d2_17.tex", rename(`rnme2b') booktabs replace `tabprefs'
esttab 	tc2c_* using "./results/table_a8/census_mainspecs_d1_18.tex", rename(`rnme2c') booktabs replace `tabprefs'
esttab 	tc2d_* using "./results/table_a8/census_mainspecs_d1_17.tex", rename(`rnme2d') booktabs replace `tabprefs'
esttab 	tc2e_* using "./results/table_a8/census_mainspecs_d1_16.tex", rename(`rnme2e') booktabs replace `tabprefs'
esttab 	tc2f_* using "./results/table1/census_mainspecs_lev16.tex", rename(`rnme2f') booktabs replace `tabprefs'

eststo clear

/* Main specifications at different relative driver license minimums */ 

eststo tdla_1:	reghdfe t_drive d2gp_bp_atp2 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_2:	reghdfe t_drive d2gp_bp_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_3:	reghdfe t_drive d2gp_now_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_4:	reghdfe t_drive d2gp_bp_atp2 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_5:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdla_6:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdla_7:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdlb_1:	reghdfe t_drive d2gp_bp_atp1 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_2:	reghdfe t_drive d2gp_bp_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_3:	reghdfe t_drive d2gp_now_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_4:	reghdfe t_drive d2gp_bp_atp1 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_5:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlb_6:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdlb_7:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi c.byr##c.byr 	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdlc_1:	reghdfe t_drive d1gp_bp_atp2 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_2:	reghdfe t_drive d1gp_bp_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_3:	reghdfe t_drive d1gp_now_atp2 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_4:	reghdfe t_drive d1gp_bp_atp2 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_5:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlc_6:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdlc_7:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdld_1:	reghdfe t_drive d1gp_bp_atp1 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_2:	reghdfe t_drive d1gp_bp_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_3:	reghdfe t_drive d1gp_now_atp1 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_4:	reghdfe t_drive d1gp_bp_atp1 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_5:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdld_6:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdld_7:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdle_1:	reghdfe t_drive d1gp_bp_atp0 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_2:	reghdfe t_drive d1gp_bp_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_3:	reghdfe t_drive d1gp_now_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_4:	reghdfe t_drive d1gp_bp_atp0 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_5:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdle_6:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdle_7:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tdlf_1:	reghdfe t_drive real_gp_atp0 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_2:	reghdfe t_drive real_gp_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_3:	reghdfe t_drive real_now_atp0 									  	  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_4:	reghdfe t_drive real_gp_atp0 d_*					if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_5:	reghdfe t_drive real_gp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdlf_6:	reghdfe t_drive real_gp_atp0 d_* lhhi				if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tdlf_7:	reghdfe t_drive real_gp_atp0 d_* lhhi c.byr##c.byr	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rnme2a "d2gp_bp_atp2 d2gpp2 d2gp_now_atp2 d2gpp2" 
local 	rnme2b "d2gp_bp_atp1 d2gpp1 d2gp_now_atp1 d2gpp1"
local 	rnme2c "d1gp_bp_atp2 d1gpp2 d1gp_now_atp2 d1gpp2" 
local 	rnme2d "d1gp_bp_atp1 d1gpp1 d1gp_now_atp1 d1gpp1"
local 	rnme2e "d1gp_bp_atp0 d1gpp0 d1gp_now_atp0 d1gpp0"   
local 	rnme2f "real_gp_atp0 realp0 real_now_atp0 realp0" 

esttab 	tdla_* using "./results/table_a8/census_mainspecs_d2_p2.tex", rename(`rnme2a') booktabs replace `tabprefs'
esttab 	tdlb_* using "./results/table1/census_mainspecs_d2_p1.tex", rename(`rnme2b') booktabs replace `tabprefs'
esttab 	tdlc_* using "./results/table_a8/census_mainspecs_d1_p2.tex", rename(`rnme2c') booktabs replace `tabprefs'
esttab 	tdld_* using "./results/table_a8/census_mainspecs_d1_p1.tex", rename(`rnme2d') booktabs replace `tabprefs'
esttab 	tdle_* using "./results/table_a8/census_mainspecs_d1_p0.tex", rename(`rnme2e') booktabs replace `tabprefs'
esttab 	tdlf_* using "./results/table1/census_mainspecs_levp0.tex", rename(`rnme2f') booktabs replace `tabprefs'

eststo clear

/* Main specifications with cohort fixed effects */ 

eststo tcodl_a_1:	reghdfe t_drive d2gp_bp_atp2 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_a_2:	reghdfe t_drive d2gp_bp_atp2 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_a_3:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_a_4:	reghdfe t_drive d2gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_b_1:	reghdfe t_drive d2gp_bp_atp1 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_b_2:	reghdfe t_drive d2gp_bp_atp1 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_b_3:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_b_4:	reghdfe t_drive d2gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_c_1:	reghdfe t_drive d1gp_bp_atp2			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_c_2:	reghdfe t_drive d1gp_bp_atp2 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_c_3:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_c_4:	reghdfe t_drive d1gp_bp_atp2 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_d_1:	reghdfe t_drive d1gp_bp_atp1 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_d_2:	reghdfe t_drive d1gp_bp_atp1 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_d_3:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_d_4:	reghdfe t_drive d1gp_bp_atp1 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_e_1:	reghdfe t_drive d1gp_bp_atp0 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_e_2:	reghdfe t_drive d1gp_bp_atp0 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_e_3:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_e_4:	reghdfe t_drive d1gp_bp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

eststo tcodl_f_1:	reghdfe t_drive real_gp_atp0 			if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_f_2:	reghdfe t_drive real_gp_atp0 d_*		if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_f_3:	reghdfe t_drive real_gp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(bpl censusyear_all byr age) cluster(bpl)
eststo tcodl_f_4:	reghdfe t_drive real_gp_atp0 d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe byr age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcodl_a_* using "./results/table_a10/census_cohfespecs_d2_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_b_* using "./results/table_a10/census_cohfespecs_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_c_* using "./results/table_a10/census_cohfespecs_d1_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_d_* using "./results/table_a10/census_cohfespecs_d1_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_e_* using "./results/table_a10/census_cohfespecs_d1_p0.tex", booktabs replace `tabprefs'
esttab 	tcodl_f_* using "./results/table_a10/census_cohfespecs_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Other outcomes */ 

eststo tother_b_1:	reghdfe t_transit d2gp_bp_at17 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_2:	reghdfe t_transit d2gp_bp_at17 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_at17 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_at17 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_at17 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tother_f_1:	reghdfe t_transit real_gp_at16  						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_2:	reghdfe t_transit real_gp_at16 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_3:	reghdfe t_vehicle real_gp_at16 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_4:	reghdfe t_vehicle real_gp_at16 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_5:	reghdfe t_vehicle real_gp_at16 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_6:	reghdfe t_vehicle real_gp_at16 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tother_b_? using "./results/table2/other_d2_17.tex", booktabs replace `tabprefs'
esttab 	tother_f_? using "./results/table2/other_lev16.tex", booktabs replace `tabprefs'

eststo clear

eststo tother_b_1:	reghdfe t_transit d2gp_bp_atp1 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_2:	reghdfe t_transit d2gp_bp_atp1 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_3:	reghdfe t_vehicle d2gp_bp_atp1 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_4:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_b_5:	reghdfe t_vehicle d2gp_bp_atp1 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_b_6:	reghdfe t_vehicle d2gp_bp_atp1 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tother_f_1:	reghdfe t_transit real_gp_atp0  						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_2:	reghdfe t_transit real_gp_atp0 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_3:	reghdfe t_vehicle real_gp_atp0 							if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_4:	reghdfe t_vehicle real_gp_atp0 c.byr##c.byr d_* lhhi	if m_samestate==1 & mi(t_transit)==0 [aw=perwt], a(stcenyr_fe age) cluster(bpl)
eststo tother_f_5:	reghdfe t_vehicle real_gp_atp0 							if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tother_f_6:	reghdfe t_vehicle real_gp_atp0 c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tother_b_? using "./results/table2/other_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tother_f_? using "./results/table2/other_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Age Heterogeneity */

gen		d2gp_age17_2534 = (age>=25 & age<=34)*d2gp_bp_at17
gen		d2gp_age17_3544 = (age>=35 & age<=44)*d2gp_bp_at17
gen		d2gp_age17_4554 = (age>=45 & age<=54)*d2gp_bp_at17

gen		d2gp_agep1_2534 = (age>=25 & age<=34)*d2gp_bp_atp1
gen		d2gp_agep1_3544 = (age>=35 & age<=44)*d2gp_bp_atp1
gen		d2gp_agep1_4554 = (age>=45 & age<=54)*d2gp_bp_atp1

local	bin10yrs_17 d2gp_age17_2534 d2gp_age17_3544 d2gp_age17_4554

local	bin10yrs_p1 d2gp_agep1_2534 d2gp_agep1_3544 d2gp_agep1_4554

eststo tcage_1:	reghdfe t_drive `bin10yrs_17' 				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tcage_2:	reghdfe t_drive `bin10yrs_17' c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

eststo tcage_3:	reghdfe t_drive `bin10yrs_p1' 				if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tcage_4:	reghdfe t_drive `bin10yrs_p1' c.byr##c.byr d_* lhhi	if m_samestate==1 [aw=perwt], a(stcenyr_fe age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcage_? using "./results/table_a16/census_agehet_17p1.tex", booktabs replace `tabprefs'

eststo clear
drop  	d2gp_age??_????

** ** ** **
/* Robust to dropping 1979/80 Crisis */
loc y79 "birthyr!=1965"	
loc y74 "birthyr!=1960"

eststo tdrop_1: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 & `y74'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo tdrop_2: reghdfe t_drive d1gp_bp_atp2 						if m_samestate==1 & `y74'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tdrop_3: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 & `y79'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo tdrop_4: reghdfe t_drive d1gp_bp_atp2 						if m_samestate==1 & `y79'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo tdrop_5: reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 & `y74' & `y79'  [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
eststo tdrop_6: reghdfe t_drive d1gp_bp_atp2 						if m_samestate==1 & `y74' & `y79' [aw=perwt], a(bpl censusyear_all age) cluster(bpl)	
	
local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
	
esttab 	tdrop_? using "./results/other/dropoilcrises.tex", booktabs replace `tabprefs'

**************************************************
/* Mediation Analysis and Additional Robustness */

rename 	bpl statefip
gen		yr_at18 = birthyr + 18
rename 	yr_at18 year

merge m:1 statefip year  using "./output/unemp_prepped.dta"
drop	if _merge==2
drop	_merge year 

rename	statefip bpl

gen 	lincw = ln(w_incw)
gen		lincp = ln(w_pinc)

keep d2gp_bp_at17 d2gp_bp_atp1 unemprate lhhi lincw lincp d_fem d_black d_hisp m_samestate perwt bpl censusyear_all age t_drive

local 	i = 1

foreach inc of varlist unemprate lhhi lincw lincp {
	foreach outc of varlist d2gp_bp_at17 d2gp_bp_atp1 {
		preserve
			keep t_drive `outc' `inc' d_fem d_black d_hisp m_samestate perwt bpl censusyear_all age

			* Step 1: sample selection
			reghdfe t_drive `outc' `inc' d_fem d_black d_hisp if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
			gen byte used=e(sample)
			keep if used==1
			drop 	used m_samestate

			*reghdfe t_drive `outc' d_fem d_black d_hisp [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
				*reg adjusted for sample
			
			gen 	bpl_se = bpl

			tempfile maindata
			save "`maindata'", replace

			* Step 2: renaming

			gen		smp = 0
			rename 	t_drive y

			tempfile sample0
			save "`sample0'", replace

			use "`maindata'"
			gen		smp = 1
			rename 	`inc' y
			gen		`inc'=0

			append using "`sample0'"

			foreach v of varlist `outc' d_fem d_black d_hisp {
				gen `v'_1 = `v'*smp
			}

			foreach v of varlist censusyear_all age bpl {
				egen `v'_comb = group(`v' smp)
			}

			reghdfe y `outc' `outc'_1 `inc' d_fem d_black d_hisp d_fem_1 d_black_1 d_hisp_1 [aw=perwt], a(bpl_comb censusyear_all_comb age_comb) cluster(bpl_se)

			local ndf = e(df_r)
			
			local thetaY_b_`i' = _b[`outc']
			local thetaY_se_`i' = _se[`outc']
			local thetaY_p_`i' = 2*ttail(`ndf',abs(`thetaY_b_`i''/`thetaY_se_`i''))

			local gamma_b_`i' = _b[`inc']
			local gamma_se_`i' = _se[`inc']
			local gamma_p_`i' = 2*ttail(`ndf',abs(`gamma_b_`i''/`gamma_se_`i''))
			
			local thetaM_b_`i' = _b[`outc'_1]
			local thetaM_se_`i' = _se[`outc'_1]
			local thetaM_p_`i' = 2*ttail(`ndf',abs(`thetaM_b_`i''/`thetaM_se_`i''))
			
			nlcom (ind: _b[`outc'_1] * _b[`inc']) (tot: _b[`outc'] + _b[`outc'_1] * _b[`inc']), post

			local ind_b_`i' = _b[ind]
			local ind_se_`i' = _se[ind]
			local ind_p_`i' = 2*ttail(`ndf',abs(`ind_b_`i''/`ind_se_`i''))
			
			local tot_b_`i' = _b[tot]
			local tot_se_`i' = _se[tot]
			local tot_p_`i' = 2*ttail(`ndf',abs(`tot_b_`i''/`tot_se_`i''))
			
			local vlist thetaY gamma thetaM ind tot 
			foreach v of local vlist {
				local `v'_b_`i': di %6.4f ``v'_b_`i''
				local `v'_se_`i': di %6.4f ``v'_se_`i''
				local `v'_p_`i': di %6.4f ``v'_p_`i''
			}				
		restore
		local	++i
	}	
}

local vlist thetaY gamma thetaM ind tot

texdoc init "./results/table_a9/mediation.tex", replace force
tex  & unemp & unemp & hhi & hhi & incw & incw & incp & incp  \\
tex  & 17 & p1 & 17 & p1 & 17 & p1 & 17 & p1 \\
tex \addlinespace \hline
foreach coeff of local vlist {
	tex `coeff' & ``coeff'_b_1' & ``coeff'_b_2' & ``coeff'_b_3' & ``coeff'_b_4' & ``coeff'_b_5' & ``coeff'_b_6' & ``coeff'_b_7' & ``coeff'_b_8'  \\
	tex   & (``coeff'_se_1') & (``coeff'_se_2') & (``coeff'_se_3') & (``coeff'_se_4') & (``coeff'_se_5') & (``coeff'_se_6') & (``coeff'_se_7') & (``coeff'_se_8')   \\
	tex   & [``coeff'_p_1'] & [``coeff'_p_2'] & [``coeff'_p_3'] & [``coeff'_p_4'] & [``coeff'_p_5'] & [``coeff'_p_6'] & [``coeff'_p_7'] & [``coeff'_p_8']    \\
}
texdoc close


**********************************
** Close out

capture noisily log close
clear
