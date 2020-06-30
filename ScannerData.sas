data b1;
infile 'H:\SAS Project\coffee_groc_1114_1165' expandtabs firstobs=2;
input IRI_KEY WEEK SY GE VEND ITEM UNITS DOLLARS F $ D PR;
run;

proc print data=b1 (obs=10);run;

/*Loading Delivery store file:-*/


proc print data=b2 (obs=10);run;

/*Merging Delivery store and Coffee_groc file:-*/
proc sort data=b1; by IRI_KEY;
proc sort data=b2; by IRI_KEY;
data b4;
merge b1 (IN=aa) b2; If aa; by IRI_KEY; run;
proc print data=b4 (obs=10); run;


/*Creating UPC Code in (Delivery store and Coffee_groc file)*/
data c2;set b4;
UPC = catx(SY,GE,VEND,ITEM);run;
proc print data=c2 (obs=10);run;


/*Import prod_coffee*/

proc print data=c3 (obs=10);run;
data C3;
set C3(rename=(SY=SYnum));
SY=input(SYnum, 8.);
drop SYnum;
run;

data C3;
set C3(rename=(GE=GEnum));
GE=input(GEnum, 8.);
drop GEnum;
run;

data C3;
set C3(rename=(VEND=VENDnum));
VEND=input(VENDnum, 8.);
drop VENDnum;
run;

data C3;
set C3(rename=(ITEM=ITEMnum));
ITEM=input(ITEMnum, 8.);
drop ITEMnum;
run;

/*Creating UPC Code in Prod Coffee*/
data c4;set C3;
UPC1 = catx(SY,GE,VEND,ITEM);run;
proc print data=c4 (obs=10);run;

data C5;
set C4;
drop UPC;
rename UPC1=UPC;
run;



proc print data = C5 (obs=10) ;run;

/*Merging Merged(Delivery store and Coffee_groc file) and prod coffee:-*/
proc sort data=c2; by UPC;
proc sort data=c5; by UPC;
data dd;
merge c2 (IN=aa) c5; If aa; by UPC; run;
proc print data=dd (obs=10);run;

proc contents data=dd;run;
proc freq; table L5;run;




proc print data=test(obs=10) ; run;


proc surveyselect data=dd method=srs n=80000
out=SampleTest;
run;

proc print data=SampleTest (obs=10) ; run;

/***********************************/
proc print;run;
data SampleTest;
set SampleTest;
Brand_test = scan(L5, 1);
run;

Data Quest_3;
set SampleTest;
if Brand_test = 'FOLGERS' then Brand_F = 'FOLGERS';
else if Brand_test='MAXWELL' then Brand_M='MAXWELL HOUSE';
else if Brand_test='PRIVATE' then  Brand_P='PRIVATE LABEL';
else if Brand_test='STARBUCKS' then Brand_S='STARBUCKS';
else if Brand_test='EIGHT' then Brand_E='EIGHT O CLOCK';
else if Brand_test='CHOCK' then Brand_C='CHOCK FULL O NUTS';
else Brand_0='OTHERS';
run;

proc print data=Quest_3 (obs=10) ; run;
proc freq data=Quest_3; table Brand_F Brand_M Brand_P Brand_S Brand_E Brand_0 Brand_C;run;
options missing='';
data q3_cat;
set Quest_3;
Brand7=catx("",Brand_F,Brand_M,Brand_P,Brand_S,Brand_E,Brand_C,Brand_0);
run;
proc freq data=q3_cat; table Brand7;run;

data q3_cat;
set q3_cat;
drop Brand_F Brand_M Brand_P Brand_S Brand_E Brand_C Brand_0;
run;


proc print data = q3_cat (obs=10) ; run;
data Q4_avg_DP;
set q3_cat;
if D>0 then Display=1;else Display=0;
if F="NONE" then Feature=0; else Feature=1;
run;

proc freq data=Q4_display;
table Feature;
run;

proc sql;
create table q4_avg_DP_MS as
select Brand7,UPC , Units,Display,Feature, Dollars,  Dollars/sum(Dollars) as MS
from Q4_avg_DP;           
run;
proc sql;
create table q4_avg_display as
select Brand7, sum(Display*MS)/sum(MS) as Avg_Display
from q4_avg_DP_MS
group by Brand7;
quit;


proc sql;
create table q4_avg_feature as
select Brand7, sum(Feature*MS)/sum(MS) as Avg_Feature
from q4_avg_DP_MS
group by Brand7;
quit;

/*Creating top 10 chains for for Folgers*/
/*Hypothesis for checking if average price , average feature and average display are different among chains */
data Q4_avg_DP;
set q3_cat;
if D>0 then Display=1;else Display=0;
if F="NONE" then Feature=0; else Feature=1;
run;

proc sql;
create table hypo1_t as 
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, VOL_EQ, (Dollars/Units)/(VOL_EQ*16) as PPO, Dollars/sum(Dollars) as MS
from q4_avg_DP;
quit;

proc sql;
create table fea_dis_table as
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, VOL_EQ ,sum(MS*PPO)/sum(MS) as WtdAvgPrice, sum(Feature*MS)/sum(MS) as Avg_Feature , sum(Display*MS)/sum(MS) as Avg_Display
from hypo1_t
group by Brand7,UPC , MskdName;
quit;
 

proc sql outobs=10;
create table Top10Stores as 
select MskdName ,sum(Dollars) as DollarTotal 
from hypo1_t
where Brand7="FOLGERS" and L2="GROUND COFFEE"
group by Mskdname
order by DollarTotal desc;
quit;



proc sql; 
create table hypo1_t2 as
select * 
from fea_dis_table
where Brand7="FOLGERS" and Mskdname in ('Chain75', 'Chain53', 'Chain6', 'Chain94', 'Chain114','Chain35');
quit;

proc sql;
create table hypo1_t3 as
select *
from hypo1_t2
where L2="GROUND COFFEE";
quit;

Data hypo1_t4;
set hypo1_t3;
if MskdName = 'Chain75' then ss1 = 'Large' ;
else if MskdName = 'Chain53' then ss2 = 'Large' ;
else if MskdName='Chain6' then  ss3='Large' ;
else if MskdName='Chain94' then ss4='Small';
else if MskdName='Chain114' then ss5='Small';
else if MskdName='Chain35' then ss6='Small';
run;

data hypo1_t5;
set hypo1_t4;
Chain_size=catx("",ss1, ss2, ss3 , ss4, ss5, ss6);
run;
proc freq data=hypo1_t5; table Chain_size;run;


proc ttest data=hypo1_t5;
var Avg_Feature;
class Chain_Size; run; 

proc ttest data=hypo1_t5;
var Avg_Display;
class Chain_Size; run;

proc ttest data=hypo1_t5;
var WtdAvgPrice;
class Chain_Size; run;

proc freq data=q3_cat;
table F;
run;

proc sql;
create table var_test as
select Week, avg(WtdAvgPrice) as WP , Chain_Size from hypo1_t5
group by Week,Chain_Size;
run;
ods graphics / reset attrpriority=color;
proc sgplot data=var_test;
series x=WEEK y=WP / group=Chain_Size
 break
markerattrs=(symbol=circlefilled)
legendlabel='average price by week';
xaxis type=discrete grid label='WEEK';
yaxis label= 'Avg Dollar Price' ;
run;

proc means data =hypo1_t5;
var WtdAvgPrice;
class Chain_Size;
run;

 
/*Time series forecasting*/

proc sql;
create table hypo1_t as 
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, VOL_EQ,PR ,(Dollars/Units)/(VOL_EQ*16) as PPO, Dollars/sum(Dollars) as MS
from q4_avg_DP;
quit;

proc sql;
create table fea_dis_table as
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, VOL_EQ ,PR, sum(MS*PR)/sum(MS)as Avg_PR,sum(MS*PPO)/sum(MS) as WtdAvgPrice, sum(Feature*MS)/sum(MS) as Avg_Feature , sum(Display*MS)/sum(MS) as Avg_Display
from hypo1_t
group by Brand7,UPC , MskdName;
quit;

proc sql;
create table TS1 as
select * from fea_dis_table
where Brand7="FOLGERS" and L2="GROUND COFFEE";
run; 


proc sql;
create table TS2 as
select Week, sum(Dollars) as TotDollars , Sum(Units) as TotUnits, avg(WtdAvgPrice) as WP, avg(Avg_Feature) as WF , avg(Avg_Display) as WD
from TS1
group by Week;
run; 


* Creating a differenced variable;
data TS3; 
set TS2; 
dTotDollars=dif(TotDollars); 
lTotDollars=lag(TotDollars);
ldTotDollars=lag(dTotDollars);
run; 

%let ylist = TotDollars;
%let dylist = dTotDollars;
%let time = week;
%let lylist = lTotDollars;
%let trend = trend;
%let xlist = TotUnits WP WD WF;



proc means data=TS3;
var &ylist &dylist &time;
run;

*Plotting the data;
proc gplot data=TS3;
plot &ylist*&time;
plot &dylist*&time;
run;

/*Durbin Watson Autocorrelation test*/

proc autoreg data=TS3;
   model TotDollars = Week/dwprob;
run;
proc arima data=TS3;
identify var=&ylist stationarity=(adf);
run;


* Dickey-Fuller test regressions;
proc reg data=TS3;
model &dylist = &lylist;
model &dylist = &lylist &trend;
run; 

* ARIMA for differenced variable;
proc arima data=TS3;
identify var=&ylist(1) stationarity=(adf);
run;


* ARIMA(2,0,3);
proc arima data=ts3;
identify var=&ylist;
estimate p=2 q=3;
forecast lead=5 out=NEW;
run;


data NEW; set NEW;
 time = _n_;
proc sgplot data=NEW;
 series x=time y=&ylist / lineattrs=(pattern=solid
thickness=3);
 series x=time y=forecast / lineattrs=(pattern=solid);
 series x=time y=l95 / lineattrs=(pattern=dash);
 series x=time y=u95 / lineattrs=(pattern=dash);
 xaxis label='Time' values=(0 to 60 by 1) ;
 yaxis label='Weekly Sales' ;
 title1 'Model 2: ARIMA(2,0,3)';
 title2 'Forecast with 95 percent confidence intervals';
run;


proc sql;
create table fea_dis_table as
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, VOL_EQ ,sum(MS*PPO)/sum(MS) as WtdAvgPrice, sum(Feature*MS)/sum(MS) as Avg_Feature , sum(Display*MS)/sum(MS) as Avg_Display
from hypo1_t
group by Brand7,UPC , MskdName;
quit;
 

proc sql;
create table coffee_all as
select Week, Sum(Dollars) as TotDollars 
from fea_dis_table
group by Week;
run;


proc sql;
create table coffee_all11 as
select Week, Sum(Dollars) as TotDollars 
from fea_dis_table
where L2='GROUND COFFEE'
group by Week;
run;

proc gplot data=coffee_all;
plot TotDollars*Week;
run;


********************************************************************************;
/* Folgers top UPCs */

proc sql;
create table FolgersUpc as
select Week, UPC, sum(Dollars) as TotDollars , Sum(Units) as TotUnits, avg(WtdAvgPrice) as WP, avg(Avg_Feature) as WF , avg(Avg_Display) as WD
from TS1
group by Week;
run; 


proc sql;
create table top_folgers as 
select UPC, sum(TotDollars) as dol, sum(TotUnits) as tunits from FolgersUPC
group by UPC;quit;

proc sort data=top_folgers; by dol;run;

proc sql;
create table topFupc as 
select Week, sum(Dollars) as TotDollars , Sum(Units) as TotUnits, avg(WtdAvgPrice) as WP, avg(Avg_Feature) as WF , avg(Avg_Display) as WD
from TS1

where UPC in ("1           025500           080273", "1           025500           080258","2           025500           081121","1           025500           06321","2           025500           053","2           025500           051")
group by WEEK;
quit;



proc sort data=GR_Panel; by week;
proc sort data=IRI; by week;
data Panel_mod;
merge GR_Panel (IN=aa) IRI; If aa; by Week; run;
proc print data=Panel_mod (obs=10);run;

proc means data=Panel_mod; var week;run;


**********************************;



/*Regression Analysis */

proc sql;
create table Regression1 as 
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, VOL_EQ*16 as ounce ,PR ,(Dollars/Units)/(VOL_EQ*16) as PPO, Dollars/sum(Dollars) as MS
from q4_avg_DP;
quit;

proc sql;
create table Regression2 as
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, ounce ,sum(MS*PR)/sum(MS) as Avg_PR,sum(MS*PPO)/sum(MS) as WtdAvgPrice, sum(Feature*MS)/sum(MS) as Avg_Feature , sum(Display*MS)/sum(MS) as Avg_Display
from Regression1
group by Brand7, Week,UPC,MskdName ;
quit;

proc sql;
create table Regression3 as 
select Brand7, Week,UPC,L2,Display, Feature, MskdName, Units,Dollars, ounce ,Avg_PR, WtdAvgPrice, Avg_Feature, Avg_Display
from Regression2
where Brand7="FOLGERS" and L2="GROUND COFFEE";
run;


proc sql;
create table regression4 as
select Brand7, Week , sum(Units) as TotUnits , sum(ounce) as Tot_ounce, sum(Dollars) as TotDollars, avg(Avg_PR) as Av_PCut, avg(WtdAvgPrice) as Av_Price, avg(Avg_Feature) as Av_F, avg(Avg_Display) as Av_D
from Regression3
group by Brand7,Week;
quit;

proc means data=regression4; var TotDollars Av_Price;run;


Data Regression5;
set Regression4;
Display_PCut= Av_D*Av_Pcut;
Display_Feat= Av_D*Av_F;
Dis_F_Pcut = Av_Pcut*Av_D*Av_F;
run;

proc reg data= Regression5;
model TotDollars = Av_price Av_Pcut Av_D Av_F Tot_ounce TotUnits Display_PCut Display_Feat Dis_F_Pcut/vif stb;
run;

proc means data=Regression5;
var TotDollars Av_price Av_Pcut Av_D Av_F Tot_ounce TotUnits Display_PCut Display_Feat Dis_F_Pcut;
run;


proc model data=Regression5;
parms b0 b1 b2 b3 b4 b5 b6 b7 b8 b9;
TotDollars = b0+b1*Av_price+b2*Av_Pcut+ b3*Av_F +b4*Av_D +b5*Display_PCut +b6*Display_Feat +b7*Dis_F_Pcut +b8*TotUnits +b9*TotVol;
fit TotDollars / white out=resid1 outresid;run;

