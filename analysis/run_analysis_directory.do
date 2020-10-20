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

**HERE**

/* Run panel analysis on census data */
do		"$dof/analysis/code/censusAll_analysis.do" 				"$dof/log/censusAll_main.log"
do		"$dof/analysis/code/censusAll_analysis_agecompare.do" 	"$dof/log/censusAll_age.log"
do		"$dof/analysis/code/censusAll_dl_analysis.do" 			"$dof/log/censusAll_dl.log"

/* Run panel analysis on NHTS data */
do		"$dof/analysis/code/nhts_analysis.do" 				"$dof/log/nhts_main.log"
do		"$dof/analysis/code/nhts_analysis_agecompare.do" 	"$dof/log/nhts_age.log"
do		"$dof/analysis/code/nhts_dl_analysis.do" 			"$dof/log/nhts_dl.log"
do		"$dof/analysis/code/nhts_analysis_gpm.do" 			"$dof/log/nhts_gpm.log"

/* Driver skill acquisition analysis */
do		"$dof/analysis/code/dl_summary.do"
do		"$dof/analysis/code/fhwa_avecohortdriving.do"

/* Cumulative Exposure Function Execution */


/* Cumulative Exposure Function Comparison */
do		"$dof/analysis/code/censusAll_analysis_agecompare_event.do" "$dof/log/censusAll_event.log"
do		"$dof/analysis/code/nhts_analysis_agecompare_event.do" 		"$dof/log/nhts_event.log"
do		"$dof/analysis/code/mn_graph.do"





/* Clean up */
