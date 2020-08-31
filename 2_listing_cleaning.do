*---------------------------------------------
* Clean the listing data and export prefills
*---------------------------------------------

/* Notes:

Input files: 
	- listing_v1_WIDE.dta, created by running the auto-generated SurveyCTO
      cleaning template file (1_listing_import) on the raw .csv data

Output files: 
	- Clean Listing dataset (listing_clean.dta)
	- Prefill for mosquito net distribution in E block 
	- Prefill for mosquito net distribution in the rest of the blocks (full prefill)


*/

* Import
***************************************************
use "$listingprocess/listing_v1.dta", clear

* Cleaning
*****************************************************

* Drop unnecessary variables
drop deviceid-username
drop caseid hh_roster_count mem_id* formdef_vers*

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

* Flag duplicate phone numbers, duplicate Aadhaar or duplicate ration cards

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
	
	drop age_years_dob_`i' age_years_`i'
	
}


* Convert bahu to patni on 10th july (patni option wasn't available on this day)

* Flag and convert cases where respondent name = member name but resp relationship is -87 or something else

* Cases where ration card number/Aadhaar/mobile looks weird

* Logical checks to clean

** There are two cases in the same HH where respondent relationship is '1'

* One case with 8 hh members and age = 0 for a lot (check for age = 0 as a flag)

* Merge split households into one

save "$listingprocess/listing_clean", replace

* Mosqutio Net Distribution prefills
******************************************************

*For E block distribution (adivasi community)

export delimited hhid resp_name resp_father_husband_name phone_num ///
             hh_size name_1 aadhaar_num_1 ration_card_num_1 ///
			 name_2 aadhaar_num_2 ration_card_num_2 ///
			 if block == "E" using "$netsprefill/Eblock_prefill.csv", replace


* For rest of the blocks

drop if block == "E" 
keep if has_mosquito_net == 0

keep hhid key under_5 *_num* *name_* resp_name


//Changing missing values of ration card/ Aadhaar to NA
forvalues i=1/10 {
replace aadhaar_num_`i' = "NA" if missing(aadhaar_num_`i')
replace ration_card_num_`i' = "NA" if missing(ration_card_num_`i')
}


//Generating a variable with all family member names
gen all_names = name_1
forvalues i=2/10 {
replace all_names = all_names + ", " + name_`i' if !missing(name_`i')
}

forvalues i = 1/10{
	drop name_`i'
}


//Saving variables that don't have to be reshaped
preserve 
keep hhid key under_5 resp_name phone_num all_names
tempfile static
save `static', replace
restore


//Reshaping Aadhaar numbers to long
preserve
keep hhid key all_names aadhaar_num_*
reshape long aadhaar_num_, i(hhid key) j(j)
drop if aadhaar_num_ == "NA"
gen all_aadhaar = aadhaar_num_
forvalues i=1/10 {
replace all_aadhaar = all_aadhaar + ", " + aadhaar_num_[_n-`i'] if hhid[_n-`i'] == hhid[_n]
replace all_aadhaar = all_aadhaar + ", " + aadhaar_num_[_n+`i'] if hhid[_n+`i'] == hhid[_n]
}
rename aadhaar_num_ aadhaar_num_1
keep hhid key all_names all_aadhaar aadhaar_num_1
tempfile aadhaar
save `aadhaar', replace
restore


//Reshaping ration card numbers to long
preserve
keep hhid key all_names ration_card_num_*
reshape long ration_card_num_, i(hhid key) j(j)
drop if ration_card_num_ == "NA"
duplicates drop hhid ration_card_num_, force
gen all_ration = ration_card_num_
forvalues i=1/10 {
replace all_ration = all_ration + ", " + ration_card_num_[_n-`i'] if hhid[_n-`i'] == hhid[_n]
replace all_ration = all_ration + ", " + ration_card_num_[_n+`i'] if hhid[_n+`i'] == hhid[_n]
}
duplicates drop hhid, force
rename ration_card_num_ rationcard_num_1
keep hhid key all_names rationcard_num_1
tempfile ration
save `ration', replace
restore


//Merging the three tempfiles
use `static', clear
merge 1:m key using `aadhaar', keep(match) nogenerate
merge m:m key using `ration', keep(match) nogenerate


//Removing duplicate ration card numbers for uniqueness in prefill
bys hhid: gen srno = _n
replace rationcard_num_1 = "" if srno > 1
drop srno


//Making pretty and outsheeting
order hhid phone_num resp_name aadhaar_num_1 rationcard_num_1 under_5 all_names all_aadhaar key
sort hhid aadhaar_num_1
duplicates drop _all, force
export delimited "$netsprefill/full_prefill.csv", replace







				 
				 
				 
				 