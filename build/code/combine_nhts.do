***************************************************************************
/* Driver level, including all people even they are not drivers */
***************************************************************************
clear

* import 2001 NHTS

* prep updated vehicle codes
import delim using "./data/nhts/2001/updated_model_codes/VEHV4_R2.csv"
rename 	modlcode modlcode_v4
rename 	makecode makecode_v4
tostring vehid, replace
gen		vehidlen=strlen(vehid)
replace	vehid = "0"+vehid if vehidlen==1
tempfile modelcodes01
save 	"`modelcodes01'", replace

* merge datasets
use "./data/nhts/2001/2001 restricted/vehv4dot.DTA", clear
gen 	whomain_dup = whomain
rename 	whomain personid
merge n:1 houseid personid using "./data/nhts/2001/2001 restricted/perv4dot.DTA"
* drop if vehicles cannot be merged to the drivers, but still people who are not main drivers (and code their annmiles == 0)
drop if _merge == 1
replace annmiles = 0 if _merge == 2
* whomain_age = the age of main driver
gen 	whomain_age = r_age
drop 	_merge
destring personid, replace
rename 	whomain_dup whomain
keep 	r_age personid usepubtr expfllpr whomain_age houseid vhcaseid vehid msacat ///
		rail cdivmsar hbhur hthur veh12mnt estmlcat vehmlcat vehtype ann_flg urbrur ///
		whomain readate1 readate2 imptrace hhr_hisp hhr_race hhsize census_r census_d ///
		ownunit maindrvr travday smplarea smplfirm smplsrce tdaydate homeown hometype ///
		hhincttl ratiowv lang urban msasize expflhhn wthhntl vtypfuel epatmpgf ///
		epatmpg btuyear btutcost eiadmpg btucost fueltype expfllhh wthhfin annualzd ///
		anulzdse bestmile gscost gstotcst gsyrgal readdiff vehownmo vehmiles estmiles ///
		anmltyr annmiles endtrav begtrav hhfaminc numadlt hhvehcnt wrkcount drvrcnt ///
		readat1 readat2 makename modlname tdaydat2 milelimt vehowned expscrhh hhstate ///
		hhstfips makecode modlcode vehage hhc_msa htppopdn hbppopdn hthresdn hbhresdn ///
		hbhtnrnt hteempdn hthtnrnt msapop vehyear r_sex worker
* merge with household level data
merge m:1 houseid using "./data/nhts/2001/2001 restricted/HHPER2001.DTA"
keep 	r_age personid usepubtr expfllpr whomain_age whomain hhintdt numadlt fueltype ///
		drvrcnt hhr_race hbhur cdivmsar hhcnty hhstfips htppopdn urbrur wtperfin wthhfin ///
		eiadmpg epatmpg gscost gstotcst gsyrgal bestmile _merge vehid houseid hhfaminc ///
		lif_cyc hhsize hhr_age wrkcount hhvehcnt hhc_msa hhstate hhstfips urban census_d /// 
		census_r msasize hh_ptused hh_usepubtr annmiles makename modlname vehmiles ///
		makecode modlcode vehage vehyear vehtype smplfirm r_sex worker
rename 	hhr_race hh_race
rename 	*, lower
gen 	nhtsyear = 2001
drop 	_merge
preserve
	keep if vehid==""
	tempfile noveh_2001
	save "`noveh_2001'", replace
restore
drop if vehid==""
merge 1:1 houseid vehid using "`modelcodes01'"
drop if _merge==2
drop 	_merge
gen 	makelen = strlen(makecode)
gen 	modllen = strlen(modlcode)
gen		makecode_f = makecode_v4 if makecode_v4!="XXX"
replace	makecode_f = makecode if makecode_v4=="XXX" & makelen!=3
gen 	modlcode_f = modlcode_v4 if modlcode_v4!="XXXX"
replace	modlcode_f = modlcode if modlcode_v4=="XXXX" & smplfirm=="01"
replace	modlcode_f = substr(modlcode,2,3) if modlcode_v4=="XXXX" & smplfirm=="02" & makelen==1
replace	modlcode_f = substr(modlcode,3,2) if modlcode_v4=="XXXX" & smplfirm=="02" & makelen==2
drop 	makecode makecode_v4 modlcode modlcode_v4 makelen modllen
rename 	modlcode_f modlcode
rename 	makecode_f makecode
append	using "`noveh_2001'"
save 	"./output/NHTScombined.dta", replace

* import 2009 NHTS

use "./data/nhts/2009/2009 restricted/vv_dotv2.DTA", clear
gen 	whomain_dup = whomain
merge n:1 houseid personid using "./data/nhts/2009/2009 restricted/pp_dotv2.DTA"
* drop if vehicles cannot be merged to the drivers, but still people who are not main drivers (and code their annmiles == 0)
drop if _merge == 1
replace annmiles = 0 if _merge == 2
* whomain_age = the age of main driver
gen 	whomain_age = r_age
drop 	_merge
destring personid, replace
rename 	wtperfin expfllpr
keep 	perindt2 r_age personid usepubtr expfllpr whomain_age houseid vehid msacat ///
		rail cdivmsar hbhur vehtype urbrur whomain hhr_hisp hhr_race hhsize census_r census_d ///
		ownunit travday tdaydate homeown hometype lang urban msasize epatmpgf epatmpg eiadmpg ///
		fueltype hybrid wthhfin bestmile gscost gstotcst gsyrgal vehownmo estmiles annmiles hhfaminc ///
		numadlt hhvehcnt wrkcount drvrcnt makename modlname tdaydat2 hhstate hhstfips makecode ///
		modlcode vehage hhc_msa htppopdn hbppopdn hbhtnrnt hteempdn hthtnrnt vehyear r_sex worker
* merge with household level data
merge m:1 houseid using "./data/nhts/2009/2009 restricted/HHPER2009.DTA"
keep 	r_age personid usepubtr expfllpr whomain_age whomain perindt2 numadlt fueltype hybrid ///
		drvrcnt hh_race hbhur cdivmsar hhstfips htppopdn urbrur wtperfin wthhfin eiadmpg ///
		epatmpg gscost gstotcst gsyrgal bestmile _merge vehid houseid hhfaminc hhsize ///
		wrkcount hhvehcnt hh_msa hhstate hhstfips urban census_d census_r msasize ///
		hh_ptused hh_usepubtr annmiles makename modlname makecode modlcode vehage vehyear vehtype r_sex worker
destring htppopdn personid, replace
replace personid = . if personid < 0
rename 	*, lower
gen 	nhtsyear = 2009
tostring vehyear, replace
append 	using "./output/NHTScombined.dta"
save 	"./output/NHTScombined.dta", replace

* import 2017 NHTS

use "./data/nhts/2017/2017 public/vehpub.DTA", clear
gen 	whomain_dup = whomain
merge n:1 houseid personid using "./data/nhts/2017/2017 public/perpub.DTA"
* drop if vehicles cannot be merged to the drivers, but still people who are not main drivers (and code their annmiles == 0)
drop if _merge == 1
replace annmiles = 0 if _merge == 2
* whomain_age = the age of main driver
gen 	whomain_age = r_age
drop 	_merge
destring personid, replace
rename 	wtperfin expfllpr
keep 	r_age personid usepubtr expfllpr whomain_age tdaydate houseid vehid msacat ///
		rail cdivmsar urbansize vehtype urbrur whomain hh_hisp hh_race hhsize census_r ///
		census_d travday tdaydate homeown urban msasize fueltype hfuel hybrid wthhfin vehownmo ///
		annmiles hhfaminc numadlt hhvehcnt wrkcount drvrcnt make model hhstate hhstfips ///
		vehage msacat msasize cdivmsar htppopdn hbppopdn hbhtnrnt hteempdn hthtnrnt vehyear r_sex worker
rename 	make makecode
rename 	model modlcode
* merge with household level data
merge m:1 houseid using "./data/nhts/2017/2017 public/HHPER2017.DTA"
keep 	r_age personid usepubtr expfllpr whomain_age tdaydate whomain numadlt fueltype hfuel hybrid ///
		drvrcnt hh_race urbansize cdivmsar hhstfips htppopdn urbrur wtperfin wthhfin ///
		_merge vehid houseid hhfaminc hhsize wrkcount hhvehcnt hhstate hhstfips urban ///
		census_d census_r msacat msasize cdivmsar hh_ptused hh_usepubtr annmiles ///
		makecode modlcode vehtype vehyear r_sex worker
destring htppopdn personid, replace
replace personid = . if personid < 0
destring fueltype, replace
rename 	*, lower
gen 	nhtsyear = 2017
tostring vehyear, replace
append 	using "./output/NHTScombined.dta"
save 	"./output/NHTScombined.dta", replace

* import 1995 NHTS

* merge datasets
use "./data/nhts/1995/1995 restricted/VEHDOT.DTA", clear
gen whomain_dup = whomain
rename whomain personid
destring personid, replace
merge n:1 houseid personid using "./data/nhts/1995/1995 restricted/PERDOT.DTA"
* drop if vehicles cannot be merged to the drivers, but still people who are not main drivers (and code their annmiles == 0)
drop if _merge == 1
replace annmiles = 0 if _merge == 2
* whomain_age = the age of main driver
gen 	whomain_age = r_age
drop 	_merge
destring personid, replace
rename 	whomain_dup whomain
keep 	r_age personid intrvday intrvmon intrvyr wrktrans whomain_age houseid vehid ///
		msasize hhmsa hhcmsa rail hbhur veh12mnt vehtype ann_flg hbhur whomain hh_hisp ///
		hh_race hhsize census_r census_d maindrvr travday wthhfin annualzd anulzdse ///
		vehmiles annmiles hhfaminc hhvehcnt wrkcount drvrcnt make model milelimt ///
		workstat makecode modlcode hbppopdn vehyear r_sex worker
* merge with household level data
merge m:1 houseid using "./data/nhts/1995/1995 restricted/HHPER1995.DTA"
keep 	r_age numadlt workstat wrktrans personid whomain_age whomain intrvday intrvmon ///
		intrvyr numadlt drvrcnt hh_race hbhur msasize hhcmsa hhcounty hhstfips htppopdn ///
		wtperfin wthhfin _merge vehid houseid hhfaminc lif_cyc hhsize ref_age wrkcount ///
		hhvehcnt hhmsa hhstate hhstfips urban census_d census_r msasize hh_ptused ///
		hh_usepubtr annmiles make model vehmiles makecode modlcode vehyear vehtype r_sex worker
rename 	*, lower
rename 	hhcounty hhcnty
rename 	make makename
rename 	model modlname
gen 	usepubtr = .
destring wrktrans, replace
replace usepubtr = 0 if wrktrans <= 8
replace usepubtr = 1 if wrktrans >= 9 & wrktrans <= 20
gen 	expfllpr = wtperfin
gen 	nhtsyear = 1995
tostring(houseid), replace
tostring(vehid), replace
tostring(hhstfips), replace
tostring(usepubtr), replace
tostring vehyear, replace
append 	using "./output/NHTScombined.dta"
save 	"./output/NHTScombined.dta", replace

* import 1990 NHTS

* merge datasets
use 	"./data/nhts/1990/1990 restricted/VEHICLE.DTA", clear
gen 	whomain_dup = whomain
rename 	whomain personid
destring personid, replace
merge n:1 houseid personid using "./data/nhts/1990/1990 restricted/PERSON.DTA"
* drop if vehicles cannot be merged to the drivers, but still people who are not main drivers (and code their annmiles == 0)
drop if _merge == 1
replace annmiles = 0 if _merge == 2
* whomain_age = the age of main driver
gen 	whomain_age = r_age
drop 	_merge
destring personid, replace
rename 	whomain_dup whomain
keep 	poppersq r_age personid intrvday intrvmon intrvyr wrktrans whomain_age houseid ///
		vehid msasize hhmsa cmsa veh12mnt vehtype whomain hh_hisp hh_race hhsize ///
		census_r census_d maindrvr travday wthhfin vehmiles annmiles hhfaminc make ///
		milelimt makecode modlcode vehyear vehmake r_sex worker
* merge with household level data
merge m:1 houseid using "./data/nhts/1990/1990 restricted/HHPER1990.DTA"
keep 	poppersq r_age numadlt wrktrans personid whomain_age whomain intrvday intrvmon ///
		intrvyr numadlt drvrcnt hh_race urban msasize cmsa hhstfips wtperfin wthhfin _merge ///
		vehid houseid hhfaminc lif_cyc hhsize ref_age hhvehcnt hhmsa hhstate hhstfips urban ///
		census_d census_r msasize hh_usepubtr annmiles vehmake vehmiles makecode modlcode vehyear vehtype r_sex worker
rename 	*, lower
rename 	vehmake makename
rename 	poppersq htppopdn
gen 	usepubtr = .
destring wrktrans, replace
replace usepubtr = 0 if wrktrans <= 8
replace usepubtr = 1 if wrktrans >= 9 & wrktrans <= 20
gen 	expfllpr = wtperfin
gen 	nhtsyear = 1990
tostring(houseid), replace
tostring(vehid), replace
tostring(hhstfips), replace
tostring(usepubtr), replace
tostring(census_d), replace
tostring(census_r), replace
tostring(msasize), replace
tostring(makename), replace
tostring(hhfaminc), replace
tostring(hh_race), replace
tostring(hhmsa), replace
tostring(whomain), replace
tostring(lif_cyc), replace
tostring(urban), replace
tostring r_sex, replace
tostring makecode modlcode, replace
tostring vehyear, replace 
tostring vehtype, replace
tostring worker, replace
append 	using "./output/NHTScombined.dta"

compress

* generate and clean variables

replace whomain_age = . if whomain_age < 0
replace whomain_age = . if whomain_age > 125

replace annmiles = . if annmiles < 0
replace annmiles = . if annmiles == 888888
replace annmiles = . if annmiles == 999998
replace annmiles = . if annmiles == 999936
replace annmiles = . if annmiles == 999999
*replace annmiles = . if annmiles == 200000 /* CSQ: Should this be missing? */
replace annmiles = 0 if hhvehcnt == 0
egen 	miles_per_psn_MI = sum(missing(annmiles)), by(houseid personid nhtsyear)
egen 	miles_per_psn = sum(annmiles) if miles_per_psn_MI==0, by(houseid personid nhtsyear) 
egen 	miles_per_psn_ALL = sum(annmiles), by(houseid personid nhtsyear)
lab var miles_per_psn 		"Miles per person across all vehicle, =missing if annmiles missing for any vehicles with this primary driver"
lab var miles_per_psn_ALL 	"Miles per person across all vehicle, if vehicle with this primary driving has missing annmiles, annmiles for that vehilce==0"

destring usepubtr, replace
replace usepubtr = . if usepubtr < 0
replace usepubtr = 0 if usepubtr == 2

gen 	employed = 0
replace employed = 1 if worker=="1"
replace employed = 1 if worker=="01"
replace employed = . if worker=="."
replace employed = . if worker=="-9"

rename 	hhfaminc hhincome /* Different codes in different years, difficult to compare */
rename 	hhsize famsize
rename 	htppopdn htppopdn_cont
rename 	hhstate statename
destring hhincome hh_race urbrur urban msasize, replace /* two cases of urbrur<0 same with urban (and 710==98) */
														/* msasize weird, diff codes across years */
replace hhincome = . if hhincome < 0 | hhincome == 98 | hhincome == 99 
replace hh_race = . if hh_race < 0

destring vehyear, replace
replace vehyear = . if vehyear<=0
replace vehyear = . if vehyear==994
replace vehyear = . if vehyear==998
replace vehyear = . if vehyear==999
replace vehyear = . if vehyear==9998
replace vehyear = vehyear+1900 if vehyear>10 & vehyear<=91

destring makecode, replace i("X")
replace makecode = . if makecode<=0
replace makecode = . if makecode>99
replace makecode = . if makecode==99

gen 	modlcode17=modlcode if nhtsyear==2017

destring modlcode, replace i("X")
replace modlcode = . if modlcode<0
replace modlcode = . if modlcode==9999
replace modlcode = . if modlcode==99998
replace modlcode = . if modlcode==99999

replace modlcode = modlcode - (floor(modlcode/1000)*1000) if nhtsyear==2017
replace modlcode = . if modlcode>=999

* generate timing variables

* NHTS 1990

sort 	intrvyr intrvmon
egen 	index = group(intrvyr intrvmon)
gen 	yr_16_new = .
forval i = 1/13 {
	replace yr_16_new = floor(1990 + (`i'-4)/12 + 16 - whomain_age) if index == `i' & nhtsyear == 1990
}
drop 	index

* NHTS 1995

sort 	intrvyr intrvmon
egen 	index = group(intrvyr intrvmon)
forval i = 14/28 {
	replace yr_16_new = floor(1995 + (`i'-15)/12 + 16 - whomain_age) if index == `i' & nhtsyear == 1995
}
drop 	index

* NHTS 2001

sort 	hhintdt
egen 	index = group(hhintdt)
forval i = 1/16 {
	replace yr_16_new = floor(2001 + (`i'-4)/12 + 16 - whomain_age) if index == `i' & nhtsyear == 2001
}
drop 	index

* NHTS 2009

sort 	perindt2
gen 	perinyrmon = substr(perindt2,1,6)
egen 	index = group(perinyrmon)
forval i = 1/15 {
	replace yr_16_new = floor(2008 + (`i'-4)/12 + 16 - whomain_age) if index == `i' & nhtsyear == 2009
}
drop 	index

* NHTS 2017

sort 	tdaydate
egen 	index = group(tdaydate)
forval i = 1/13 {
	replace yr_16_new = floor(2016 + (`i'-3)/12 + 16 - whomain_age) if index == `i' & nhtsyear == 2017
}
drop 	index

compress

save 	"./output/NHTScombined_veh.dta", replace

duplicates report nhtsyear houseid personid
sort	nhtsyear houseid personid vehid
duplicates drop nhtsyear houseid personid, force

drop fueltype hfuel hybrid vehage bestmile gsyrgal gscost gstotcst epatmpg ///
	eiadmpg vehidlen modlcode17 annmiles vehmiles makecode modlcode vehid vehyear

sum  	miles_per_psn, d	
sum  	miles_per_psn_ALL if miles_per_psn_MI==0, d
sum 	miles_per_psn_ALL if miles_per_psn_MI!=0, d
sum  	miles_per_psn_ALL, d
	
tab 	employed nhtsyear
	
save 	"./output/NHTScombined_per.dta", replace


