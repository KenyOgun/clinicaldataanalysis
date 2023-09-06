/* IMPORTING THE EXCEL DEMOGRAPHICS DATA INTO SAS*/
PROC IMPORT OUT=demog 
            DATAFILE= "C:\oncologystudydocs\demog.xls" 
            DBMS=EXCEL REPLACE;
     RANGE="demog$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
/* VERIFYING CONTENTS OF THE DEMOG DATASET*/
proc contents data = work.demog;
run;

/* DERIVING THE AGE VARIABLE*/

data demog1;
	set demog;
	format dob2 date9.;
/*creating a new variable for date of birth*/
/* using the cat function to concatenate month, day and year resulting in dob column*/
/* using compress function to remove trailing spaces resulting in dob1 column*/
/* using input function to convert dob1 into numeric data type resulting in dob2 column*/
/* utilizing format statement to convert dob2 into dates that can be displayed*/
dob = cat(month, '/', day, '/', year);
dob1 = compress(cat(month, '/', day, '/', year));
dob2 = input(dob, mmddyy10.);
/*dob2 can now be used for calculation of age variable since it is numeric and has date 9 format*/
/* calculating age of subjects*/
age = (diagdt - dob2) / 365;
/* adding the third treatment group using explicit output*/
output;
trt = 2;
output;
run;

/* OBTAINING SUMMARY STATISTICS FOR AGE BY TREATMENT GROUP USING PROC MEANS*/
/* we have to obtain the output from proc means in a dataset form, hence the output statement in the proc means procedure;
/* this dataset form is stored in agestats dataset*/
/* this output corresponds to the total number of subjects*/
/* utilizing by statement in proc means to generate summary statistics for each treatment group*/
/* it is necessary to sort demog1 by trt before running the proc means procedure*/
/* the sorted table is seen in demog1_sorted*/
proc sort data = demog1 out = work.demog1_sorted;
by trt;
run;
proc means data = demog1_sorted noprint;
var age;
output out = agestats;
by trt;
run;

/* OBTAINING STATISTICAL PARAMETERS FOR GENDER*/
/* running proc format in order to assign labels to the gender*/
/*creating a new dataset called demog2 with the formatted values*/
proc format;
value genfmt
1 = 'Male'
2 = 'Female'
;
run;

data demog2;
	set demog1;
	sex = put(gender, genfmt.);
run;
/* creating a two dimensional table using proc freq*/
/* putting the results in dataset form into a new table called genderstats*/
proc freq data = demog2 noprint;
table trt*sex / outpct out = genderstats;
run;

/* concatenating the count and percent variables in genderstats*/
data genderstats;
	set genderstats;
	length value $ 10;
	value = cat(count, ' (', round(pct_row, .1), '%)');
run;

/* obtaining statistical parameters for race*/
/* creating format racefmt*/
proc format;
value racefmt
1 = 'White'
2 = 'Black'
3 = 'Hispanic'
4 = 'Asian'
5 = 'Other'
;
run;

data demog3;
	set demog2;
	racec = put(race, racefmt.);
run;

/* obtaining summary statistics for race*/
/* new dataset stored in racestats*/
proc freq data = demog3 noprint;
table trt*racec / outpct out = racestats;
run;

data racestats;
	set racestats;
	value = cat(count, ' (', strip(put(round(pct_row, .1),8.1)),'%)' );
run;

/* stacking all three summary statistics together*/
/* making modifications to agestats, genderstats and racestats before stacking*/
/* for agestats renaming _stat_ variable to stat and converting age variable into the value variable of character type sa
ve in agestats1*/
/* for genderstats rename sex variable to stat, save in genderstats1*/
/* for racestats rename racec variable to stat, save in racestats1*/
data agestats7;
rename _stat_ = stat;
	set agestats;
	if _stat_ = 'N' then value = strip(put(age, 8.));
	else if _stat_ = 'MEAN' then value = strip(put(age, 8.1));
	else if _stat_ = 'STD' then value = strip(put(age, 8.2));
	else if _stat_ = 'MIN' then value = strip(put(age, 8.1));
	else if _stat_ = 'MAX' then value = strip(put(age, 8.1));
	drop _type_ _freq_ age;
run;

data genderstats1;
	set genderstats;
	length value $ 10;
	value = cat(count, ' (', round(pct_row, .1), '%)');
	rename sex = stat;
	drop count percent pct_row pct_col;
run;

data racestats1;
	set racestats;
	length value $ 10;
	value = cat(count, ' (', strip(put(round(pct_row, .1),8.1)),'%)' );
	rename racec = stat;
	drop count percent pct_row pct_col;
run;
/*appending all stats together in new dataset called allstats*/
/* fixing the precision points*/
/* using the length statement to determine the order of the variables*/
data allstats10;
length trt 8 stat $8 value $10;
	set agestats7 genderstats1 racestats1;
run;

proc contents data = work.allstats10;
run;


/* transposing data to bring it to a format consistent with the mock shell*/
/*three columns for the three treatment groups as seen in the mock shell*/
proc sort data = allstats10 out = allstats10_sorted;
by stat;
run;
proc transpose data = allstats10_sorted out = t_allstats10 prefix = _;
var value;
id trt;
by stat;
run;

/* in each of the three datasets agestats7, genderstats1 and racestats1 we will create two new variables*/
/* one called ord to indicate the order in ascending form i.e age, gender race*/
/* the other is the subord to indicate the order within each stat category i.e n, mean, sd, min, max for age, male, female for 
gender etc*/
/*creating a new dataset called agestats8, genderstats2 and racestats2*/
data agestats8;
rename _stat_ = stat;
	set agestats;
	ord=1;
	if _stat_ = 'N' then do; subord=1; value = strip(put(age, 8.)); end;
	else if _stat_ = 'MEAN' then do; subord=2; value = strip(put(age, 8.1)); end;
	else if _stat_ = 'STD' then do; subord=3; value = strip(put(age, 8.2)); end;
	else if _stat_ = 'MIN' then do; subord=4; value = strip(put(age, 8.1));end;
	else if _stat_ = 'MAX' then do; subord=5; value = strip(put(age, 8.1)); end;
	drop _type_ _freq_ age;
run;

data genderstats2;
	set genderstats;
	length value $ 10;
	value = cat(count, ' (', round(pct_row, .1), '%)');
	ord = 2;
	if sex = 'Male' then subord=1;
	else subord = 2;
	rename sex = stat;
	drop count percent pct_row pct_col;
run;

data racestats2;
	set racestats;
	length value $ 10;
	value = cat(count, ' (', strip(put(round(pct_row, .1),8.1)),'%)' );
	ord=3;
	if racec='Asian' then subord=1;
	else if racec='Black' then subord=2;
	else if racec='Hispanic' then subord=3;
	else if racec='White' then subord=4;
	else if racec='Other' then subord=5;
	rename racec = stat;
	drop count percent pct_row pct_col;
run;

/* appending agestats8, genderstats2 and racestats2 to get allstats11*/
data allstats11;
length trt 8 stat $8 value $10;
	set agestats8 genderstats2 racestats2;
run;

/* transposing allstats11 data to bring it to a format consistent with the mock shell*/
/*three columns for the three treatment groups as seen in the mock shell*/
/*final table is t_allstats11*/
proc sort data = allstats11 out = allstats11_sorted;
by ord subord stat;
run;
proc transpose data = allstats11_sorted out = t_allstats11 prefix = _;
var value;
id trt;
by ord subord stat;
run;
