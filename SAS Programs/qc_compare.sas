***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_compare.sas                                                                   ***;
***                                                                                                 ***;
*** Purpose:       Create a summary of Comparison and Raise Note/warning in Log                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    08Mar2023                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** basein   |  Base dataset                                          |     BASE        |   Yes     ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** compin   |  Compare dataset                                       |     COMP        |   Yes     ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** difname  |  Name of Domain or Table or Listing - Used for         |    No default   |   Yes     ***;
***          |  creating the file name and displayed in Summary       |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** criterion| Value to use as criterion option if needed             |    No default   |   No      ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** difpath  | Path of folder where diff files will be written        |   See in        |  Yes      ***;
***          |  Default Value - &droot\&dbpath\Compare                |   Description   |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Variables:          None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Macro Variables:    unote, uwarn - Used for raising User Note or User Warning in Log            ***;
***                                                                                                 ***;
*** Macros:             None                                                                        ***;
***                                                                                                 ***;
*** Other:              None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
%macro qc_compare(basein=BASE, compin=COMP, difname=, criterion=, difpath=&droot&dbpath\Compare);

/*Step 01: - Time Stamp Information in title */
%local runtime ;

data _null_;
    length RUNTIME $20;
    RUNTIME = strip(put(datetime(),datetime20.));
    call symput('runtime',RUNTIME);
run;

%put runtime=&runtime.;;

options nosource nonotes;

/*Stpe 02: - Use Criterion option if a value has been passed */
%if %length(&criterion) ^= 0 %then 
    %do;
        %let criterion = CRITERION=%sysfunc(tranwrd(%upcase(&criterion), %str(CRITERION=), %str()));
    %end;

%if %sysfunc(exist(&COMPIN.)) %then 
    %do;
        proc sql noprint;
            select count(*) into: VAL_COUNT from &COMPIN.;
        quit;
   %end;
   %else %do;
      %let VAL_COUNT=0;
   %end;


%if %sysfunc(exist(&BASEIN.)) %then 
    %do;
        proc sql noprint;
            select count(*) into: PRO_COUNT from &BASEIN.;
        quit;
   %end;
   %else %do;
      %let PRO_COUNT=0;
   %end;


%if &VAL_COUNT. gt 0 and &PRO_COUNT. gt 0 %then 
    %do;
        
        /* Step 03: - Comparison of Variable and Attributes - For Raising Notes / Warning in Log*/
        proc compare base=&BASEIN comp=&COMPIN out=DIF 
            outbase outcomp outdif outnoequal warning noprint &criterion;     
        run;

        %let NUMB_DIFF=&sysnobs.;

        %if &NUMB_DIFF=0 %then 
            %do;
                %put &unote. NO DIFFERENCES FOUND IN &difname;
                %let QC_STAT =PASS; 
            %end;
        %else
            %do;
                %put &uwarn. DIFFERENCES FOUND IN &difname, PLEASE REVIEW.;
                %let QC_STAT =FAIL; 
            %end;

        /* Step 04: - Comparison and Generation of Report*/
        
        title; 
        footnote;

        options nodate nonumber;
        ods results= off;
        ods pdf file ="&difpath.\&difname._COMP.pdf" ;

        title  color = blue "&difname.";
        title3 color = blue "Validation performed on &runtime.";

        %if "&QC_STAT." eq "PASS" %then 
            %do;
                title5 color = green "QC Status: PASS";
            %end;
        %else %if "&QC_STAT." eq "FAIL" %then 
            %do;
                title5 color = red "QC Status: FAIL";
            %end;

        proc compare base=&BASEIN comp=&COMPIN out=DIF listall &criterion;     
        run;

        ods pdf close; 
        title; 
        footnote;
        ods results= on;
        options date number;
    %end;
%else
    %do;
        %put &unote. No Observations present in Input datasets, &difname. Comparison is not performed ; 
    %end;
    
options source notes;
%mend qc_compare;




