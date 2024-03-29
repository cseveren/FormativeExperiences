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

* Drop things to preserve space
drop	hhwt metro puma conspuma cpuma0010 ownershp hhincome vehicles pernum relate ///
			related pwpuma00 tranwork trantime autos trucks e_* w_* d_*

tab 	year multyear

gen 	year_all = year
replace year_all = multyear if year==2010 | year==2015
tab		year_all

drop 	year 
rename 	year_all censusyear_all

rename 	statefip stfip
rename 	bpl statefip

local 	agelist 13 14 15 16 17 18 19 20 21 22

foreach age of local agelist {
	gen 	year = birthyr + `age'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_merge`age')

	rename	gas_price gas_price_at`age'
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

rename 	statefip bpl

********************************
********************************
** Panel Regressions 		 ***
********************************
********************************

egen	stcenyr_fe = group(stfip censusyear_all)	
egen 	bplcohort = group(bpl yr_age16)

drop if perwt==0
drop if bpl==2
drop if bpl==15
	/* Gas Price panel balanaced except AK HI */

compress

/* Longer series */

** Table A.14 (partial) **

eststo tc1b_2:	reghdfe t_drive d1gp_bp_at13   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_3:	reghdfe t_drive d1gp_bp_at14   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_4:	reghdfe t_drive d1gp_bp_at15   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_5:	reghdfe t_drive d1gp_bp_at16   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_6:	reghdfe t_drive d1gp_bp_at17   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_7:	reghdfe t_drive d1gp_bp_at18   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_8:	reghdfe t_drive d1gp_bp_at19   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_9:	reghdfe t_drive d1gp_bp_at20   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_10:	reghdfe t_drive d1gp_bp_at21   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1b_11:	reghdfe t_drive d1gp_bp_at22   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rn1	"d1gp_bp_at13 d1gp d1gp_bp_at14 d1gp d1gp_bp_at15 d1gp d1gp_bp_at16 d1gp d1gp_bp_at17 d1gp d1gp_bp_at18 d1gp d1gp_bp_at19 d1gp d1gp_bp_at20 d1gp d1gp_bp_at21 d1gp d1gp_bp_at22 d1gp"

esttab 	tc1b_* using "./results/table_a14/census_reald1.tex", rename(`rn1') booktabs replace `tabprefs' 

eststo clear

/* Test different ages */

** Table A.15 (partial) **
	
eststo tc1a_2:	reghdfe t_drive d2gp_bp_at13   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_3:	reghdfe t_drive d2gp_bp_at14   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_4:	reghdfe t_drive d2gp_bp_at15   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_5:	reghdfe t_drive d2gp_bp_at16   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_6:	reghdfe t_drive d2gp_bp_at17   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_7:	reghdfe t_drive d2gp_bp_at18   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_8:	reghdfe t_drive d2gp_bp_at19   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_9:	reghdfe t_drive d2gp_bp_at20   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_10:	reghdfe t_drive d2gp_bp_at21   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tc1a_11:	reghdfe t_drive d2gp_bp_at22   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rn2	"d2gp_bp_at13 d2gp d2gp_bp_at14 d2gp d2gp_bp_at15 d2gp d2gp_bp_at16 d2gp d2gp_bp_at17 d2gp d2gp_bp_at18 d2gp d2gp_bp_at19 d2gp d2gp_bp_at20 d2gp d2gp_bp_at21 d2gp d2gp_bp_at22 d2gp"

esttab 	tc1a_* using "./results/table_a15/census_reald2.tex", rename(`rn2') booktabs replace `tabprefs' 

eststo clear

drop	gas_price_at?? real_gp_at?? d1gp_bp_at?? d2gp_bp_at??
drop	yr_age??

********************************
********************************
** Gas Price Merge; DL 		****
********************************
********************************

** Set up DL Merge **

rename 	stfip statefip
rename 	bpl stfip

gen		yr_at16 = birthyr + 16

merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16

rename 	stfip bpl
rename	statefip stfip
compress

** Set up Specify Merge Year **

rename 	bpl statefip

foreach diff of numlist 1/4 {
	gen 	year = round(min_age_full) + birthyr - `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_mergen`diff')

	rename	gas_price gas_price_atn`diff'
	rename	gas_price_99 real_gp_atn`diff'
	rename	d1gp_bp  d1gp_bp_atn`diff'
	rename	d2gp_bp  d2gp_bp_atn`diff'

	drop if _mergen`diff'==2

	rename 	year yr_fulln`diff'
	lab var yr_fulln`diff' "Year before/after (`diff') full age" 
}

foreach diff of numlist 0/6 {
	gen 	year = round(min_age_full) + birthyr + `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_mergep`diff')

	rename	gas_price gas_price_atp`diff'
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

rename 	statefip bpl

/* Test different ages */

** Table A.14 and Table A.15 (partial) **	
	
eststo tq1a_2:	reghdfe t_drive d2gp_bp_atn3   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_3:	reghdfe t_drive d2gp_bp_atn2   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_4:	reghdfe t_drive d2gp_bp_atn1   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_5:	reghdfe t_drive d2gp_bp_atp0   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_6:	reghdfe t_drive d2gp_bp_atp1   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_7:	reghdfe t_drive d2gp_bp_atp2   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_8:	reghdfe t_drive d2gp_bp_atp3   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_9:	reghdfe t_drive d2gp_bp_atp4   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_10:	reghdfe t_drive d2gp_bp_atp5   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1a_11:	reghdfe t_drive d2gp_bp_atp6   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)

eststo tq1b_2:	reghdfe t_drive d1gp_bp_atn3   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_3:	reghdfe t_drive d1gp_bp_atn2   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_4:	reghdfe t_drive d1gp_bp_atn1   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_5:	reghdfe t_drive d1gp_bp_atp0   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_6:	reghdfe t_drive d1gp_bp_atp1   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_7:	reghdfe t_drive d1gp_bp_atp2   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_8:	reghdfe t_drive d1gp_bp_atp3   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_9:	reghdfe t_drive d1gp_bp_atp4   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_10:	reghdfe t_drive d1gp_bp_atp5   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
eststo tq1b_11:	reghdfe t_drive d1gp_bp_atp6   if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rndl2	"d2gp_bp_atn3 d2gp d2gp_bp_atn2 d2gp d2gp_bp_atn1 d2gp d2gp_bp_atp0 d2gp d2gp_bp_atp1 d2gp d2gp_bp_atp2 d2gp d2gp_bp_atp3 d2gp d2gp_bp_atp4 d2gp d2gp_bp_atp5 d2gp d2gp_bp_atp6 d2gp"
local 	rndl1	"d1gp_bp_atn3 d1gp d1gp_bp_atn2 d1gp d1gp_bp_atn1 d1gp d1gp_bp_atp0 d1gp d1gp_bp_atp1 d1gp d1gp_bp_atp2 d1gp d1gp_bp_atp3 d1gp d1gp_bp_atp4 d1gp d1gp_bp_atp5 d1gp d1gp_bp_atp6 d1gp"

esttab 	tq1a_* using "./results/table_a15/compare_dlreald2.tex", rename(`rndl2') booktabs replace `tabprefs' 
esttab 	tq1b_* using "./results/table_a14/compare_dlreald1.tex", rename(`rndl1') booktabs replace `tabprefs' 

eststo clear
clear
log close
