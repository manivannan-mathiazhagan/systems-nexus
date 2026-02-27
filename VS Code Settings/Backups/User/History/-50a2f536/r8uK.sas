***-------------------------------------------------------------------------------------------------***;
*** Study Name:         BSP Demo Project                                                            ***;
*** Program Name:       _val_runall_SDTM_v20250630.sas                                              ***;
***                                                                                                 ***;
*** Purpose:            Program to Validate the SDTM datasets.                                      ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         07Jul2025                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Modification History                                                                            ***;
***-------------------------------------------------------------------------------------------------***;
*** Date        | Modified By          | Description                                                ***;
***-------------|----------------------|------------------------------------------------------------***;
*** 07Jul2025   | Manivannan           | Initial version created                                    ***;
***-------------------------------------------------------------------------------------------------***;

/* Assigning the SDTM path as macro variable */
%let sd_path=raw_v20250618\sdtm_v20250630;

%setenv(sponsor =Veristat,
        study   =BSP Demo Project,
        dbver2  =&sd_path.);      

/* call individual programs for validation */
%qc_cdisc_data(cdisc_type=SDTM,dsets=DM SV SE EC EX AE CE CM MH PR DS IE EG LB MB PC PE OE QS VS FA FT ZS);

/*   Log Check Summary*/
%log_check(&logroot.&dbpath.\Compare\Logs);
