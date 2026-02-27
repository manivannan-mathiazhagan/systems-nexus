***-------------------------------------------------------------------------------------------------***;
*** Study Name:         FER-021-003                                                                 ***;
*** Program Name:       _runall_ADaM_v20250829.sas                                                  ***;
***                                                                                                 ***;
*** Purpose:            Program to Generate ADaM datasets.                                          ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         06Aug2025                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Last SVN Commit details                                                                         ***;
***-------------------------------------------------------------------------------------------------***;
*** Updated by:         $Author:: manivannan     $:                                                 ***;
*** Updated on:         $Date:: 2025-08-06 12:05:11 +0530 (Wed, 06 Aug 2025)   $:                   ***;
*** Version No:         $Rev:: 208    $:                                                            ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%setenv(sponsor =Covis Pharma,
        study   =Feraheme Imaging Supplemental,
        dbver2  =raw_v20240822\sdtm_v20240822\adam_v20240822);
        
%include "&proot\ADaM\_runall-MACRO.sas"; 
%include "&proot\SDTM\SDTM_Macros.sas"; 

%macro yes_pt(yesdsn);  
 
  %imp_gdoc(sheet    =&yesdsn,
            gdoc_key =1DnxpE1gDiuBZFCWsw8kbUXKZbu4XoOrEoF3xwUHEaZg, 
            outlib   =adamspec)

  %sdtm_create(speclib        =adamspec,
               specds         =&yesdsn,
               outlib         =adam,
               pgmpath        =&proot\adam,
               source_id_vars =usubjid);
%mend;

/*Spec and cr_ program creation */
%yes_pt(ADSL);
%yes_pt(ADAE);
%yes_pt(ADRS);
%yes_pt(ADEFF);
%yes_pt(ADEFF1);

/*Deleting previously generated files */
%delete_all_type_files_in_folder(&droot.\&dbpath., sas7bdat);
%delete_all_type_files_in_folder(&droot.\&dbpath.\XPT, xpt);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Logs, log);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Logs, html);

/*Individual Domain Program call*/
%inc "&proot\ADAM\cr_adsl.sas"; 
%shortlen_adm(adam.adsl,Subject-Level Analysis Dataset,format TRTSDT TRTEDT BRTHDT DTHDT date9.);

%inc "&proot\ADAM\cr_adae.sas"; 
%shortlen_adm(adam.adae,Adverse Event Analysis Dataset,format ASTDT date9.);

%inc "&proot\ADAM\cr_adrs.sas"; 
%shortlen_adm(adam.adrs,Tumor Response Analysis Dataset,format ADT date9.);

%inc "&proot\ADAM\cr_adeff.sas"; 
%shortlen_adm(adam.adeff,Efficacy Analysis Dataset,format ADT date9.);

%inc "&proot\ADAM\cr_adeff1.sas"; 
%shortlen_adm(adam.adeff1,Efficacy Analysis Dataset 1,format ADT date9.);

/*Creating xpt files*/
%sas2xpt(ADAM);

/*Checking the Log files*/
%logchk(&droot.&dbpath.\Logs);
