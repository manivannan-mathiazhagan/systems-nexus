/* Caller for QC_CHK_TAB.sas from this repo.                                    */
/* The original snippet expects two work datasets PROD and VALI each with a    */
/* one-column key named _1; it does PROC FREQ on each, then merges by _1 and  */
/* keeps rows where the production count differs from the validation count.   */
/* This bundle stands in two small inline datasets so the script body itself  */
/* runs without any external libraries. The PROC FREQ OUT= rename was hoisted */
/* into a follow-on rename data step for portability; the merge body is        */
/* otherwise verbatim.                                                         */

/* Production-side counts (e.g. from a derived ADaM dataset) */
data PROD;
    length _1 $5;
    input _1 $;
    datalines;
A
A
A
B
B
C
D
D
D
;
run;

/* Validation-side counts (independent re-derivation) */
data VALI;
    length _1 $5;
    input _1 $;
    datalines;
A
A
A
B
B
B
C
D
D
;
run;

/* === body of QC_CHK_TAB.sas (verbatim where possible) === */
/* Frequency of Production dataset */
proc freq data =PROD noprint;
    tables _1/out=PRO_FRQ_RAW;
run;
data PRO_FRQ;
    set PRO_FRQ_RAW(rename=(COUNT=PROC));
run;

/* Frequency of Validation dataset */
proc freq data =VALI noprint;
    tables _1/out=VAL_FRQ_RAW;
run;
data VAL_FRQ;
    set VAL_FRQ_RAW(rename=(COUNT=VALC));
run;

/* Merging and subsetting the records not matching by count */
data CHK;
    merge PRO_FRQ(in=a) VAL_FRQ(in=b);
    by _1;

    if PROC ne VALC;
run;

proc print data=CHK noobs;
    title "QC_CHK_TAB: keys where Production count differs from Validation count";
    var _1 PROC VALC;
run;
