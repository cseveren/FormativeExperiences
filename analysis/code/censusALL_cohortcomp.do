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

local 	agelist 17 

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

drop if _merge17!=3
drop	_merge*

** Merge to current state prices at age 16 **

rename 	statefip bpl
rename 	stfip statefip

local 	agelist 17

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

foreach diff of numlist 1 {
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

foreach diff of numlist 1 {
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

collapse (mean) t_drive d2gp_bp_at17 d2gp_now_at17 d2gp_bp_atp1 d2gp_now_atp1 real_gp_at17 real_now_at17 real_gp_atp1 real_now_atp1 [aw=perwt], by(birthyr censusyear_all)

save	"./output/censusall_meansbycohortsampleyear.dta", replace

use		"./output/censusall_meansbycohortsampleyear.dta", clear

gen 	age = censusyear_all - birthyr

rename 	* *_0
rename	age_0 age
tempfile initial_year
save	"`initial_year'", replace

rename 	*_0 *_1

joinby	age using "`initial_year'"
sort	age birthyr_0 birthyr_1

gen		year_diff = birthyr_1 - birthyr_0
drop if year_diff<=0 /* Ensures no double couting */

gen		price_diff = d2gp_bp_at17_1 - d2gp_bp_at17_0
gen		level_diff = real_gp_at17_1 - real_gp_at17_0
gen		drive_diff = t_drive_1 - t_drive_0


set scheme plotplainblind	
lpoly drive_diff price_diff, ci
lpoly drive_diff level_diff, ci

binscatter drive_diff price_diff, n(50)
binscatter drive_diff level_diff, n(50)

binscatter drive_diff price_diff, line(none) n(50)
binscatter drive_diff level_diff, line(none) n(50)


	binscatter drive_diff price_diff, n(25) reportreg savegraph("./results/cohort_compare/binscatter_pricechange.png") replace
	binscatter drive_diff level_diff, n(25) reportreg savegraph("./results/cohort_compare/binscatter_pricelevel.png") replace

	lpoly drive_diff price_diff, ci legend(pos(6) row(1)) mc(gs11) lineopts(lc(black)) 
	graph export "./results/cohort_compare/lpoly_pricechange.png", replace
	lpoly drive_diff level_diff, ci legend(pos(6) row(1)) mc(gs11) lineopts(lc(black)) 
	graph export "./results/cohort_compare/lpoly_pricelevel.png", replace
		
	///
			(lfit drive_diff price_diff if age==`a', range(-1 1) lc(red) lp(dash)), ///
			yline(0, lc(gs8) lp(solid)) ///
			xtitle("Difference in DeltaP(15,17)") ytitle("Difference Pr(Drive to Work)") ///
			legend(pos(6) r(1) lab(1 "Age `a'")) saving("`n1'") nodraw
			
	tempfile n2		
	twoway (scatter drive_diff level_diff if age==`a', mc("115 145 255") msize(`ms') m(o)) ///
			(lfit drive_diff level_diff if age==`a', range(-2 2) lc(red) lp(dash)), ///
			yline(0, lc(gs8) lp(solid)) ///
			xtitle("Difference in Log Level Price at 17") ///
			legend(pos(6) r(1) lab(1 "Age `a'")) saving("`n2'") nodraw
			
	graph combine "`n1'" "`n2'"
	graph export "./results/cohort_compare/age_`a'.png", replace


scatter	drive_diff price_diff
reg 	drive_diff price_diff, robust
reg 	drive_diff price_diff year_diff, robust

scatter	drive_diff price_diff
reg 	drive_diff price_diff, robust
reg 	drive_diff price_diff year_diff, robust

set scheme plotplainblind	
loc ms vsmall
twoway (scatter drive_diff price_diff if age==25, mc("75 45 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==26, mc("77 50 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==27, mc("79 55 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==28, mc("81 60 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==29, mc("83 65 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==30, mc("85 70 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==31, mc("87 75 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==32, mc("89 80 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==33, mc("91 85 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==34, mc("93 90 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==35, mc("95 95 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==36, mc("97 100 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==37, mc("99 105 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==38, mc("101 110 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==39, mc("103 115 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==40, mc("105 120 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==41, mc("107 125 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==42, mc("109 130 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==43, mc("111 135 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==44, mc("113 140 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==45, mc("115 145 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==46, mc("117 150 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==47, mc("119 155 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==48, mc("121 160 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==49, mc("123 165 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==50, mc("125 170 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==51, mc("127 175 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==52, mc("129 180 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==53, mc("131 185 145") msize(`ms')) || ///
		(scatter drive_diff price_diff if age==54, mc("133 190 145") msize(`ms')), ///
		legend(off)
	
set scheme plotplainblind	
loc ms small
twoway (scatter drive_diff price_diff if age==25, mc("115 145 255") msize(`ms') m(o)) ///
		(lfit drive_diff price_diff if age==25, range(-0.9 0.8) lc(red) lp(dash)), ///
		yline(0, lc(gs8) lp(solid)) ///
		xtitle("Difference in DeltaP(15,17)") ytitle("Difference Pr(Drive to Work)") ///
		legend(pos(6) r(1) lab(1 "Age 25")) 
					
set scheme plotplainblind	
loc ms small
twoway (scatter drive_diff level_diff if age==25, mc("115 145 255") msize(`ms') m(o)) ///
		(lfit drive_diff level_diff if age==25, range(-1.3 1.5) lc(red) lp(dash)), ///
		yline(0, lc(gs8) lp(solid)) ///
		xtitle("Difference in Log Level Price at 17") ytitle("Difference Pr(Drive to Work)") ///
		legend(pos(6) r(1) lab(1 "Age 25")) 

set scheme plotplainblind	
foreach a of numlist 25/54 {		

	loc ms small
	tempfile n1
	
	twoway (scatter drive_diff price_diff if age==`a', mc("115 145 255") msize(`ms') m(o)) ///
			(lfit drive_diff price_diff if age==`a', range(-1 1) lc(red) lp(dash)), ///
			yline(0, lc(gs8) lp(solid)) ///
			xtitle("Difference in DeltaP(15,17)") ytitle("Difference Pr(Drive to Work)") ///
			legend(pos(6) r(1) lab(1 "Age `a'")) saving("`n1'") nodraw
			
	tempfile n2			
	twoway (scatter drive_diff level_diff if age==`a', mc("115 145 255") msize(`ms') m(o)) ///
			(lfit drive_diff level_diff if age==`a', range(-2 2) lc(red) lp(dash)), ///
			yline(0, lc(gs8) lp(solid)) ///
			xtitle("Difference in Log Level Price at 17") ///
			legend(pos(6) r(1) lab(1 "Age `a'")) saving("`n2'") nodraw
			
	graph combine "`n1'" "`n2'"
	graph export "./results/cohort_compare/age_`a'.png", replace
}		
		
		
set scheme plotplainblind	
loc ms small
twoway (scatter drive_diff price_diff if age>=45 & age<55, mc("115 145 255") msize(`ms') m(o)) || ///
		(scatter drive_diff price_diff if age>=35 & age<45, mc("97 100 195") msize(`ms') m(o)) || ///
		(scatter drive_diff price_diff if age>=25 & age<35, mc("75 45 145") msize(`ms') m(o)) || ///
		(lfit drive_diff price_diff, range(-0.9 0.8) lc(red) lp(dash)), ///
		yline(0, lc(gs8) lp(solid)) ///
		xtitle("Difference in DeltaP(15,17)") ytitle("Difference Pr(Drive to Work)") ///
		legend(pos(6) r(1) order(3 2 1) lab(3 "Age 25-34") lab(2 "Age 35-44") lab(1 "Age 45-54")) 
				
		
set scheme plotplainblind	
loc ms small
twoway (scatter drive_diff level_diff if age>=45 & age<55, mc("115 145 255") msize(`ms') m(o)) || ///
		(scatter drive_diff level_diff if age>=35 & age<45, mc("97 100 195") msize(`ms') m(o)) || ///
		(scatter drive_diff level_diff if age>=25 & age<35, mc("75 45 145") msize(`ms') m(o)) || ///
		(lfit drive_diff level_diff, range(-0.9 0.8) lc(red) lp(dash)), ///
		yline(0, lc(gs8) lp(solid)) ///
		xtitle("Difference in Log Level Price at 17") ytitle("Difference Pr(Drive to Work)") ///
		legend(pos(6) r(1) order(3 2 1) lab(3 "Age 25-34") lab(2 "Age 35-44") lab(1 "Age 45-54")) 		
		
		
reg drive_diff price_diff if age==25, robust
reg drive_diff level_diff2 if age==25, robust

reg drive_diff price_diff, robust
reg drive_diff level_diff2, robust


capture noisily log close
clear
