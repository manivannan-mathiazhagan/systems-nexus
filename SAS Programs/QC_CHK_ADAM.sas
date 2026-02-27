/* Checking SDTM Domain Mismatches - count */

%let DS1N=adqs;
%let VARS=%str(usubjid*paramn*paramcd*param);
/*%let VARS=%str(paramcd*param);*/
/*%let VARS=%str(parcat1n*parcat1*PARCAT2N*PARCAT2*PARAMN*paramcd*param*avisitn*usubjid*paramtyp);*/
/*%let VARS=%str(parcat1n*parcat1);*/
%let COND=%str(   );
/*%let COND=%str( );*/
%let MRGVARS=%sysfunc(tranwrd(&VARS.,*, ));

%put &DS1N. &VARS. &MRGVARS. ;

/* Frequency of Production dataset */
proc freq data =adam.&ds1n. noprint;
    tables &VARS./out=PRO_FRQ(rename =(COUNT=PROC));
    &COND.
run;

/* Frequency of Validation dataset */
proc freq data =val_&ds1n. noprint;
    tables &VARS./out=VAL_FRQ(rename =(COUNT=VALC));
    &COND. 
run;

/* Merging and subsetting the records not matching by count */
data CHK;
    LENGTH PARAM PARAMCD $400.;
    merge PRO_FRQ(in=a) VAL_FRQ(in=b);
    by &MRGVARS.;
    
    if PROC ne VALC;
run;



