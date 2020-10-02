/**** /build/run_build_directory.do ***********
Create intermediate datasets from scratch. Files should generally be executed in 
the order in which they are listed below. The file clean_up.do is not necessary
for to generate results, but deletes intermediate data sets that are not used in
the analysis files, hopefully saving space.  */
***********************************************

/* Build Census Data */
do		"$dof/build/code/make_census8090.do" 	"./output/census8090_basefile.dta"
do		"$dof/build/code/make_census2000.do" 	"./output/census2000_basefile.dta"
do		"$dof/build/code/make_acs06-15.do" 		"./output/acs06-15_basefile.dta"
do		"$dof/build/code/make_acs16-17.do" 		"./output/acs16-17_basefile.dta"

do		"$dof/build/code/combine_allcensus.do"
do		"$dof/build/code/prep_allcensus.do"

/* Build NHTS Data */
do		"$dof/build/code/import_NHTS1990.do" 
do		"$dof/build/code/import_NHTS1995.do" 
do		"$dof/build/code/import_NHTS2001.do" 
do		"$dof/build/code/import_NHTS2009.do" 
do		"$dof/build/code/import_NHTS2017.do" 

do		"$dof/build/code/combine_nhts.do" 
do		"$dof/build/code/combine_gpm.do"

/* Prep gas price data */
do		"$dof/build/code/prep_gasprice.do" 

/* Prep driver license data */
do		"$dof/build/code/prep_drive_license_data.do" 

/* Prep unemployment data */
do		"$dof/build/code/prep_unemp_data.do" 

/* Clean up files */
do		"$dof/build/code/clean_up.do" 
