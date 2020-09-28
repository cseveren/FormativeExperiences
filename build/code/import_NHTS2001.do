*==============================================================================*
*                        MERGE HOUSEHOLD & PERSON FILES                        *
*==============================================================================*

use "./data/nhts/2001/2001 restricted/hhv4dot.DTA"
merge 1:m houseid using "./data/nhts/2001/2001 restricted/perv4dot.DTA"
rename *,lower
keep hhintdt numadlt drvrcnt hhr_race hbhur cdivmsar hhcnty hhstfips htppopdn urbrur houseid personid hhfaminc lif_cyc hhsize hhr_age wrkcount hhvehcnt hhc_msa hhstate hhstfips urban census_d census_r msasize ptused usepubtr wtperfin wthhfin
sort houseid
* usepubtr
destring usepubtr, replace force
replace usepubtr=. if usepubtr == -1
replace usepubtr=. if usepubtr == -8
replace usepubtr=. if usepubtr == -9
replace usepubtr=0 if usepubtr == 2
by houseid: egen hh_usepubtr = mean(usepubtr)
* ptused
destring ptused, replace force
replace ptused=. if ptused == -7
replace ptused=. if ptused == -8
replace ptused=. if ptused == -9
replace ptused=. if ptused == -1
replace ptused=. if ptused == 6
by houseid: egen hh_ptused_freq = mean(ptused)
* drop duplicate household/other members' observations in household;
* drop usepubtr and ptused
sort houseid
quietly by houseid: gen dup = cond(_N==1,0,_n)
replace dup=1 if dup==0
drop if dup > 1
drop dup
drop personid
drop ptused
drop usepubtr
save "./data/nhts/2001/2001 restricted/HHPER2001.dta",replace

