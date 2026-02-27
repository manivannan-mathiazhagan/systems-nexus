***-------------------------------------------------------------------------------------------------***;
*** Study Name:         BSP Demo Project                                                            ***;
*** Program Name:       _runall_SDTM_v20250618_d20250630.sas                                        ***;
***                                                                                                 ***;
*** Purpose:            Program to create the SDTM datasets.                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         18Jun2025                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Modification History                                                                            ***;
***-------------------------------------------------------------------------------------------------***;
*** Date        | Modified By          | Description                                                ***;
***-------------|----------------------|------------------------------------------------------------***;
*** 18Jun2025   | Manivannan           | Initial version created                                    ***;
***-------------------------------------------------------------------------------------------------***;

/* Assigning the SDTM path as macro variable */
%let sd_path=raw_v20250618\sdtm_v20250630;

%setenv(sponsor =Instat,
        study   =BSP Demo Project,
        dbver2  =&sd_path.); 
 
%imp_sp_xlsx(Teams_channel=&SP_Channel_Name,filepath=BSP/SDTM_SPECS/&SDTM_SPECS_FILENAME..xlsx,outlib=SDTMSPEC,sheet=SUPPQUAL);
%imp_sp_xlsx(Teams_channel=&SP_Channel_Name,filepath=BSP/SDTM_SPECS/&SDTM_SPECS_FILENAME..xlsx,outlib=SDTMSPEC,sheet=Domains);

/*  For Empty Dataset, sheet value can domain name with space separation or ALL for all the domains in "Domain" sheet*/
%create_empty(cdisc_type=SDTM,sheet=ALL);

/*   For generating the develpment output*/
%cdisc_output(dev=SDTM,dsn=TA TE TI TS TV DM SV SE EC EX AE CE CM MH PR DS IE EG LB MB PC PE OE QS VS FA FT ZS);

/*   Log Check Summary*/
%log_check(&logroot.&dbpath.\Logs);
