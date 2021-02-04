*************************************************************
** This file makes graphs and performs RD analysis from year
** 2000 Census data. 
*************************************************************

local 	logf "`1'" 
log using "`logf'", replace text

use 	"./output/census2000_basefile.dta", clear

********************************
** Sample Restrictions

keep if bpl<100
drop if farm==2

********************************
** Variable Creation

* Transit
gen 	t_drive = 0 if tranwork!=0
replace t_drive = 1 if tranwork==10

gen 	t_transit = 0 if tranwork!=0
replace t_transit = 1 if tranwork==31 | tranwork==32 | tranwork==33 | tranwork==34

gen 	t_walk = 0 if tranwork!=0
replace t_walk = 1 if tranwork==50

gen 	t_workathome = 0 if tranwork!=0
replace t_workathome = 1 if tranwork==70

gen 	t_time = trantime if tranwork!=0
replace t_time = 120 if t_time>120 & t_time!=.

gen 	t_timedr = t_time if tranwork==10

gen 	t_novehicle = 0 if vehicles!=0
replace t_novehicle = 1 if vehicles==9
gen 	t_vehicle = 1 - t_novehicle
drop	t_novehicle

sum 	t_*

* Housing
gen 	h_own = 0
replace h_own = 1 if ownershp==1

gen 	h_rent = 0
replace h_rent = 1 if ownershp==2

gen 	h_other = 0
replace h_other = 1 if ownershp==0

sum 	rent valueh, d
replace	rent = . if ownershp!=2
replace	valueh = . if ownershp!=1
rename 	rent h_rentpr
rename  value h_value

sum		h_*

* Employment and labor force participation
gen 	e_emp = 0
replace e_emp = 1 if empstat==1

gen 	e_lfp = 0
replace e_lfp = 1 if empstat==1 | empstat==2

sum 	uhrswork wkswork1 workedyr

gen		e_hrs_unc = uhrswork
gen 	e_hrs_con = uhrswork if empstat==1

gen		e_wks_unc = wkswork1
gen	 	e_wks_con = wkswork1 if empstat==1

* Wage and income
gen 	w_wage_unc = incwage
gen 	w_wage_con = incwage if empstat==1
replace w_wage_con = 175000 if w_wage_con>175000 & w_wage_con!=. /* Dealing with top coding */

gen		w_hhi = hhincome

* Demographics
gen		d_fem = 0
replace	d_fem = 1 if sex==2

gen		d_marr = 0
replace d_marr = 1 if marst==0 | marst==1

gen 	d_div = 0 
replace d_div = 1 if marst==4

gen 	d_hs  = 0
replace d_hs  = 1 if educd>=62 & educd!=.

gen 	d_col = 0 
replace d_col = 1 if educd>=101 & educd!=.

********************************
********************************
** RD Analysis and Tables  *****
********************************
********************************

gen 	yr_age16 = birthyr + 16
lab var yr_age16 "Year Turned 16" 

gen 	yr_age15 = birthyr + 15
lab var yr_age15 "Year Turned 15" 


********************************
** 1979 Oil Crisis *************
********************************

** RD variables
gen 	D 	= 1964 - birthyr 	/* D is age in 1964 */
gen		D2	= D*D
gen 	T 	= 0	 				/* T is 0 if 16 or older in 1980 */
replace T 	= 1 if D<0			/* T is 1 if 15 or younger in 1980 */
gen 	bwA = abs(D+0.5) 		/* Symmetric around 1980.5, include all years */
gen 	bwB = abs(D) if D!=0 	/* Symmetric around 1980, exclude 1980 */		

lab var D "Age in 1964"
lab var T "15 and younger in 1980"

gen 	DT = D*T
gen 	D2T = D2*T

** Prep covariates
gen 	linc 	= ln(hhincome)
gen 	nwhite 	= 0
replace nwhite 	= 1 if race>=2

compress

****************************************
** RD in commuting (Table A.3 = bwA, A.5 = bwB)* *
****************************************

eststo clear

local bwlist 	02 03 04 05 06 07 08 09 10
local bwlistq 	05 06 07 08 09 10
local clist 	i.sex i.nwhite i.d_hs i.d_col

* Simple (unconditional) RD

foreach bw of local bwlist {
	eststo rdl_dri_A`bw'_no_rb: 	reg t_drive T D DT 			if bwA<=`bw' [aw=perwt], robust
	eststo rdl_dri_B`bw'_no_rb: 	reg t_drive T D DT 			if bwB<=`bw' [aw=perwt], robust
}

foreach bw of local bwlistq {
	eststo rdq_dri_A`bw'_no_rb: 	reg t_drive T D DT D2 D2T 	if bwA<=`bw' [aw=perwt], robust
	eststo rdq_dri_B`bw'_no_rb: 	reg t_drive T D DT D2 D2T 	if bwB<=`bw' [aw=perwt], robust
}

* Demographic Controls

foreach bw of local bwlist {
	eststo rdl_dri_A`bw'_cA_rb: 	reg t_drive T D DT `clist'	if bwA<=`bw' [aw=perwt], robust
	eststo rdl_dri_B`bw'_cA_rb: 	reg t_drive T D DT `clist'	if bwB<=`bw' [aw=perwt], robust
}

foreach bw of local bwlistq {
	eststo rdq_dri_A`bw'_cA_rb: 	reg t_drive T D DT D2 D2T `clist'	if bwA<=`bw' [aw=perwt], robust
	eststo rdq_dri_B`bw'_cA_rb: 	reg t_drive T D DT D2 D2T `clist'	if bwB<=`bw' [aw=perwt], robust
}

* Demographic Controls + State of Birth FE

foreach bw of local bwlist {
	eststo rdl_dri_A`bw'_cB_rb: 	reghdfe t_drive T D DT `clist'	if bwA<=`bw' [aw=perwt], a(bpl) vce(robust)
	eststo rdl_dri_B`bw'_cB_rb: 	reghdfe t_drive T D DT `clist'	if bwB<=`bw' [aw=perwt], a(bpl) vce(robust)
}

foreach bw of local bwlistq {
	eststo rdq_dri_A`bw'_cB_rb: 	reghdfe t_drive T D DT D2 D2T `clist'	if bwA<=`bw' [aw=perwt], a(bpl) vce(robust)
	eststo rdq_dri_B`bw'_cB_rb: 	reghdfe t_drive T D DT D2 D2T `clist'	if bwB<=`bw' [aw=perwt], a(bpl) vce(robust)
}

* Demographic Controls + State of Birth FE + linc

foreach bw of local bwlist {
	eststo rdl_dri_A`bw'_cI_rb: 	reghdfe t_drive T D DT linc `clist'	if bwA<=`bw' [aw=perwt], a(bpl) vce(robust)
	eststo rdl_dri_B`bw'_cI_rb: 	reghdfe t_drive T D DT linc `clist'	if bwB<=`bw' [aw=perwt], a(bpl) vce(robust)
}

foreach bw of local bwlistq {
	eststo rdq_dri_A`bw'_cI_rb: 	reghdfe t_drive T D DT D2 D2T linc `clist'	if bwA<=`bw' [aw=perwt], a(bpl) vce(robust)
	eststo rdq_dri_B`bw'_cI_rb: 	reghdfe t_drive T D DT D2 D2T linc `clist'	if bwB<=`bw' [aw=perwt], a(bpl) vce(robust)
}

***************************
** RD in transit (Table A.4, partial) **
***************************

* Simple (unconditional) RD

foreach bw of local bwlist {
	eststo rdl_trn_A`bw'_no_rb: 	reg t_transit T D DT 		if bwA<=`bw' [aw=perwt], robust
}

foreach bw of local bwlistq {
	eststo rdq_trn_A`bw'_no_rb: 	reg t_transit T D DT D2 D2T 	if bwA<=`bw' [aw=perwt], robust
}

***************************
** RD in vehicle ownersh (Table A.4, partial) **
***************************

* Simple (unconditional) RD

foreach bw of local bwlist {
	eststo rdl_veh_A`bw'_no_rb: 	reg t_vehicle T D DT 		if bwA<=`bw' [aw=perwt], robust
}

foreach bw of local bwlistq {
	eststo rdq_veh_A`bw'_no_rb: 	reg t_vehicle T D DT D2 D2T 	if bwA<=`bw' [aw=perwt], robust
}

********************************
** RD OUTPUT              ******
********************************

** Set preferences

local tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01) 

** Output display in TEX **

* Driving, standard
esttab rdl_dri_A??_no_rb using "./results/table_a3/dri_nocont_1o_regbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_A??_no_rb using "./results/table_a3/dri_nocont_2o_regbw.tex", keep(T) booktabs replace `tabprefs' 

esttab rdl_dri_A??_cA_rb using "./results/table_a3/dri_demo_1o_regbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_A??_cA_rb using "./results/table_a3/dri_demo_2o_regbw.tex", keep(T) booktabs replace `tabprefs' 

esttab rdl_dri_A??_cB_rb using "./results/table_a3/dri_demsob_1o_regbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_A??_cB_rb using "./results/table_a3/dri_demsob_2o_regbw.tex", keep(T) booktabs replace `tabprefs' 

esttab rdl_dri_A??_cI_rb using "./results/table_a3/dri_demstinc_1o_regbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_A??_cI_rb using "./results/table_a3/dri_demstinc_2o_regbw.tex", keep(T) booktabs replace `tabprefs' 

* Vehicle, standard
esttab rdl_veh_A??_no_rb using "./results/table_a4/veh_nocont_1o_regbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_veh_A??_no_rb using "./results/table_a4/veh_nocont_2o_regbw.tex", keep(T) booktabs replace `tabprefs' 

* Transit, standard
esttab rdl_trn_A??_no_rb using "./results/table_a4/tran_nocont_1o_regbw.tex",  keep(T) booktabs replace `tabprefs' 
esttab rdq_trn_A??_no_rb using "./results/table_a4/tran_nocont_2o_regbw.tex", keep(T) booktabs replace `tabprefs' 

* Driving, alternate
esttab rdl_dri_B??_no_rb using "./results/table_a5/dri_nocont_1o_altbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_B??_no_rb using "./results/table_a5/dri_nocont_2o_altbw.tex", keep(T) booktabs replace `tabprefs' 

esttab rdl_dri_B??_cA_rb using "./results/table_a5/dri_demo_1o_altbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_B??_cA_rb using "./results/table_a5/dri_demo_2o_altbw.tex", keep(T) booktabs replace `tabprefs' 

esttab rdl_dri_B??_cB_rb using "./results/table_a5/dri_demsob_1o_altbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_B??_cB_rb using "./results/table_a5/dri_demsob_2o_altbw.tex", keep(T) booktabs replace `tabprefs' 

esttab rdl_dri_B??_cI_rb using "./results/table_a5/dri_demstinc_1o_altbw.tex", keep(T) booktabs replace `tabprefs' 
esttab rdq_dri_B??_cI_rb using "./results/table_a5/dri_demstinc_2o_altbw.tex", keep(T) booktabs replace `tabprefs' 

eststo clear 

********************************
** RD HETEROGENEITY (Table A.6) **
********************************

** Race = Black **
foreach bw of local bwlist {
	eststo hetrdl_dri_blk_A`bw': reg t_drive T D DT if bwA<=`bw' & race==2 [aw=perwt], vce(robust)
}
foreach bw of local bwlistq {
	eststo hetrdq_dri_blk_A`bw': reg t_drive T D DT D2 D2T if bwA<=`bw' & race==2 [aw=perwt], vce(robust)
}

** School = <College **
foreach bw of local bwlist {
	eststo hetrdl_dri_noc_A`bw': reg t_drive T D DT if bwA<=`bw' & d_col==0 [aw=perwt], vce(robust)
}
foreach bw of local bwlistq {
	eststo hetrdq_dri_noc_A`bw': reg t_drive T D DT D2 D2T if bwA<=`bw' & d_col==0 [aw=perwt], vce(robust)
}

/*
0                       Not identifiable |    642,101        8.80        8.80
1                      Not in metro area |  1,637,813       22.43       31.23
2In metro area, central / principal city |    897,637       12.30       43.53
3In metro area, outside central / princi |  2,071,852       28.38       71.91
4Central / Principal city status unknown |  2,051,014       28.09      100.00
*/

** Not in MA **
foreach bw of local bwlist {
	eststo hetrdl_dri_nMA_A`bw': reg t_drive T D DT if bwA<=`bw' & metro==1 [aw=perwt], vce(robust)
}
foreach bw of local bwlistq {
	eststo hetrdq_dri_nMA_A`bw': reg t_drive T D DT D2 D2T if bwA<=`bw' & metro==1 [aw=perwt], vce(robust)
}

** In PC **
foreach bw of local bwlist {
	eststo hetrdl_dri_iPC_A`bw': reg t_drive T D DT if bwA<=`bw' & metro==2 [aw=perwt], vce(robust)
}
foreach bw of local bwlistq {
	eststo hetrdq_dri_iPC_A`bw': reg t_drive T D DT D2 D2T if bwA<=`bw' & metro==2 [aw=perwt], vce(robust)
}


********************************
** RD HETEROGENEITY OUTPUT *****
********************************

esttab hetrdl_dri_blk_A?? using "./results/table_a6/hetdri_blk_lin.tex",  keep(T) booktabs replace `tabprefs'
esttab hetrdq_dri_blk_A?? using "./results/table_a6/hetdri_blk_quad.tex", keep(T) booktabs replace `tabprefs'

esttab hetrdl_dri_noc_A?? using "./results/table_a6/hetdri_noc_lin.tex",  keep(T) booktabs replace `tabprefs'
esttab hetrdq_dri_noc_A?? using "./results/table_a6/hetdri_noc_quad.tex", keep(T) booktabs replace `tabprefs'

esttab hetrdl_dri_nMA_A?? using "./results/table_a6/hetdri_nMA_lin.tex",  keep(T) booktabs replace `tabprefs'
esttab hetrdq_dri_nMA_A?? using "./results/table_a6/hetdri_nMA_quad.tex", keep(T) booktabs replace `tabprefs'

esttab hetrdl_dri_iPC_A?? using "./results/table_a6/hetdri_iPC_lin.tex",  keep(T) booktabs replace `tabprefs'
esttab hetrdq_dri_iPC_A?? using "./results/table_a6/hetdri_iPC_quad.tex", keep(T) booktabs replace `tabprefs'

eststo clear

********************************
** Covariate checks *****
********************************

local checkvars e_emp e_lfp e_hrs_con e_wks_con w_wage_con w_hhi h_own h_rent h_value h_rentpr d_marr d_div d_hs d_col
foreach n of numlist 3 4 5{
foreach v of local checkvars {
	reg `v' T D DT 		if bwA<=`n' [aw=perwt], robust

	local se_`n'_`v' = "(" + string(_se[T], "%9.4f") + ")"
	
	local df_r = e(df_r)
	local p = 2*ttail(`df_r',abs(_b[T]/_se[T]))
	if `p' <0.01 {
		local b_`n'_`v' = string(_b[T], "%9.4f") + "**"
	}
	else if `p'<0.05 {
		local b_`n'_`v' = string(_b[T], "%9.4f") + "*"
	}
	else if `p'<0.10 {
		local b_`n'_`v' = string(_b[T], "%9.4f") + "+"
	}
	else {
		local b_`n'_`v' = string(_b[T], "%9.4f")
	}
} 
}

texdoc init "./results/other/eventstudyrobustness.tex", replace force
foreach v of local checkvars {
tex `v' & `b_3_`v'' & `b_4_`v''  & `b_5_`v'' \\
tex 	& `se_3_`v''& `se_4_`v'' & `se_5_`v'' \\[4pt]
}

texdoc close

eststo clear

********************************
** 1974 Oil Crisis *************
********************************

preserve 
	drop 	D D2 T bwA bwB DT D2T linc nwhite 
	** RD variables
	gen 	D 	= 1959 - birthyr 	/* D is age in 1959 */
	gen		D2	= D*D
	gen 	T 	= 0	 				/* T is 0 if 16 or older in 1975 */
	replace T 	= 1 if D<0			/* T is 1 if 15 or younger in 1975 */
	gen 	bwA = abs(D+0.5) 		/* Symmetric around 1975.5, include all years */
	gen 	bwB = abs(D) if D!=0 	/* Symmetric around 1975, exclude 1975 */		

	lab var D "Age in 1964"
	lab var T "15 and younger in 1980"

	gen 	DT = D*T
	gen 	D2T = D2*T

	** Prep covariates
	gen 	linc 	= ln(hhincome)
	gen 	nwhite 	= 0
	replace nwhite 	= 1 if race>=2

	compress

	** RD in commuting 

	eststo clear

	local bwlist 	02 03 04 05 06 07 08 09 10
	local bwlistq 	05 06 07 08 09 10
	local clist 	i.sex i.nwhite i.d_hs i.d_col

	* Simple (unconditional) RD

	foreach bw of local bwlist {
		eststo rdl_dri_A`bw'_1974: 	reg t_drive T D DT 			if bwA<=`bw' [aw=perwt], robust
	}

	foreach bw of local bwlistq {
		eststo rdq_dri_A`bw'_1974: 	reg t_drive T D DT D2 D2T 	if bwA<=`bw' [aw=perwt], robust
	}

	local tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01) 

	esttab rdl_dri_A??_1974 using "./results/other/rd1974_dri_1o.tex", keep(T) booktabs replace `tabprefs' 
	esttab rdq_dri_A??_1974 using "./results/other/rd1974_dri_2o.tex", keep(T) booktabs replace `tabprefs' 
	
	estimates clear
restore



********************************
********************************
** RD and RDxIncome PICTURES ***
********************************
********************************

preserve 

* Prep Data and Environment
collapse t_* h_* e_* w_* d_* [aw=perwt], by(birthyr)
/* Note that casewise deletion is NOT used -- this means all statistics potentially use different denominators... */

** Shift year at age XX to account for census birth year wonkiness **

gen 	yr_age16 = birthyr + 16 - 0.25
lab var yr_age16 "Year Turned 16"  

gen 	yr_age15 = birthyr + 15 - 0.25
lab var yr_age15 "Year Turned 15"  

set scheme plotplainblind

foreach y of numlist 15 {

	local gphlist yr_age`y' if yr_age`y'>=1965 & yr_age`y'<=1990, connect(d) xline(1973.81 1974.64 1979.16 1980.54, lc(red) lp(dash)) xline(1973.85 1974.6 1979.2 1980.5, lc(red) lp(dot))

	scatter t_drive 	`gphlist' name(t1, replace) ytitle("Drive to Work") 
	graph export "./results/figures/tgraphs`y'_drive.png", replace
	
	scatter t_transit 	`gphlist' name(t2, replace) ytitle("Take Transit to Work")
	graph export "./results/figures/tgraphs`y'_transit.png", replace
	
	scatter t_vehicle   `gphlist' name(t3, replace) ytitle("Household Vehicle Access")
	graph export "./results/figures/tgraphs`y'_vehicle.png", replace

	** Figure 2 **
	graph combine t1 t2 t3, row(3) xcommon saving(tgraphs_127, replace) ysize(8.5)
	graph export "./results/figures/tgraphs15_main3outcomes.png", replace

	scatter t_walk 		`gphlist' name(t4, replace) ytitle("Walk to Work")
	scatter t_workathome `gphlist'name(t5, replace) ytitle("Work at Home")
	scatter t_time 		`gphlist' name(t6, replace) ytitle("Mean Travel Time")
	scatter t_timedr 	`gphlist' name(t7, replace) ytitle("Mean Drive Time")

	graph combine t4 t5 t6 t7, row(3) xcommon title("Other Commuting Outcomes in 2000") saving(tgraphs_other, replace)
	graph export "./results/figures/tgraphs`y'_other.png", replace
	
	scatter e_emp 		`gphlist' name(e1, replace) ytitle("Employed")
	scatter e_lfp 		`gphlist' name(e2, replace) ytitle("Labor Force Part.")
	scatter e_hrs_con 	`gphlist' name(e6, replace) ytitle("Hours Worked if Employed")
	scatter e_wks_con 	`gphlist' name(e8, replace) ytitle("Weeks Worked if Employed") ylab(46(0.5)48)
	scatter w_wage_con 	`gphlist' name(w2, replace) ytitle("Wage Income if Employed") 
	scatter w_hhi  		`gphlist' name(w3, replace) ytitle("Household Income")

	** Figure A.3 **
	graph combine e1 e2 e6 e8 w2 w3, row(3) xcommon title("Labor Market in 2000") saving(eWgraphs, replace) xsize(5)
	graph export "./results/figures/eWgraphs`y'.png", replace

	scatter h_own  		`gphlist' name(h1, replace) ytitle("Owned Home")
	scatter h_rent  	`gphlist' name(h2, replace) ytitle("Rented")
	scatter h_value  	`gphlist' name(h3, replace) ytitle("House Value")
	scatter h_rentpr 	`gphlist' name(h4, replace) ytitle("Contract Rent")

	** Figure A.4
	graph combine h1 h2 h3 h4, row(2) xcommon title("Housing in 2000") saving(hgraphs, replace)
	graph export "./results/figures/hgraphs`y'.png", replace

	scatter d_marr  `gphlist' name(d1, replace) ytitle("Married")
	scatter d_div 	`gphlist' name(d2, replace) ytitle("Divorced")
	scatter d_hs  	`gphlist' name(d3, replace) ytitle("Graduated High School")
	scatter d_col 	`gphlist' name(d4, replace) ytitle("Graduated College")

	** Figure A.2 **
	graph combine d1 d2 d3 d4, row(2) xcommon title("Education and Household in 2000") saving(dgraphs, replace)
	graph export "./results/figures/dgraphs`y'.png", replace

	graph close 
	graph drop _all
}

********************************
** Centiles to make pretty pics
********************************

restore 

drop if w_wage_con==.
keep if bwA<=5

tempfile workingdata_all
save 	"`workingdata_all'"

egen inc_centile = cut(w_wage_con), g(100)
bys  inc_centile: egen n_icent = count(t_drive)
drop if n_icent<2000

tempfile centile_all
save 	"`centile_all'" 

keep 	n_icent inc_centile
collapse (mean) n_icent, by(inc_centile)
tempfile centile_freq
save 	"`centile_freq'" 
clear

use		"`centile_all'" 

statsby _b _se, by(inc_centile) clear: reg t_drive T D DT [fw=perwt], robust

merge 	1:1 inc_centile using "`centile_freq'"
drop	_merge

rename	_b_T  	 b_T100
rename 	n_icent n_bin100
keep 	inc_centile b_T100 n_bin100

tempfile centile_results
save 	"`centile_results'"


* 2) Make decile results
use 	"`workingdata_all'"

egen inc_centile = cut(w_wage_con), g(10)

statsby _b _se, by(inc_centile) clear: reg t_drive T D DT [fw=perwt], robust

gen 	hse = _b_T + _se_T*1.96
gen 	lse = _b_T - _se_T*1.96

/* Bonferroni correction, 10 tests */
gen 	hse_bon = _b_T + _se_T*2.81
gen 	lse_bon = _b_T - _se_T*2.81

replace inc_centile = inc_centile*10 + 5

* 3) Merge and graph
merge 	1:1 inc_centile using "`centile_results'"

twoway (scatter _b_T inc_centile,  msize(tiny)) || (rspike hse_bon lse_bon inc_centile), ///
		legend(label(1 "Decile-specific RD Estimate") label(2 "Bonferroni Corrected Standard Errors")) ///
		legend(position(6)) legend(ring(3)) legend(rows(1)) yline(0, lc(black)) ///
		xti("Income Decile in 2000") yti("RD Effect") ///
		saving(RDincome_het, replace)

graph export "./results/figures/RDincome_het.png", replace
		
** Figure A.5 **		
twoway (scatter _b_T inc_centile,  msize(tiny)) || (rspike hse_bon lse_bon inc_centile) || ///
		(lpoly b_T100 inc_centile [aw=n_bin100]), ///
		legend(label(1 "Decile-specific RD Estimate") label(2 "Bonferroni Corrected Standard Errors") label(3 "Smoothed, Weighted Centile Effect")) ///
		legend(position(6)) legend(ring(3)) legend(rows(2)) yline(0, lc(black)) ///
		xti("Income Centile in 2000") yti("Estimated RD Effect") ///
		saving(RDincome_het2, replace)
		
graph export "./results/figures/RDincome_het2.png", replace

graph close 


**********************************
** Close **

erase dgraphs.gph 
erase eWgraphs.gph 
erase hgraphs.gph 
erase RDincome_het.gph 
erase RDincome_het2.gph 
erase tgraphs_127.gph 
erase tgraphs_other.gph 

capture noisily log close
clear
