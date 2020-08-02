*---------------------------------------------
* Clean the listing data and export prefills
*---------------------------------------------

/* Notes:

Input files: 
	- listing_v1_WIDE.dta, created by running the auto-generated SurveyCTO
      cleaning template file (import_listing_v1) on the raw .csv data

Output files: 

*/

* Set-up and import
***************************************************

*Mihir
	if "`c(username)'" == "Mihir_Bhaskar"{
		gl userdb "D:/Dropbox" // location of the user's Dropbox
	}

*Sohaib
	if "`c(username)'" == "Sohaib Nasim"{
		gl userdb "C:/Users/" // location of the user's Dropbox
	}


gl root "$userdb/Mayur Vihar Project"
gl data "$root/Listing Survey/Data/Processed"

use "$data/listing_v1.dta", clear

* Cleaning
*****************************************************

* Create household unique ID
sort block key
by block: gen count = string(_n,"%03.0f")
gen hhid = block + count

* Clean out dummy surveys (check odd starttimes, etc.)
drop if submissiondate <= d(10july2020)
drop if surveyor_code == 2
drop if phone_num == "2222222222"


* Clean bad phone numbers (could consider checking if they have entered ration card instead)
forval i=0/5{
replace phone_num="" if substr(phone_num, 1, 1) == "`i'"
}  

* Collapse the two age variables for each member into one, generate
* flag for if household has kid < 5 years
foreach var of varlist age_years_dob*{
	destring `var', replace
}

gen under_5 = 0
la var under_5 "Whether household has child aged 5 or younger"

forvalues i=1/10{
	gen age_`i' = .
	replace age_`i' = age_years_dob_`i' if age_years_dob_`i' != .
	replace age_`i' = age_years_`i' if age_years_`i' != .
	
	replace under_5 = 1 if age_`i' <= 5 & age_`i' != .
}


* Convert bahu to patni on 10th july (patni option wasn't available on this day)

* Flag and convert cases where respondent name = member name but resp relationship is -87 or something else

* Logical checks to clean

** There are two cases in the same HH where respondent relationship is '1'

* One case with 8 hh members and age = 0 for a lot (check for age = 0 as a flag)

* Merge split households into one

* Mosqutio Net Distribution prefills
******************************************************

*For E block distribution (adivasi community)

export delimited hhid resp_name resp_father_husband_name phone_num ///
             hh_size name_1 aadhaar_num_1 ration_card_num_1 ///
			 name_2 aadhaar_num_2 ration_card_num_2 ///
			 if block == "E" using "$root/Mosquito Net Distribution/Beneficiary Prefills/Eblock_prefill.csv"


* For rest of the blocks
preserve
drop if block == "E" 
keep if has_mosquito_net == 0
export delimited hhid key block under_5 resp_name resp_father_husband_name phone_num hh_size ///
				 name_* aadhaar_num_* ration_card_num_* using "$root/Mosquito Net Distribution/Beneficiary Prefills/full_prefill.csv"
