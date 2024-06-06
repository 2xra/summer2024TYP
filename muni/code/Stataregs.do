capture
	clear
use "C:\Users\rra3\Desktop\summer2024TYP\muni\data\stata\countymuni.dta"
gen Bcom = 0
replace Bcom = 1 if PropBlackTC >= .0878
gen stata_date = dofc(Sale_Date)
generate postBLM = stata_date > 22067
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



gen logamount = ln(Par_Amount__USD_Millions_)
gen logcomp =ln(Composite_Amount__USD_Millions_)
gen logpop = ln(TOT_POP)
gen logmaturity = ln(Years_to_Maturity)
gen Revbond = 1 if Security == "Revenue"
replace Revbond = 0 if Revbond ==.

gen TaxExempt = 1
replace TaxExempt = 0 if Tax_Status != "Tax Exempt"

gen enhancement = 0 if Credit_Enhancer_Type ==""
replace enhancement = 1 if Credit_Enhancer_Type !=""

encode Bid_Type, gen(PrivateCat)

xtile black_dec = PropBlackTC, nq(10)
xtile black_quint = PropBlackTC, nq(5)
xtile black_quart = PropBlackTC, nq(4)

xtile Asian_dec = PropAsianTC, nq(10)
xtile Asian_quint = PropAsianTC, nq(5)
xtile Asian_quart = PropAsianTC, nq(4)

xtile Hispa_dec = PropHispaTC, nq(10)
xtile Hispa_quint = PropHispaTC, nq(5)
xtile Hispa_quart = PropHispaTC, nq(4)
*regression things that matter:

gen cstreatvar=22067  if black_dec >=7
replace cstreatvar=0 if cstreatvar ==.
replace cstreatvar=0  if postBLM == 0

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
 

reg Reported_Gross_Spread__per_thous i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ i.Moody_Number postBLM#i.black_dec Charter_School_Flag__Y_N_ logmaturity ,r


reg Reported_Gross_Spread__per_thous i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ i.Moody_Number postBLM#i.black_dec Charter_School_Flag__Y_N_ logmaturity ,cluster(clustergroup)



reg Reported_Gross_Spread__per_thous i.PrivateCat enhancement Revbond logpop TaxExempt Callable_Issue Sinking_fund_flag logcomp  Deals_with_Financial_Advisor__Y_ Deals_with_Underwriter_Counsel__ i.Moody_Number postBLM#i.black_dec Charter_School_Flag__Y_N_ logmaturity Percent_Below_Poverty_Level_Popu _25__High_School_Graduate,cluster(clustergroup)
/*
sample limiter stuff
drop if stata_date <= 22007
drop if stata_date >= 22127
drop if Reported_Gross_Spread__per_thous ==.

*/