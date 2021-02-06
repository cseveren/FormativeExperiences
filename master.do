/******* master.do ***************************
Runs all analysis. Calls two separate files, which can be run separately if so
	desired (all relevant data files in build files are saved to memory for use
	in the analysis files)
		+ $dof/build/run_build_directory.do builds all data
		+ $dof/analysis/run_analysis_directory.do performs most of the analysis 
		  in the paper, except for the cumulative exposure function results, 
		  which are much more computationally intensive.
		+ If you're only goal is to replicate results using our (provided) 
		  intermediate data, you only need the $dof/analysis/ code.
		+ The CEF analysis is computationally more intensive, see README.

To replicate our analysis:
	0) Ensure the following packages are installed locally: (config_stata.do does this automatically)
		+ carryforward blindschemes estout reghdfe ftools texdoc
	1) Ensure that files are structured as provided. If you obtained the project code 
			from github rather than from openICPSR, put those files ubder /codelog/
	2) Set the two global macros in the box below (replace XXXXX as appropriate)
		+ $data should point to top level folder, 
		    i.e.: /FormativeExperiences_Replication/
		+ $dof should point to codelog one level below, 
		    i.e.: /FormativeExperiences_Replication/codelog/
	3) Execute the code below
											*/
***********************************************

clear
set more off

*============== User Edit Here ================*
global 	data	"XXXXX/FormativeExperiences_Replication"
global 	dof 	"XXXXX/FormativeExperiences_Replication/codelog" 
*==============================================*

** Set data location to current directory **
cd 		"$data"
do 		"$dof/config_stata.do"

** Execute script to construct data **
do		"$dof/build/run_build_directory.do"

** Execute script perform analysis in the paper **
do		"$dof/analysis/run_analysis_directory.do"
