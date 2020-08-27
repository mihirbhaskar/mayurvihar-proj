set more off

import delimited using "/Users/mihirbhaskar/Downloads/sohaib_test_v4_WIDE.csv", stringcols(_all) clear

drop if _n == 1 | _n == 2 // these are the dummy forms I filled

gen matched = 0
foreach var of varlist confirm_*{
	replace matched = 1 if `var' == "1"
}

gen num_matched = 0 
foreach var of varlist confirm_*{
	replace num_matched = num_matched + 1 if `var' == "1"
}


* Reshape data 
tempfile full
save `full', replace

*Selecting variables to reshape 
unab vars : *_1
local stubs : subinstr local vars "1" "", all


reshape long `stubs', i(key)

drop if id_one == "" 

*Pulling data from multiple rows into one

rename key newkey

unab vars : *_one_
local stubs : subinstr local vars "_one_" "", all
local not id
local stubs: list stubs - not

local count one two three

foreach var in `stubs' {
	
	gen `var' = ""

	foreach rep in `count' {
	
		cap replace `var' = `var'_`rep'_ if `var'_`rep'_ != ""
	
		cap drop `var'_`rep'_
	
	}
}

*Checking for duplicates in matched people
duplicates tag hhid, gen(dup)
replace dup = 0 if missing(hhid)

duplicates tag resp_name resp_block, gen(dup1)
replace dup1 = 0 if missing(resp_name)

replace dup = 1 if dup1 == 1

drop dup1

br if dup == 1

* Watch out for cases where no HHID was matched but no respondent name or block was also given
br if resp_name == "" & hhid == ""

