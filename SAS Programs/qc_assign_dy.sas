***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_assign_dy.sas                                                                 ***;
***                                                                                                 ***;
*** Purpose:       Create Study day variable based on character date variable given and RFSTDTC     ***;
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
*** DTC      | the character datetime variable name based on which    | No default      |   Yes     ***;
***          | study day has to be calculated with respect to RFSTDTC |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DY       | the numeric variable name - to calculated DY is mapped | No default      |   Yes     ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          None - This macro is called within any dataset                              ***;
***                                                                                                 ***;
*** Variables:          new variable &DY is added to the dataset                                    ***;
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
*** Other:              The variable RFSTDTC should be present in the dataset within which the      ***;
***                     macro is called as derivation is based on that                              ***;
***-------------------------------------------------------------------------------------------------***;

%macro qc_assign_dy(DTC,DY);

    if cmiss(RFSTDTC,&DTC.) eq 0 and length(scan(&DTC.,1,"T")) ge 10 then 
        do;
           if input(substr(&DTC.,1,10),??is8601da.) ge input(substr(RFSTDTC,1,10),is8601da.) 
               then &DY. = input(substr(&DTC.,1,10),??is8601da.)-input(substr(RFSTDTC,1,10),is8601da.)+1;
           else if input(substr(&DTC.,1,10),??is8601da.) lt input(substr(RFSTDTC,1,10),is8601da.) 
               then &DY. = input(substr(&DTC.,1,10),??is8601da.)-input(substr(RFSTDTC,1,10),is8601da.);
        end;

    else call missing(&DY.);

%mend qc_assign_dy;
