use 	"./data/gasprice/gasprice.dta"
replace statefip = 11 if statename=="DC"
xtset 	statefip year

keep statefip year statename gas_price_99

gen 	d1gp_bp = (gas_price_99-L.gas_price_99)/L.gas_price_99
gen 	d2gp_bp = (gas_price_99-L2.gas_price_99)/L2.gas_price_99

save	"./output/gasprice_prepped.dta", replace
