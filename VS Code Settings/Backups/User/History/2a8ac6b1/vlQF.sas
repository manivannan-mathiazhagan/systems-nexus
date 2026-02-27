***-------------------------------------------------------------------------------------------------***;
*** Study Name:         FER-021-003                                                                 ***;
*** Program Name:       _val_runall_ADaM_v20250829.sas                                              ***;
***                                                                                                 ***;
*** Purpose:            Program to Validate ADaM datasets.                                          ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         06Aug2025                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Last SVN Commit details                                                                         ***;
***-------------------------------------------------------------------------------------------------***;
*** Updated by:         $Author:: manivannan     $:                                                 ***;
*** Updated on:         $Date:: 2025-08-06 12:08:11 +0530 (Wed, 06 Aug 2025)   $:                   ***;
*** Version No:         $Rev:: 209    $:                                                            ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%setenv(sponsor =Covis Pharma,
        study   =Feraheme Imaging Supplemental,
        dbver2  =raw_v20250729\sdtm_v20250829\adam_v20250829);

/*Deleting previously generated files */
%delete_all_type_files_in_folder(&droot.\&dbpath.\Compare, pdf);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Compare\Logs, log);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Compare\Logs, html);

/*calling individual Validation programs*/
%qc_adam_datasets(dsets=%str(ADSL,ADAE,ADRS,ADEFF,ADEFF1));
/*
%qc_adam_datasets(dsets=%str(ADEFF,ADEFF1));
*/
/* Checking Logs */
%logchk(&droot.\&dbpath.\Compare\Logs); 
