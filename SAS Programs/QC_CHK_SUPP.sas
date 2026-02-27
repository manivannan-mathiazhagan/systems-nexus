/* Checking SUPP Domain Mismatch Count */

%let DS1N=SUPPDM;
%let VARS=%str(QNAM*QLABEL*QORIG*usubjid*idvarval);
%let COND=%str( );
%let MRGVARS=%sysfunc(tranwrd(&VARS.,*, ));

%put &DS1N. &VARS. &MRGVARS. ;

/* Frequency of Production dataset */
proc freq data =sdtm.&DS1N noprint;
    tables &VARS./out=PRO_FRQ(rename =(COUNT=PROC));
    &COND.
run;

/* Frequency of Validation dataset */
proc freq data =VAL_&DS1N noprint;
    tables &VARS./out=VAL_FRQ(rename =(COUNT=VALC));
    &COND.
run;

/* Merging and subsetting the records not matching by count */
data CHK;
    merge PRO_FRQ(in=a) VAL_FRQ(in=b);
    by &MRGVARS.;
    if PROC ne VALC;
run;
