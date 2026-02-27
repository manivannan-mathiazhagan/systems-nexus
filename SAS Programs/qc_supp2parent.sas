***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_supp2parent.sas                                                               ***;
***                                                                                                 ***;
*** Purpose:       Transpose SUPP dataset and merge with PARENT dataset                             ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    11Mar2022                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** INLIB    | Name of Library where SUPP and Parent datasets are     | SDTM            |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** PARENT   | the name of parent dataset                             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          |     N           |   No      ***; 
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &PARENT.FULL - ex: if parent is CM then output dataset name is CMFULL       ***;
***                                                                                                 ***;
*** Variables:          None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             None                                                                        ***;
***                                                                                                 ***;
*** Other:              1) If both &PARENT. and SUPP&PARENT. are present- then  SUPP&PARENT. will   ***;
***                        be transposed and merged based on IDVAR and &PARENT.FULL is created      ***;
***                     2) If &PARENT. is present and SUPP&PARENT. is not  present - then           ***;
***                        &PARENT.FULL is a copy of &PARENT.                                       ***;
***-------------------------------------------------------------------------------------------------***;

%macro qc_supp2parent(INLIB=SDTM,
                   PARENT=,
                   DEBUG=N);
        
    %let SUPPDS =SUPP&PARENT.;

    /*getting the count of PARENT datset*/
    data _null_;
        set &INLIB..&PARENT.;
    run;

    %let PAR_CNT =&sysnobs.;

    %if %sysfunc(exist(&INLIB..&SUPPDS.)) %then
        %do;
            /*getting the count of SUPP dataset*/
            data _null_;
                set &INLIB..&SUPPDS.;
            run;

            %let SUP_CNT =&sysnobs.;
        %end;
    %else
        %do;
            %let SUP_CNT =0;
        %end;

    %if &PAR_CNT. gt 0 %then
        %do;
            %if &SUP_CNT. gt 0 %then
                %do;
                    %put Note: Parent dataset &PARENT. has &PAR_CNT. records and Supplemental dataset &SUPPDS. has &SUP_CNT. records.;

                    %if "&PARENT." ne "DM" %then
                        %do;

                            proc sql noprint;
                                select distinct IDVAR into: IDVARS separated by ' ' from &INLIB..&SUPPDS. ;
                            quit;

                            %put &idvars.;

                            %let __t=%sysfunc(countw(&idvars.));        
                                           
                            %put total number of ID Variables: &__t. ;
                            /*Runing all the program based on the Number of ID variables */

                            %do __ds=1 %to &__t;                   
                            
                                %let invar = %scan(&idvars,&__ds,%str( )); 

                                data SP2P_1_&__ds.;
                                    set &INLIB..&SUPPDS.;
                                    IDVAL&__ds.     = IDVARVAL;
                                    where IDVAR eq "&invar.";

                                    keep STUDYID USUBJID IDVAL&__ds. QNAM QLABEL QVAL;
                                run;

                                proc sort data=SP2P_1_&__ds. out=SP2P_2_&__ds.;
                                    by STUDYID USUBJID IDVAL&__ds.;
                                run;

                                proc transpose data=SP2P_2_&__ds. out=SP2P_3_&__ds.(drop=_:);
                                    by STUDYID USUBJID IDVAL&__ds.;
                                    var QVAL;
                                    id QNAM;
                                    idlabel QLABEL;
                                run;

                                data SP2P_4_&__ds.;

                                    set 
                                    %if "&__ds." eq "1" %then 
                                        %do; 
                                            &INLIB..&PARENT.;
                                        %end;
                                    %else 
                                        %do;
                                            SP2P_FULL;
                                        %end;
                                    IDVAL&__ds.     = strip(vvalue(&invar.));
                                run;

                                proc sort data=SP2P_4_&__ds.;
                                    by STUDYID USUBJID IDVAL&__ds.;
                                run;

                                data SP2P_FULL(drop =IDVAL&__ds.);
                                    merge SP2P_4_&__ds.(in=a) SP2P_3_&__ds.;
                                    by STUDYID USUBJID IDVAL&__ds.;

                                    if a;
                                run;

                            %end;

                        %end;
                    %else
                        %do;

                            proc sort data=&INLIB..&SUPPDS. out=SP2P_2;
                                by STUDYID USUBJID;
                            run;

                            proc transpose data=SP2P_2 out=SP2P_3(drop=_:);
                                by STUDYID USUBJID;
                                var QVAL;
                                id QNAM;
                                idlabel QLABEL;
                            run;

                            proc sort data=&INLIB..&PARENT. out=SP2P_4;
                                by STUDYID USUBJID;
                            run;

                            data SP2P_FULL;
                                merge SP2P_4(in=a) SP2P_3;
                                by STUDYID USUBJID;

                                if a;
                            run;

                        %end;
                %end;
            %else
                %do;
                    %put Note: Supplemental dataset &SUPPDS. is empty, output will be a copy of the parent dataset.;

                    data SP2P_FULL;
                        set &INLIB..&PARENT.;
                    run;

                %end;

            data &PARENT.FULL;
                set SP2P_FULL;
            run;
        %end;
    %else
        %do;

            %put Note: Parent dataset &PARENT. is empty, output will be a copy of the parent.;
        %end;
        
%if "&DEBUG." ne "Y" %then 
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete SP2P_:;
            quit;
        run;
    %end;
    
%mend qc_supp2parent;
