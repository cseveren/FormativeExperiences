capture program drop mn_wrapper_eval
program mn_wrapper_eval
	version 16
	syntax varlist [aw] [if], tfirst(integer) tlast(integer) expvar(namelist min=1 max=1) awts(namelist min=1 max=1) [init3(name)] [initall(name)] [cluster(varlist)]

	gettoken dpvar ivars1 : varlist
	gettoken avar controlvars : ivars1
	
	local n : word count `controlvars'
	local npms = `n'+3
	
	if "`init3'" != "" {
		mat A = `init3'
	
		if `n' == 0 {
			mat C = A
			} 
		else {
			mat B = J(1,`n',0)
			mat C = A,B
		}
	}
	else {
		mat C = `initall'
	}
	
	if "`aw'" != "" {
		local awpass "[aw=`aw']"
		}
	else {
		local awpass ""
	}
	
	if "`cluster'" != "" {
		nl simpleevalfe @ `varlist' `if' `awpass', tfirst(`tfirst') tlast(`tlast') expvar(`expvar') awts(`awts') nparameters(`npms') initial(C) cluster(`cluster')
		}
	else {
		nl simpleevalfe @ `varlist' `if' `awpass', tfirst(`tfirst') tlast(`tlast') expvar(`expvar') awts(`awts') nparameters(`npms') initial(C) robust
	}
end


capture program drop mn_wrapper_grid
program mn_wrapper_grid, rclass
	version 16
	syntax varlist [aw] [if], tfirst(integer) tlast(integer) expvar(namelist min=1 max=1) awts(namelist min=1 max=1) mat3(name)
	
	gettoken dpvar ivars1 : varlist
	gettoken avar controlvars : ivars1
	mat A = `mat3'
	
	if "`aw'" != "" {
		local awpass "[aw=`aw']"
		}
	else {
		local awpass ""
	}
	
	local	plist ""
	local	wlist ""
	
	foreach t of numlist `tfirst'/`tlast' {
		local 	plist = `"`plist'"' + " `expvar'_`t'"
		local 	wlist = `"`wlist'"' + " `awts'_`t'"
	}
	
	tempvar y diff
	quietly gen		`y' = 0 `if' 
	quietly gen		`diff' = 0 `if'
	
	tempname b0 b1 lmb
	scalar `b0' = A[1,1]
	scalar `b1' = A[1,2]
	scalar `lmb' = A[1,3]
	local lmbda = `lmb'
	
	mata: mnfunction("`plist'", "`wlist'", "`avar'", `lmbda')
	quietly replace `y' = `b0' + `b1'*`avar' `if'
	
	quietly sum		`y' `if' `awpass'
	local 	ymean = r(mean)
	quietly replace	`diff' = (`y' - `ymean' - `dpvar')^2 `if' `awpass'
	quietly sum 	`diff' `if' `awpass'
	
	return scalar rss = r(mean)*r(N) 
end


capture program drop nlsimpleevalfe
program nlsimpleevalfe
	version 16
	syntax varlist [if] [aw], at(name) tfirst(integer) tlast(integer) expvar(namelist min=1 max=1) awts(namelist min=1 max=1)
	/* order is dpvar avar othervariables */
	gettoken dpvar ivars1 : varlist
	gettoken avar controlvars : ivars1
	
	/* THIS SECTION PREPS THE CONSTANT and 2 EXPOSURE VARIABLES (LINEAR AND WT-Exponent) and
	*   then updates the value of the avar	*/

	local	plist ""
	local	wlist ""
	
	foreach t of numlist `tfirst'/`tlast' {
		local 	plist = `"`plist'"' + " `expvar'_`t'"
		local 	wlist = `"`wlist'"' + " `awts'_`t'"
	}

	tempvar y
	generate double `y' = 0 `if'
	
	tempname b0 b1 lmb
	scalar `b0' = `at'[1,1]
	scalar `b1' = `at'[1,2]
	scalar `lmb' = `at'[1,3]
	local lmbda = `lmb'
	
	mata: mnfunction("`plist'", "`wlist'", "`avar'", `lmbda')
	replace `y' = `b0' + `b1'*`avar' `if'

	sum `avar'
	display r(mean)
	
	** THIS SECTION CYCLES THROUGH THE REMAINING (LINEAR) EXPLANATORY VARIABLES **
	tokenize `controlvars'
	local k : word count `controlvars'
	
	forvalues i=1/`k' {
       tempname ipar
       scalar `ipar' = `at'[1,`i'+3]              // retrieve parameter values
       replace `y' = `y' + `ipar'*``i'' `if'      // calculates function value 
	}  
	
	replace `dpvar' = `y' `if'
end

mata: mata clear
mata:
void mnfunction(string scalar varlist_p, string scalar varlist_wt, string scalar var_a, real scalar lambda)
{
	real matrix 	P, W
	real colvector 	a
	
	st_view(P, ., tokens(varlist_p))
	st_view(W, ., tokens(varlist_wt))
	st_view(a, ., tokens(var_a))

	a[.] = rowsum(P :* (W :!= 0) :* (W :^ lambda)) :/ rowsum((W :!= 0) :* (W :^ lambda))
}
end
