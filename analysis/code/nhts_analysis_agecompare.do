* Last update 3-18-2019
*==============================================================================*
*                      	   NHTS analysis do file                               *
*==============================================================================*
* This program uses 1990 and later NHTS data to investigate driving decisions.

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

/* ADD IN DL DATA */
gen		yr_at16 = yr_16_new
rename 	statefip stfip
merge m:1 stfip yr_at16  using "./output/dlpanel_prepped.dta"
keep	if _merge==3 /* Unmatched are post 2008 or pre 1967 */
drop	_merge year yr_at16
rename 	stfip statefip
/* END: Add in DL */

local 	agelist 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30

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

foreach diff of numlist 1/4 {
	gen 	year = round(min_age_full) + (yr_16_new - 16) - `diff'

	merge m:1 year statefip using "./output/gasprice_prepped.dta", keepusing(gas_price gas_price_99 d1gp_bp d2gp_bp) gen(_mergen`diff')

	rename	gas_price gas_price_atn`diff'
	rename	gas_price_99 real_gp_atn`diff'
	rename	d1gp_bp  d1gp_now_atn`diff'
	rename	d2gp_bp  d2gp_now_atn`diff'

	drop if _mergen`diff'==2

	rename 	year yr_fulln`diff'
	lab var yr_fulln`diff' "Year before/after (`diff') full age" 
}

foreach diff of numlist 0/6 {
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

sum miles_per_psn
sum miles_per_psn if miles_per_psn>0

/* Define treatment using all vehicle data, enforce topcode of 115k miles */

gen		lvmt_pc 	= log(min(miles_per_psn_ALL,115000))

compress 

********************************
** Panel Regressions 		 ***
********************************

** Longer Model
eststo tc1b_2:	reghdfe lvmt_pc d1gp_now_at13  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_3:	reghdfe lvmt_pc d1gp_now_at14 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_4:	reghdfe lvmt_pc d1gp_now_at15 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_5:	reghdfe lvmt_pc d1gp_now_at16 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_6:	reghdfe lvmt_pc d1gp_now_at17 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_7:	reghdfe lvmt_pc d1gp_now_at18 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_8:	reghdfe lvmt_pc d1gp_now_at19 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_9:	reghdfe lvmt_pc d1gp_now_at20 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_10:	reghdfe lvmt_pc d1gp_now_at21 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_11:	reghdfe lvmt_pc d1gp_now_at22 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_12:	reghdfe lvmt_pc d1gp_now_at23 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_13:	reghdfe lvmt_pc d1gp_now_at24 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_14:	reghdfe lvmt_pc d1gp_now_at25 if age>26 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_15:	reghdfe lvmt_pc d1gp_now_at26 if age>27 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_16:	reghdfe lvmt_pc d1gp_now_at27 if age>28 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_17:	reghdfe lvmt_pc d1gp_now_at28 if age>29 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_18:	reghdfe lvmt_pc d1gp_now_at29 if age>30 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

local 	rn1	"d1gp_now_at13 d1gp d1gp_now_at14 d1gp d1gp_now_at15 d1gp d1gp_now_at16 d1gp d1gp_now_at17 d1gp d1gp_now_at18 d1gp d1gp_now_at19 d1gp d1gp_now_at20 d1gp d1gp_now_at21 d1gp d1gp_now_at22 d1gp d1gp_now_at23 d1gp d1gp_now_at24 d1gp d1gp_now_at25 d1gp d1gp_now_at26 d1gp d1gp_now_at27 d1gp d1gp_now_at28 d1gp d1gp_now_at29 d1gp"

esttab 	tc1b_* using "./results/panel_nhts/compare_reald1ages_long.tex", rename(`rn1') booktabs replace `tabprefs' 

eststo clear

** No Quadratic

eststo clear

eststo tc1a_1:	reghdfe lvmt_pc d2gp_now_at12  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_2:	reghdfe lvmt_pc d2gp_now_at13  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_3:	reghdfe lvmt_pc d2gp_now_at14  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_4:	reghdfe lvmt_pc d2gp_now_at15  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_5:	reghdfe lvmt_pc d2gp_now_at16  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_6:	reghdfe lvmt_pc d2gp_now_at17  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_7:	reghdfe lvmt_pc d2gp_now_at18  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_8:	reghdfe lvmt_pc d2gp_now_at19  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_9:	reghdfe lvmt_pc d2gp_now_at20  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_10:	reghdfe lvmt_pc d2gp_now_at21  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_11:	reghdfe lvmt_pc d2gp_now_at22  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tc1b_1:	reghdfe lvmt_pc d1gp_now_at12  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_2:	reghdfe lvmt_pc d1gp_now_at13  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_3:	reghdfe lvmt_pc d1gp_now_at14 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_4:	reghdfe lvmt_pc d1gp_now_at15 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_5:	reghdfe lvmt_pc d1gp_now_at16 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_6:	reghdfe lvmt_pc d1gp_now_at17 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_7:	reghdfe lvmt_pc d1gp_now_at18 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_8:	reghdfe lvmt_pc d1gp_now_at19 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_9:	reghdfe lvmt_pc d1gp_now_at20 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_10:	reghdfe lvmt_pc d1gp_now_at21 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_11:	reghdfe lvmt_pc d1gp_now_at22 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tc1c_1:	reghdfe lvmt_pc real_gp_at12 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_2:	reghdfe lvmt_pc real_gp_at13 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_3:	reghdfe lvmt_pc real_gp_at14 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_4:	reghdfe lvmt_pc real_gp_at15 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_5:	reghdfe lvmt_pc real_gp_at16 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_6:	reghdfe lvmt_pc real_gp_at17 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_7:	reghdfe lvmt_pc real_gp_at18 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_8:	reghdfe lvmt_pc real_gp_at19 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_9:	reghdfe lvmt_pc real_gp_at20 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_10:	reghdfe lvmt_pc real_gp_at21 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_11:	reghdfe lvmt_pc real_gp_at22 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)


eststo tq1a_1:	reghdfe lvmt_pc d2gp_now_atn4 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_2:	reghdfe lvmt_pc d2gp_now_atn3 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_3:	reghdfe lvmt_pc d2gp_now_atn2 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_4:	reghdfe lvmt_pc d2gp_now_atn1 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_5:	reghdfe lvmt_pc d2gp_now_atp0 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_6:	reghdfe lvmt_pc d2gp_now_atp1 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_7:	reghdfe lvmt_pc d2gp_now_atp2 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_8:	reghdfe lvmt_pc d2gp_now_atp3 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_9:	reghdfe lvmt_pc d2gp_now_atp4 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_10:	reghdfe lvmt_pc d2gp_now_atp5 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_11:	reghdfe lvmt_pc d2gp_now_atp6 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tq1b_1:	reghdfe lvmt_pc d1gp_now_atn4 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_2:	reghdfe lvmt_pc d1gp_now_atn3 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_3:	reghdfe lvmt_pc d1gp_now_atn2 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_4:	reghdfe lvmt_pc d1gp_now_atn1 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_5:	reghdfe lvmt_pc d1gp_now_atp0 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_6:	reghdfe lvmt_pc d1gp_now_atp1 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_7:	reghdfe lvmt_pc d1gp_now_atp2 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_8:	reghdfe lvmt_pc d1gp_now_atp3 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_9:	reghdfe lvmt_pc d1gp_now_atp4 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_10:	reghdfe lvmt_pc d1gp_now_atp5 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_11:	reghdfe lvmt_pc d1gp_now_atp6 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tq1c_1:	reghdfe lvmt_pc real_gp_atn4 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_2:	reghdfe lvmt_pc real_gp_atn3 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_3:	reghdfe lvmt_pc real_gp_atn2 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_4:	reghdfe lvmt_pc real_gp_atn1 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_5:	reghdfe lvmt_pc real_gp_atp0 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_6:	reghdfe lvmt_pc real_gp_atp1 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_7:	reghdfe lvmt_pc real_gp_atp2 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_8:	reghdfe lvmt_pc real_gp_atp3 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_9:	reghdfe lvmt_pc real_gp_atp4 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_10:	reghdfe lvmt_pc real_gp_atp5 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_11:	reghdfe lvmt_pc real_gp_atp6 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

estimates drop t?1?_1

local 	rn2	"d2gp_now_at13 d2gp d2gp_now_at14 d2gp d2gp_now_at15 d2gp d2gp_now_at16 d2gp d2gp_now_at17 d2gp d2gp_now_at18 d2gp d2gp_now_at19 d2gp d2gp_now_at20 d2gp d2gp_now_at21 d2gp d2gp_now_at22 d2gp"
local 	rn1	"d1gp_now_at13 d1gp d1gp_now_at14 d1gp d1gp_now_at15 d1gp d1gp_now_at16 d1gp d1gp_now_at17 d1gp d1gp_now_at18 d1gp d1gp_now_at19 d1gp d1gp_now_at20 d1gp d1gp_now_at21 d1gp d1gp_now_at22 d1gp"
local 	rnlev	"real_gp_at13 lev real_gp_at14 lev real_gp_at15 lev real_gp_at16 lev real_gp_at17 lev real_gp_at18 lev real_gp_at19 lev real_gp_at20 lev real_gp_at21 lev real_gp_at22 lev"

local 	rndl2	"d2gp_now_atn3 d2gp d2gp_now_atn2 d2gp d2gp_now_atn1 d2gp d2gp_now_atp0 d2gp d2gp_now_atp1 d2gp d2gp_now_atp2 d2gp d2gp_now_atp3 d2gp d2gp_now_atp4 d2gp d2gp_now_atp5 d2gp d2gp_now_atp6 d2gp"
local 	rndl1	"d1gp_now_atn3 d1gp d1gp_now_atn2 d1gp d1gp_now_atn1 d1gp d1gp_now_atp0 d1gp d1gp_now_atp1 d1gp d1gp_now_atp2 d1gp d1gp_now_atp3 d1gp d1gp_now_atp4 d1gp d1gp_now_atp5 d1gp d1gp_now_atp6 d1gp"
local 	rndllev	"real_gp_atn3 lev real_gp_atn2 lev real_gp_atn1 lev real_gp_atp0 lev real_gp_atp1 lev real_gp_atp2 lev real_gp_atp3 lev real_gp_atp4 lev real_gp_atp5 lev real_gp_atp6 lev"

esttab 	tc1a_* using "./results/panel_nhts/compare_reald2ages.tex", rename(`rn2') booktabs replace `tabprefs' 
esttab 	tc1b_* using "./results/panel_nhts/compare_reald1ages.tex", rename(`rn1') booktabs replace `tabprefs' 
esttab 	tc1c_* using "./results/panel_nhts/compare_reallevels.tex", rename(`rnlev') booktabs replace `tabprefs' 

esttab 	tq1a_* using "./results/panel_nhts/compare_dlreald2ages.tex", rename(`rndl2') booktabs replace `tabprefs' 
esttab 	tq1b_* using "./results/panel_nhts/compare_dlreald1ages.tex", rename(`rndl1') booktabs replace `tabprefs' 
esttab 	tq1c_* using "./results/panel_nhts/compare_dlreallevels.tex", rename(`rndllev') booktabs replace `tabprefs' 

** With Quadratic

eststo clear

eststo tc1a_1:	reghdfe lvmt_pc d2gp_now_at12 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_2:	reghdfe lvmt_pc d2gp_now_at13 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_3:	reghdfe lvmt_pc d2gp_now_at14 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_4:	reghdfe lvmt_pc d2gp_now_at15 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_5:	reghdfe lvmt_pc d2gp_now_at16 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_6:	reghdfe lvmt_pc d2gp_now_at17 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_7:	reghdfe lvmt_pc d2gp_now_at18 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_8:	reghdfe lvmt_pc d2gp_now_at19 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_9:	reghdfe lvmt_pc d2gp_now_at20 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_10:	reghdfe lvmt_pc d2gp_now_at21 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1a_11:	reghdfe lvmt_pc d2gp_now_at22 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tc1b_1:	reghdfe lvmt_pc d1gp_now_at12 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_2:	reghdfe lvmt_pc d1gp_now_at13 c.byr##c.byr 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_3:	reghdfe lvmt_pc d1gp_now_at14 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_4:	reghdfe lvmt_pc d1gp_now_at15 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_5:	reghdfe lvmt_pc d1gp_now_at16 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_6:	reghdfe lvmt_pc d1gp_now_at17 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_7:	reghdfe lvmt_pc d1gp_now_at18 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_8:	reghdfe lvmt_pc d1gp_now_at19 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_9:	reghdfe lvmt_pc d1gp_now_at20 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_10:	reghdfe lvmt_pc d1gp_now_at21 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1b_11:	reghdfe lvmt_pc d1gp_now_at22 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tc1c_1:	reghdfe lvmt_pc real_gp_at12 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_2:	reghdfe lvmt_pc real_gp_at13 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_3:	reghdfe lvmt_pc real_gp_at14 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_4:	reghdfe lvmt_pc real_gp_at15 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_5:	reghdfe lvmt_pc real_gp_at16 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_6:	reghdfe lvmt_pc real_gp_at17 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_7:	reghdfe lvmt_pc real_gp_at18 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_8:	reghdfe lvmt_pc real_gp_at19 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_9:	reghdfe lvmt_pc real_gp_at20 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_10:	reghdfe lvmt_pc real_gp_at21 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc1c_11:	reghdfe lvmt_pc real_gp_at22 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)


eststo tq1a_1:	reghdfe lvmt_pc d2gp_now_atn4 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_2:	reghdfe lvmt_pc d2gp_now_atn3 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_3:	reghdfe lvmt_pc d2gp_now_atn2 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_4:	reghdfe lvmt_pc d2gp_now_atn1 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_5:	reghdfe lvmt_pc d2gp_now_atp0 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_6:	reghdfe lvmt_pc d2gp_now_atp1 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_7:	reghdfe lvmt_pc d2gp_now_atp2 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_8:	reghdfe lvmt_pc d2gp_now_atp3 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_9:	reghdfe lvmt_pc d2gp_now_atp4 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_10:	reghdfe lvmt_pc d2gp_now_atp5 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1a_11:	reghdfe lvmt_pc d2gp_now_atp6 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tq1b_1:	reghdfe lvmt_pc d1gp_now_atn4 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_2:	reghdfe lvmt_pc d1gp_now_atn3 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_3:	reghdfe lvmt_pc d1gp_now_atn2 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_4:	reghdfe lvmt_pc d1gp_now_atn1 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_5:	reghdfe lvmt_pc d1gp_now_atp0 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_6:	reghdfe lvmt_pc d1gp_now_atp1 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_7:	reghdfe lvmt_pc d1gp_now_atp2 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_8:	reghdfe lvmt_pc d1gp_now_atp3 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_9:	reghdfe lvmt_pc d1gp_now_atp4 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_10:	reghdfe lvmt_pc d1gp_now_atp5 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1b_11:	reghdfe lvmt_pc d1gp_now_atp6 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

eststo tq1c_1:	reghdfe lvmt_pc real_gp_atn4 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_2:	reghdfe lvmt_pc real_gp_atn3 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_3:	reghdfe lvmt_pc real_gp_atn2 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_4:	reghdfe lvmt_pc real_gp_atn1 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_5:	reghdfe lvmt_pc real_gp_atp0 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_6:	reghdfe lvmt_pc real_gp_atp1 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_7:	reghdfe lvmt_pc real_gp_atp2 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_8:	reghdfe lvmt_pc real_gp_atp3 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_9:	reghdfe lvmt_pc real_gp_atp4 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_10:	reghdfe lvmt_pc real_gp_atp5 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tq1c_11:	reghdfe lvmt_pc real_gp_atp6 c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

estimates drop t?1?_1

local 	rn2	"d2gp_now_at13 d2gp d2gp_now_at14 d2gp d2gp_now_at15 d2gp d2gp_now_at16 d2gp d2gp_now_at17 d2gp d2gp_now_at18 d2gp d2gp_now_at19 d2gp d2gp_now_at20 d2gp d2gp_now_at21 d2gp d2gp_now_at22 d2gp"
local 	rn1	"d1gp_now_at13 d1gp d1gp_now_at14 d1gp d1gp_now_at15 d1gp d1gp_now_at16 d1gp d1gp_now_at17 d1gp d1gp_now_at18 d1gp d1gp_now_at19 d1gp d1gp_now_at20 d1gp d1gp_now_at21 d1gp d1gp_now_at22 d1gp"
local 	rnlev	"real_gp_at13 lev real_gp_at14 lev real_gp_at15 lev real_gp_at16 lev real_gp_at17 lev real_gp_at18 lev real_gp_at19 lev real_gp_at20 lev real_gp_at21 lev real_gp_at22 lev"

local 	rndl2	"d2gp_now_atn3 d2gp d2gp_now_atn2 d2gp d2gp_now_atn1 d2gp d2gp_now_atp0 d2gp d2gp_now_atp1 d2gp d2gp_now_atp2 d2gp d2gp_now_atp3 d2gp d2gp_now_atp4 d2gp d2gp_now_atp5 d2gp d2gp_now_atp6 d2gp"
local 	rndl1	"d1gp_now_atn3 d1gp d1gp_now_atn2 d1gp d1gp_now_atn1 d1gp d1gp_now_atp0 d1gp d1gp_now_atp1 d1gp d1gp_now_atp2 d1gp d1gp_now_atp3 d1gp d1gp_now_atp4 d1gp d1gp_now_atp5 d1gp d1gp_now_atp6 d1gp"
local 	rndllev	"real_gp_atn3 lev real_gp_atn2 lev real_gp_atn1 lev real_gp_atp0 lev real_gp_atp1 lev real_gp_atp2 lev real_gp_atp3 lev real_gp_atp4 lev real_gp_atp5 lev real_gp_atp6 lev"

esttab 	tc1a_* using "./results/panel_nhts/compareq_reald2ages.tex", rename(`rn2') booktabs replace `tabprefs' 
esttab 	tc1b_* using "./results/panel_nhts/compareq_reald1ages.tex", rename(`rn1') booktabs replace `tabprefs' 
esttab 	tc1c_* using "./results/panel_nhts/compareq_reallevels.tex", rename(`rnlev') booktabs replace `tabprefs' 

esttab 	tq1a_* using "./results/panel_nhts/compareq_dlreald2ages.tex", rename(`rndl2') booktabs replace `tabprefs' 
esttab 	tq1b_* using "./results/panel_nhts/compareq_dlreald1ages.tex", rename(`rndl1') booktabs replace `tabprefs' 
esttab 	tq1c_* using "./results/panel_nhts/compareq_dlreallevels.tex", rename(`rndllev') booktabs replace `tabprefs' 

log close
eststo clear
clear
