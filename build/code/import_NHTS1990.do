*==============================================================================*
*                        MERGE HOUSEHOLD & PERSON FILES                        *
*==============================================================================*

use "./data/nhts/1990/1990 restricted/HOUSEHLD.dta"
gen hhintdt = "19" + string(mstr_yr) + string(mstr_mon ,"%02.0f")
merge 1:m houseid using "./data/nhts/1990/1990 restricted/PERSON.dta"
sort houseid
keep hhintdt numadlt drvrcnt hh_race hhstfips hhcofips poppersq wthhfin wtperfin houseid personid wrkrcnt hhvehcnt census_d census_r hhmsa hhstate hhstfips urban msasize lif_cyc hhsize hhfaminc ref_age wrktrans
* use wrktrans to generate the ave number of hh members use public transit
* wrktrans = main means of transportation to work 
replace wrktrans=0 if wrktrans == 01
replace wrktrans=0 if wrktrans == 08
replace wrktrans=0 if wrktrans == 09
replace wrktrans=0 if wrktrans == 10
replace wrktrans=0 if wrktrans == 11
replace wrktrans=0 if wrktrans == 94
replace wrktrans=0 if wrktrans == 98
replace wrktrans=1 if wrktrans == 02
replace wrktrans=1 if wrktrans == 04
replace wrktrans=1 if wrktrans == 05
replace wrktrans=1 if wrktrans == 07
by houseid: egen hh_usepubtr = mean(wrktrans)
* drop duplicate household/other members' observations in household;
* drop other variable
quietly by houseid: gen dup = cond(_N==1,0,_n)
replace dup=1 if dup==0
drop if dup > 1
drop dup
drop personid
drop wrktrans
save "./data/nhts/1990/1990 restricted/HHPER1990.dta", replace

