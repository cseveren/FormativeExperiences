*************************************************************
** This file makes performs panel analyses from all census 
** data years.
*************************************************************

use 	"./output/NHTScombined_per.dta", clear
do 	"mn_wrapper_eval.do"
********************************
********************************
** Gas Price Merge	 		****
********************************
********************************

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

local 	agelist 16 17 

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


*********************************************
/* To maintain same sample with main specs */

drop if _merge16!=3
drop	_merge*

drop if statename=="HI"
drop if statename=="AK"
	/* Gas Price panel balanaced except AK HI */

egen 	stateid = group(statefip)
egen	stsamyr_fe = group(statefip nhtsyear)	

gen 	expfllprr = round(expfllpr) 

gen		byr = yr_16_new-16

/* Define treatment using all vehicle data, enforce topcode of 115k miles */

gen		lvmt_pc 	= log(min(miles_per_psn_ALL,115000))

gen		mile_per_psn_ALL_lt115 = min(miles_per_psn_ALL,115000)
sum 	mile_per_psn_ALL_lt115
sum 	mile_per_psn_ALL_lt115 if mile_per_psn_ALL_lt115>0

reghdfe lvmt_pc d2gp_now_at17  	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
gen 	insample = e(sample)
keep if insample==1

keep 	lvmt_pc d2gp_now_at17 nhtsyear expfllp* age stateid statefip
compress

preserve
	** Gas Price Changes
	use 	"./output/gasprice_prepped.dta", clear
	keep	statefip year d1gp_bp
	rename	d1gp_bp d1gp_bp_
	reshape wide d1gp_bp_, i(statefip) j(year)

	gen		nhtsyear = .
	tempfile gaspanel
	save 	"`gaspanel'", replace

	foreach y of numlist 1990 1995 2001 2009 2017 {
		use 	"`gaspanel'"
		replace	nhtsyear = `y'
		tempfile gp
		save 	"`gp'", replace
		
		if `y'==1990 {
			tempfile compl_gp
			save 	"`compl_gp'", replace
		} 
		else {
			use 	"`compl_gp'", clear
			append using "`gp'"
			save	"`compl_gp'", replace
		}
	}

	foreach t of numlist 0/51 { /* In 2017 only see gas 51 years before */
		gen d1gp_bp_`t' = .
	}

	foreach y of numlist 1990 1995 2001 2009 2017 {
		local	yrcountmax = `y' - 1966
		foreach t of numlist 0/`yrcountmax' {
			local yr = `y'-`t'
			display `yr'
			replace d1gp_bp_`t' = d1gp_bp_`yr' if nhtsyear==`y'
		}
	}
	drop 	d1gp_bp_????
	tempfile	gas_history_changes
	save	"`gas_history_changes'", replace
restore

** Gas changes
merge m:1 statefip nhtsyear using "`gas_history_changes'"
drop if _merge==2
drop 	_merge

* STARTS AT AGE 14 (Delta age 15 to 14)
foreach t of numlist 0/51 {
	gen byte wt_`t' = max(age-15-`t',0)
}

drop 	wt_39-wt_51
drop 	d1gp_bp_39-d1gp_bp_51

foreach t of numlist 0/38 {
	replace d1gp_bp_`t' = 0 if wt_`t'==0
}

* Get rid of problematic missing values 
foreach t of numlist 0/38 {
	drop if d1gp_bp_`t'==. | wt_`t'==.
}

* make sure denominator isn't stupid
egen 	row_wts = rowtotal(wt_*)
drop if row_wts==0
drop 	row_wts

******************
** Main Block ****

keep 	d1gp_bp_* wt_* expfllp* lvmt_pc age stateid statefip nhtsyear

tab age, gen(age_)
drop 	age_1

tab statefip, gen(stf_)
drop 	stf_1

tab nhtsyear, gen(nyr_)
drop 	nyr_1

compress

gen float aexp=1


* Grid Search

preserve
	replace aexp = 0
	reg 	lvmt_pc age_* stf_* nyr_*
	predict td_resids, r

	matrix 	P = J(21,17,.)

	local 	i = 1

	foreach ic of numlist -0.5(0.05)0.5 {
		local 	j = 1
		foreach jc of numlist -4(0.5)4 { 
			mat 	A = (0,`ic',`jc')
			mn_wrapper_grid td_resids aexp age_* stf_* nyr_* [aw=expfllpr], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) mat3(A)
			matrix 	P[`i',`j'] = r(rss)
			local 	++j
		}
		local 	++i
	}

	matrix 	list P, format(%2.1f)
restore


* Final optimization

* APPROACH B
reg 	lvmt_pc  age_* stf_* nyr_* [aw=expfllpr]
predict td_resids, r

mat 	C1 = e(b)

mat 	As = (0,-0.4,-0.5)
mn_wrapper_eval td_resids aexp [aw=expfllpr], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) initall(As)

mat 	C2 = e(b)

mat 	Af = (C1[1,82]+C2[1,1],C2[1,2],C2[1,3], C1[1,1..81])
mn_wrapper_eval lvmt_pc aexp age_* stf_* nyr_* [aw=expfllpr], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) initall(Af)


****** STOP ********











** -0.011391, -0.9882452

gen  	t_drivealt1 = t_drive + 0.011391*aexp
reg 	t_drivealt1 age_* bpl_* cy_* if insample_samestate==1 [aw=perwt]
predict	resid_1, r

mat 	Af = (0,-0.011391,-0.9882452)
mn_wrapper_eval resid_1 aexp if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) init3(Af)
** -0.002697, -0.8367698

mat 	Af = (0.94,-0.011391,-0.9882452)
mn_wrapper_eval resid_1 aexp age_* bpl_* cy_* if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) init3(Af)

mat 	Af = (0.94,-0.011391,-0.9882452)
mn_wrapper_eval t_drive aexp age_* bpl_* cy_* if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) init3(Af)

mn_wrapper_eval t_drive aexp age_* bpl_* cy_* if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) init3(Af)


capture noisily log close
clear
