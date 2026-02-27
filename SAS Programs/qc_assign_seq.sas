***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_assign_seq.sas                                                                ***;
***                                                                                                 ***;
*** Purpose:       Create Sequence number based on key vars Passed                                  ***;
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
*** DMAIN    | the main domain name - to create the --SEQ variable    | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** INDSET   |  the name of INPUT dataset                             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** OUTDSET  | the name of OUTPUT dataset                             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** SORT_ORD | the order for sorting the dataset                      | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &OUTDSET.                                                                   ***;
***                                                                                                 ***;
*** Variables:          new variable &DMAIN.SEQ is added to the dataset                             ***;
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
*** Other:              None                                                                        ***;
***-------------------------------------------------------------------------------------------------***;

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
