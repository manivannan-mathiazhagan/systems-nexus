***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    compare_P21.sas                                                                  ***;
***                                                                                                 ***;
*** Purpose:       Compare two Pinnacle 21 reports and generate a summary in an Excel file          ***;
***                Comparison 1 -  Newly added issues which are not present in Old report           ***;
***                Comparison 2 -  Resolved issues which are not present in New report              ***;
***                Comparison 3 -  issues which are not present in both reports                     ***;
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
*** P21_PATH    | The path where both the Pinnacle 21 report files    | No default      |   Yes     ***;
***             | are stored e.g: E:\Projects\Reports                 |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** OLD_FILE    | The Old Pinnacle 21 report XLSX filename            | No default      |   Yes     ***;
***             | e.g: pinnacle21-report-2021-06-29T23-22-13-417.xlsx |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** NEW_FILE    | The New Pinnacle 21 report XLSX filename            | No default      |   Yes     ***;
***             | e.g: pinnacle21-report-2021-06-29T23-22-13-417.xlsx |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** COMM_COL    | The Name of comments Column if added in Old report  | No default      |   No      ***;
***             | It can be merged to new report and shown in         |                 |           ***;
***             | Comparison 3 sheet                                  |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** DEBUG       | Used for debugging - if it is given as Y, the       | No default      |   No      ***; 
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
*** Other:              Comparison_Report.xlsx file with three sheets and Compared results          ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             imp_xlsx                                                                    ***;
***                                                                                                 ***;
*** Other:              The two report files should be in same location and the report will also    ***;
***                     stored in the same location                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%macro compare_P21(P21_PATH=,OLD_FILE=,NEW_FILE=,COMM_COL=,DEBUG=N);

/* because Excel field names often have spaces */
options validvarname=any;

/* Importing Old report*/
%imp_xlsx(fname=&P21_PATH.\&OLD_FILE.,sheet=Issue Summary,outlib=WORK,hdrrow=4,datarow=5);

/*Taking needed data from Old report*/
data OLD(rename = (Found = Found_Old ));
    retain Domain Message Found;
    set ISSUE_SUMMARY;
    retain Domain;
    if Source ne "" then Domain = Source;
    else Domain = Domain;
    
    if Message ne "";
    keep Domain Message Found &COMM_COL.;
run;

proc sort data = OLD;
    by Domain Message;
run;

/* Importing New report*/
%imp_xlsx(fname=&P21_PATH.\&NEW_FILE.,sheet=Issue Summary,outlib=WORK,hdrrow=4,datarow=5);

/*Taking needed data from New report*/
data NEW(rename = (Found = Found_New ));
    retain Domain Message Found;
    set ISSUE_SUMMARY;
    retain Domain;
    if Source ne "" then Domain = Source;
    else Domain = Domain;

    if Message ne "";
    keep Domain Message Found;
run;

proc sort data = NEW;
    by Domain Message;
run;

/* Comparison 1 - Newly added issues in New Report */
data COMP_1(rename = ( Found_new =Found));
    merge NEW(in=a) OLD(in=b);
    by Domain Message;
    if a and not b;
    keep Domain Message Found_new;
run;

/* Comparison 2 - Resolved issues from Old Report */
data COMP_2(rename = ( Found_old =Found));
    merge NEW(in=a) OLD(in=b);
    by Domain Message;
    if b and not a;
    drop Found_new;
run;

/* Comparison 3 - Unresolved issues present in both Reports */
data COMP_3;
    merge NEW(in=a) OLD(in=b);
    by Domain Message;
    if a and b;

         if Found_new gt Found_Old then Status = "Increased";
    else if Found_new lt Found_Old then Status = "Decreased";
    else if Found_new eq Found_Old then Status = "No Change";

run;

/*ods noresults;*/

/*generating the Report file*/
ods excel file="&P21_PATH.\Comparison_Report.xlsx" 
    options (embedded_titles="YES" frozen_headers= "ON");
    
    ods excel options(sheet_name="Comparison 1");
    title1 "Comparison between two files present in &P21_PATH." ;
    title3 "Old Report - &OLD_FILE" ;
    title4 "New Report - &NEW_FILE" ; 
    title6 "Newly added issues in New Report" ; 
    proc print data=COMP_1 noobs ;
    run;

    ods excel options(sheet_name="Comparison 2");

    title6 "Resolved issues from Old Report" ; 
    proc print data=COMP_2 noobs ;
    run;

    ods excel options(sheet_name="Comparison 3");

    title6 "Unresolved issues - Present in both Reports" ; 
    proc print data=COMP_3 noobs ;
    run;

ods excel close;

/*ods results;*/

/*Deleting Intermediate datasets created*/
%if "&DEBUG." ne "Y" %then
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete OLD NEW COMP_1 COMP_2 COMP_3;
            quit;
        run;
    %end;
    
%mend compare_P21;

/* %compare_P21(P21_PATH=%nrquote(E:\Projects\Paidion\BBN-IF-001 (3rd Arm)\SASDATA\raw_v20210628_pooled\sdtm_v20210628_pooled\Pinnacle Reports), */
             /* OLD_FILE=%nrquote(pinnacle21-report-2021-08-18T07-07-34-459.xlsx), */
             /* NEW_FILE=%nrquote(pinnacle21-report-2021-08-18T21-59-59-084.xlsx), */
             /* COMM_COL=%nrquote(Comments)); */
