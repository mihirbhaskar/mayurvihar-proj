*---------------------------------------------
* Final clean and merge across all datasets
*---------------------------------------------

/* Notes:


*/	

use "$netsprocess/matched_nets_clean", clear

*Drop duplicates in HHID to allow 1:1 merge with main listing data
duplicates drop hhid, force // this method of duplicate dropping is okay because it doesn't matter which observation is dropped. All information is the same.

*Merging net distribution data for households that could be matched to the listing data
merge 1:1 hhid using "$listingprocess/listing_clean"


*Appending new people/households discovered during the net distribution
append using "$netsprocess/unmatched_nets_clean"

*Dropping cases where no block was specified (a few error cases in the mosquito net distribution)
drop if block == ""

*Tidying up how the data looks for appended people
replace name_1 = resp_name if name_1 == ""
replace resp_relation_1 = 1 if resp_relation_1 == .
replace has_aadhaar_1 = 1 if aadhaar_num_1 != ""


*Export merged data for use in R
export delimited using "$root/full_master_hh_data.csv", replace

*Creating an individual-level listing for use in R
unab vars : *_1
local stubs : subinstr local vars "1" "", all

// Dropping the people that don't have hhids - from the mosquito net distribution
drop if hhid == ""

reshape long `stubs', i(hhid)

rename *_ *

drop if name == ""

export delimited using "$root/full_master_ind_data.csv", replace
