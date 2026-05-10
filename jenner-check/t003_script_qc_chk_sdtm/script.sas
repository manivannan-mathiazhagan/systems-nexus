/* Caller for QC_CHK_SDTM.sas from this repo.                                  */
/* The original snippet expects a SUPPAE production dataset and a Val_SUPPAE  */
/* validation dataset, both with USUBJID and QNAM columns; it does PROC FREQ */
/* on each (by USUBJID*QNAM), then merges by USUBJID/QNAM and keeps rows     */
/* where the production count differs from the validation count.            */
/* The OUT= rename was hoisted into a follow-on rename DATA step for         */
/* portability; the macro variable substitutions and merge body are verbatim.*/

/* Production-side SUPPAE (one row per QNAM/USUBJID pair); duplicate QNAM   */
/* allowed for some subjects to make the FREQ counts informative.            */
data SUPPAE;
    length USUBJID $11 QNAM $8 QVAL $20;
    input USUBJID $ QNAM $ QVAL $;
    datalines;
SUBJ-001 AESEV    MILD
SUBJ-001 AESEV    MILD
SUBJ-001 AERELN   POSSIBLE
SUBJ-002 AESEV    MODERATE
SUBJ-002 AERELN   PROBABLE
SUBJ-002 AERELN   PROBABLE
;
run;

/* Validation-side Val_SUPPAE (independent re-derivation) */
data Val_SUPPAE;
    length USUBJID $11 QNAM $8 QVAL $20;
    input USUBJID $ QNAM $ QVAL $;
    datalines;
SUBJ-001 AESEV    MILD
SUBJ-001 AESEV    MILD
SUBJ-001 AERELN   POSSIBLE
SUBJ-001 AERELN   POSSIBLE
SUBJ-002 AESEV    MODERATE
SUBJ-002 AERELN   PROBABLE
;
run;

/* === body of QC_CHK_SDTM.sas (verbatim, with libref seap02. resolved to WORK) === */
%let DS1N=SUPPAE;

%let VARS=%str(USUBJID*QNAM);
%let COND=%str( );
%let MRGVARS=%sysfunc(tranwrd(&VARS.,*, ));

%put &DS1N. &VARS. &MRGVARS. ;

/* Frequency of Production dataset */
proc freq data =&DS1N noprint;
    tables &VARS./out=PRO_FRQ_RAW;
    &COND.
run;
data PRO_FRQ;
    set PRO_FRQ_RAW(rename=(COUNT=PROC));
run;

/* Frequency of Validation dataset */
proc freq data =Val_&DS1N. noprint;
    tables &VARS./out=VAL_FRQ_RAW;
    &COND.
run;
data VAL_FRQ;
    set VAL_FRQ_RAW(rename=(COUNT=VALC));
run;

/* Merging and subsetting the records not matching by count */
data CHK;
    merge VAL_FRQ(in=b) PRO_FRQ(in=a) ;
    by &MRGVARS.;
    if PROC ne VALC;
run;

proc print data=CHK noobs;
    title "QC_CHK_SDTM: USUBJID*QNAM keys where production count differs from validation";
    var USUBJID QNAM PROC VALC;
run;
