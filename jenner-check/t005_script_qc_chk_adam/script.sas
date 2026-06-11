/* Caller for QC_CHK_ADAM.sas from this repo (first half).                     */
/* Same dual-FREQ + merge pattern as QC_CHK_TAB but with the dataset name and */
/* libref carried in macro variables (DS1N=rt_lb_abnorm_mets_vis, libref      */
/* VTDATA. for Production and VTVAL. for Validation, both resolved to WORK    */
/* in this bundle).                                                            */

/* Production-side rt_lb_abnorm_mets_vis with a single key column */
data rt_lb_abnorm_mets_vis;
    length _1 $20;
    input _1 $;
    datalines;
WBC_LOW
WBC_LOW
WBC_HIGH
ALT_HIGH
ALT_HIGH
ALT_HIGH
;
run;

/* Validation re-derivation of the same checks - one extra WBC_HIGH */
data rt_lb_abnorm_mets_vis_v;
    length _1 $20;
    input _1 $;
    datalines;
WBC_LOW
WBC_LOW
WBC_HIGH
WBC_HIGH
ALT_HIGH
ALT_HIGH
ALT_HIGH
;
run;

/* === body of QC_CHK_ADAM.sas (verbatim, with VTDATA./VTVAL. resolved to WORK */
/* and the OUT= rename hoisted into a follow-on DATA step rename).          */
%let DS1N      = rt_lb_abnorm_mets_vis;
%let VARS      = %str(_1);
%let COND      = %str(   );
%let MRGVARS   = %sysfunc(tranwrd(&VARS.,*, ));

%put &DS1N. &VARS. &MRGVARS. ;

/* Frequency of Production dataset */
proc freq data =&DS1N. noprint;
    tables &VARS./out=PRO_FRQ_RAW;
    &COND.
run;
data PRO_FRQ;
    set PRO_FRQ_RAW(rename=(COUNT=PROC));
run;

/* Frequency of Validation dataset */
proc freq data =&DS1N._v noprint;
    tables &VARS./out=VAL_FRQ_RAW;
    &COND.
run;
data VAL_FRQ;
    set VAL_FRQ_RAW(rename=(COUNT=VALC));
run;

/* Merging and subsetting the records not matching by count */
data CHK;
    merge PRO_FRQ(in=a) VAL_FRQ(in=b);
    by &MRGVARS.;
    if PROC ne VALC;
run;

proc print data=CHK noobs;
    title "QC_CHK_ADAM (rt_lb_abnorm_mets_vis): keys with count mismatch";
    var _1 PROC VALC;
run;
