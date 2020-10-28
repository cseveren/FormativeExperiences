
local 	logf "`1'" 
log using "`logf'", replace text

use 	"./output/NHTScombined_per.dta", clear

**************************************
******* Merge in Gas Price ***********
**************************************

rename whomain_age age

tab		age
drop if age<=24
drop if age>54
drop 	_merge

destring hhstfips, replace
rename hhstfips statefip

destring r_sex, replace
replace	r_sex = . if r_sex<0
rename	r_sex sex

/* ADD IN DL DATA */
gen		yr_at16 = yr_16_new
rename 	statefip stfip
merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename 	stfip statefip
/* END: Add in DL */

local 	agelist 16 17 18

foreach age of local agelist {
	gen 	year = yr_16_new + (`age' - 16)

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_merge`age')

	rename	gas_price gas_price_at`age'
	rename	gas_price_99 real_gp_at`age'
	rename	d1gp_bp d1gp_now_at`age'
	rename	d2gp_bp d2gp_now_at`age'

	drop if _merge`age'==2

	rename 	year yr_age`age'
	lab var yr_age`age' "Year Turned `age'" 
}

/* 	_merge==1 are years with older people but no gasoline data
	_merge==2 are years that are not yet adulted
*/

drop if _merge16!=3
drop	_merge*

foreach diff of numlist 0/2 {
	gen 	year = round(min_age_full) + (yr_16_new - 16) + `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_mergep`diff')

	rename	gas_price gas_price_atp`diff'
	rename	gas_price_99 real_gp_atp`diff'
	rename	d1gp_bp  d1gp_now_atp`diff'
	rename	d2gp_bp  d2gp_now_atp`diff'

	drop if _mergep`diff'==2

	rename 	year yr_fullp`diff'
	lab var yr_fullp`diff' "Year before/after (`diff') full age" 
}

drop if statename=="HI"
drop if statename=="AK"
	/* Gas Price panel balanaced except AK HI */

gen 	age2 = age*age

gen		white = (hh_race==1)

gen		urban_bin = 0
replace	urban_bin = 1 if urban==1 & nhtsyear<=1995 & urban!=.
replace	urban_bin = 1 if urban<=3 & nhtsyear>=2001 & urban!=.

gen		ldens = ln(htppopdn_cont)
replace ldens = . if htppopdn_cont==999998
replace ldens = 0 if htppopdn_cont==0 /* Not true zeros, from rounding error */


/* Income bins (quintiles), see Table H-1 and H-3 */
	/* https://www.census.gov/data/tables/time-series/demo/income-poverty/historical-income-households.html */

gen		hhi_bin = .

replace hhi_bin = 1 if nhtsyear==1990 & (hhincome==1 | hhincome==2 | hhincome==3)
replace hhi_bin = 1 if nhtsyear==1995 & (hhincome==1 | hhincome==2 | hhincome==3)
replace hhi_bin = 1 if nhtsyear==2001 & (hhincome==1 | hhincome==2 | hhincome==3 | hhincome==4)
replace hhi_bin = 1 if nhtsyear==2009 & (hhincome==1 | hhincome==2 | hhincome==3 | hhincome==4)
replace hhi_bin = 1 if nhtsyear==2017 & (hhincome==1 | hhincome==2 | hhincome==3)

replace hhi_bin = 2 if nhtsyear==1990 & (hhincome==4 | hhincome==5)
replace hhi_bin = 2 if nhtsyear==1995 & (hhincome==4 | hhincome==5)
replace hhi_bin = 2 if nhtsyear==2001 & (hhincome==5 | hhincome==6 | hhincome==7 )
replace hhi_bin = 2 if nhtsyear==2009 & (hhincome==5 | hhincome==6 | hhincome==7 | hhincome==8)
replace hhi_bin = 2 if nhtsyear==2017 & (hhincome==4 | hhincome==5)

replace hhi_bin = 3 if nhtsyear==1990 & (hhincome==6 | hhincome==7)
replace hhi_bin = 3 if nhtsyear==1995 & (hhincome==6 | hhincome==7 | hhincome==8)
replace hhi_bin = 3 if nhtsyear==2001 & (hhincome==8 | hhincome==9 | hhincome==10 | hhincome==11)
replace hhi_bin = 3 if nhtsyear==2009 & (hhincome==9 | hhincome==10 | hhincome==11 | hhincome==12)
replace hhi_bin = 3 if nhtsyear==2017 & (hhincome==6)

replace hhi_bin = 4 if nhtsyear==1990 & (hhincome==8 | hhincome==9 | hhincome==10 | hhincome==11)
replace hhi_bin = 4 if nhtsyear==1995 & (hhincome==9 | hhincome==10 | hhincome==11 | hhincome==12 | hhincome==13)
replace hhi_bin = 4 if nhtsyear==2001 & (hhincome==12 | hhincome==13 | hhincome==14 | hhincome==15 | hhincome==16)
replace hhi_bin = 4 if nhtsyear==2009 & (hhincome==13 | hhincome==14 | hhincome==15 | hhincome==16 | hhincome==17)
replace hhi_bin = 4 if nhtsyear==2017 & (hhincome==7 | hhincome==8)

replace hhi_bin = 5 if nhtsyear==1990 & (hhincome==12 | hhincome==13 | hhincome==14 | hhincome==15 | hhincome==16 | hhincome==17)
replace hhi_bin = 5 if nhtsyear==1995 & (hhincome==14 | hhincome==15 | hhincome==16 | hhincome==17 | hhincome==18)
replace hhi_bin = 5 if nhtsyear==2001 & (hhincome==17 | hhincome==18)
replace hhi_bin = 5 if nhtsyear==2009 & (hhincome==18)
replace hhi_bin = 5 if nhtsyear==2017 & (hhincome==9 | hhincome==10 | hhincome==11)

tab hhi_bin nhtsyear

egen 	stateid = group(statefip)
egen	stsamyr_fe = group(statefip nhtsyear)	
egen	hhi_bin_yr = group(hhi_bin nhtsyear)

gen 	anyhhveh = .
replace anyhhveh = 0 if hhvehcnt==0
replace anyhhveh = 1 if hhvehcnt>0 & mi(hhvehcnt)==0

gen 	expfllprr = round(expfllpr) /* for use with ppmlhdfe, which doesn't accept aw */

egen 	age_f_grps=cut(min_age_full), at(15(1)19)
replace age_f_grps=16 if age_f_grps==15

egen 	age_i_grps=cut(min_int_age), at(14(1)17)
replace age_i_grps=15 if age_i_grps==14	

gen		byr = yr_16_new-16

/* Define treatment using all vehicle data, enforce topcode of 115k miles */

gen		lvmt_pc 	= log(min(miles_per_psn_ALL,115000))

gen		mile_per_psn_ALL_lt115 = min(miles_per_psn_ALL,115000)
sum 	mile_per_psn_ALL_lt115
sum 	mile_per_psn_ALL_lt115 if mile_per_psn_ALL_lt115>0

*************

est clear

/* GDL and stuff */
local demc white urban_bin famsize i.sex

eststo dle_1:	reghdfe lvmt_pc min_age_full									[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dle_2:	reghdfe lvmt_pc min_int_age 									[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dle_3:	reghdfe lvmt_pc min_age_full min_int_age 						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_4:	reghdfe lvmt_pc min_age_full min_int_age `demc'					[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_5:	reghdfe lvmt_pc min_age_full min_int_age `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_6:	reghdfe lvmt_pc min_age_full min_int_age `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

eststo dle_7:	reghdfe lvmt_pc min_age_full min_int_age `demc' c.byr##c.byr 	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
test min_age_full min_int_age
estadd scalar F_diff = r(F)
estadd scalar p_diff = r(p)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par))  stats(r2_a N F_diff p_diff, fmt(%9.4f %9.0g %9.3f %9.3f) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
 
esttab 	dle_* using "./results/table6/nhts_dl.tex", booktabs replace `tabprefs' 


eststo clear
log close
clear
