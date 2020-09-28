** summary table on driver license minimum ages **
clear

** Prep State Populations **
insheet using 	"./data/state_pops/nhgis0081_ds94_1970_state.csv", c
keep 	year statea cbc001	
rename 	statea stfip
rename	cbc001 pop
tempfile p1970
save	"`p1970'", replace
clear

insheet using 	"./data/state_pops/nhgis0081_ds104_1980_state.csv", c
keep 	year statea c7l001
rename 	statea stfip
rename	c7l001 pop
tempfile p1980
save	"`p1980'", replace
clear

insheet using 	"./data/state_pops/nhgis0081_ds120_1990_state.csv", c
keep 	year statea et1001
rename 	statea stfip
rename	et1001 pop
tempfile p1990
save	"`p1990'", replace
clear

insheet using 	"./data/state_pops/nhgis0081_ds146_2000_state.csv", c
keep 	year statea fl5001
rename 	statea stfip
rename	fl5001 pop
tempfile p2000
save	"`p2000'", replace
clear

insheet using 	"./data/state_pops/nhgis0081_ds172_2010_state.csv", c
keep 	year statea h7v001
rename 	statea stfip
rename	h7v001 pop

append using "`p2000'"
append using "`p1990'"
append using "`p1980'"
append using "`p1970'"

tempfile statepops
save	"`statepops'", replace

*******************

use		"./output/dlpanel_prepped", clear

*keep if year==1970 | year==1975 | year==1980 | year==1985 | year==1990 | year==1995 | year==2000 | year==2005 | year==2010
keep if year==1970 | year==1980 | year==1990 | year==2000 | year==2010

gen		min_age_full_round = round(min_age_full)
gen		min_int_age_round = round(min_int_age)

estpost tab year min_age_full_round
esttab using "./results/dl_summary_full", unstack cell(b) booktabs replace 

estpost tab year min_int_age_round
esttab using "./results/dl_summary_provisional", unstack cell(b) booktabs replace 


merge 1:1 stfip year using "`statepops'"
drop if _merge!=3
drop	_merge

collapse (mean) min_age_full min_int_age [aw=pop], by(year)

estpost tabstat min_age_full, by(year)
esttab  using "./results/dl_ave_full", main(mean) booktabs replace 

estpost tabstat min_int_age, by(year)
esttab  using "./results/dl_ave_int", main(mean) booktabs replace

********************
clear
import excel using 	"./data/driver_license_requirements/learner_permit_counts.xlsx", first case(l) 
rename	c y1967
rename	d y1972
rename	e y1980
rename 	f y1988
rename 	g y1994
rename  h y2010

reshape long y, i(stateid) j(year)
rename  y lp_age

gen lp_age_round = round(lp_age)

estpost tab year lp_age_round
esttab using "./results/dl_summary_lp", unstack cell(b) booktabs replace 
