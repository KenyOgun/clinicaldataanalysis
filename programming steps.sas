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
proc means data = demog1_sorted;
var age;
output out = agestats;
by trt;
run;
