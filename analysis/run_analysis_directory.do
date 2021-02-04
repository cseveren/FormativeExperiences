/**** /build/run_analysis_directory.do ***********
Perform analysis shown in paper and appendices.
This file assumes that <master.do> and <run_build_directory.do> have both been
executed so that the appropriate processed data files are located in the correct
locations  */
***********************************************

/* Make graphs of gas price and changes */
do 		"$dof/analysis/code/gas_graphs.do"
do 		"$dof/analysis/code/gas_cpi.do"

/* Run RD-in-time/event study analysis */
do		"$dof/analysis/code/census2000_analysis.do" 	"$dof/log/census2000.log"

/* Run panel analysis on census data */
do		"$dof/analysis/code/censusAll_analysis.do" 				"$dof/log/censusAll_main.log"
do		"$dof/analysis/code/censusAll_analysis_agecompare.do" 	"$dof/log/censusAll_age.log"
do		"$dof/analysis/code/censusAll_analysis_agecompare_event.do" "$dof/log/censusAll_age_event.log"
do		"$dof/analysis/code/censusAll_dl_analysis.do" 			"$dof/log/censusAll_dl.log"

/* Run panel analysis on NHTS data */
do		"$dof/analysis/code/nhts_analysis.do" 				"$dof/log/nhts_main.log"
do		"$dof/analysis/code/nhts_analysis_agecompare.do" 	"$dof/log/nhts_age.log"
do		"$dof/analysis/code/nhts_analysis_agecompare_event.do" "$dof/log/nhts_age_event.log"
do		"$dof/analysis/code/nhts_dl_analysis.do" 			"$dof/log/nhts_dl.log"
do		"$dof/analysis/code/nhts_analysis_gpm.do" 			"$dof/log/nhts_gpm.log"

/* Driver skill acquisition analysis */
do		"$dof/analysis/code/dl_summary.do"
do		"$dof/analysis/code/fhwa_avecohortdriving.do"

/* Cumulative Exposure Function */
** CAUTION: census_mnfunction_change.do should not be run without taking a subsample on a desktop -- it requires
**  too much memory. Uncomment line 21 in census_mnfunction_change.do to take a 20% sample to verify code works
**  or too explore if on a desktop. Otherwise, if on larger memory machine, leave line 21 commented to reproduce
**  the results in the paper.

do		"$dof/analysis/code/cef/census_mnfunction_change.do" 	"$dof/log/cef_census.log"
do		"$dof/analysis/code/cef/nhts_mnfunction_change.do" 		"$dof/log/cef_nhts.log"

** Note, you must hand type the results from the above two files into the below to produce the graph output
do		"$dof/analysis/code/cef/mn_graph.do"