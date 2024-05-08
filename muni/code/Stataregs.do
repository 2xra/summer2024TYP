use "C:\Users\rra3\Desktop\summer2024TYP\muni\data\stata\MuniDemo.dta"
gen Bcom = 0
replace Bcom = 1 if PropBlackTC >= .0878
gen stata_date = dofc(Sale_Date)
generate postBLM = stata_date > 22067
drop *_1
drop if COUNTY == .

logpop = ln(TOT_POP)