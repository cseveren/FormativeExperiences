*==============================================================================*
*                          MERGE HH & VEHICLE FILES                         *
*==============================================================================*

use "./data/nhts/2017/2017 public/vehpub.dta", clear
merge n:1 houseid personid using "./data/nhts/2017/2017 public/perpub.dta"
drop if _merge == 2
drop _merge
rename r_age whomain_age
keep whomain_age houseid vehid vehyear vehage make model fueltype vehtype whomain od_read hfuel vehowned vehownmo annmiles hybrid personid travday homeown hhsize hhvehcnt hhfaminc drvrcnt hhstate hhstfips numadlt wrkcount tdaydate lif_cyc msacat msasize rail urban urbansize urbrur census_d census_r cdivmsar hh_race hh_hisp hh_hisp hbhtnrnt hbppopdn hbresdn hteempdn hthtnrnt htppopdn htresdn smplsrce wthhfin
save "./data/nhts/2017/2017 public/vehpub_new.dta", replace

use "./data/nhts/2017/2017 public/hhpub.dta",clear
merge 1:m houseid using "./data/nhts/2017/2017 public/perpub.dta"
* get age for household, R_RELAT == "01" means household
replace r_age = . if r_age < 0
egen yngch_2017 = min(r_age), by(houseid)

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
*replace ptused=. if ptused == 6
by houseid: egen hh_ptused_freq = mean(ptused)
* drop duplicate household/other members' observations in household;
drop if r_relat != "01"
drop _merge
* drop usepubtr and ptused
drop personid
drop ptused
drop usepubtr

save "./data/nhts/2017/2017 public/HHPER2017.dta", replace
