** run_analysis_directory.do **

/* Run all analysis. Assumes <run_build_directory.do> has been executed and <cd>
is set to same value in <run_build_directory.do> and <run_analysis_directory.do>
	+ .do file locations. In a local github folder; set up as a macro, only 
			called from this do file
	+ data locations. In a dropbox folder; set cd here, data file calls are all 
			relative to cd, which is set here
*/

clear
set more off

*============== User Edit Here ================*
cd 		"C:/Dropbox/Dropbox/Data_Projects/Driving_Gas_Shocks/"
loc dof	"C:/GitHub/gas-price-shock"
*==============================================*

local 	D = c(current_date)

/* Miscellaneous analyses */
*do		"`dof'/analysis/code/dl_summary.do"
*do		"`dof'/analysis/code/fhwa_avecohortdriving.do"


/* Make graphs of gas price and changes */
*do 		"`dof'/analysis/code/gas_graphs.do"
*do 		"`dof'/analysis/code/gas_cpi.do"

/* Run RD-style analysis */
*do		"`dof'/analysis/code/census2000_analysis.do" "`dof'/log/census2000_`D'.log"

/* Run panel analysis on census data */
do		"`dof'/analysis/code/censusAll_analysis_agecompare.do" 	"`dof'/log/censusAll_age_`D'.log"
do		"`dof'/analysis/code/censusAll_analysis.do" 	"`dof'/log/censusAll_main_`D'.log"
do		"`dof'/analysis/code/censusAll_dl_analysis.do" 	"`dof'/log/censusAll_dl_`D'.log"

/* Run panel analysis on NHTS data */

*do		"`dof'/analysis/code/nhts_analysis.do" 			"`dof'/log/nhts_main_`D'.log"
*do		"`dof'/analysis/code/nhts_analysis_gpm.do" 		"`dof'/log/nhts_gpm_`D'.log"

** Event Study Comparisons
do		"`dof'/analysis/code/censusAll_analysis_agecompare_event.do" 	"`dof'/log/censusAll_age_`D'.log"
do		"`dof'/analysis/code/nhts_analysis_agecompare_event.do" 		"`dof'/log/nhts_age_`D'.log"
do		"`dof'/analysis/code/mn_graph.do"



/* Clean up */
