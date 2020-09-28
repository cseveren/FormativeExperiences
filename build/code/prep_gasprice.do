use 	"./data/gasprice/gasprice.dta"
replace statefip = 11 if statename=="DC"
xtset 	statefip year

gen 	d1gp_bp = (gas_price_99-L.gas_price_99)/L.gas_price_99
gen 	d2gp_bp = (gas_price_99-L2.gas_price_99)/L2.gas_price_99

/*Nominal
gen 	d1gp_bp = (gas_price-L.gas_price)/L.gas_price
gen 	d2gp_bp = (gas_price-L2.gas_price)/L2.gas_price
*/
save	"./output/gasprice_prepped.dta", replace
