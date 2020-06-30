/*Load Panel Data - GR_Panel, DR_panel and MA_Panel*/
/*Loading Delivery store file:-*/


/*Merging Delivery store and Coffee_groc file:-*/
proc sort data=gr_panel; by IRI_KEY;
proc sort data=stores; by IRI_KEY;
data g1;
merge gr_panel (IN=aa) stores; If aa; by IRI_KEY; run;
proc print data=g1 (obs=10); run;

/*Merging Delivery store and Coffee_drug file:-*/
proc sort data=dr_panel; by IRI_KEY;
proc sort data=stores; by IRI_KEY;
data d1;
merge dr_panel (IN=aa) stores; If aa; by IRI_KEY; run;
proc print data=d1 (obs=10); run;

/*Merging Delivery store and Coffee_MA file:-*/
proc sort data=ma_panel; by IRI_KEY;
proc sort data=stores; by IRI_KEY;
data m1;
merge ma_panel (IN=aa) stores; If aa; by IRI_KEY; run;
proc print data=m1 (obs=10); run;


/* Create upc*/
options missing='';
data prod;
set prod;
upc1=catx("",SY,GE,VEND,ITEM);
run;
data prod;
set prod;
drop UPC;
upc1=compress(upc1);run;
data prod;
set prod;
COLUPC=upc1; 
drop upc1;run;
proc print data=prod (obs=10); run;



proc contents data=gr_panel;run;

data gr_panel;
set gr_panel(rename=(COLUPC=COLUPCnum));
COLUPC=put(COLUPCnum, 14.);
drop COLUPCnum;
run;


/*Merging Merged(Delivery store and Coffee_groc file) and prod coffee:-*/
proc sort data=g1; by COLUPC;
proc sort data=prod; by COLUPC;
data gr;
merge g1 (IN=aa) prod; If aa; by COLUPC; run;
proc print data=g1 (obs=10);run;

proc contents data=Prod; run;


proc means data=Grocery n nmiss; run;


/*Load Demo data*/
proc print data=Demo (obs=10);run;

data Demo;
set Demo(rename=(Panelist_ID=PANID));
run;

proc sort data=Grocery; by PANID;
proc sort data=Demo; by PANID;
data Final;
merge Grocery (IN=aa) Demo; If aa; by PANID; run;
proc print data=Final (obs=10);run;

proc means data=Demo n nmiss; run;
proc means data=Final n nmiss; run;

data Final;
 set Final;
 missing_flag = missing(deathcause);
 keep missing_flag deathcause;
run;

PROC SORT DATA=Final OUT=SORTED; by UPC ;run;

data SampleTest;
set Sorted;
Brand_test = scan(L5, 1);
run;

Data Brand7;
set SampleTest;
if Brand_test = 'FOLGERS' then Brand_F = 'FOLGERS';
else if Brand_test='MAXWELL' then Brand_M='MAXWELL HOUSE';
else if Brand_test='PRIVATE' then  Brand_P='PRIVATE LABEL';
else if Brand_test='STARBUCKS' then Brand_S='STARBUCKS';
else if Brand_test='EIGHT' then Brand_E='EIGHT O CLOCK';
else if Brand_test='CHOCK' then Brand_C='CHOCK FULL O NUTS';
else Brand_0='OTHERS';
run;
proc freq data=Brand7; table Brand_F Brand_M Brand_P Brand_S Brand_E Brand_0 Brand_C;run;

data Brand7;
set Brand7;
Brand7=catx("",Brand_F,Brand_M,Brand_P,Brand_S,Brand_E,Brand_C,Brand_0);
run;
proc freq data=Brand7; table Brand7;run;

data Brand7;
set Brand7;
drop Brand_F Brand_M Brand_P Brand_S Brand_E Brand_C Brand_0;
run;


DATA MYBRAND ; SET Brand7;
If Brand7= 'FOLGERS';run;

proc freq data=Brand7; table Market_Name;run;

PROC SUMMARY DATA=MYBRAND ;
CLASS PANID ;
VAR UNITS DOLLARS;
OUTPUT OUT = FAMILIES 
MEAN = MUNITS MDOLLARS 
SUM = SUNITS SDOLLARS; run;

proc means data=FAMILIES;run;


proc sql;
create table Try as 
select WEEK, Market_Name, sum(Dollars) as totDollars from Brand7
group by WEEK, Market_Name; quit;

ods graphics / reset attrpriority=color;
proc sgplot data=Customers1week;
series x=WEEK y=NoOfCust / group=Brand7
 break
markerattrs=(symbol=circlefilled)
legendlabel='average price by week';
xaxis type=discrete grid label='WEEK';
yaxis label= 'Avg Dollar Price' ;
run;

proc sql;
create table Customers1week as
select unique(PANID), sum(UNITS) as TUnits, WEEK from Brand7
where Brand7='FOLGERS'
group by WEEK;quit;

proc means data=Brand7 sum; var Dollars; run;
proc sql;
create table purchasepct as 
select Brand7, 100*sum(Dollars)/189627.82 as MS
from Brand7
group by Brand7;



proc sql;
create table Bought as
select * from Brand7
where Units>0;

proc sql;
create table PenetrationRate as 
select Brand7, 100*count(PANID)/44387 as MS
from Bought
group by Brand7;

/*Buying Rate*/
proc sql;
create table DollarRate as 
select Brand7, mean((Dollars/Units)/ounces) as DollarRate, mean(16*(Dollars/Units)/ounces) as Dollarsperpound
from Brand7
group by Brand7;quit;

data Brand7;
set Brand7;
volume_eq=input(vol_eq,8.6);
run;

data Brand7;
set Brand7;
ounces=volume_eq*16;
run;

proc sql;
create table OuncesRate as 
select Brand7, mean(ounces) as DollarRate
from Brand7
group by Brand7;
quit;

proc sql;
create table Purchasefreq as 
select Brand7, sum(Units) as Pfreq
from Brand7
group by Brand7, PANID; quit;

proc means data=Purchasefreq mean; var Pfreq; class Brand7; run;

proc sql;
create table FinalLoyal as
select Brand7, avg(loyalcalc) from Loyal2
group by Brand7;quit;
data=MergedLoyal;var brand7;class loyalcalc; run;

proc sql;
create table Folgersupc as
select colupc, sum(units) as Sunits, WEEK
from Brand7
where Brand7='FOLGERS'
group by WEEK, colupc;
quit;

proc sql;
create table upclevel as
select Colupc, sum(Sunits) as Tunits
from Folgersupc
group by colupc;quit;

proc sort data=upclevel; by Tunits;run;

;
proc sql; 
create table weeklysales

proc contents data=Brand7;run;



/* Distribution of Household size */
proc freq data=Brand7; table Family_Size;run;


*STUBSPEC 1440RC;
proc sort data=Mergedgr; by _STUBSPEC_1440RC;
proc sort data=scan; by _STUBSPEC_1440RC;
data Finaldata;
merge Mergedgr (IN=aa) scan; If aa; by _STUBSPEC_1440RC; run;
proc print data=Finaldata (obs=10);run;


proc freq data=FinalData;table HH_Age*D;run;



proc means data=Finaldata n nmiss; run;
proc freq data=MYBRAND; table HH_AGE Family_Size;run;

proc sql;
create table form1 as 
select *, (Dollars/Units)/(ounces) as PPO, Dollars/sum(Dollars) as MS
from Brand7;
quit;

 

proc sql;
create table form2 as
select *,sum(MS*PPO)/sum(MS) as WtdAvgPrice
from form1
group by Brand7, Week, COLUPC;
quit;


proc sql;
create table form3 as
select PANID, Brand7, COLUPC, sum(Units) as Tunits, WEEK, WtdAvgPrice
from form2
group by PANID, Brand7, Week;quit;

proc sql;
create table loyal as 
select PANID,count(PANID) as LBrand
from form3
group by PANID;

proc sql;
create table loyal1 as 
select PANID,BRAND7,count(PANID) as countid
from form3
group by Brand7,PANID;
run;
 
proc sql;
create table loyal2 as 
select PANID,BRAND7,countid, countid/sum(countid) as loyalcalc
from loyal1
group by PANID;
run;

proc sort data=form2; by PANID;
proc sort data=loyal2; by PANID;
data mergedloyal;
merge form2 (IN=aa) loyal2; If aa; by PANID Brand7; run;

*proc print data=dr (obs=10);run;

proc sql ;
create table prices as 
select Week, Brand7, avg(WtdAvgPrice) as AvgPricePPO
from mergedloyal
group by Brand7, Week;quit;
