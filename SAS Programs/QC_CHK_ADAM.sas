/* Checking Datasets Mismatches - count */

%let DS1N		=	rt_lb_abnorm_mets_vis;
%let VARS		=	%str(_1);
%let COND		=	%str(   );
%let MRGVARS	=	%sysfunc(tranwrd(&VARS.,*, ));

%put &DS1N. &VARS. &MRGVARS. ;

/* Frequency of Production dataset */
proc freq data =VTDATA.&DS1N. noprint;
    tables &VARS./out=PRO_FRQ(rename =(COUNT=PROC));
    &COND.
run;

/* Frequency of Validation dataset */
proc freq data =VTVAL.&DS1N. noprint;
    tables &VARS./out=VAL_FRQ(rename =(COUNT=VALC));
    &COND. 
run;

/* Merging and subsetting the records not matching by count */
data CHK;
    merge PRO_FRQ(in=a) VAL_FRQ(in=b);
    by &MRGVARS.;
    if PROC ne VALC;
run;



