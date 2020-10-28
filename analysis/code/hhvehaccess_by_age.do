*************************************************************
** Make chart of vehicle access by age
*************************************************************

use 	"./output/census8017_basefile.dta", clear

********************************
** Variable Creation

tab 	vehicles year
tab 	vehicles year, nol
tab		autos year
tab		autos year, nol
tab 	trucks year
tab 	trucks year, nol

** Drop not in universe
drop if vehicles==0 & year==2017
drop if autos==0 & year==1980
drop if trucks==0 & year==1980

gen 	hhvehaccess = (vehicles!=9) if year==2017
replace hhvehaccess = 1-(autos==1 & trucks==1) if year==1980

tab hhveh year [aw=perwt], column
tab hhveh year [aw=hhwt], column
* Use perwt *

collapse (mean) hhveh [aw=perwt], by(age year)

** GRAPHING **
set scheme plotplainblind

twoway (scatter hhveh age if year==1980 & age<63, c(l) lp(dash) lc(gray) mc(gray)) || ///
		(scatter hhveh age if year==2017 & age<63, c(l) lp(solid) lc(black) mc(black)), ///
		legend(pos(6) row(1) lab(1 "in 1980 Census") lab(2 "in 2013-17 5yr ACS")) ///
		ytitle("Percent with Vehicle Access in HH") xtick(0(10)60) xlabel(0(10)60)

graph export "./results/figures/hhveh_byage.png"
