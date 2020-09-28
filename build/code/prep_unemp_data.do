clear
import delim using "./data/unemployment/1965-1975_State_Unemployment.csv"
rename 	fips statefip

reshape long u, i(statefip) j(year)
rename 	u unemprate

append using "./data/unemployment/unemployment.dta"

drop 	state stateandarea
drop if statefip>=100

sort 	statefip year

save	"./output/unemp_prepped.dta", replace
