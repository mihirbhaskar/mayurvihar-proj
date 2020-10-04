/* Master do-file

Purpose: 
	- Set globals, other settings centrally to apply to all other do-files
	- Run all do-files in sequence, aiding replicability 
	
*/



clear
set more off
set mem 100m

*Mihir
	if "`c(username)'" == "Mihir_Bhaskar"{
		gl userdb "D:/Dropbox" // location of the user's Dropbox
		gl usergit "C:/Users/Mihir_Bhaskar/Documents/mayurvihar-proj" // location of the user's GitHub clone
	}

*Sohaib
	if "`c(username)'" == "Sohaib Nasim"{
		gl userdb "C:/Users/" // location of the user's Dropbox
	}


gl root "$userdb/Mayur Vihar Project"

// Listing

gl listingraw "$root/Listing Survey/Data/Raw"
gl listingprocess "$root/Listing Survey/Data/Processed"
 
// Mosqutio Nets

gl netsprefill "$root/Mosquito Net Distribution/Beneficiary Prefills"
gl netsraw "$root/Mosquito Net Distribution/Data/Raw"
gl netsprocess "$root/Mosquito Net Distribution/Data/Processed"

local date: dis %td_DD_NN_CCYY date(c(current_date), "DMY")
gl date_string = subinstr(trim("`date'"), " " , "_", .)

*Run files

do "$usergit/1_listing_import.do" // auto-generated SurveyCTO template do-file to import and process listing data

do "$usergit/2_listing_cleaning.do" // further cleaning and processing. generating prefills

do "$usergit/3_nets_import.do" // 

do "$usergit/4_nets_cleaning.do"

do "$usergit/final_merge_clean.do"
