*************************************************************
** Gas and CPI monthly for long history
** Feb 2020
*************************************************************

************************************
************************************
** Read in data

insheet using "./data/gasprice_cpi/CUUR0000SETB01.csv", clear

gen		myr = mofd(date(date,"YMD"))
drop if myr < -36
format 	myr %tm
drop 	date
rename 	cuur gas_price_nom_cpi

tempfile gasp
save "`gasp'", replace

insheet using "./data/gasprice_cpi/CPILFESL.csv", clear

gen		myr = mofd(date(date,"YMD"))
drop if myr < -36
format 	myr %tm
drop 	date
rename 	cpilfesl cpiu

merge 1:1 myr using "`gasp'"
drop	_merge

** JAN 2017 has nominal gas price at 2.349 https://fred.stlouisfed.org/series/GASREGM
** JAN 2017 gas_price_nom_cpi has value at 206.36
**  --> nominal gas price is (gas_price_nom_cpi)*2.349/206.36

gen 	gp_nom = gas_price_nom_cpi*2.349/206.36

** JAN 2017 has cpiu at 250.519
**  --> nominal gas price is (gp_nom)*(250.519/cpiu)

gen 	gp_real = gp_nom*(250.519/cpiu)

tsset myr

set scheme plotplainblind

twoway (scatter gp_real myr if myr>tm(1965m1) & myr<=tm(1990m1), c(d) lp(solid)) || ///
		(scatter gp_nom myr if myr>tm(1965m1) & myr<=tm(1990m1), c(d) lp(solid)), ///
		legend(pos(6) row(1) label(1 "Real Price ($2017)") label(2 "Nominal Price")) ///
		xtitle("Year/Month") ytitle("Price of Gasoline") ///
		xline(`=tm(1973m9)' `=tm(1974m5)' `=tm(1979m2)' `=tm(1980m4)', lc(red) lp(dash))

graph export "./results/gasprices_1970s.png", replace
clear

