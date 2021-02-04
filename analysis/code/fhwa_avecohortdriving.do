clear

insheet using "./data/fhwa_highwaystats/dl220_prepped.csv", c

reshape	long male female total, i(year) j(age)

rename 	male n_male
rename	female n_female
rename 	total n_total

label var n_male	"Number of male drivers of age (x1000)"
label var n_female 	"Number of females drivers of age (x1000)"
label var n_total 	"Total drivers of age (x1000)"

foreach n of varlist n_male n_female n_total {
	replace `n' = round(`n')
}

compress

****************************
/* CDFs of adoption */

merge 1:1 age year using "./output/SeerPopEst_National.dta"

drop if _merge!=3
drop	_merge n_male n_female

gen 	bcohort = year-age
gen 	cohort16 = bcohort+16

replace pop = pop/1000
gen		p_drivers = n_total/pop

preserve 

	drop if bcohort<=1953
	drop if cohort16>=2000

	gen ofage17inyr = cohort16+1
	gen ofage18inyr = cohort16+2
	gen ofage20inyr = cohort16+4
	gen ofage22inyr = cohort16+6

	foreach n of numlist 17 18 20 22 {
		gen drop`n' = 0
		replace drop`n' = 1 if ofage`n'inyr==1983
		replace drop`n' = 1 if ofage`n'inyr==1985
	}
	gen drop16 = 0
	replace drop16 = 1 if cohort16==1983
	replace drop16 = 1 if cohort16==1985

	set scheme plotplainblind

	** Figure 5 **
	
	twoway (scatter p_drivers cohort16 if age==16 & drop16==0, c(l)) || (scatter p_drivers ofage17inyr if age==17 & drop17==0, c(l)) || ///
		(scatter p_drivers ofage18inyr if age==18 & drop18==0, c(l)) || (scatter p_drivers ofage20inyr if age==20 & drop20==0, c(l)) || ///
		(scatter p_drivers ofage22inyr if age==22 & drop22==0, c(l)), ///
		ytitle("Probability of Having License by Age...") xtitle("Year of Tally") ///
		legend(lab(1 "By Age 16") lab(2 "By Age 17") lab(3 "By Age 18") ///
			lab(4 "By Age 20") lab(5 "By Age 22") pos(6) r(1))	

	graph export "./results/figures/dladoption_byageALL.png", as(png) replace
	
restore 
****************************
/* Adoption by age by year */

keep age year p_drivers

reshape wide p_drivers, i(year) j(age)

export delim "./results/figures/dladoption_by_age.csv"
