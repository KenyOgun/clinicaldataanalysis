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
