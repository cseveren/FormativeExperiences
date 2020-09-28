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

compress 

********************************
** Panel Regressions 		 ***
********************************

eststo clear

/* sandbox */
/*
gen 	d2gp_now_atp1_sq = d2gp_now_atp1*d2gp_now_atp1

reghdfe lvmt_pc d2gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

reghdfe lvmt_pc d2gp_now_atp1 d2gp_now_atp1_sq [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)




reghdfe lvmt_pc d2gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
reghdfe lvmt_pc d2gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
reghdfe lvmt_pc d2gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear yr_age16) cluster(stateid)
reghdfe lvmt_pc d2gp_now_atp1 age age2	[aw=expfllpr], a(stateid nhtsyear yr_age16) cluster(stateid)
reghdfe lvmt_pc d2gp_now_atp1 age age2	[aw=expfllpr], a(stsamyr_fe hhi_bin_yr yr_age16) cluster(stateid)



reghdfe lvmt_pc d2gp_now_at17  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

reghdfe lvmt_pc d2gp_now_at17 if employed==1 						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
*/

/* Summary Stats */ 


eststo 	sum1: estpost tabstat mile_per_psn_ALL_lt115 d2gp_now_at17 white urban_bin famsize sex age [aw=expfllpr], s(mean sd count) c(s) 
eststo 	sum2: estpost tabstat mile_per_psn_ALL_lt115 if mile_per_psn_ALL_lt115>0 & !mi(mile_per_psn_ALL_lt115) [aw=expfllpr], s(mean sd min max count) c(s) 

esttab sum? using "./results/panel_nhts/summary_stats.tex", booktabs replace cells(mean sd min max count)

	

/* Main specifications at different ages */ 

local demc white urban_bin famsize i.sex

eststo tc2a_1:	reghdfe lvmt_pc d2gp_now_at18  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2a_2:	reghdfe lvmt_pc d2gp_now_at18 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2a_3:	reghdfe lvmt_pc d2gp_now_at18 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2a_4:	reghdfe lvmt_pc d2gp_now_at18 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2a_5:	reghdfe lvmt_pc d2gp_now_at18 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2b_1:	reghdfe lvmt_pc d2gp_now_at17  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2b_2:	reghdfe lvmt_pc d2gp_now_at17 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2b_3:	reghdfe lvmt_pc d2gp_now_at17 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2b_4:	reghdfe lvmt_pc d2gp_now_at17 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2b_5:	reghdfe lvmt_pc d2gp_now_at17 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2c_1:	reghdfe lvmt_pc d1gp_now_at18  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2c_2:	reghdfe lvmt_pc d1gp_now_at18 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2c_3:	reghdfe lvmt_pc d1gp_now_at18 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2c_4:	reghdfe lvmt_pc d1gp_now_at18 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2c_5:	reghdfe lvmt_pc d1gp_now_at18 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2d_1:	reghdfe lvmt_pc d1gp_now_at17  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2d_2:	reghdfe lvmt_pc d1gp_now_at17 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2d_3:	reghdfe lvmt_pc d1gp_now_at17 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2d_4:	reghdfe lvmt_pc d1gp_now_at17 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2d_5:	reghdfe lvmt_pc d1gp_now_at17 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2e_1:	reghdfe lvmt_pc d1gp_now_at16  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2e_2:	reghdfe lvmt_pc d1gp_now_at16 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2e_3:	reghdfe lvmt_pc d1gp_now_at16 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2e_4:	reghdfe lvmt_pc d1gp_now_at16 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2e_5:	reghdfe lvmt_pc d1gp_now_at16 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc2f_1:	reghdfe lvmt_pc real_gp_at16  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2f_2:	reghdfe lvmt_pc real_gp_at16  `demc' 				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc2f_3:	reghdfe lvmt_pc real_gp_at16  `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc2f_4:	reghdfe lvmt_pc real_gp_at16  `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc2f_5:	reghdfe lvmt_pc real_gp_at16  `demc'  c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tc2a_* using "./results/panel_nhts/mainspecs_d2_18.tex", booktabs replace `tabprefs'
esttab 	tc2b_* using "./results/panel_nhts/mainspecs_d2_17.tex", booktabs replace `tabprefs'
esttab 	tc2c_* using "./results/panel_nhts/mainspecs_d1_18.tex", booktabs replace `tabprefs'
esttab 	tc2d_* using "./results/panel_nhts/mainspecs_d1_17.tex", booktabs replace `tabprefs'
esttab 	tc2e_* using "./results/panel_nhts/mainspecs_d1_16.tex", booktabs replace `tabprefs'
esttab 	tc2f_* using "./results/panel_nhts/mainspecs_lev16.tex", booktabs replace `tabprefs'

eststo clear

/* Main specifications at different driver license minimums */ 

local demc white urban_bin famsize i.sex

eststo tdla_1:	reghdfe lvmt_pc d2gp_now_atp2  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdla_2:	reghdfe lvmt_pc d2gp_now_atp2 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdla_3:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdla_4:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdla_5:	reghdfe lvmt_pc d2gp_now_atp2 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdlb_1:	reghdfe lvmt_pc d2gp_now_atp1  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlb_2:	reghdfe lvmt_pc d2gp_now_atp1 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlb_3:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdlb_4:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdlb_5:	reghdfe lvmt_pc d2gp_now_atp1 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdlc_1:	reghdfe lvmt_pc d1gp_now_atp2  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlc_2:	reghdfe lvmt_pc d1gp_now_atp2 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlc_3:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdlc_4:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdlc_5:	reghdfe lvmt_pc d1gp_now_atp2 `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdld_1:	reghdfe lvmt_pc d1gp_now_atp1  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdld_2:	reghdfe lvmt_pc d1gp_now_atp1 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdld_3:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdld_4:	reghdfe lvmt_pc d1gp_now_atp1 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdld_5:	reghdfe lvmt_pc d1gp_now_atp1 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdle_1:	reghdfe lvmt_pc d1gp_now_atp0  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdle_2:	reghdfe lvmt_pc d1gp_now_atp0 `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdle_3:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdle_4:	reghdfe lvmt_pc d1gp_now_atp0 `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdle_5:	reghdfe lvmt_pc d1gp_now_atp0 `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tdlf_1:	reghdfe lvmt_pc real_gp_atp0  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlf_2:	reghdfe lvmt_pc real_gp_atp0  `demc' 				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tdlf_3:	reghdfe lvmt_pc real_gp_atp0  `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tdlf_4:	reghdfe lvmt_pc real_gp_atp0  `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tdlf_5:	reghdfe lvmt_pc real_gp_atp0  `demc'  c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tdla_* using "./results/panel_nhts/mainspecs_d2_p2.tex", booktabs replace `tabprefs'
esttab 	tdlb_* using "./results/panel_nhts/mainspecs_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tdlc_* using "./results/panel_nhts/mainspecs_d1_p2.tex", booktabs replace `tabprefs'
esttab 	tdld_* using "./results/panel_nhts/mainspecs_d1_p1.tex", booktabs replace `tabprefs'
esttab 	tdle_* using "./results/panel_nhts/mainspecs_d1_p0.tex", booktabs replace `tabprefs'
esttab 	tdlf_* using "./results/panel_nhts/mainspecs_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Main specifications with cohort fixed effects */ 

local demc white urban_bin famsize i.sex

eststo tcogp_a_1:	reghdfe lvmt_pc d2gp_now_at18			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_a_2:	reghdfe lvmt_pc d2gp_now_at18 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_a_3:	reghdfe lvmt_pc d2gp_now_at18 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcogp_a_4:	reghdfe lvmt_pc d2gp_now_at18 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcogp_b_1:	reghdfe lvmt_pc d2gp_now_at17			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_b_2:	reghdfe lvmt_pc d2gp_now_at17 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_b_3:	reghdfe lvmt_pc d2gp_now_at17 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcogp_b_4:	reghdfe lvmt_pc d2gp_now_at17 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcogp_c_1:	reghdfe lvmt_pc d1gp_now_at18			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_c_2:	reghdfe lvmt_pc d1gp_now_at18 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_c_3:	reghdfe lvmt_pc d1gp_now_at18 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcogp_c_4:	reghdfe lvmt_pc d1gp_now_at18 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcogp_d_1:	reghdfe lvmt_pc d1gp_now_at17			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_d_2:	reghdfe lvmt_pc d1gp_now_at17 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_d_3:	reghdfe lvmt_pc d1gp_now_at17 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcogp_d_4:	reghdfe lvmt_pc d1gp_now_at17 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcogp_e_1:	reghdfe lvmt_pc d1gp_now_at16			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_e_2:	reghdfe lvmt_pc d1gp_now_at16 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_e_3:	reghdfe lvmt_pc d1gp_now_at16 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcogp_e_4:	reghdfe lvmt_pc d1gp_now_at16 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcogp_f_1:	reghdfe lvmt_pc real_gp_at16 			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_f_2:	reghdfe lvmt_pc real_gp_at16 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcogp_f_3:	reghdfe lvmt_pc real_gp_at16 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcogp_f_4:	reghdfe lvmt_pc real_gp_at16 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)


eststo tcodl_a_1:	reghdfe lvmt_pc d2gp_now_atp2			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_a_2:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_a_3:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_a_4:	reghdfe lvmt_pc d2gp_now_atp2 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_b_1:	reghdfe lvmt_pc d2gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_b_2:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_b_3:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_b_4:	reghdfe lvmt_pc d2gp_now_atp1 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_c_1:	reghdfe lvmt_pc d1gp_now_atp2			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_c_2:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_c_3:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_c_4:	reghdfe lvmt_pc d1gp_now_atp2 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_d_1:	reghdfe lvmt_pc d1gp_now_atp1			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_d_2:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_d_3:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_d_4:	reghdfe lvmt_pc d1gp_now_atp1 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_e_1:	reghdfe lvmt_pc d1gp_now_atp0			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_e_2:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_e_3:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_e_4:	reghdfe lvmt_pc d1gp_now_atp0 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

eststo tcodl_f_1:	reghdfe lvmt_pc real_gp_atp0 			[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_f_2:	reghdfe lvmt_pc real_gp_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age) cluster(stateid)
eststo tcodl_f_3:	reghdfe lvmt_pc real_gp_atp0 `demc' 	[aw=expfllpr], a(stateid nhtsyear yr_age16 age hhi_bin_yr) cluster(stateid)
eststo tcodl_f_4:	reghdfe lvmt_pc real_gp_atp0 `demc' 	[aw=expfllpr], a(stsamyr_fe age yr_age16 hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcogp_a_* using "./results/panel_nhts/cohfespecs_d2_18.tex", booktabs replace `tabprefs'
esttab 	tcogp_b_* using "./results/panel_nhts/cohfespecs_d2_17.tex", booktabs replace `tabprefs'
esttab 	tcogp_c_* using "./results/panel_nhts/cohfespecs_d1_18.tex", booktabs replace `tabprefs'
esttab 	tcogp_d_* using "./results/panel_nhts/cohfespecs_d1_17.tex", booktabs replace `tabprefs'
esttab 	tcogp_e_* using "./results/panel_nhts/cohfespecs_d1_16.tex", booktabs replace `tabprefs'
esttab 	tcogp_f_* using "./results/panel_nhts/cohfespecs_lev16.tex", booktabs replace `tabprefs'

esttab 	tcodl_a_* using "./results/panel_nhts/cohfespecs_d2_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_b_* using "./results/panel_nhts/cohfespecs_d2_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_c_* using "./results/panel_nhts/cohfespecs_d1_p2.tex", booktabs replace `tabprefs'
esttab 	tcodl_d_* using "./results/panel_nhts/cohfespecs_d1_p1.tex", booktabs replace `tabprefs'
esttab 	tcodl_e_* using "./results/panel_nhts/cohfespecs_d1_p0.tex", booktabs replace `tabprefs'
esttab 	tcodl_f_* using "./results/panel_nhts/cohfespecs_levp0.tex", booktabs replace `tabprefs'

eststo clear

/* Other outcomes */ 

local demc white urban_bin famsize i.sex

eststo tc4a_1:	reghdfe lvmt_pc 		d2gp_now_at18 										[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc4a_2:	reghdfe lvmt_pc 		d2gp_now_at18 c.byr##c.byr `demc' 					[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc4a_3:	reghdfe lvmt_pc 		d2gp_now_at18 c.byr##c.byr `demc' 	if urban_bin==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc4a_4:	reghdfe miles_per_psn 	d2gp_now_at18 										[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc4a_5:	reghdfe miles_per_psn 	d2gp_now_at18 c.byr##c.byr `demc' 					[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc4a_6:	reghdfe miles_per_psn 	d2gp_now_at18 c.byr##c.byr `demc' 	if urban_bin==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc4a_7:	reghdfe miles_per_psn 	d2gp_now_at18 						if miles_per_psn>0 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc4a_8:	reghdfe miles_per_psn 	d2gp_now_at18 c.byr##c.byr `demc' 	if miles_per_psn>0 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc4a_9:	reghdfe miles_per_psn 	d2gp_now_at18 c.byr##c.byr `demc' 	if urban_bin==1 & miles_per_psn>0 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tc4a_* using "./results/panel_nhts/other_vmt_d2_18.tex", booktabs replace `tabprefs'

eststo clear

/* Age Heterogeneity */

gen		d2gp_age18_2534 = (age>=25 & age<=34)*d2gp_now_at18
gen		d2gp_age18_3544 = (age>=35 & age<=44)*d2gp_now_at18
gen		d2gp_age18_4554 = (age>=45 & age<=54)*d2gp_now_at18

gen		d2gp_age18_2529 = (age>=25 & age<=29)*d2gp_now_at18
gen		d2gp_age18_3034 = (age>=30 & age<=34)*d2gp_now_at18
gen		d2gp_age18_3539 = (age>=35 & age<=39)*d2gp_now_at18
gen		d2gp_age18_4044 = (age>=40 & age<=44)*d2gp_now_at18
gen		d2gp_age18_4549 = (age>=45 & age<=49)*d2gp_now_at18
gen		d2gp_age18_5054 = (age>=50 & age<=54)*d2gp_now_at18

gen		d2gp_agep2_2534 = (age>=25 & age<=34)*d2gp_now_atp2
gen		d2gp_agep2_3544 = (age>=35 & age<=44)*d2gp_now_atp2
gen		d2gp_agep2_4554 = (age>=45 & age<=54)*d2gp_now_atp2

gen		d2gp_agep2_2529 = (age>=25 & age<=29)*d2gp_now_atp2
gen		d2gp_agep2_3034 = (age>=30 & age<=34)*d2gp_now_atp2
gen		d2gp_agep2_3539 = (age>=35 & age<=39)*d2gp_now_atp2
gen		d2gp_agep2_4044 = (age>=40 & age<=44)*d2gp_now_atp2
gen		d2gp_agep2_4549 = (age>=45 & age<=49)*d2gp_now_atp2
gen		d2gp_agep2_5054 = (age>=50 & age<=54)*d2gp_now_atp2

local 	bin5yrs_18  d2gp_age18_2529 d2gp_age18_3034 d2gp_age18_3539 d2gp_age18_4044 d2gp_age18_4549 d2gp_age18_5054
local	bin10yrs_18 d2gp_age18_2534 d2gp_age18_3544 d2gp_age18_4554

local 	bin5yrs_p2  d2gp_agep2_2529 d2gp_agep2_3034 d2gp_agep2_3539 d2gp_agep2_4044 d2gp_agep2_4549 d2gp_agep2_5054
local	bin10yrs_p2 d2gp_agep2_2534 d2gp_agep2_3544 d2gp_agep2_4554

local demc white urban_bin famsize i.sex

eststo tcage_1:	reghdfe lvmt_pc  `bin5yrs_18' 	 					[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_2:	reghdfe lvmt_pc  `bin5yrs_18' `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tcage_3:	reghdfe lvmt_pc  `bin10yrs_18'	 					[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_4:	reghdfe lvmt_pc  `bin10yrs_18' `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tcage_5:	reghdfe lvmt_pc  `bin5yrs_p2'	 			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_6:	reghdfe lvmt_pc  `bin5yrs_p2' c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_7:	reghdfe lvmt_pc  `bin10yrs_p2'	 			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_8:	reghdfe lvmt_pc  `bin10yrs_p2' c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcage_? using "./results/panel_nhts/agehet_18p2.tex", booktabs replace `tabprefs'

eststo clear
drop  	d2gp_age??_????

gen		d2gp_age17_2534 = (age>=25 & age<=34)*d2gp_now_at17
gen		d2gp_age17_3544 = (age>=35 & age<=44)*d2gp_now_at17
gen		d2gp_age17_4554 = (age>=45 & age<=54)*d2gp_now_at17

gen		d2gp_age17_2529 = (age>=25 & age<=29)*d2gp_now_at17
gen		d2gp_age17_3034 = (age>=30 & age<=34)*d2gp_now_at17
gen		d2gp_age17_3539 = (age>=35 & age<=39)*d2gp_now_at17
gen		d2gp_age17_4044 = (age>=40 & age<=44)*d2gp_now_at17
gen		d2gp_age17_4549 = (age>=45 & age<=49)*d2gp_now_at17
gen		d2gp_age17_5054 = (age>=50 & age<=54)*d2gp_now_at17

gen		d2gp_agep1_2534 = (age>=25 & age<=34)*d2gp_now_atp1
gen		d2gp_agep1_3544 = (age>=35 & age<=44)*d2gp_now_atp1
gen		d2gp_agep1_4554 = (age>=45 & age<=54)*d2gp_now_atp1

gen		d2gp_agep1_2529 = (age>=25 & age<=29)*d2gp_now_atp1
gen		d2gp_agep1_3034 = (age>=30 & age<=34)*d2gp_now_atp1
gen		d2gp_agep1_3539 = (age>=35 & age<=39)*d2gp_now_atp1
gen		d2gp_agep1_4044 = (age>=40 & age<=44)*d2gp_now_atp1
gen		d2gp_agep1_4549 = (age>=45 & age<=49)*d2gp_now_atp1
gen		d2gp_agep1_5054 = (age>=50 & age<=54)*d2gp_now_atp1

local 	bin5yrs_17  d2gp_age17_2529 d2gp_age17_3034 d2gp_age17_3539 d2gp_age17_4044 d2gp_age17_4549 d2gp_age17_5054
local	bin10yrs_17 d2gp_age17_2534 d2gp_age17_3544 d2gp_age17_4554

local 	bin5yrs_p1  d2gp_agep1_2529 d2gp_agep1_3034 d2gp_agep1_3539 d2gp_agep1_4044 d2gp_agep1_4549 d2gp_agep1_5054
local	bin10yrs_p1 d2gp_agep1_2534 d2gp_agep1_3544 d2gp_agep1_4554

local demc white urban_bin famsize i.sex

eststo tcage_1:	reghdfe lvmt_pc  `bin5yrs_17' 	 					[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_2:	reghdfe lvmt_pc  `bin5yrs_17' `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tcage_3:	reghdfe lvmt_pc  `bin10yrs_17'	 					[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_4:	reghdfe lvmt_pc  `bin10yrs_17' `demc' c.byr##c.byr	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tcage_5:	reghdfe lvmt_pc  `bin5yrs_p1'	 			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_6:	reghdfe lvmt_pc  `bin5yrs_p1' c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_7:	reghdfe lvmt_pc  `bin10yrs_p1'	 			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tcage_8:	reghdfe lvmt_pc  `bin10yrs_p1' c.byr##c.byr	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tcage_? using "./results/panel_nhts/agehet_17p1.tex", booktabs replace `tabprefs'

eststo clear
drop  	d2gp_age??_????

/* Asymmetry  */
gen		d2gp_now_at18_pos = max(0, d2gp_now_at18) if !mi(d2gp_now_at18)
gen		d2gp_now_at18_neg = min(0, d2gp_now_at18) if !mi(d2gp_now_at18)

gen		d2gp_now_atp2_pos = max(0, d2gp_now_atp2) if !mi(d2gp_now_atp2)
gen		d2gp_now_atp2_neg = min(0, d2gp_now_atp2) if !mi(d2gp_now_atp2)

gen		d2gp_now_at17_pos = max(0, d2gp_now_at17) if !mi(d2gp_now_at17)
gen		d2gp_now_at17_neg = min(0, d2gp_now_at17) if !mi(d2gp_now_at17)

gen		d2gp_now_atp1_pos = max(0, d2gp_now_atp1) if !mi(d2gp_now_atp1)
gen		d2gp_now_atp1_neg = min(0, d2gp_now_atp1) if !mi(d2gp_now_atp1)

local demc white urban_bin famsize i.sex

eststo tc_asym8_1:	reghdfe lvmt_pc d2gp_now_at18_???  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc_asym8_2:	reghdfe lvmt_pc d2gp_now_at18_??? `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc_asym8_3:	reghdfe lvmt_pc d2gp_now_at18_??? `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc_asym8_4:	reghdfe lvmt_pc d2gp_now_at18_??? `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc_asym8_5:	reghdfe lvmt_pc d2gp_now_at18_??? `demc' c.byr##c.byr 	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo tc_asym7_1:	reghdfe lvmt_pc d2gp_now_at17_???  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc_asym7_2:	reghdfe lvmt_pc d2gp_now_at17_??? `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo tc_asym7_3:	reghdfe lvmt_pc d2gp_now_at17_??? `demc'			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo tc_asym7_4:	reghdfe lvmt_pc d2gp_now_at17_??? `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo tc_asym7_5:	reghdfe lvmt_pc d2gp_now_at17_??? `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo td_asym2_1:	reghdfe lvmt_pc d2gp_now_atp2_???  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo td_asym2_2:	reghdfe lvmt_pc d2gp_now_atp2_??? `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo td_asym2_3:	reghdfe lvmt_pc d2gp_now_atp2_??? `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo td_asym2_4:	reghdfe lvmt_pc d2gp_now_atp2_??? `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo td_asym2_5:	reghdfe lvmt_pc d2gp_now_atp2_??? `demc' c.byr##c.byr 	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo td_asym1_1:	reghdfe lvmt_pc d2gp_now_atp1_???  						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo td_asym1_2:	reghdfe lvmt_pc d2gp_now_atp1_??? `demc'				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo td_asym1_3:	reghdfe lvmt_pc d2gp_now_atp1_??? `demc'			 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo td_asym1_4:	reghdfe lvmt_pc d2gp_now_atp1_??? `demc'				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo td_asym1_5:	reghdfe lvmt_pc d2gp_now_atp1_??? `demc' c.byr##c.byr  	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	tc_asym8_? using "./results/panel_nhts/asym_d2_18.tex.tex", booktabs replace `tabprefs'
esttab 	tc_asym7_? using "./results/panel_nhts/asym_d2_17.tex.tex", booktabs replace `tabprefs'
esttab 	td_asym2_? using "./results/panel_nhts/asym_d2_p2.tex.tex", booktabs replace `tabprefs'
esttab 	td_asym1_? using "./results/panel_nhts/asym_d2_p1.tex.tex", booktabs replace `tabprefs'

/* GDL and stuff */
local demc white urban_bin famsize i.sex

eststo dle_1:	reghdfe lvmt_pc min_age_full min_int_age 						[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dle_2:	reghdfe lvmt_pc min_age_full min_int_age `demc'					[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dle_3:	reghdfe lvmt_pc min_age_full min_int_age `demc' 				[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo dle_4:	reghdfe lvmt_pc min_age_full min_int_age `demc' 				[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo dle_5:	reghdfe lvmt_pc min_age_full min_int_age `demc' c.byr##c.byr 	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 
 
esttab 	dle_* using "./results/nhts_dl/both_int.tex", booktabs replace `tabprefs' 

eststo clear


**********************************
** Close out

capture noisily log close
clear



