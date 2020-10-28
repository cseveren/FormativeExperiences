* Last update 2020
*==============================================================================*
*                      	   NHTS analysis do file                               *
*==============================================================================*
* This program uses 1990 and later NHTS data to investigate driving decisions.

local 	logf "`1'" 
log using "`logf'", replace text

use 	"./output/NHTScombined_veh.dta", clear

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

gegen 	GPMCombo_All = mean(GPMCombined) [aw=miles_per_psn_ALL], by(houseid personid nhtsyear)

sum 	GPMCombined [aw=expfllpr], d
gen		gpm_gtmedian = 0 if !mi(GPMCombined)
replace gpm_gtmedian = 1 if !mi(GPMCombined) & GPMCombined>0.05

sort	nhtsyear houseid personid vehid
bys 	houseid personid nhtsyear: gen idco = _n

sum 	GPMCombo_All if idco==1 [aw=expfllpr], d
gen		gpm_All_gtmedian = 0 if idco==1 & !mi(GPMCombo_All)
replace gpm_All_gtmedian = 1 if idco==1 & !mi(GPMCombo_All) & GPMCombo_All>0.05

replace vehyear = 1976 if vehyear<1976 & !mi(vehyear)
rename 	vehage vehage_original
gen		vehage = vehage_original

replace vehage = . if vehage==-9
replace vehage = nhtsyear - vehyear if mi(vehage)
replace	vehage = 20 if vehage>20 & !mi(vehage)

egen 	vehageyr = group(vehage vehyear)

gen		hi_eff = 0 /* Hybrid or electric */
replace hi_eff = 1 if fueltype==1 | hybrid==1
gegen 	hi_eff_All = max(hi_eff), by(houseid personid nhtsyear)

destring vehtype, replace
replace vehtype = . if vehtype<=0
replace vehtype = . if vehtype>=8

gen		bigveh = .
replace bigveh = 0 if vehtype==1 | vehtype==7
replace bigveh = 1 if vehtype==2 | vehtype==3 | vehtype==4 | vehtype==5 | vehtype==6
gegen 	bigveh_All = max(bigveh), by(houseid personid nhtsyear)


********************************
** Panel Regressions 		 ***
********************************

eststo clear

bys nhtsyear: sum GPMCombined [aw=expfllpr], d
bys nhtsyear: sum GPMCombo_All if idco==1 [aw=expfllpr], d
sum GPMCombined [aw=expfllpr], d
sum GPMCombo_All if idco==1 [aw=expfllpr], d
sum bigveh [aw=expfllpr], d
sum bigveh_All if idco==1 [aw=expfllpr], d

/* Summary Stats */

eststo 	gsum1: estpost tabstat GPMCombo_All bigveh_All if idco==1 [aw=expfllpr], s(mean sd min max count) c(s) 
eststo 	gsum2: estpost tabstat GPMCombined bigveh [aw=expfllpr], s(mean sd min max count) c(s) 

esttab gsum? using "./results/table_a2/summary_stats_gpm.tex", booktabs replace cells(mean sd min max count)

/*MERGE AT 17*/
est clear

local demc white urban_bin famsize i.sex

eststo gpm_tabA_1:	reghdfe GPMCombo_All d2gp_now_at18 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabA_2:	reghdfe GPMCombo_All d2gp_now_at18 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabA_3:	reghdfe GPMCombined d2gp_now_at18 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabA_4:	reghdfe GPMCombined d2gp_now_at18 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo gpm_tabA_5:	reghdfe bigveh_All 	d2gp_now_at18 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabA_6:	reghdfe bigveh_All 	d2gp_now_at18 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabA_7:	reghdfe bigveh 		d2gp_now_at18 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabA_8:	reghdfe bigveh		d2gp_now_at18 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)


eststo gpm_tabB_1:	reghdfe GPMCombo_All d2gp_now_at17 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabB_2:	reghdfe GPMCombo_All d2gp_now_at17 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabB_3:	reghdfe GPMCombined d2gp_now_at17 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabB_4:	reghdfe GPMCombined d2gp_now_at17 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo gpm_tabB_5:	reghdfe bigveh_All 	d2gp_now_at17 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabB_6:	reghdfe bigveh_All 	d2gp_now_at17 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabB_7:	reghdfe bigveh 		d2gp_now_at17 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabB_8:	reghdfe bigveh		d2gp_now_at17 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)


eststo gpm_tabC_1:	reghdfe GPMCombo_All d2gp_now_atp2 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabC_2:	reghdfe GPMCombo_All d2gp_now_atp2 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabC_3:	reghdfe GPMCombined d2gp_now_atp2 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabC_4:	reghdfe GPMCombined d2gp_now_atp2 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo gpm_tabC_5:	reghdfe bigveh_All 	d2gp_now_atp2 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabC_6:	reghdfe bigveh_All 	d2gp_now_atp2 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabC_7:	reghdfe bigveh 		d2gp_now_atp2 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabC_8:	reghdfe bigveh		d2gp_now_atp2 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)


eststo gpm_tabD_1:	reghdfe GPMCombo_All d2gp_now_atp1 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabD_2:	reghdfe GPMCombo_All d2gp_now_atp1 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabD_3:	reghdfe GPMCombined d2gp_now_atp1 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabD_4:	reghdfe GPMCombined d2gp_now_atp1 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo gpm_tabD_5:	reghdfe bigveh_All 	d2gp_now_atp1 						 if idco==1 [aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabD_6:	reghdfe bigveh_All 	d2gp_now_atp1 `demc' 				 if idco==1 [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)
eststo gpm_tabD_7:	reghdfe bigveh 		d2gp_now_atp1 c.vehyear##c.vehyear vehage		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo gpm_tabD_8:	reghdfe bigveh		d2gp_now_atp1 `demc' c.vehyear##c.vehyear vehage [aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	gpm_tabA_? 		using "./results/table_a13/gpm_table_d2_18.tex", booktabs replace `tabprefs'
esttab 	gpm_tabB_? 		using "./results/table_a13/gpm_table_d2_17.tex", booktabs replace `tabprefs'
esttab 	gpm_tabC_? 		using "./results/table_a13/gpm_table_d2_p2.tex", booktabs replace `tabprefs'
esttab 	gpm_tabD_? 		using "./results/table_a13/gpm_table_d2_p1.tex", booktabs replace `tabprefs'

eststo clear

log close
clear
