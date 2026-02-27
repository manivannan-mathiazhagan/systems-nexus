***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    raw_issue_export.sas                                                             ***;
***                                                                                                 ***;
*** Purpose:       To create the records with Issues in pinnacle report separately so that issues   ***;
***                can be analysed easily                                                           ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    11Mar2022                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name        | Description                                         | Default value   | Required  ***;
***             |                                                     |                 | Parameter ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** BASEDS      | The Base dataset which needs to be merged with each | No default      |   Yes     ***;
***             | domain dataset with needed variables                |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** BYVAR       | The By variable based on which baseds and each      | No default      |   Yes     ***;
***             | domain dataset has to be merged                     |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** XLS_PATH    | The path where created excel files are to be stored | No default      |   Yes     ***;
***             |                                                     |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** P21_PATH    | The path where pinnacle 21 report is stored         | No default      |   No      ***;
***             |                                                     |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** P21_REPT    | The filename of Pinnacle 21 report with extension   | No default      |   No      ***;
***             |                                                     |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** DEBUG       | Used for debugging - if it is given as Y, the       | N               |   No      ***; 
***             |  intermediate datasets will not be deleted          |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Variables:          None                                                                        ***;
***                                                                                                 ***;
*** Other:              Separate Excel files with subsetted records                                 ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          &BASEDS.                                                                    ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             imp_xlsx  and exp_xls                                                       ***;
***                                                                                                 ***;
*** Other:              None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Limitations                                                                                     ***;
***                                                                                                 ***;
*** Other:              1) As this uses Transpose to get the record numbers and subsetting, there   ***;
***                     are chances that this macro can remove needed macros while subsetting       ***;
***                                                                                                 ***;
***                     2) If need to subset any dataset - add it in taking needed data from Old    ***;
***                     report part like DV/SUPPDV                                                  ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

/*macro for Exporting - records satisfying for SDTM*/
%macro raw_issue_export(BASEDS=,
                        BYVAR=,
                        XLS_PATH=,
                        P21_PATH=,
                        P21_REPT=,
                        DEBUG=N);

/* Importing Pinnacle report*/
%imp_xlsx(fname=&P21_PATH.\&P21_REPT.,sheet=Details,outlib=WORK);

%imp_xlsx(fname=&P21_PATH.\&P21_REPT.,sheet=Issue Summary,outlib=WORK);

/*Taking needed data from Old report*/
data P21_REPRT;
    set DETAILS;
    if RECORD ne .
    and DOMAIN not in ( "TA" "TE" "TI" "TS" "TV" )

/*    and DOMAIN  in ( "DV" "SUPPDV" )*/
    ;
    MESSAGE = tranwrd(tranwrd(tranwrd(tranwrd(tranwrd(tranwrd(tranwrd(compbl(strip(MESSAGE)),"'","_"),",","_"),"-","_"),".","_"),"/","_")," ","_"),"=","_") ;
    keep DOMAIN RECORD PINNACLE_21_ID MESSAGE;
run;

proc sort data = P21_REPRT ;
    by DOMAIN PINNACLE_21_ID MESSAGE RECORD;
run;

/* Transposing to get record numbers */
proc transpose data = P21_REPRT out= P21_Issues;
    by DOMAIN PINNACLE_21_ID MESSAGE;
    var RECORD;
run;

data _NULL_;
    set P21_ISSUES;
    array INCOL[*] COL:;
    call symputx ("IN_DIM", dim(INCOL));
run;

%put &IN_DIM.;

data P21_ISSUES_1;
    length OVER $10000.;
    set P21_ISSUES;
    array INCOL[*] COL:;
    array OUTCOL[&IN_DIM.] $100 SCOL1-SCOL&IN_DIM.;

    do i = 1 to dim(INCOL);

        if not missing(INCOL[i]) then OUTCOL[i] = strip(put(INCOL[i],best.));
        else OUTCOL[i] = "";
    end;

    OVER = catx(",", of SCOL:);
    NUM = _n_;

    call symputx("DATS"||strip(put(NUM,best.)),DOMAIN);
    call symputx("ID"||strip(put(NUM,best.)),PINNACLE_21_ID);
    call symputx("NME"||strip(put(NUM,best.)),MESSAGE);
    call symputx("ROWS"||strip(put(NUM,best.)),OVER);

    keep DOMAIN PINNACLE_21_ID OVER;
run;

%let ISSUE_COUNT =&SYSNOBS.;

%put &ISSUE_COUNT. ;

    %do index = 1 %to &ISSUE_COUNT;

        %let DOMAIN =&&DATS&index..;
        %let ISS_ID = &&ID&index..;
        %let NME_MES = %bquote(&&NME&index..);
        %let SUBS_ROWN=%bquote(&&ROWS&index..);

        data &DOMAIN.;
            set SDTM.&DOMAIN;
            ROW = _n_;
        run;

        %if "&BASEDS." ne "" %then
            %do;

                proc sort data = &DOMAIN.;
                    by &BYVAR.;
                run;

                proc sort data = &BASEDS.;
                    by &BYVAR.;
                run;

                data &DOMAIN._&ISS_ID.;
                    merge &DOMAIN.(in=a) &BASEDS.;
                    by &BYVAR.;
                    if a;
                    if ROW in ( &SUBS_ROWN. );
                run;

            %end;

        %else
            %do;

                data &DOMAIN._&ISS_ID.;
                    set &DOMAIN.;
                    if ROW in ( &SUBS_ROWN. );
                run;

            %end;

        %exp_xls(&DOMAIN._&ISS_ID.,&XLS_PATH.\&DOMAIN._&NME_MES..xlsx);

        proc datasets lib=work nolist;
            delete &DOMAIN._&ISS_ID.;
            quit;
        run;
    %end;

/*Deleting Intermediate datasets created*/
%if "&DEBUG." ne "Y" %then
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete P21_ISSUES P21_ISSUES_1 P21_REPRT DETAILS;
            quit;
        run;
    %end;
    
%mend raw_issue_export;

/* Generating needed base dataset */
/*library and environment assignment for v20210628_pooled folders*/
/*%setenv(sponsor=Paidion,study=BBN-IF-001 (3rd Arm),dbver2=raw_v20211112_pooled\sdtm_v20211112_pooled\adam_v20211112_pooled);*/

proc datasets library=WORK memtype = data kill noprint;
quit;

%SUPP2PARENT(PARENT=DM);

data APHASE;
    merge DMFULL(keep = USUBJID PHASE RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFPENDTC RFICDTC) ADAM.ADSL(keep = USUBJID DCSREAS EOSDTC);
    by USUBJID;
run;

%raw_issue_export(BASEDS=APHASE,
                  BYVAR=USUBJID,
                  XLS_PATH=%nrquote(E:\Projects\Paidion\BBN-IF-001 (3rd Arm)\SASDATA\raw_v20211208_pooled\sdtm_v20220110_pooled\Pinnacle report\Raw issues new),
                  P21_PATH=%nrquote(E:\Projects\Paidion\BBN-IF-001 (3rd Arm)\SASDATA\raw_v20211208_pooled\sdtm_v20220110_pooled\Pinnacle report),
                  P21_REPT=%nrquote(pinnacle21-report-2022-01-10T00-11-13-496.xlsx));

