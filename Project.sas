Proc import datafile ="C:\Users\HOME10\Desktop\csvsas\New_Wireless_Pipe.Txt" 
Dbms=Dlm
out=Project
replace;
Delimiter='|';
getnames =yes;
run;
/*1  Explore and describe the dataset briefly. For example, is the acctno unique? What
is the number of accounts activated and deactivated? When is the earliest and
latest activation/deactivation dates available? And so on….
*/

data wireless;
  /* length Acctno $13 DeactReason $4 DealerType $2 Province $2; */
  infile "C:\Users\HOME10\Desktop\csvsas\New_Wireless_Fixed.Txt" ; 
  /* informat  Actdt mmddyy10. Deactdt mmddyy10. sales dollar8.2; */
 
  input @1  Acctno $13.
        @15 Actdt  mmddyy10.
        @26 Deactdt mmddyy10.
        @41 DeactReason $4. 
        @53 GoodCredit 1.
        @62 RatePlan 1. 
        @65 DealerType $2.
        @74 AGE 2.
        @80 Province $2.
        @85 Sales    dollar8.2 
  
;
run;
proc contents data =wireless; run;
proc summary data= wireless;
output out= Wireless2;
run;
proc print data= wireless2;
title "Summary of the data";
run;
proc sql;
  create table Acctnono as /*there are 102255 Unique account numbers*/
  select distinct acctno
  from Wireless;
quit;
proc print data=Acctnono ;run;

/*Number of Account Activated*/
proc sql;
  create table ActAtv as /*there are 102255 Activated  account numbers*/
  select actdt
  from Wireless;
quit;
/*Number of Account Deactivated*/
proc sql;
  create table DActAtv as 
  select Deactdt
  from Project;
quit;

data Deactat;   /*there are 19635 Deactivated  account numbers*/
set DActAtv;
if Deactdt='.' then Delete;
Run;

*Eariest Activation and Deactivation Date;

proc sort data = Project out=actdtsort;
by actdt;   /* Earlest date is 01/20/1999*/
run;


proc sort data = Deactat out=deactdtsort;
by deactdt; /* Earlest Deactivation Date is 01/25/1999 */
run;

proc sql;
  create table DeactReas as /*there are 5 Unique reasons for deactivation
  								Comp Debt Move Need Tech*/
  select count(distinct deactreason)
  from Wireless;
quit;

proc format;
value Salseg(multilabel notsorted)
		low-100 = 'Low'
		100-500   = 'Mid'
         500-800   = 'Average'
            800-10000  = 'High';

Value Ageseg (multilabel notsorted)
			low-20  = 'Teen'
            21-40 = 'young Adult'
            41-60 = 'Adult' 
         60-200     = 'Senior';
	 run;
 /*1.2 What is the age and province distributions of active 
	 and deactivated customers?*/
	 title'Age  distributions of active 
	 and deactivated customers';
proc Sgplot data= T1;
vbar age/group=status groupdisplay=cluster;
format age ageseg.;
run;
title'Province distributions of active 
	 and deactivated customers';
proc Sgplot data= T1;
vbar province/group=status groupdisplay=cluster;
run;

/*1.3 Segment the customers based on age, province and sales amount:*/


data formated;
set T1;
format sales salseg. age ageseg.;
run;
title" ";
proc tabulate data=formated;
class age Province  Sales;
Table Province, Age, Sales;
run;

proc means data=formated;
var Age Sales;
Class Province;
title " Mean procedure for Age and Sales by Province";
run;
ods pdf file="C:\Users\HOME10\Desktop\Project\freq1.pdf";
proc freq data=formated;
tables  Province * Sales;
run;
ods pdf close;

ods graphics on;
GOPTION RESET=ALL;
title "Barchart of Sales by Province";
proc sgplot data=wireless;
format sales salseg.;
Vbar Sales/Group=Province groupdisplay=cluster;
run;
ODS GRAPHICS OFF;

ods graphics on;
GOPTION RESET=ALL;
title 'Barchart of Age by pronvince';
proc sgplot data = wireless;
vbar age/Group=Province groupdisplay=cluster;
format age ageseg.;
run;
ODS GRAPHICS OFF;


ODS GRAPHICS ON;
GOPTION RESET = ALL;
TITLE "GENERATING A VERTICAL Barchart of Age by pronvince USING PROC SGPLOT";
run; 
ods pdf file="C:\Users\HOME10\Desktop\Project\Distribution.pdf";
proc gchart data = wireless;
pie age province/discrete value=inside
        percent= outside slice= outside;
format age ageseg.;
title 'piechart of Age';
title2 'piechart of pronvince';
run;
ods pdf close;
options nodate ps=60 ls=80;

ods graphics/discretemax=1300;
TITLE;
proc sgplot data=wireless;
format age ageseg.;
  HBOX  sales/category=province;
  title2 "Results by Division";
run;
ods graphics off;

proc sort data= wireless;
by actdt; run;

/*question 1.4 (1)*/
data Day;
set Status;
if deactdt = missing then Deac= '14995';
else Deac= Deactdt;
output;
run;
proc sort data=day; by actdt; run;
/* Assuming that latest date was jan 20 2001*/
data date;
set day;
by actdt;
   days=intck('day',actdt,deac);
   put days=;
run;
proc means data=date;
var days;
title"Summary Statistics of Account Tenure by days ";
run;
PROC UNIVARIATE DATA=date;
  VAR days;
  title;
RUN;
/*question 1.4 (2)*/
data _null_;
first_deactivation="25jan1999"d;
months=intck('Months', first_deactivation,today()+2);
d_accts=19635;
d_accts_per_months= round(d_accts/months);
put _all_;
run;

/*question 1.4 (3)*/
data status;
set wireless;
format date mmddyy10. status $10.;
if deactdt = missing then status= 'Active';
else  status ='Deactive' ; 
output;
run;

proc format;
value Tenure
            0-30 = '<30 days' 
           31-60 =  '31-60 days'
          61-365 =  '61 days-one year' 
        365-High =  'over one year';
		run;
		data T1;
		set date;
		format days tenure.; run;

proc sgplot data = T1;
vbar days/Group=status groupdisplay=cluster;
title 'Barchart of Account Tenure by Status';
run;
proc gchart data =T1;
pie days/discrete value =outside  percent=inside slice= outside;
title 'Pie chart of Account by Tenure';
 run;
 proc gchart data =T1;
pie Status/discrete value =outside  percent=inside slice= outside;
title 'Pie chart of account by Status';
 run;

/*proc sgplot data= wireless;
scatter x=*/
/*question 1.4 (4)*/
 data Tea;
 set T1;
format dealertype $DT.;run;

ods pdf file="C:\Users\HOME10\Desktop\Project\associ.pdf";
	PROC FREQ DATA=T1;
  TABLES  days*(GoodCredit RatePlan DealerType)/CHISQ;
  Title'Association Between Days and (GoodCredit RatePlan DealerType)';
RUN;
ods pdf close;

data TN(keep=Dealertype);
set T1;
run;
proc Sort data=TN nodupkey;
by dealertype;
run;
title;
proc print data=TN; run;


proc format;
value $DT
		 'A1'=11
         'A2'=12
		 'B1'=21
		 'C1'=31
		 ;run;

 /*question 1.4 (5)*/
		PROC FREQ DATA=T1;
  TABLES Status*Days/CHISQ;
  Title'Association Between Account status and Tenure';
RUN;

/*question 1.4(6)*/
proc tabulate data =formated format=dollar12.;
class Status goodcredit age;
var sales;
table sales*(N mean min  max), status goodcredit age
/rts=60;
title 'Difference In Sales Amount  Status, Good credit and Age';
run;


ods pdf file="C:\Users\HOME10\Desktop\Project";

