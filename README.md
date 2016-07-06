# KLIPS Panel Data

`KLIPS_compile.do` is a [do-file] (http://www.stata.com/manuals13/u16.pdf) that compiles the KLIPS data from multiple Stata data files (.dta), which are divided by the year when the survey was carried out. At the end of the script, the script runs panel-data logistic regression, which shows the correlation between the tenure choice of households and their individual characteristics.

## What is KLIPS?

Korean Labor & Income Panel Study (KLIPS) is a longitudinal survey of the labor market and the income activities of households and individuals residing in urban areas in South Korea. It is currently one and only comprehensive panel data on the South Korean households. The data can provide valuable microeconomic insights into the labor market activities. The first survey was conducted in 1998 and the data are released on a yearly basis by [Korea Labor Institute](https://www.kli.re.kr/klips_eng/index.do). The data can be downloaded [here](https://www.kli.re.kr/klips_eng/selectBbsNttList.do?bbsNo=74&key=263).

## Data

Each yearly survey is called "wave". The original `.dta` files come in a compressed `zip` file. The files are divided according to these waves, which are further divided into separete household data files and individual data files. The official codebook of the data can be found [here](https://www.kli.re.kr/klips_eng/selectBbsNttList.do?bbsNo=73&key=261). Each individual household member is uniquely identified by the variable `pid`, and individual household is uniquely identified by the variable `hhid__`.
* eg. Use hhid17 when linking between Household and Individual dataset in Wave 17.
Other key variables are coded as either `h__****` or `p__****`, where `h` indicates household data, `p` indicates individual data, the two-digit integer in place of `__` indicates respective wave number, and the four-digit integer in place of `****` indicates the variable concepts.

## How does this script work?

### Setting the working directory
```
global path "your working directory goes here"
cd "$path"
```
First, place the folder that contains all the KLIPS data files inside your working directory. Check the file path and change the script accordingly. This script use `path` as a global variable that contains the address of the working directory.

### Setting the waves in `foreach` loop
```
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
'''
As seen above, the script is set to retrieve data from wave 2 to wave 17. This range can be adjusted to extract the wave of primary interest. The script first cleanses personal data and then moves on to household data. Also, note that the range of the loop has to be the same for both personal and household data.
For instance, if one is extracting data from wave 1 to wave 15 from personal data, one has to extract from wave 1 to wave 15 from household data as well.

### Selecting the relevant variables
```
keep pid hhid`i' p`i'0102 p`i'0110
```
Irrelevant variables are dropped to improve the speed of the script and to reduce the size of the output datasets. However, it is important that the variable ``` hhid`i' ``` is preserved as ``` hhid`i' ``` contains unique household id.
The script first screens out the individuals who are household heads and extract their education levels.
From the household data, the script extracts household variables including the type of their residence, income, savings, consumption, and the number of household members.
Refer to the official [codebook](https://www.kli.re.kr/klips_eng/selectBbsNttList.do?bbsNo=73&key=261) to check the variables in the original KLIPS datasets. 

### Merging the personal and household data

```
merge 1:m hhid`i' using "$path/p`i'.dta", nogen
```
Lastkly the script merges the personal and household data using the unique household ids, the variable `hhid__`.

### Creating a dummy variable for years

```
forvalue y=1999(1)2014 {
gen DY`y'=1 if year==`y'
replace DY`y'=0 if year!=`y'
label var DY`y' "`y' year dummy"
}
```

### Declaring as panel data
```
xtset pid year, yearly
```
The dataset is declared as panel data for regression analysis. Afterward, the output dataset of the cleansing and compilation process is saved.
```
save "$path/panel_klips_hp",replace
```