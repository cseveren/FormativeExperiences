*==============================================================================*
*                        MERGE HOUSEHOLD & PERSON FILES                        *
*==============================================================================*

use "./data/nhts/2009/2009 restricted/hh_dotv2.dta"
merge 1:m houseid using "./data/nhts/2009/2009 restricted/pp_dotv2.dta"
rename *, lower
drop _merge
sort houseid
keep perindt2 numadlt drvrcnt hh_race hbhur cdivmsar hhcntyfp hhstfips htppopdn houseid personid wrkcount hhvehcnt census_d census_r hh_msa hhstate hhstfips urban msasize lif_cyc hhsize hhfaminc r_age ptused usepubtr urbrur wthhfin wtperfin
* usepubtr: Use public transit on travel day
* replace following to missing: -1:Appropriate skip, -7:Refused, -8:Don't know, -9:Not ascertained, 2: NO
* replace yes to 1 and no to 0
destring usepubtr, replace force
replace usepubtr=. if usepubtr == -1 
replace usepubtr=. if usepubtr == -7 
replace usepubtr=. if usepubtr == -8
replace usepubtr=. if usepubtr == -9 
replace usepubtr=0 if usepubtr == 2 
by houseid: egen hh_usepubtr = mean(usepubtr)
* ptused: How often S used public transit in past month
* replace following to missing: -7: Refused, -8:Don't know, -9:Not ascertained, -1:Appropriate skip
destring ptused, replace force
replace ptused=. if ptused == -7 
replace ptused=. if ptused == -8 
replace ptused=. if ptused == -9 
replace ptused=. if ptused == -1 
by houseid: egen HH_ptused = mean(ptused)
* drop duplicate household/other members' observations in household; drop USEPUBTR and PTUSED
sort houseid
quietly by houseid: gen dup = cond(_N==1,0,_n)
replace dup=1 if dup==0
drop if dup > 1
drop dup
drop personid
drop ptused
drop usepubtr
rename *, lower
save "./data/nhts/2009/2009 restricted/HHPER2009.dta", replace
