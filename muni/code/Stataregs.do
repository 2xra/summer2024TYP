capture
	clear
*use "C:\Users\rra3\Desktop\summer2024TYP\muni\data\stata\countymuni.dta"
use "C:\Users\rra3\Desktop\summer2024TYP\muni\data\stata\countymuniunemp.dta"
gen Bcom = 0
replace Bcom = 1 if PropBlackTC >= .0878
gen stata_date = dofc(Sale_Date)
merge m:m stata_date using "C:\Users\rra3\Desktop\summer2024TYP\muni\data\stata\tbillsdaily.dta"

generate postBLM = stata_date > 22067
*dates: day 22067, month
generate postRoe = stata_date>22820
*drop *_1
drop if COUNTY == .
/*key vars
logpop
Revbond
TaxExempt
postBLM
Callable_Issue


*/


*duplicate code

gen STCOID = STNAME + CTYNAME

sort STNAME CTYNAME
quietly by STNAME CTYNAME: gen dup = cond(_N==1,0,_n)
egen largestdup = max(dup), by(STNAME CTYNAME)

gen reportedspreadbp = Reported_Gross_Spread__per_thous*10

gen logamount = ln(Par_Amount__USD_Millions_)
gen logcomp =ln(Composite_Amount__USD_Millions_)
gen logpop = ln(TOT_POP)
gen logmaturity = ln(Years_to_Maturity)
gen Revbond = 1 if Security == "Revenue"
gen logproptax = ln(Property_Tax)
gen logpercap = ln(Percap2020)
gen PropCrimeProportionper1k = (Property_crime/TOT_POP)*1000

replace Revbond = 0 if Revbond ==.

gen TaxExempt = 1
replace TaxExempt = 0 if Tax_Status != "Tax Exempt"

gen enhancement = 0 if Credit_Enhancer_Type ==""
replace enhancement = 1 if Credit_Enhancer_Type !=""

encode Bid_Type, gen(PrivateCat)
*regression things that matter:

label define State_Name 01 "Alabama" 02 "Alaska" 04 "Arizona" 05 "Arkansas" 06 "California" 08 "Colorado" 09 "Connecticut" 10 "Delaware" 11 "District of Columbia" 12 "Florida" 13 "Georgia" 15 "Hawaii" 16 "Idaho" 17 "Illinois" 18 "Indiana" 19 "Iowa" 20 "Kansas" 21 "Kentucky" 22 "Louisiana" 23 "Maine" 24 "Maryland" 25 "Massachusetts" 26 "Michigan" 27 "Minnesota" 28 "Mississippi" 29 "Missouri" 30 "Montana" 31 "Nebraska" 32 "Nevada" 33 "New Hampshire" 34 "New Jersey" 35 "New Mexico" 36 "New York" 37 "North Carolina" 38 "North Dakota" 39 "Ohio" 40 "Oklahoma" 41 "Oregon" 42 "Pennsylvania" 44 "Rhode Island" 45 "South Carolina" 46 "South Dakota" 47 "Tennessee" 48 "Texas" 49 "Utah" 50 "Vermont" 51 "Virginia" 53 "Washington" 54 "West Virginia" 55 "Wisconsin" 56 "Wyoming", add

label values STATE State_Name

tab STNAME, sort
gen clustergroup = .
replace clustergroup = 1 if STNAME == "Texas"

replace clustergroup = 2 if STNAME == "Illinois"
replace clustergroup = 3 if STNAME == "California"
replace clustergroup = 4 if STNAME == "Wisconsin"

replace clustergroup = 5 if STNAME == "Minnesota"

replace clustergroup = 0 if clustergroup ==.

gen resen_quint = 1

replace resen_quint = 2 if Racial_Resent<=40
 
replace resen_quint = 3 if Racial_Resent<=30
replace resen_quint = 4 if Racial_Resent<=20
replace resen_quint = 5 if Racial_Resent<=10

gen highresent =1 if resen_quint==5
replace highresent = 0  if resen_quint !=5

*two outliers
drop if Reported_Gross_Spread__per_thous != . & Reported_Gross_Spread__per_thous>=100

*DATA CLEANING 

gen dropme = 0
replace dropme = 1 if Coupon_Type_of_Maturity == "Variable Rate Long"
replace dropme = 1 if Coupon_Type_of_Maturity == "Variable Rate No Put"
replace dropme = 1 if Coupon_Type_of_Maturity == "Variable Rate Short"
replace dropme = 1 if Coupon_Type_of_Maturity == "Convertible"
replace dropme = 1 if Highest_coupon_price_yield > 150
replace dropme = 1 if Beginning_Serial__Term_Yield > 150
replace dropme = 1 if Final_Ending_Price_Yield > 150
replace dropme = 1 if Years_to_Maturity > 50
replace dropme = 0 if Highest_coupon_price_yield == Beginning_Serial__Term_Yield & Highest_coupon_price_yield == Final_Ending_Price_Yield

gen dropme2 = 0
gen dropmetype =0
replace dropmetype = 1 if Coupon_Type_of_Maturity == "Variable Rate Long"
replace dropmetype = 1 if Coupon_Type_of_Maturity == "Variable Rate No Put"
replace dropmetype = 1 if Coupon_Type_of_Maturity == "Variable Rate Short"
replace dropmetype = 1 if Coupon_Type_of_Maturity == "Convertible"

replace dropme2 = 1 if Highest_coupon_price_yield > 30
replace dropme2 = 1 if Beginning_Serial__Term_Yield > 30
replace dropme2 = 1 if Final_Ending_Price_Yield >30
replace dropme2 = 1 if Years_to_Maturity > 50

gen yield = Final_Ending_Price_Yield

gen keephigh = 0
gen keepbeg = 0
gen keepfinmat = 0
gen keepending = 0
gen badbondflag = 1 if _8_digit_CUSIP == "nan"
drop if badbondflag == 1

replace keephigh = 1 if Highest_coupon_price_yield <=30 
replace keepbeg = 1 if Beginning_Serial__Term_Yield <= 30 
replace keepfinmat = 1 if Final_maturity_yield <= 30 
replace keepending = 1 if Final_Ending_Price_Yield <=30 

replace yield = Highest_coupon_price_yield if keephigh & dropme2
replace yield = Beginning_Serial__Term_Yield if keepbeg & dropme2
replace yield = Final_maturity_yield if keepfinmat & dropme2
replace yield = Final_Ending_Price_Yield if keepending & dropme2



replace yield = Highest_coupon_price_yield if Highest_coupon_price_yield>yield & keephigh
replace yield = Beginning_Serial__Term_Yield if Beginning_Serial__Term_Yield>yield & keepbeg

replace yield = Final_maturity_yield if Final_maturity_yield>yield & keepfinmat
replace yield = Final_Ending_Price_Yield if Final_Ending_Price_Yield>yield &keepending

gen dropcheck = 0
replace dropcheck =1 if keepbeg
replace dropcheck = 1 if keepending
replace dropcheck = 1 if keepfinmat
replace dropcheck = 1 if keephigh


gen hackysolution = 0
replace hackysolution = 1 if yield >= 90
replace yield = yield/100 if hackysolution
gen stillprobyield =0
replace stillprobyield = 1 if yield>30







gen milproptax = Property_Tax/1000
gen thoupercap = Percap2020/1000
*reg Reported_Gross_Spread__per_thous i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ i.Moody_Number postBLM#i.black_dec Charter_School_Flag__Y_N_ logmaturity ,r


gen enhancementpct = enhancement*100
gen Revbondpct = Revbond*100
gen TaxExemptpct = TaxExempt*100
gen Callable_Issuepct = Callable_Issue*100
gen Sinking_fund_flagpct = Sinking_fund_flag*100
gen Deals_with_Advisor__Y_pct = Deals_with_Financial_Advisor__Y_*100
gen Deals_with_Underwriterpct = Deals_with_Underwriter_Counsel__*100
gen Charterpct= Charter_School_Flag__Y_N_*100 


label variable Reported_Gross_Spread__per_thous "Reported Gross Spread (per thousand)"
label variable yield "Yield"
label variable Highest_coupon_price_yield "Highest Coupon Price Yield"
label variable Beginning_Serial__Term_Yield "Beginning Serial Term Yield"
label variable Final_Ending_Price_Yield "Final Ending Price Yield"
label variable enhancementpct "Enhancement (\%)"
label variable Revbondpct "Revenue Bond (\%)"
label variable TaxExemptpct "Tax Exempt (\%)"
label variable Callable_Issuepct "Callable Issue (\%)"
label variable Sinking_fund_flagpct "Sinking Fund Flag (\%)"
label variable Composite_Amount__USD_Millions_ "Amount (\$ Mil)"
label variable Deals_with_Advisor__Y_pct "Deals with Financial Advisor (\%)"
label variable Deals_with_Underwriterpct "Deals with Underwriter Counsel (\%)"
label variable Charterpct "Charter School Flag (\%)"
label variable Years_to_Maturity "Years to Maturity"
label variable highresent "High Racial Animus"
label variable postBLM "Post George Floyd"
label variable Percent_Below_Poverty_Level_Popu "Below Poverty Level (\%)"
label variable _25__High_School_Graduate "High School Education (25+) (\%)"
label variable milproptax "Property Tax income (\$ mil)"
label variable thoupercap "Per Capita Income (\$ thousand)"
label variable PropCrimeProportion "Proportion of Property Crimes"
label variable unemployment "Unemployment Rate"
gen highquint =1 if BlackQuintile >3
replace highquint = 0 if highquint ==.

gen highterc = 1 if BlackTercile ==3
replace highterc = 0 if highterc ==.
gen interhighblm = highresent*postBLM
gen interhighquint = highresent*BlackQuintile
gen interblmquint = postBLM *BlackQuintile
*reg Reported_Gross_Spread__per_thous i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ i.Moody_Number postBLM#i.black_dec Charter_School_Flag__Y_N_ logmaturity ,cluster(clustergroup)

gen ReportedSpreadBP = Reported_Gross_Spread__per_thous*10

gen logspread =ln(Reported_Gross_Spread__per_thous)

gen keepvar = 0 
replace keepvar = 1 if stata_date < 22067-145
replace keepvar = 1 if stata_date > 22067+585

*reg Reported_Gross_Spread__per_thous i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ i.Moody_Number postBLM#i.BDecile Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate,cluster(clustergroup)

*debate about usinig i.moody_number need to fix the data if included.

*merge m:1 stata_date using "C:\Users\rra3\Desktop\summer2024TYP\muni\data\bonds\gov finance data\tenyearyieldsstata.dta"

asdoc reg Reported_Gross_Spread__per_thous highresent#postBLM#i.BlackQuintile i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion,r replace abb(.) dec(4) drop(_cons) nest


asdoc reg logspread highresent postBLM i.BlackQuintile interhighblm  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion, r replace abb(.) dec(4) drop(_cons) nest label


asdoc reg logspread highresent postBLM i.BlackQuintile i.BlackQuintile#highresent i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion, r replace abb(.) dec(4) drop(_cons) nest
/*
sample limiter stuff
drop if stata_date <= 22007
drop if stata_date >= 22127
drop if Reported_Gross_Spread__per_thous ==.

*/



*latex code


*






* export spread regressions


*1
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r replace abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\allspread.doc)

*2
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*3
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest


*main spread regs

*1
*2
*3
*4
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  replace abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\mainspread.doc)
*5
*6
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
*9
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest

*all spreads split by enhancement


*1
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\nonenhancespread.doc)

*2
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*3
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest

*1
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\enhancespread.doc)

*2
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*3
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc reg ReportedSpreadBP i.highterc i.postBLM i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest





*export all yields
*1
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r replace abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\allyield.doc)


*2
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest

*3
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc reg yield i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc reg yield i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc reg yield i.highterc i.postBLM i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*export main yields
*1

*2

*3
*4
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r replace abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\mainyield.doc)

*5
*6
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
*9
asdoc reg yield i.highterc i.postBLM i.highresent  i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion treasury20yrcmt  unemployment if !stillprobyield, r  abb(.) dec(4) drop(_cons i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest


*yield split by enhancement
*1
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\nonenhanceyield.doc)

*2
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*3
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc reg yield i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc reg yield i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc reg yield i.highterc i.postBLM i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 0, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest

*1
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\enhanceyield.doc)

*2
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*3
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc reg yield i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg yield i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc reg yield i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc reg yield i.highterc i.postBLM i.highresent  i.PrivateCat  Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment if enhancement== 1, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest



*all linear enhancement

*1
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\alllinear.doc)


*2
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*3
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc reg enhancement i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc reg enhancement i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc reg enhancement i.highterc i.postBLM i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest

*main linear enhancement
*1
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\mainlinear.doc)

*2
*3
asdoc reg enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
*5
asdoc reg enhancement i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
*7
*8
*9
asdoc reg enhancement i.highterc i.postBLM i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest



*all logit enhance

*1
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\alllogit.doc)


*2
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc i.highresent#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*3
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*5
asdoc logit enhancement i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*7
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*8
asdoc logit enhancement i.highterc i.postBLM i.highresent i.highterc#i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*9
asdoc logit enhancement i.highterc i.postBLM i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest

*main logit enhancement
*1
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#highresent i.postBLM#i.highterc i.highresent#i.highterc i.postBLM#i.highresent#i.highterc i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r replace abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest save(C:\Users\rra3\Desktop\summer2024TYP\muni\tables\mainlogit.doc)

*2
*3
asdoc logit enhancement i.highterc i.postBLM i.highresent i.postBLM#i.highresent i.highresent#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*4
*5
asdoc logit enhancement i.highterc i.postBLM i.highresent i.highterc#i.highresent i.postBLM#i.highterc  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion  unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest
*6
*7
*8
*9
asdoc logit enhancement i.highterc i.postBLM i.highresent  i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment, r  abb(.) dec(4) drop(_cons i.PrivateCat Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate logproptax logpercap PropCrimeProportion unemployment) nest



/*gen enhancementpct = enhancement*100
gen Revbondpct = Revbond*100
gen TaxExemptpct = TaxExempt*100
gen Callable_Issuepct = Callable_Issue*100
gen Sinking_fund_flagpct = Sinking_fund_flag*100
gen Deals_with_Advisor__Y_pct = Deals_with_Financial_Advisor__Y_*100
gen Deals_with_Underwriterpct = Deals_with_Underwriter_Counsel__*100
gen Charterpct= Charter_School_Flag__Y_N_*100*/ 
*latex code
label variable highterc "Top Tercile of race"

estpost su  Composite_Amount__USD_Millions_ ReportedSpreadBP yield enhancementpct Revbondpct TaxExemptpct Callable_Issuepct Sinking_fund_flagpct Deals_with_Advisor__Y_pct Deals_with_Underwriterpct Charterpct Years_to_Maturity if Reported_Gross_Spread__per_thous !=. & !stillprobyield, d 

esttab using smallsample.tex, replace cells("mean(fmt(3)) sd(fmt(3)) p50(fmt(3)) p1(fmt(3)) p99(fmt(3))" ) label

estpost su Composite_Amount__USD_Millions_ ReportedSpreadBP yield enhancementpct Revbondpct TaxExemptpct Callable_Issuepct Sinking_fund_flagpct  Deals_with_Advisor__Y_pct Deals_with_Underwriterpct Charterpct Years_to_Maturity if !stillprobyield, d

esttab using fullsample.tex, replace cells("mean(fmt(3)) sd(fmt(3)) p50(fmt(3)) p1(fmt(3)) p99(fmt(3)) count(fmt(0))" ) label


estpost su highterc highresent postBLM Percent_Below_Poverty_Level_Popu _25__High_School_Graduate milproptax thoupercap PropCrimeProportion unemployment, d

esttab using fullsamplecounty.tex, replace cells("mean(fmt(3)) sd(fmt(3)) p50(fmt(3)) p1(fmt(3)) p99(fmt(3)) count(fmt(0))" ) label



