*************************************************************
** Summary materials for gas prices
*************************************************************

************************************
************************************
** Set up log and output directory

use "./output/gasprice_prepped.dta", clear


collapse (median) gas_price gas_price_99 d1gp_bp d2gp_bp ///
			(min) p0_gas_price=gas_price p0_real_gas=gas_price_99 p0_d1gp_bp=d1gp_bp p0_d2gp_bp=d2gp_bp ///
			(p25) p25_gas_price=gas_price p25_real_gas=gas_price_99 p25_d1gp_bp=d1gp_bp p25_d2gp_bp=d2gp_bp ///
			(p75) p75_gas_price=gas_price p75_real_gas=gas_price_99 p75_d1gp_bp=d1gp_bp p75_d2gp_bp=d2gp_bp ///
			(max) p100_gas_price=gas_price p100_real_gas=gas_price_99 p100_d1gp_bp=d1gp_bp p100_d2gp_bp=d2gp_bp, by(year)

set scheme plotplainblind

tempfile real d1 d2
	   
twoway line gas_price_99 year, lcolor(gs12) || ///
	   rbar p25_real_gas gas_price_99 year, fcolor(gs12) lcolor(black) barw(.7) || ///
       rbar gas_price_99 p75_real_gas year, fcolor(gs12) lcolor(black) barw(.7) || ///
       rspike p25_real_gas p0_real_gas year, lcolor(black) || ///
       rspike p75_real_gas p100_real_gas year, lcolor(black) || ///
       rcap p0_real_gas p0_real_gas year, msize(*.7) lcolor(black) || ///
       rcap p100_real_gas p100_real_gas year, msize(*.7) pstyle(p1) legend(off) ///
	   yti("Real Gasoline Price (USD)") xlabel(,nogrid) ylabel(,nogrid) xti("") ///
	   yline(0, lcolor(gs8) lstyle(grid)) saving(real, replace) xsc(r(1965 2017))

twoway line d1gp_bp year, lcolor(gs12) || ///
	   rbar p25_d1gp_bp d1gp_bp year, fcolor(gs12) lcolor(black) barw(.7) || ///
       rbar d1gp_bp p75_d1gp_bp year, fcolor(gs12) lcolor(black) barw(.7) || ///
       rspike p25_d1gp_bp p0_d1gp_bp year, lcolor(black) || ///
       rspike p75_d1gp_bp p100_d1gp_bp year, lcolor(black) || ///
       rcap p0_d1gp_bp p0_d1gp_bp year, msize(*.7) lcolor(black) || ///
       rcap p100_d1gp_bp p100_d1gp_bp year, msize(*.7) pstyle(p1) legend(off) ///
	   yti("Gas Price Change over One Year") xlabel(,nogrid) ylabel(,nogrid) xti("") ///
	   yline(0, lcolor(gs8) lstyle(grid)) saving(d1, replace) xsc(r(1965 2017)) ///
	   ylab(-0.4 "-40%" -0.2 "-20%" 0 "0%" 0.2 "20%" 0.4 "40%")
	   
twoway line d2gp_bp year, lcolor(gs12) || ///
	   rbar p25_d2gp_bp d2gp_bp year, fcolor(gs14) lcolor(black) barw(.7) || ///
       rbar d2gp_bp p75_d2gp_bp year, fcolor(gs14) lcolor(black) barw(.7) || ///
       rspike p25_d2gp_bp p0_d2gp_bp year, lcolor(black) || ///
       rspike p75_d2gp_bp p100_d2gp_bp year, lcolor(black) || ///
       rcap p0_d2gp_bp p0_d2gp_bp year, msize(*.7) lcolor(black) || ///
       rcap p100_d2gp_bp p100_d2gp_bp year, msize(*.7) pstyle(p1) legend(off) ///
	   yti("Gas Price Change over Two Years") xlabel(,nogrid) ylabel(,nogrid) xti("Year") ///
	   yline(0, lcolor(gs8) lstyle(grid)) saving(d2, replace) xsc(r(1965 2017)) ///
	   ylab(-0.5 "-50%" 0 "0%" 0.5 "50%" 1 "100%")
	
	
gr combine real.gph d1.gph d2.gph, xcommon col(1) ysize(10) xsize(6.8)
graph export "./results/figures/gasprice_variation_picture.png", replace

twoway line d2gp_bp year, lcolor(gs12) || ///
	   rbar p25_d2gp_bp d2gp_bp year, fcolor(gs14) lcolor(black) barw(.7) || ///
       rbar d2gp_bp p75_d2gp_bp year, fcolor(gs14) lcolor(black) barw(.7) || ///
       rspike p25_d2gp_bp p0_d2gp_bp year, lcolor(black) || ///
       rspike p75_d2gp_bp p100_d2gp_bp year, lcolor(black) || ///
       rcap p0_d2gp_bp p0_d2gp_bp year, msize(*.7) lcolor(black) || ///
       rcap p100_d2gp_bp p100_d2gp_bp year, msize(*.7) pstyle(p1) legend(off) ///
	   yti("Gas Price Change over Two Years") xlabel(,nogrid) ylabel(,nogrid) xti("Year") ///
	   yline(0, lcolor(gs8) lstyle(grid)) saving(d2, replace) xsc(r(1965 2010)) ///
	   ylab(-0.5 "-50%" 0 "0%" 0.5 "50%" 1 "100%")
graph export "./results/figures/gasprice_variation_picture_d2.png", replace	

erase real.gph 
erase d1.gph 
erase d2.gph
clear
