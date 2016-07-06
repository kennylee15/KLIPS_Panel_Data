clear all
set maxvar 20000
global path "your working directory goes here"
cd "$path"
***********************
* clean personal data *
***********************
foreach i in 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17{
* load personal data
use "$path/klips1-17/eklips`i'p.dta"
keep pid hhid`i' p`i'0102 p`i'0110
drop if pid == .
foreach var of varlist * {
	drop if `var' == -1 
}
* keep only household heads
rename p`i'0102 head
drop if head != 10

* education
gen high = 0
replace high = 1 if p`i'0110 == 5 
gen higher = 0
replace higher = 1 if p`i'0110 == 6 | p`i'0110 == 7 | p`i'0110 == 8 | ///
p`i'0110 == 9
drop p`i'*
save "$path/p`i'.dta",replace
}
************************
* clean household data *
************************
foreach i in 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17{
* open household files
use "$path/klips1-17/eklips`i'h.dta"
* get variables on household characteristics
keep hhid`i' h`i'0141 h`i'1406 h`i'2102 h`i'2301 h`i'2402 h`i'2705 h`i'2112  ///
h`i'2113 h`i'2114 h`i'2115 h`i'2116 h`i'0150 h`i'2501
drop if hhid`i' == .
* drop missing value or "don't know / no response (-1)"
foreach var of varlist * {
	drop if `var' == -1 
	}

* distinguish landlord
gen landlord = 0
replace landlord = 1 if h`i'2501 == 1 
drop h`i'2501

* location of residence
rename h`i'0141 location
gen seoul = 0
replace seoul = 1 if location == 1

* income
rename h`i'2102 income_labor
egen income_nonlabor = rowtotal(h`i'2112 h`i'2113 h`i'2114 h`i'2115 h`i'2116)

* saving (avg monthly saving in t-1)fa
rename h`i'2402 saving
gen lsaving = log(saving)

* consumption
rename h`i'2301 consump

* number of household members
rename h`i'0150 members

* tenure choice
rename h`i'1406 tenure
gen chonsei = 0 if tenure == 1 | tenure == 3
replace chonsei = 1 if tenure == 2
drop if chonsei == .

* drop old variables
drop h`i'*

* drop if household id is missing
drop if hhid`i' == .
* merge houehold and its members (household codes -> individual codes)
merge 1:m hhid`i' using "$path/p`i'.dta", nogen
* drop if personal id is missing
drop if pid == .
* generate years
gen year=`i'+1997

* save the merged data file
save "$path/hp`i'",replace

}
use hp02.dta, clear
append using hp03 hp04 hp05 hp06 hp07 hp08 hp09 hp10 hp11 hp12 ///
hp14 hp15 hp16 hp17

* drop if personal id is unavailable
drop if pid==.
forvalue y=1999(1)2014 {
gen DY`y'=1 if year==`y'
replace DY`y'=0 if year!=`y'
label var DY`y' "`y' year dummy"
}
* drop if chonsei value is missing
drop if chonsei == .
* declare as panel data
xtset pid year, yearly
save "$path/panel_klips_hp",replace
summarize chonsei members income_labor income_nonlabor seoul lsaving high higher if landlord == 0
xtlogit chonsei members income_labor income_nonlabor seoul lsaving high higher if landlord == 0, fe nolog
reg chonsei members income_labor income_nonlabor seoul lsaving high higher DY1999-DY2014 if landlord == 0
