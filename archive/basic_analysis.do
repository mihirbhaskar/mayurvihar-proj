cd "D:/Dropbox/Mayur Vihar Project/Listing Survey/Data/Processed"

use "listing_v1.dta", clear

keep if submissiondate >= d(10july2020) & surveyor_code != 2 & phone_num != "2222222222"

foreach var of varlist age_years_dob*{
	destring `var', replace
}

*Combined age + creating flag for if HH has a member < 5 years

gen under_5 = 0

forvalues i=1/10{
	gen age_`i' = .
	replace age_`i' = age_years_dob_`i' if age_years_dob_`i' != .
	replace age_`i' = age_years_`i' if age_years_`i' != .
	
	replace under_5 = 1 if age_`i' <= 5 & age_`i' != .
}


gen under_5_nonet = (under_5 == 1 & has_mosquito_net == 0)

gen no_net = (has_mosqutio_net == 0)

gen pop = 1

tabstat pop no_net under_5_
