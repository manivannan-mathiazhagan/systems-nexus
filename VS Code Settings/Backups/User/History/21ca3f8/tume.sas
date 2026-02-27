***-------------------------------------------------------------------------------------------------***;
*** Study Name:         BSP Demo Project                                                            ***;
*** Program Name:       _runall_ADaM_v20250630.sas                                                  ***;
***                                                                                                 ***;
*** Purpose:            Program to create the ADaM datasets.                                        ***;
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

/* Setenv call with respective folders and Parameters */
%let ad_path=raw_v20250618\sdtm_v20250630\adam_v20250630;

%setenv(sponsor =Veristat,
        study   =BSP Demo Project,
        dbver2  =&ad_path.);       

/*  Import Domains sheet for getting Key order */ 
%imp_sp_xlsx(Teams_channel=&SP_Channel_Name,filepath=BSP/ADaM_SPECS/&ADaM_SPECS_FILENAME..xlsx,outlib=adamspec,sheet=Domains);

/*  For Empty Dataset, sheet value can domain name with space separation or ALL for all the domains in "Domain" sheet*/
%create_empty(cdisc_type=ADaM,sheet=ALL);

/*   For generating the develpment output*/
%cdisc_output(dev=ADAM,dsn=ADSL ADAE ADVS ADEG ADLB ADQS ADCM ADEC ADMH ADCE ADFT);

/*   Log Check Summary*/
%log_check(&logroot.&dbpath.\Logs);
