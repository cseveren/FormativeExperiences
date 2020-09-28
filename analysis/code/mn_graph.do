*************************************************************
** Plotting Cumulative Exposure function vs. our results
*************************************************************

************************************
************************************

use 	"./results/panel_census/compare_reald1ages_long", clear
gen		model = 0

append using "./results/panel_nhts/compare_reald1ages_long"
replace model = 1 if mi(model)

gen 	age = substr(varname,-2,.)
destring age, replace
drop varname

reshape wide b se, i(age) j(model)

set obs 27
replace age = age[_n-1]+1 if mi(age)


foreach m of numlist 0/1 {
	gen 	ci95_`m'_lo = b`m' - 1.965*se`m'
	gen		ci95_`m'_hi = b`m' + 1.965*se`m'
	gen 	ci90_`m'_lo = b`m' - 1.65*se`m'
	gen		ci90_`m'_hi = b`m' + 1.65*se`m'
	gen		mn_`m'_age39 = .
}


** Census Shock

local wt = 0
local b2_censusshock = -.0140099
local b3_censusshock = -1.078637

foreach v of numlist 16/39 {
	local wt = `wt'+(`v'-15)^`b3_censusshock'
}
display `wt'

foreach v of numlist 16/39 {
	replace mn_0_age39 = `b2_censusshock'*(((`v'-15)^`b3_censusshock')/(`wt')) if age==`v'
}

** NHTS Shock

local wt = 0
local b2_nhtsshock = -.6795835
local b3_nhtsshock = -.3293701

foreach v of numlist 16/39 {
	local wt = `wt'+(`v'-15)^`b3_nhtsshock'
}
display `wt'

foreach v of numlist 16/39 {
	replace mn_1_age39 = `b2_nhtsshock'*(((`v'-15)^`b3_nhtsshock')/(`wt')) if age==`v'
}



set scheme plotplainblind

** Individual
twoway (rspike ci95_0_hi ci95_0_lo age if age<=25, lc(gs10) lw(vthin)) || ///
		(rspike ci90_0_hi ci90_0_lo age if age<=25, lc(gs10) lw(medthick)) || ///
		(scatter b0 age if age<=25, mc(black) ms(Oh)) || ///
		(scatter mn_0_age39 age if age<=25, mc(blue%40) ms(o) connect(l) lc(blue%40) lp(dashed)), ///
		legend(pos(6) r(2) order(3 "Shock at age of exposure: Heterogeneous effects" ///
			4 "Marginal effect: Cumulative exposure function for adult aged 39")) ///
		xscale(range(10 25)) yscale(range(-.01 .01)) ylabel(-0.01(0.005)0.01) yline(0, lc(black) lp(solid)) ///
		xtitle("Age of exposure (gas price shock {&Delta}(a{sub:t},a{sub:t-1}))") ///
		ytitle("Extensive margin effect")

graph export "./results/mn_ext.png", replace
		
		
twoway (rspike ci95_1_hi ci95_1_lo age if age<=25, lc(gs10) lw(vthin)) || ///
		(rspike ci90_1_hi ci90_1_lo age if age<=25, lc(gs10) lw(medthick)) || ///
		(scatter b1 age if age<=25, mc(black) ms(Oh)) || ///
		(scatter mn_1_age39 age if age<=25, mc(blue%40) ms(o) connect(l) lc(blue%40) lp(dashed)), ///
		legend(pos(6) r(2) order(3 "Shock at age of exposure: Heterogeneous effects" ///
			4 "Marginal effect: Cumulative exposure function for adult aged 39")) ///
		xscale(range(10 25)) yscale(range(-.2 .2)) ylabel(-0.2(0.1)0.2) yline(0, lc(black) lp(solid)) ///
		xtitle("Age of exposure (gas price shock {&Delta}(a{sub:t},a{sub:t-1}))") ///
		ytitle("Intensive margin effect") 

graph export "./results/mn_int.png", replace

** COMBINED
tempfile g1 g2		
		
twoway (rspike ci95_0_hi ci95_0_lo age if age<=25, lc(gs10) lw(vthin)) || ///
		(rspike ci90_0_hi ci90_0_lo age if age<=25, lc(gs10) lw(medthick)) || ///
		(scatter b0 age if age<=25, mc(black) ms(Oh)) || ///
		(scatter mn_0_age39 age if age<=25, mc(blue%40) ms(o) connect(l) lc(blue%40) lp(dashed)), ///
		legend(off) ///
		xscale(range(10 25)) yscale(range(-.01 .01)) ylabel(-0.01(0.005)0.01) yline(0, lc(black) lp(solid)) ///
		xtitle("") ///
		ytitle("Extensive margin effect") ///
		subtitle("A. Extensive margin (1[drive])") ///
		saving("`g1'", replace) fysize(43)
		
twoway (rspike ci95_1_hi ci95_1_lo age if age<=25, lc(gs10) lw(vthin)) || ///
		(rspike ci90_1_hi ci90_1_lo age if age<=25, lc(gs10) lw(medthick)) || ///
		(scatter b1 age if age<=25, mc(black) ms(Oh)) || ///
		(scatter mn_1_age39 age if age<=25, mc(blue%40) ms(o) connect(l) lc(blue%40) lp(dashed)), ///
		legend(pos(6) r(2) order(3 "Shock at age of exposure: Heterogeneous effects" ///
			4 "Marginal effect: Cumulative exposure function for adult aged 39")) ///
		xscale(range(10 25)) yscale(range(-.2 .2)) ylabel(-0.2(0.1)0.2) yline(0, lc(black) lp(solid)) ///
		xtitle("Age of exposure (gas price shock {&Delta}(a{sub:t},a{sub:t-1}))") ///
		ytitle("Intensive margin effect" " ") ///
		subtitle("B. Intensive margin (ln(VMT))") ///
		saving("`g2'", replace)  fysize(57)
			
graph combine "`g1'" "`g2'", c(1) xcommon  ///
 imargin(0 0 0 0) ysize(5.5) 
 
graph export "./results/mn_both.png", replace


tempfile g1 g2		
		
twoway (rspike ci95_0_hi ci95_0_lo age if age<=25, lc(gs10) lw(thin)) || ///
		(rspike ci90_0_hi ci90_0_lo age if age<=25, lc(gs10) lw(medthick)) || ///
		(scatter b0 age if age<=25, mc(black) ms(Oh)) || ///
		(scatter mn_0_age39 age if age<=25, mc(blue%40) ms(o) connect(l) lc(blue%40) lp(dashed)), ///
		legend(off) ///
		xscale(range(10 25)) yline(0, lc(black) lp(solid)) ///
		xtitle("") ///
		ytitle("Extensive margin effect") ///
		subtitle("A. Extensive margin (1[drive])") ///
		saving("`g1'", replace) fysize(42)
		
twoway (rspike ci95_1_hi ci95_1_lo age if age<=25, lc(gs10) lw(thin)) || ///
		(rspike ci90_1_hi ci90_1_lo age if age<=25, lc(gs10) lw(medthick)) || ///
		(scatter b1 age if age<=25, mc(black) ms(Oh)) || ///
		(scatter mn_1_age39 age if age<=25, mc(blue%40) ms(o) connect(l) lc(blue%40) lp(dashed)), ///
		legend(pos(6) r(2) order(3 "Shock at age of exposure: Event study" ///
			4 "Marginal effect: Cumulative exposure function for adult aged 39")) ///
		xscale(range(10 25)) yline(0, lc(black) lp(solid)) ///
		xtitle("Age of exposure (gas price shock {&Delta}(a{sub:t},a{sub:t-1}))") ///
		ytitle("Intensive margin effect" " ") ///
		subtitle("B. Intensive margin (ln(VMT))") ///
		saving("`g2'", replace)  fysize(58)
			
graph combine "`g1'" "`g2'", c(1) xcommon  ///
 imargin(0 0 0 0) ysize(5.5) 
 


clear
