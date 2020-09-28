*==============================================================================*
*                        MERGE HOUSEHOLD & PERSON FILES                        *
*==============================================================================*

use "./data/nhts/1995/1995 restricted/HHDOT1.dta"
merge 1:m houseid using "./data/nhts/1995/1995 restricted/PERDOT.dta"
gen hhintdt = "19" + string(mstr_yr) + string(mstr_mon ,"%02.0f")
rename *,lower
keep hhintdt numadlt drvrcnt hh_race hbhur hhstfips hhcounty htppopdn wthhfin wtperfin wrkcount houseid personid hhfaminc lif_cyc hhsize ref_age wrkcount hhvehcnt hhmsa hhmsa hhstate hhstfips urban census_d census_r msasize ptused
sort houseid
* ptused
destring ptused, replace
replace ptused=. if ptused == 94
replace ptused=. if ptused == 98
replace ptused=. if ptused == 99
replace ptused=. if ptused == 6
replace ptused=0 if ptused == 5
sort houseid
by houseid: egen hh_ptused_freq = mean(ptused)
replace ptused=1 if ptused == 1
replace ptused=1 if ptused == 2
replace ptused=1 if ptused == 3
replace ptused=1 if ptused == 4
by houseid: egen hh_usepubtr = mean(ptused)
* drop duplicate household/other members' observations in household;
* drop ptused
sort houseid
quietly by houseid: gen dup = cond(_N==1,0,_n)
replace dup=1 if dup==0
drop if dup > 1
drop dup
drop personid
drop ptused
save "./data/nhts/1995/1995 restricted/HHPER1995.dta", replace

