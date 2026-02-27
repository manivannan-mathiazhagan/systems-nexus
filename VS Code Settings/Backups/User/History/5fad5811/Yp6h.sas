***-------------------------------------------------------------------------------------------------***;
*** Study Name:         FER-021-003                                                                 ***;
*** Program Name:       _val_runall_SDTM_v20250829.sas                                              ***;
***                                                                                                 ***;
*** Purpose:            Program to Validate SDTM datasets.                                          ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         06Aug2025                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Last SVN Commit details                                                                         ***;
***-------------------------------------------------------------------------------------------------***;
*** Updated by:         $Author:: manivannan     $:                                                 ***;
*** Updated on:         $Date:: 2025-08-06 11:59:48 +0530 (Wed, 06 Aug 2025)   $:                   ***;
*** Version No:         $Rev:: 207    $:                                                            ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%setenv(sponsor =Covis Pharma,
        study   =Feraheme Imaging Supplemental,
        dbver2  =raw_v20250729\sdtm_v20250829);

/*Deleting previously generated files */
%delete_all_type_files_in_folder(&droot.\&dbpath.\Compare, pdf);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Compare\Logs, log);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Compare\Logs, html);

/*calling individual Validation programs*/
%qc_sdtm_datasets(dsets=%str(DM,SV,SE,AE,EX,TU,TR,RS));

/*
%qc_sdtm_datasets(dsets=%str(SV));
*/

/* Checking Logs */
%logchk(&droot.\&dbpath.\Compare\Logs);
