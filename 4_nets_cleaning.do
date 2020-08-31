*---------------------------------------------
* Cleaning the mosquito net distribution data
*---------------------------------------------

/* Notes:

Input files: 
	- sohaib_test_v4.dta, created by running the auto-generated SurveyCTO
      cleaning template file (3_nets_import) on the raw .csv data
	- eblock_distribution.xlsx - direct Google Sheet entered for E block distribution

Output files: 

- dups.xlsx, a list of duplicates found in the distribution to be clarified with Vikram


*/	
 


use "$netsprocess/sohaib_test_v4", clear

************************************
* General cleaning/processing
*************************************

*Creating date of distribution variable
gen date = dofc(endtime)
format date %td

*Dropping dummy forms Mihir filled when testing (before the earliest date of distribution)
drop if date < d(24aug2020)

*Dropping unnecessary variables
drop *deets*

*Converting vars to string to prevent type mismatches in loops
foreach var of varlist confirm_* notmatch_* stillgive_*{
	tostring `var', replace force
	replace `var' = "" if `var' == "."
}

*Getting the total number of repeat groups in the data (for loops)
	local totrepeat=0
		forvalues i=1/50{
			cap conf v name_one_`i'
			if !_rc{
				local ++totrepeat
			}
		}
		


*Consolidating data stored in multiple columns into one

rename key mosquitokey

		
// Getting the variable names that need to be consolidated
	unab vars : *_one_1
	local stubs : subinstr local vars "_one_1" "", all
	local not id
	local stubs: list stubs - not
	
local count one two three

forvalues i = 1/`totrepeat'{

	foreach var in `stubs'{
		
		gen `var'_`i' = ""
		
		foreach rep in `count'{
			
			cap replace `var'_`i' = `var'_`rep'_`i' if `var'_`rep'_`i' != ""
			
			cap drop `var'_`rep'_`i'
			
		}
		
	}
 
}

* Checking if match not found but vikram still confirmed
// There are 3 cases like this, where the match produced no details, but Vikram still confirmed the match so the respondent name and block weren't entered
gen falseconfirm = 0
forvalues i = 1/`totrepeat'{
	replace falseconfirm = 1 if (name_`i' == "" & confirm_`i' == "1")
}


* Reshape data // Needed because on the first day, 25th August, Vikram entered multiple households' distribution details in the same form (through multiple repeat groups)
* So in this case, only reshapinng gives us a unique dataset at the household level
* On all subsequent days, Vikram used one form per household. Further, he only used one repeat group (no multiple verifications in the same form), so reshaping gives us 
* a household level dataset for distribution

tempfile full
save `full', replace

*Selecting variables to reshape 
unab vars : *_1
local stubs : subinstr local vars "1" "", all

reshape long `stubs', i(mosquitokey)

* Dropping missing values
drop if id_one == .
drop if stillgive == "0"


*****************************************************
* Flagging and exporting duplicates, error resolution 
******************************************************

// Two different households that gave the same phone number; correcting the hhid to the correct one
replace hhid = "B197" if phone_ == "9990985337" & name_ == "Rajan mehto"
replace hhid = "A339" if phone_ == "9354458894" & name_ == "Ramveer"

// Double-entries where in fact one net was given

// HHID B046 (Laung Shri) entered twice, and data identical, so dropping one
drop if mosquitokey == "uuid:a3b77610-d9f2-44f9-9e21-4abb7a36af92"

// HHID A238, same case as above
drop if mosquitokey == "uuid:4ddcff7a-8aaf-4d81-924e-4fbfda4bf62d"

// HHID A159, same as above
drop if mosquitokey == "uuid:9cce421d-3dfe-4a91-8815-c97b041ab692"


*Checking for duplicates; for matched hhs, this comes from hhid
duplicates tag hhid, gen(dup)
replace dup = 0 if missing(hhid)

// for unmatched households, checking for duplicates in resp_name and resp_block, phone number, aadhaar, or ration
gen respnameblock = resp_name + resp_block
foreach var of varlist respnameblock phone_ aadhaar_ rationcard_{
	duplicates tag `var', gen(dup1)
	replace dup1 = 0 if missing(`var')
	replace dup = dup1 if dup1 > 0 
	drop dup1
}


// Consolidate respondent name and name fields
replace name_ = resp_name if resp_name != ""
drop resp_name


// Two different people named Maya devi from the same block
replace dup = 0 if name_ == "Maya devi" & date == d(25aug2020)
replace dup = 0 if name_ == "Maya devi" & date == d(28aug2020)

// Two different families giving same phone number
replace dup = 0 if name_ == "Bhupendra" & date == d(25aug2020)
replace dup = 0 if name_ == "Krishan Kumar" & date == d(25aug2020)



// Creating block for matched households
replace resp_block = substr(hhid,1,1) if hhid != ""

// Exporting dups
gsort -hhid name_ phone_ aadhaar_ rationcard_

export excel date hhid resp_block name_ phone_ aadhaar_ rationcard_ ///
			 if dup > 0 using "$netsprocess/dups.xlsx", firstrow(var) replace


// Exporting full data
export excel date hhid resp_block name_ phone_ aadhaar_ rationcard_ ///
			 using "$netsprocess/full_list.xlsx", firstrow(var) replace
			 			 
**************************************************
* Appending on one-off E Block distribution data
***************************************************

preserve
import excel "$netsraw/eblock_distribution.xlsx", firstrow allstring clear
destring net_yn_, replace

gen id_one_ = 2 if aadhaar_ != ""
replace id_one_ = 1 if id_one_ == . & phone_ != ""
gen resp_block_ = "E"

tempfile eblock
save `eblock', replace
restore

append using `eblock'
replace date = d(31jul2020) if missing(date)

			 
*************************************************************
* Saving clean mosquito net data for merge with listing data
*************************************************************

drop _j deviceid-username caseid duration
rename (id_one_ net_yn_ date hhid_) (net_verification_id net_received net_dist_date hhid)

drop if net_received == 0

// Saving one dataset of the matched households for easy merge
preserve
keep if hhid != ""
keep hhid net_verification_id net_received net_dist_date
save "$netsprocess/matched_nets_clean", replace
restore

// Saving one dataset of the new households, with consistent variable names so we preserve
// the info on phone/aadhaar/name captured
preserve
keep if hhid == ""
** Renaming to make vars consistent with listing clean data
rename (phone_ aadhaar_ rationcard_ resp_block_ name_) (phone_num aadhaar_num_1 ration_card_num_1 block resp_name)
keep phone_num aadhaar_num_1 ration_card_num_1 block resp_name net_verification_id net_received net_dist_date
save "$netsprocess/unmatched_nets_clean", replace
restore



