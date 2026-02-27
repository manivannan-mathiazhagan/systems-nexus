***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_assign_visitnum.sas                                                           ***;
***                                                                                                 ***;
*** Purpose:       Create Visit number based on SV domain and DTC field for Unscheduled Visit       ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    04Jul2022                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** DTCVAR   | the main domain name - to create the --SEQ variable    | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** INDSET   |  the name of INPUT dataset                             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** OUTDSET  | the name of OUTPUT dataset                             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          |     N           |   No      ***; 
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &OUTDSET.                                                                   ***;
***                                                                                                 ***;
*** Variables:          VISIT, VISITNUM is added to the dataset                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          SDTM.SV                                                                     ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             None                                                                        ***;
***                                                                                                 ***;
*** Other:              The INPUT dataset(&INDSET.) should not contain  variable VISIT or VISITNUM  ***;
***                     as the macro creates it                                                     ***;
***-------------------------------------------------------------------------------------------------***;

%macro qc_assign_visitnum(DTCVAR=,VISITVAR=VISIT_,INDSET=,OUTDSET=,DEBUG=N);

/*Splitting Unscheduled and Scheduled records*/
data ___VIS_SCH( where = ( VISIT ne "Unscheduled" ) ) 
     ___VIS_UNS( where = ( VISIT eq "Unscheduled" ) );
    length VISIT $200.;
    set &INDSET.;  
    
    if index(upcase(&VISITVAR.),"UNSCHEDULED") gt 0  
    then VISIT = "Unscheduled";
    else VISIT = strip(put(&VISITVAR.,$q_s_visit.)); 

    VISITNUM = input(&VISITVAR.,q_s_visitnum.);
    
    if  VISIT = "check Visit" then
        do;
            put "&uwarn.: [VISITNUM] Visit mapping needs to be adapted for " &VISITVAR.;;
        end;
run;

/*Assigning VISIT details for UNS visit and Appending with Scheduled ones*/
proc sql noprint;

    create table ___VIS_UNS_1 as 
    select a.*,b.VISITNUM,b.VISIT from 
    ___VIS_UNS (drop = VISIT VISITNUM) a left join
    (select * from SDTM.SV where index(upcase(strip(VISIT)),"UNSCHEDULED") gt 0)  b 
    on a.USUBJID eq b.USUBJID and scan(a.&DTCVAR.,1,"T") eq scan(b.SVSTDTC,1,"T");  
    
    create table &OUTDSET. as  
    select * from ___VIS_SCH 
    outer union corr 
    select * from ___VIS_UNS_1;

quit;

%if "&DEBUG." ne "Y" %then 
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete ___VIS_:;
            quit;
        run;
    %end;

%mend qc_assign_visitnum;
