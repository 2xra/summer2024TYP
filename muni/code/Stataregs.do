use "C:\Users\rra3\Desktop\summer2024TYP\muni\data\stata\MuniDemo.dta"
drop Credit_Enhancer_Type_1
drop Date_at_Maturity_1
gen Bcom = 0
replace Bcom = 1 if PropBlackTC >= .0878
gen stata_date = dofc(Sale_Date)
generate postBLM = stata_date > 22067
