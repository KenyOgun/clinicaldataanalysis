/* IMPORTING THE EXCEL DEMOGRAPHICS DATA INTO SAS*/

PROC IMPORT OUT= WORK.demog 
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
proc contents data = work.demog1;
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
data agestats1;
	set agestats;
	value = put(age, 8.);
	rename _stat_ = stat;
	drop _type_ _freq_ age;
run;

data genderstats1;
	set genderstats;
	value = cat(count, ' (', round(pct_row, .1), '%)');
	rename sex = stat;
	drop count percent pct_row pct_col;
run;

data racestats1;
	set racestats;
	value = cat(count, ' (', strip(put(round(pct_row, .1),8.1)),'%)' );
	rename racec = stat;
	drop count percent pct_row pct_col;
run;

/*appending all stats together in new dataset called allstats*/
data allstats;
	set agestats1 genderstats1 racestats1;
run;





