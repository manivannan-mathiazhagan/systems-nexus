***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_sdtm_attrib.sas                                                               ***;
***                                                                                                 ***;
*** Purpose:       Adds domain level attributes to dataset based on SDTM specification(gdoc)        ***;
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
*** SDTM_DS  | Name of SDTM domain                                    | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** IN_DATA  | the name of INPUT dataset                              | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** OUTSET   | the name of OUTPUT dataset                             | VAL_&SDTM_DS.   |   No      ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          | N               |   No      ***; 
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &OUTSET.                                                                    ***;
***                                                                                                 ***;
*** Variables:          None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          P21_SD32.SD33_DATASETS and P21_SD33.SD33_VARIABLES                          ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             qc_reduce_length                                                            ***;
***                                                                                                 ***;
*** Other:              The respective domain sheet in gdoc should have Keep column filled with 1   ***;
***                     for the variables to be kept and Type chould be either Char or Num only     ***;
***-------------------------------------------------------------------------------------------------***;

%macro qc_sdtm_attrib(SDTM_DS=,
                   IN_DATA=,
                   OUTSET=,
                   DEBUG=N);

%let SDT_NME=%sysfunc(compress(%sysfunc(tranwrd(&SDTM_VERSN.,., ))));

options validvarname=V7;

%if "&OUTSET." eq  "" %then 
    %do;
        %let OUTSET=VAL_&SDTM_DS.;
    %end;

%if %index(&SDTM_DS.,SUPP) eq 0 %then 
    %do;
        /* Subsetting the Specs for respective Parent domain*/
        data ___SPEC_&SDTM_DS.;
            set P21_SPEC.SD&SDT_NME._VARIABLES;
            where DATASET eq upcase("&SDTM_DS.");
        run;

        data _NULL_;
            set P21_SPEC.SD&SDT_NME._DATASETS;
            where DATASET eq upcase("&SDTM_DS.");

            call symput("DSETLAB", trim(compbl(LABEL)));
        run;
%end;
%else 
    %do;
        /* Subsetting the Specs for SUPPQUAL domain*/
        data ___SPEC_&SDTM_DS.;
            set P21_SPEC.SD&SDT_NME._VARIABLES;
            where DATASET eq "SUPPQUAL";
        run;
        
        %let PAR_DS=%substr(&SDTM_DS.,5,2);
        
        data _NULL_;
            length LABEL $200.;
            LABEL = "Supplemental Qualifiers for &PAR_DS.";
            call symput("DSETLAB", trim(compbl(LABEL)));
        run;
    %end;

/*Finding the list of matching variables kept in Input dataset and Specs*/
proc sql noprint;
    create table 
    ___SPEC_INPUT_VAR as 
    select NAME,1 as KEEP 
    from SASHELP.VCOLUMN 
    where LIBNAME eq "WORK" and MEMNAME eq upcase("&IN_DATA.");

    create table ___SPEC_MATCH as 
    select a.*, b.keep from 
    ___SPEC_&SDTM_DS. a left join ___SPEC_INPUT_VAR b on a.VARIABLE eq b.NAME;
quit;

*************************;
*** Subset for domain ***;
*************************;
data ___SPEC_TAB1 (keep =  LABEL VARIABLE ORDER DATA_TYPE rename = ( VARIABLE = NAME DATA_TYPE= TYPE));
    set ___SPEC_MATCH;
    where KEEP eq 1 ;
run;

proc sort data=___SPEC_TAB1 out=___SPEC_TAB2;
    by  ORDER;
run;

/*Checking if Required (Mandatory) Variables are not present*/
data ___SPEC_MAND (keep =  LABEL VARIABLE ORDER DATA_TYPE rename = ( VARIABLE = NAME DATA_TYPE= TYPE));
    set ___SPEC_MATCH;
    where KEEP eq . and upcase(strip(MANDATORY)) eq "YES" ;
    put "WARN" "ING: Mandatory variable of Domain " Dataset "- " Variable " is not present in &IN_DATA." ;
run;

*** Define variable attributes (name, label, type, length) ***;
data ___SPEC_ATTRIB;
    length STRING_ VARS_ $1000;
    retain VARS_;
    set ___SPEC_TAB2 end=eof;

    if upcase(TYPE) in("CHAR", "TEXT" "DATETIME" "DATE") then
        do;
             STRING_ = "attrib " || trim(left(NAME)) || " label='" || trim(left(LABEL)) || "' length=$200";
        end;
    else if upcase(TYPE) in("NUM", "INTEGER", "FLOAT") then
        do;
             STRING_ = "attrib " || trim(left(NAME)) || " label='" || trim(left(LABEL)) || "' length=8";
        end;

    call symput("ATT_" || compress(put(_N_, best.)), STRING_);

    *call symput("ATT_" || compress(put(order, best.)), string_);
    if _N_=1 then
        VARS_ = compress(NAME);
    else VARS_ = trim(left(VARS_)) || " " || compress(NAME);

    if EOF then
        do;
            call symput("COUNTTO", put(_N_, best.));
            call symput("KEEPVAR", VARS_);
        end;
run;
    
%qc_reduce_length(&IN_DATA.);

*** Assign attributes ***;
data &OUTSET. (keep = &KEEPVAR. label="&DSETLAB." );
    retain &KEEPVAR. ;
    %do ii = 1 %to &COUNTTO.;
        &&ATT_&ii..;
    %end;

    set &IN_DATA.;
    informat _all_;
    format _all_;
run;

%qc_reduce_length(&OUTSET.);

data &OUTSET.(label="&DSETLAB." );
    set &OUTSET.;
run;

/*Deleting Intermediate datasets created*/
%if "&DEBUG." ne "Y" %then
%do;
    /*Deleting Intermediate datasets created*/
    proc datasets lib=work nolist;
        delete ___SPEC_: ;
        quit;
    run;
%end;
    
%mend qc_SDTM_ATTRIB;
