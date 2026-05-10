/* Caller for the qc_assign_seq macro from this repo.                            */
/* The macro re-sorts an SDTM-style domain by user-specified key variables,      */
/* then assigns a 1-based sequence number that resets at each new USUBJID.       */
/* The new variable is named &DMAIN.SEQ (e.g. AESEQ for the AE domain).         */

/* === macro under test (verbatim from SAS Programs/qc_assign_seq.sas) === */
%macro qc_assign_seq(DMAIN=,
                  INDSET=,
                  OUTDSET=,
                  SORT_ORD=);

/*Sorting the Dataset based on the Order from Specs*/
proc sort data = &INDSET. ;
    by &SORT_ORD.;
run;

/*Assigning SEQ*/
data &OUTDSET.;
    set &INDSET.;
    by &SORT_ORD.;

    if first.USUBJID then SEQ = 1;
    else SEQ + 1;

    &DMAIN.SEQ = SEQ;

    drop SEQ;

run;

%mend qc_assign_seq;

/* === small AE-style domain that exercises the macro === */
/* deliberately fed in non-key order so the PROC SORT inside the macro      */
/* has something to do; two subjects, several events each.                  */
data ae_in;
    length USUBJID $11 AETERM $20 AESTDTC $10;
    input USUBJID $ AETERM $ AESTDTC $;
    datalines;
SUBJ-002 NAUSEA 2023-04-08
SUBJ-001 HEADACHE 2023-03-22
SUBJ-001 FATIGUE 2023-03-10
SUBJ-002 RASH 2023-04-01
SUBJ-001 NAUSEA 2023-03-15
SUBJ-002 HEADACHE 2023-04-05
;
run;

%qc_assign_seq(DMAIN=AE,
               INDSET=ae_in,
               OUTDSET=ae_out,
               SORT_ORD=USUBJID AESTDTC AETERM);

proc print data=ae_out noobs;
    title "qc_assign_seq: AESEQ resets at each new USUBJID, increments within";
    var USUBJID AESTDTC AETERM AESEQ;
run;
