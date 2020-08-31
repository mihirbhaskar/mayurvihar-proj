* import_listing_v1.do
*
* 	Imports and aggregates "listing_v1" (ID: listing_v1) data.
*
*	Inputs:  "D:/Dropbox/Mayur Vihar Project/Listing Survey/Data/Raw/listing_v1_WIDE.csv"
*	Outputs: "D:/Dropbox/Mayur Vihar Project/Listing Survey/Data/Processed/listing_v1.dta"
*
*	Output by SurveyCTO August 2, 2020 8:02 AM.

* initialize Stata
clear all
set more off
set mem 100m

* initialize workflow-specific parameters
*	Set overwrite_old_data to 1 if you use the review and correction
*	workflow and allow un-approving of submissions. If you do this,
*	incoming data will overwrite old data, so you won't want to make
*	changes to data in your local .dta file (such changes can be
*	overwritten with each new import).
local overwrite_old_data 0

* initialize form-specific parameters
local csvfile "$listingraw/listing_v1_WIDE.csv"
local dtafile "$listingprocess/listing_v1.dta"
local corrfile "$listingraw/listing_v1_corrections.csv"
local note_fields1 ""
local text_fields1 "deviceid subscriberid simid devicephonenum username duration caseid block resp_name resp_father_husband_name phone_num alt_phone_num hh_roster_count mem_id_* name_* age_years_dob_* aadhaar_num_*"
local text_fields2 "ration_card_num_* voter_id_* edu_level_oth_* comments instanceid"
local date_fields1 "dob_*"
local datetime_fields1 "submissiondate starttime endtime"

disp
disp "Starting import of: `csvfile'"
disp

* import data from primary .csv file
insheet using "`csvfile'", names clear

* drop extra table-list columns
cap drop reserved_name_for_field_*
cap drop generated_table_list_lab*

* continue only if there's at least one row of data to import
if _N>0 {
	* drop note fields (since they don't contain any real data)
	forvalues i = 1/100 {
		if "`note_fields`i''" ~= "" {
			drop `note_fields`i''
		}
	}
	
	* format date and date/time fields
	forvalues i = 1/100 {
		if "`datetime_fields`i''" ~= "" {
			foreach dtvarlist in `datetime_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=clock(`tempdtvar',"MDYhms",2025)
						* automatically try without seconds, just in case
						cap replace `dtvar'=clock(`tempdtvar',"MDYhm",2025) if `dtvar'==. & `tempdtvar'~=""
						format %tc `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
		if "`date_fields`i''" ~= "" {
			foreach dtvarlist in `date_fields`i'' {
				cap unab dtvarlist : `dtvarlist'
				if _rc==0 {
					foreach dtvar in `dtvarlist' {
						tempvar tempdtvar
						rename `dtvar' `tempdtvar'
						gen double `dtvar'=.
						cap replace `dtvar'=date(`tempdtvar',"MDY",2025)
						format %td `dtvar'
						drop `tempdtvar'
					}
				}
			}
		}
	}

	* ensure that text fields are always imported as strings (with "" for missing values)
	* (note that we treat "calculate" fields as text; you can destring later if you wish)
	tempvar ismissingvar
	quietly: gen `ismissingvar'=.
	forvalues i = 1/100 {
		if "`text_fields`i''" ~= "" {
			foreach svarlist in `text_fields`i'' {
				cap unab svarlist : `svarlist'
				if _rc==0 {
					foreach stringvar in `svarlist' {
						quietly: replace `ismissingvar'=.
						quietly: cap replace `ismissingvar'=1 if `stringvar'==.
						cap tostring `stringvar', format(%100.0g) replace
						cap replace `stringvar'="" if `ismissingvar'==1
					}
				}
			}
		}
	}
	quietly: drop `ismissingvar'


	* consolidate unique ID into "key" variable
	replace key=instanceid if key==""
	drop instanceid


	* label variables
	label variable key "Unique submission ID"
	cap label variable submissiondate "Date/time submitted"
	cap label variable formdef_version "Form version used on device"
	cap label variable review_status "Review status"
	cap label variable review_comments "Comments made during review"
	cap label variable review_corrections "Corrections made during review"


	label variable surveyor_code "Surveyor name"
	note surveyor_code: "Surveyor name"
	label define surveyor_code 101 "Naresh" 102 "Devendra" 103 "Ram Babu" 104 "Ranjit" 105 "Rahul" 106 "Munna" 107 "Rambabu" 108 "Vishnu" 109 "Vikram" 110 "Mandip Kumar" 111 "Love Kush" 112 "Raja" 113 "Sumit"
	label values surveyor_code surveyor_code

	label variable block "Block"
	note block: "Block"

	label variable consent "Do you agree to take part in this survey?"
	note consent: "Do you agree to take part in this survey?"
	label define consent 1 "Yes" 0 "No"
	label values consent consent

	label variable resp_name "Name of respondent"
	note resp_name: "Name of respondent"

	label variable resp_father_husband_name "Name of respondent's father/husband"
	note resp_father_husband_name: "Name of respondent's father/husband"

	label variable religion "Religion of household"
	note religion: "Religion of household"
	label define religion 1 "Hindu" 2 "Muslim" 3 "Christian" 4 "Sikh" 5 "Aadivaasi (indegenious faith)" -87 "Other" -88 "Did not know" -89 "Did not answer"
	label values religion religion

	label variable phone_num "Main contact number of household"
	note phone_num: "Main contact number of household"

	label variable alt_phone_num "Alternative contact number of household"
	note alt_phone_num: "Alternative contact number of household"

	label variable length_of_stay "How long have you been living in this area for?"
	note length_of_stay: "How long have you been living in this area for?"
	label define length_of_stay 1 "Keep coming and going" 2 "0 to 1 year" 3 "1 to 5 years" 4 "5 to 10 years" 5 "10 to 20 years" 6 "20 years or more"
	label values length_of_stay length_of_stay

	label variable hh_size "How many members are there in your household?"
	note hh_size: "How many members are there in your household?"

	label variable has_mosquito_net "Whether household has access to a mosquito net"
	note has_mosquito_net: "Whether household has access to a mosquito net"
	label define has_mosquito_net 0 "No" 1 "Yes" 2 "Yes but it is shared with other households"
	label values has_mosquito_net has_mosquito_net

	label variable has_light "Whether household has access to a light"
	note has_light: "Whether household has access to a light"
	label define has_light 0 "No" 1 "Yes" 2 "Yes but it is shared with other households"
	label values has_light has_light

	label variable has_toilet_seat "Whether household has access to toilet with seat"
	note has_toilet_seat: "Whether household has access to toilet with seat"
	label define has_toilet_seat 0 "No" 1 "Yes" 2 "Yes but it is shared with other households"
	label values has_toilet_seat has_toilet_seat

	label variable hh_locationlatitude "Household GPS location (latitude)"
	note hh_locationlatitude: "Household GPS location (latitude)"

	label variable hh_locationlongitude "Household GPS location (longitude)"
	note hh_locationlongitude: "Household GPS location (longitude)"

	label variable hh_locationaltitude "Household GPS location (altitude)"
	note hh_locationaltitude: "Household GPS location (altitude)"

	label variable hh_locationaccuracy "Household GPS location (accuracy)"
	note hh_locationaccuracy: "Household GPS location (accuracy)"

	label variable survey_status "Survey status"
	note survey_status: "Survey status"
	label define survey_status 1 "Survey complete" 2 "Survey incomplete" 3 "Respondent not at home or unwell/ busy" 4 "Refused before starting the survey" 5 "Refused during the survey" 6 "Other"
	label values survey_status survey_status

	label variable comments "Comments on the survey"
	note comments: "Comments on the survey"



	capture {
		foreach rgvar of varlist name_* {
			label variable `rgvar' "Name of household member"
			note `rgvar': "Name of household member"
		}
	}

	capture {
		foreach rgvar of varlist gender_* {
			label variable `rgvar' "Gender"
			note `rgvar': "Gender"
			label define `rgvar' 1 "Male" 0 "Female" -87 "Other"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist resp_relation_* {
			label variable `rgvar' "How is this member related to the respondent?"
			note `rgvar': "How is this member related to the respondent?"
			label define `rgvar' 1 "Self" 2 "Husband" 3 "Son" 4 "Daughter" 5 "Father-in-law" 6 "Mother-in-law" 7 "Brother-in-law" 8 "Sister-in-law" 9 "Father" 10 "Mother" 11 "Brother" 12 "Sister" 13 "Grandfather/Grandmother" 14 "Son-in-law/Daughter-in-law" 15 "Cousin" 16 "Aunt/Uncle" 17 "Niece/Nephew" 18 "Husband's other wife" 19 "Step-son/ Step-daughter" 20 "Wife" -87 "Other"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist know_dob_* {
			label variable `rgvar' "Do you know the member's date of bith?"
			note `rgvar': "Do you know the member's date of bith?"
			label define `rgvar' 1 "Yes" 0 "No"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist dob_* {
			label variable `rgvar' "What is the member's date of birth?"
			note `rgvar': "What is the member's date of birth?"
		}
	}

	capture {
		foreach rgvar of varlist age_years_* {
			label variable `rgvar' "Age - years completed"
			note `rgvar': "Age - years completed"
		}
	}

	capture {
		foreach rgvar of varlist has_aadhaar_* {
			label variable `rgvar' "Does the member have Aadhaar"
			note `rgvar': "Does the member have Aadhaar"
			label define `rgvar' 1 "Yes" 0 "No" 2 "Yes but does not want to provide details" -88 "Did not know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist aadhaar_num_* {
			label variable `rgvar' "Aadhaar card number"
			note `rgvar': "Aadhaar card number"
		}
	}

	capture {
		foreach rgvar of varlist has_ration_* {
			label variable `rgvar' "Does the member have a ration card"
			note `rgvar': "Does the member have a ration card"
			label define `rgvar' 1 "Yes" 0 "No" 2 "Yes but does not want to provide details" -88 "Did not know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist ration_card_num_* {
			label variable `rgvar' "Ration card number"
			note `rgvar': "Ration card number"
		}
	}

	capture {
		foreach rgvar of varlist has_voterid_* {
			label variable `rgvar' "Does the member have a voter ID"
			note `rgvar': "Does the member have a voter ID"
			label define `rgvar' 1 "Yes" 0 "No" 2 "Yes but does not want to provide details" -88 "Did not know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist voter_id_* {
			label variable `rgvar' "Voter ID number"
			note `rgvar': "Voter ID number"
		}
	}

	capture {
		foreach rgvar of varlist has_bank_account_* {
			label variable `rgvar' "Does the membe have a bank account"
			note `rgvar': "Does the membe have a bank account"
			label define `rgvar' 1 "Yes" 0 "No" -88 "Did not know"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist edu_level_* {
			label variable `rgvar' "Highest education level of household member"
			note `rgvar': "Highest education level of household member"
			label define `rgvar' 0 "Illiterate" 1 "1st" 2 "2nd" 3 "3rd" 4 "4th" 5 "5th" 6 "6th" 7 "7th" 8 "8th" 9 "9th" 10 "10th" 11 "11th" 12 "12th" 13 "Bachelor's Degree" 14 "Master's Degree" 15 "Professional Degree (B.Tech/M.Tech/BSw/MSw/MBA)" 16 "Aanganwadi/nursery/Preschool" 17 "Some self-taught/home taught education" -87 "Other ---------------" -88 "Did not know" -89 "Did not answer"
			label values `rgvar' `rgvar'
		}
	}

	capture {
		foreach rgvar of varlist edu_level_oth_* {
			label variable `rgvar' "Other please specify"
			note `rgvar': "Other please specify"
		}
	}

	capture {
		foreach rgvar of varlist edu_online_status_* {
			label variable `rgvar' "Whether member is currently taking classes online"
			note `rgvar': "Whether member is currently taking classes online"
			label define `rgvar' 1 "Yes" 0 "No" -88 "Did not know"
			label values `rgvar' `rgvar'
		}
	}




	* append old, previously-imported data (if any)
	cap confirm file "`dtafile'"
	if _rc == 0 {
		* mark all new data before merging with old data
		gen new_data_row=1
		
		* pull in old data
		append using "`dtafile'"
		
		* drop duplicates in favor of old, previously-imported data if overwrite_old_data is 0
		* (alternatively drop in favor of new data if overwrite_old_data is 1)
		sort key
		by key: gen num_for_key = _N
		drop if num_for_key > 1 & ((`overwrite_old_data' == 0 & new_data_row == 1) | (`overwrite_old_data' == 1 & new_data_row ~= 1))
		drop num_for_key

		* drop new-data flag
		drop new_data_row
	}
	
	* save data to Stata format
	save "`dtafile'", replace

	* show codebook and notes
	codebook
	notes list
}

disp
disp "Finished import of: `csvfile'"
disp

* OPTIONAL: LOCALLY-APPLIED STATA CORRECTIONS
*
* Rather than using SurveyCTO's review and correction workflow, the code below can apply a list of corrections
* listed in a local .csv file. Feel free to use, ignore, or delete this code.
*
*   Corrections file path and filename:  D:/Dropbox/Mayur Vihar Project/Listing Survey/Data/Raw/listing_v1_corrections.csv
*
*   Corrections file columns (in order): key, fieldname, value, notes

capture confirm file "`corrfile'"
if _rc==0 {
	disp
	disp "Starting application of corrections in: `corrfile'"
	disp

	* save primary data in memory
	preserve

	* load corrections
	insheet using "`corrfile'", names clear
	
	if _N>0 {
		* number all rows (with +1 offset so that it matches row numbers in Excel)
		gen rownum=_n+1
		
		* drop notes field (for information only)
		drop notes
		
		* make sure that all values are in string format to start
		gen origvalue=value
		tostring value, format(%100.0g) replace
		cap replace value="" if origvalue==.
		drop origvalue
		replace value=trim(value)
		
		* correct field names to match Stata field names (lowercase, drop -'s and .'s)
		replace fieldname=lower(subinstr(subinstr(fieldname,"-","",.),".","",.))
		
		* format date and date/time fields (taking account of possible wildcards for repeat groups)
		forvalues i = 1/100 {
			if "`datetime_fields`i''" ~= "" {
				foreach dtvar in `datetime_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						gen origvalue=value
						replace value=string(clock(value,"MDYhms",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
						* allow for cases where seconds haven't been specified
						replace value=string(clock(origvalue,"MDYhm",2025),"%25.0g") if strmatch(fieldname,"`dtvar'") & value=="." & origvalue~="."
						drop origvalue
					}
				}
			}
			if "`date_fields`i''" ~= "" {
				foreach dtvar in `date_fields`i'' {
					* skip fields that aren't yet in the data
					cap unab dtvarignore : `dtvar'
					if _rc==0 {
						replace value=string(clock(value,"MDY",2025),"%25.0g") if strmatch(fieldname,"`dtvar'")
					}
				}
			}
		}

		* write out a temp file with the commands necessary to apply each correction
		tempfile tempdo
		file open dofile using "`tempdo'", write replace
		local N = _N
		forvalues i = 1/`N' {
			local fieldnameval=fieldname[`i']
			local valueval=value[`i']
			local keyval=key[`i']
			local rownumval=rownum[`i']
			file write dofile `"cap replace `fieldnameval'="`valueval'" if key=="`keyval'""' _n
			file write dofile `"if _rc ~= 0 {"' _n
			if "`valueval'" == "" {
				file write dofile _tab `"cap replace `fieldnameval'=. if key=="`keyval'""' _n
			}
			else {
				file write dofile _tab `"cap replace `fieldnameval'=`valueval' if key=="`keyval'""' _n
			}
			file write dofile _tab `"if _rc ~= 0 {"' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab _tab `"disp "CAN'T APPLY CORRECTION IN ROW #`rownumval'""' _n
			file write dofile _tab _tab `"disp"' _n
			file write dofile _tab `"}"' _n
			file write dofile `"}"' _n
		}
		file close dofile
	
		* restore primary data
		restore
		
		* execute the .do file to actually apply all corrections
		do "`tempdo'"

		* re-save data
		save "`dtafile'", replace
	}
	else {
		* restore primary data		
		restore
	}

	disp
	disp "Finished applying corrections in: `corrfile'"
	disp
}
