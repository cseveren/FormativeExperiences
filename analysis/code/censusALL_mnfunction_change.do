*************************************************************
** This file makes performs panel analyses from all census 
** data years.
*************************************************************
cd 	"/home/c1cns02/Desktop/stata_work/Driving_Gas_Shocks_mnanalysis/"

use 	"censusall_prepped.dta", clear
do 	"mn_wrapper_eval.do"
drop 	perwt
rename 	perwt_orig perwt
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

local 	agelist 16 17 

foreach age of local agelist {
	gen 	year = birthyr + `age'

	merge m:1 year statefip using "gasprice_prepped.dta", keepusing(gas_price_99 d1gp_bp d2gp_bp) gen(_merge`age')

	rename	gas_price_99 real_gp_at`age'
	rename	d1gp_bp  d1gp_bp_at`age'
	rename	d2gp_bp  d2gp_bp_at`age'

	drop if _merge`age'==2

	rename 	year yr_age`age'
	lab var yr_age`age' "Year Turned `age'" 
}

*********************************************
/* To maintain same sample with main specs */

drop if _merge16!=3 
drop	_merge*

rename 	statefip bpl
compress

drop if perwt==0
drop if bpl==2
drop if bpl==15
	/* Gas Price panel balanaced except AK HI */

reghdfe t_drive d2gp_bp_at17 						if m_samestate==1 [aw=perwt], a(bpl censusyear_all age) cluster(bpl)
gen 	insample_samestate = e(sample)

reghdfe t_drive d2gp_bp_at17 						[aw=perwt], a(bpl censusyear_all age) cluster(bpl)
gen 	insample_all = e(sample)

tab  	birthyr insample_samestate
tab 	censusyear_all insample_samestate
tab  	birthyr insample_all
tab 	censusyear_all insample_all

keep if insample_samestate==1 | insample_all==1

keep 	t_drive d2gp_bp_at17 m_samestate bpl censusyear_all age stfip perwt insample_samestate insample_all
compress

preserve
	** Gas Price Changes
	use 	"gasprice_prepped.dta", clear
	keep	statefip year d1gp_bp
	rename	d1gp_bp d1gp_bp_
	reshape wide d1gp_bp_, i(statefip) j(year)

	gen		censusyear_all = .
	tempfile gaspanel
	save 	"`gaspanel'", replace

	foreach y of numlist 1980 1990 2000 2005/2017 {
		use 	"`gaspanel'"
		replace	censusyear_all = `y'
		tempfile gp
		save 	"`gp'", replace
		
		if `y'==1980 {
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

	foreach y of numlist 1980 1990 2000 2005/2017 {
		local	yrcountmax = `y' - 1966
		foreach t of numlist 0/`yrcountmax' {
			local yr = `y'-`t'
			display `yr'
			replace d1gp_bp_`t' = d1gp_bp_`yr' if censusyear_all==`y'
		}
	}
	drop 	d1gp_bp_????
	tempfile	gas_history_changes
	save	"`gas_history_changes'", replace
restore

** Gas changes
rename 	bpl statefip

merge m:1 statefip censusyear_all using "`gas_history_changes'"
drop if _merge==2
drop 	_merge

rename statefip bpl

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

keep 	d1gp_bp_* wt_* perwt t_drive age bpl censusyear_all insample_*
keep if insample_samestate==1

tab age, gen(age_)
drop 	age_1

tab bpl, gen(bpl_)
drop 	bpl_1

tab censusyear_all, gen(cy_)
drop 	cy_1

compress

gen float aexp=1

* Make sure code works
preserve
	sample 0.5
	mat A = (0.89,-0.2,1)

	mn_wrapper_eval t_drive aexp age_* bpl_* cy_* if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) init3(A)
restore

* Grid Search

preserve
	replace aexp = 0
	reg 	t_drive age_* bpl_* cy_*
	predict td_resids, r

	matrix 	P = J(21,17,.)

	local 	i = 1

	foreach ic of numlist -0.05(0.005)0.05 {
		local 	j = 1
		foreach jc of numlist -4(0.5)4 { 
			mat 	A = (0,`ic',`jc')
			mn_wrapper_grid td_resids aexp age_* bpl_* cy_* if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) mat3(A)
			matrix 	P[`i',`j'] = r(rss)
			local 	++j
		}
		local 	++i
	}

	matrix 	list P, format(%2.1f)
restore


* Final optimization
* APPROACH A

sum t_drive if insample_samestate==1 [aw=perwt]
replace aexp=0

reg 	t_drive age_* bpl_* cy_* if insample_samestate==1 [aw=perwt]

mat 	D = e(b)

mat 	Af = (D[1,92],-0.01,-1, D[1,1..91])
mn_wrapper_eval t_drive aexp age_* bpl_* cy_* if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) initall(Af)


* APPROACH B
reg 	t_drive age_* bpl_* cy_* if insample_samestate==1 [aw=perwt]
predict td_resids, r

mat 	C1 = e(b)

mat 	As = (0,-0.01,-1)
mn_wrapper_eval td_resids aexp if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) initall(As)

mat 	C2 = e(b)

mat 	Af = (C1[1,92]+C2[1,1],C2[1,2],C2[1,3], C1[1,1..91])
mn_wrapper_eval t_drive aexp age_* bpl_* cy_* if insample_samestate==1 [aw=perwt], tfirst(0) tlast(38) expvar(d1gp_bp) awts(wt) initall(Af)


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
