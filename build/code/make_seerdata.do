clear

infix using "./data/seerpopest/SeerPopEstDictionary.dct"

compress

collapse (sum) pop, by(year age stfips)

drop if age>=85

tab age
tab stfips
tab year
tab year if stfips==99

sum pop age if stfips==99, d
/* Code 99 are Katrina Adjustments, see: https://seer.cancer.gov/data/hurricane.html.
	However, this doesn't matter for national statistics */

collapse (sum) pop, by(year age)

save "./output/SeerPopEst_National.dta", replace

clear
