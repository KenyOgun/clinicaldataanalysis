/*code for importing data from the excel sheet into SAS session*/
FILENAME REFFILE 'C:\oncologystudydocs\demog.xls';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLS
	OUT=WORK.DEMOG;
	GETNAMES=YES;
RUN;

/*Section 1: Summary stats for age*/

data demog1;
	set demog;
	format dob1 date9.;
	/*creating a new variable for date of birth*/
	
	dob=compress(cat(month,'/', day,'/', year));
	dob1= input(dob, mmddyy10.);
	
	/*calculating the age of patients*/
	
	age = (diagdt-dob1)/365;
	
	output;
	trt=2;
	output;
run;

/*evaluating the statistical parameters for age */

proc sort data=demog1;
by trt;
run;

proc means data =demog1 noprint;
var age;
output out = agestats;
by trt;
run;

data agestats;
	set agestats;
	length value $10.;
	ord= 1;
	if _stat_ = 'N' then do; subord=1; value = strip(put(age, 8.));end;
	else if _stat_='MEAN' then do; subord =2; value =strip(put(age, 8.1));end;
	else if _stat_='STD' then do; subord=3; value = strip(put(age,8.2));end;
	else if _stat_ ='MIN' then do; subord=4; value =strip(put(age, 8.1));end;
	else if _stat_ ='MAX' then do; subord = 5; value =strip(put(age, 8.1));end;
	
	
	rename _stat_= stat;
	drop _type_ _freq_ age;
	
run;


/* obtaining the statistical parameters for gender*/

proc format;
value genfmt
1='Male'
2='Female'
;
run;

data demog2;
	set demog1;
	sex = put(gender, genfmt.);
run;

proc freq data=demog2 noprint ;
table trt*sex / outpct out = genderstats;

run;


data genderstats;
	set genderstats;
	value = cat(count, ' (', strip(put(round(pct_row,.1),8.1)),'%)');
	ord =2;
	if sex = 'Male' then subord=1;
	else subord = 2;
	
rename sex= stat;
drop count percent pct_col pct_row;
run;

/*obtain statistical parameters for race*/
proc format;
value racefmt
1='White'
2='Black'
3='Hispanic'
4='Asian'
5='Other'
;
run;

data demog3;
	set demog2;
	racec = put(race, racefmt.);
run;

proc freq data= demog3 noprint;
table trt*racec  / outpct out = racestats;
run;

data racestats;
	set racestats;
	value = cat(count, ' (', strip(put(round(pct_row,.1),8.1)), '%)');
	ord =3;
	if racec='Asian' then subord =1;
	else if racec='Black' then subord=2;
	else if racec='Hispanic' then subord=3;
	else if racec='White' then subord=4;
	else if racec='Other' then subord=5;
rename racec = stat;
drop count percent pct_row pct_col; 
run;

/*appending all stats together*/
data allstats;
	set agestats genderstats racestats;
run;

/*transposing data by treatment groups*/

proc sort data = allstats;
by ord subord stat;
run;

proc transpose data =allstats out =t_allstats;
var value;
id trt;
by ord subord stat; 
run;

data final;
length stat $30.;
	 set t_allstats;
	 by ord subord;
	 output;
	 if first.ord then do;
	 	if ord=1 then stat='Age (years)';
	 	if ord =2 then stat = 'Gender';
	 	if ord=3 then stat = 'Race';
	 	subord=0;
	 	_0='';
	 	_1='';
	 	_2='';
	 output;
	 end;
	 run;
	 
proc sort data=final;
by ord subord;
run;
	 
proc sql noprint;
select count(*) into :placebo from demog1 where trt=0;
select count(*) into :active from demog1 where trt=1;
select count(*) into :total from demog1 where trt=2;
quit;

/*removing the leading space in each macro variable*/
%let placebo =&placebo;
%let active =&active;
%let total = &total;

/*constructing the final report*/
ODS RTF FILE = 'c:\MyRTFFiles\t_demog.rtf' BODYTITLE STARTPAGE = NO;
title 'Table 1.1';
title2 'Demographic and Baseline Characteristics by Treatment Group';
title3 'Randomized Population';
footnote 'Note: Percentages are based on the number of non-missing values in each treatment group.';

proc report data = final split ='|';
columns ord subord stat _0 _1 _2;
define ord/ noprint order;
define subord/ noprint order;
define stat / display width =50 "" ;
define _0 / display width =30 "Placebo| (N=&placebo)";
define _1/ display width =30 "Active Treatment| (N=&active)";
define _2 / display width =30 "All Patients| (N=&total)";
run;
ODS RTF CLOSE;
title;
footnote;
