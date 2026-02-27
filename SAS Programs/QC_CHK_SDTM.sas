/* Checking SDTM Domain Mismatches - count */

%let DS1N=SUPPAE;

%let VARS=%str(USUBJID*QNAM);
%let COND=%str( );
%let MRGVARS=%sysfunc(tranwrd(&VARS.,*, ));

%put &DS1N. &VARS. &MRGVARS. ;

/* Frequency of Production dataset */
proc freq data =seap02.&DS1N noprint; tables &VARS./out=PRO_FRQ(rename =(COUNT=PROC));
    &COND.
run;

/* Frequency of Validation dataset */
proc freq data =Val_&DS1N. noprint; tables &VARS./out=VAL_FRQ(rename =(COUNT=VALC));
    &COND.
run;

/* Merging and subsetting the records not matching by count */
data CHK;merge VAL_FRQ(in=b) PRO_FRQ(in=a) ;by &MRGVARS.; if PROC ne VALC;
run;



