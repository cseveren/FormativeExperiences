/* GDL and stuff */
local demc white urban_bin famsize

eststo dla_1:	reghdfe lvmt_pc min_age_full age age2 	[aw=expfllpr], a(stateid nhtsyear) cluster(stateid)
eststo dla_2:	reghdfe lvmt_pc min_age_full			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dla_3:	reghdfe lvmt_pc min_age_full `demc' 	[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dla_4:	reghdfe lvmt_pc min_age_full `demc' 	[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo dla_5:	reghdfe lvmt_pc min_age_full `demc' 	[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo dlb_1:	reghdfe lvmt_pc i.age_f_grps age age2 	[aw=expfllpr], a(stateid nhtsyear) cluster(stateid)
eststo dlb_2:	reghdfe lvmt_pc i.age_f_grps			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dlb_3:	reghdfe lvmt_pc i.age_f_grps `demc' 		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dlb_4:	reghdfe lvmt_pc i.age_f_grps `demc' 		[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo dlb_5:	reghdfe lvmt_pc i.age_f_grps `demc' 		[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo dlc_1:	reghdfe lvmt_pc min_int_age age age2 	[aw=expfllpr], a(stateid nhtsyear) cluster(stateid)
eststo dlc_2:	reghdfe lvmt_pc min_int_age				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dlc_3:	reghdfe lvmt_pc min_int_age `demc' 		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dlc_4:	reghdfe lvmt_pc min_int_age `demc' 		[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo dlc_5:	reghdfe lvmt_pc min_int_age `demc' 		[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo dld_1:	reghdfe lvmt_pc i.age_i_grps age age2 	[aw=expfllpr], a(stateid nhtsyear) cluster(stateid)
eststo dld_2:	reghdfe lvmt_pc i.age_i_grps			[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dld_3:	reghdfe lvmt_pc i.age_i_grps `demc' 		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dld_4:	reghdfe lvmt_pc i.age_i_grps `demc' 		[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo dld_5:	reghdfe lvmt_pc i.age_i_grps `demc' 		[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

eststo dle_1:	reghdfe lvmt_pc min_age_full min_int_age age age2 	[aw=expfllpr], a(stateid nhtsyear) cluster(stateid)
eststo dle_2:	reghdfe lvmt_pc min_age_full min_int_age				[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dle_3:	reghdfe lvmt_pc min_age_full min_int_age `demc' 		[aw=expfllpr], a(stateid nhtsyear age) cluster(stateid)
eststo dle_4:	reghdfe lvmt_pc min_age_full min_int_age `demc' 		[aw=expfllpr], a(stateid nhtsyear age hhi_bin_yr) cluster(stateid)
eststo dle_5:	reghdfe lvmt_pc min_age_full min_int_age `demc' 		[aw=expfllpr], a(stsamyr_fe age hhi_bin_yr) cluster(stateid)

local 	tabprefs cells(b(star fmt(%9.4f)) se(par)) stats(r2_a N, fmt(%9.4f %9.0g) labels(R-squared)) legend label starlevels(+ 0.10 * 0.05 ** 0.01 *** 0.001) 

esttab 	dla_* using "./results/nhts_dl/fullage_cont.tex", booktabs replace `tabprefs' 
esttab 	dlb_* using "./results/nhts_dl/fullage_int.tex", booktabs replace `tabprefs' 
esttab 	dlc_* using "./results/nhts_dl/intage_cont.tex", booktabs replace `tabprefs' 
esttab 	dld_* using "./results/nhts_dl/intage_int.tex", booktabs replace `tabprefs' 
esttab 	dle_* using "./results/nhts_dl/both_int.tex", booktabs replace `tabprefs' 

eststo clear
