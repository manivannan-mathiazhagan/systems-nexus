
/* Frequency of Production dataset */
proc freq data =PROD noprint;
    tables _1/out=PRO_FRQ(rename =(COUNT=PROC));
run;

/* Frequency of Validation dataset */
proc freq data =VALI noprint;
    tables _1/out=VAL_FRQ(rename =(COUNT=VALC));
run;

/* Merging and subsetting the records not matching by count */
data CHK;
    merge PRO_FRQ(in=a) VAL_FRQ(in=b);
    by _1;
    
    if PROC ne VALC;
run;



