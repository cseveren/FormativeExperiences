
use 	"./output/censusall.dta", clear

********************************
** Sample Restrictions

keep if bpl<100
drop if farm==2

drop if age<=24
drop if age>54

********************************
** Variable Creation - VV means verified codes compatible

* Transit
tab 	tranwork year

replace tranwork = 10 if tranwork==11 | tranwork==14 | tranwork==15
replace tranwork = 30 if tranwork==31 | tranwork==32

gen 	t_drive = 0 if tranwork!=0
replace t_drive = 1 if tranwork==10

gen 	t_transit = 0 if tranwork!=0
replace t_transit = 1 if tranwork==30 | tranwork==33 | tranwork==34 | tranwork==36

gen 	t_walk = 0 if tranwork!=0
replace t_walk = 1 if tranwork==50

gen 	t_workathome = 0 if tranwork!=0
replace t_workathome = 1 if tranwork==70

gen 	t_time = trantime if tranwork!=0
replace t_time = 99 if t_time>99 & t_time!=.
replace t_time = . if t_time==0 /* Not correct for 1980! */

gen 	t_timedr = t_time if tranwork==10

gen 	t_novehicle = 0 if vehicles!=0
replace t_novehicle = 1 if vehicles==9
replace t_novehicle = 1 if autos==1 & trucks==1

gen 	t_vehicle = 1 - t_novehicle
drop	t_novehicle

bys year: sum t_drive [aw=perwt]
bys year: sum t_transit [aw=perwt]
bys year: sum t_walk [aw=perwt]
bys year: sum t_workathome [aw=perwt]
bys year: sum t_time [aw=perwt]
bys year: sum t_vehicle [aw=perwt]


* Employment and labor force participation
gen 	e_emp = 0
replace e_emp = 1 if empstat==1

gen 	e_lfp = 0
replace e_lfp = 1 if empstat==1 | empstat==2

* to Jan '15
gen		w_hhi = hhincome if hhincome!=9999999
gen		w_incw = incwage if incwage<999998
gen		w_pinc = inctot if incwage<9999998

foreach var of varlist w_hhi w_incw w_pinc {
	replace `var' = 3*`var' if year==1980
	replace `var' = 1.83*`var' if year==1990
	replace `var' = 1.38*`var' if year==2000
	replace `var' = 1.11*`var' if year==2010
	replace `var' = 1.01*`var' if year==2015
	replace `var' = 0.99*`var' if year==2016
	replace `var' = 0.96*`var' if year==2017
}

replace w_hhi = 225000 if w_hhi>225000 & w_hhi!=. /* Dealing with top coding */

bys year: sum e_emp [aw=perwt]
bys year: sum e_lfp [aw=perwt]
bys year: sum w_hhi [aw=perwt]

* Demographics
gen		d_fem = 0
replace	d_fem = 1 if sex==2

gen		d_marr = 0
replace d_marr = 1 if marst==0 | marst==1

gen 	d_hs  = 0
replace d_hs  = 1 if educd>=62 & educd!=.

gen 	d_col = 0 
replace d_col = 1 if educd>=100 & educd!=.

gen 	d_black = 0 
replace d_black = 1 if race==2 & race!=.

gen 	d_hisp = 0 
replace d_hisp = 1 if hispan!=0 & hispan!=.

bys year: sum d_fem [aw=perwt]
bys year: sum d_marr [aw=perwt]
bys year: sum d_hs [aw=perwt]
bys year: sum d_col [aw=perwt]
bys year: sum d_black [aw=perwt]
bys year: sum d_hisp [aw=perwt]

* Mobility
gen		m_samestate = 0
replace m_samestate = 1 if statefip==bpl

bys year: sum m_samestate [aw=perwt]

********************************
drop 	rent rentgrs marst race hispan hispand bpld ///
		 educd empstat labforce wkswork1 uhrswork looking workedyr inctot ftotinc incwage

compress

save 	"./output/censusall_prepped", replace
erase 	"./output/censusall.dta"
