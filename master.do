/******* master.do ***************************
Runs all analysis. Calls two separate files, which can be run separately if so
	desired (all relevant data files in build files are saved to memory for use
	in the analysis files)
		+ $dof/build/run_build_directory.do builds all data
		+ $dof/analysis/run_analysis_directory.do performs most of the analysis 
		  in the paper, except for the cumulative exposure function results, 
		  which are much more computationally intensive.
		+ CEF stuff

To replicate our analysis:
	0) Ensure the following packages are installed locally
	1) Ensure that files structure XXX and CEF
	2) Set the two global macros in the box below
	3) Execute the code below
											*/
***********************************************

clear
set more off

*============== User Edit Here ================*
global 	dof 	"C:/GitHub/FormativeExperiences" 
global 	data	"C:\Dropbox\Dropbox\Data_Projects\FormativeExperiences_Data"
*==============================================*

** Set data location to current directory **
cd 		"$data"

** Execute script to construct data **
do		"$dof/build/run_build_directory.do"

** Execute script perform analysis in the paper **
do		"$dof/analysis/run_analysis_directory.do"

** CEF STUFF **

