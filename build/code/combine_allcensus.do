use 	"./output/census2000_basefile.dta", clear
drop 	occ ind citizen countyfips citypop pumaarea gq taxincl insincl datanum

append 	using "./output/census8090_basefile.dta"
drop 	occ ind citizen countyfips citypop gq taxincl insincl datanum
erase 	"./output/census8090_basefile.dta"

append 	using "./output/acs06-15_basefile.dta"
drop 	occ ind citizen gq datanum ancestr1 ancestr1d birthqtr
drop	serial metarea metaread mortgage raced school
erase 	"./output/acs06-15_basefile.dta"

append 	using "./output/acs16-17_basefile.dta"
drop 	occ ind citizen gq datanum ancestr1 ancestr1d birthqtr
drop	serial cbserial raced
erase 	"./output/acs16-17_basefile.dta"

drop 	yrimmig yrsusa1 empstatd migrate5 migrate5d migplac5 movedin disabwrk valueh mortamt1 ownershpd

compress
save 	"./output/censusall.dta", replace
