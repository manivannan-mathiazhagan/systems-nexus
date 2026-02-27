***-------------------------------------------------------------------------------------------------***;
*** Study Name:         FER-021-003                                                                 ***;
*** Program Name:       _runall_SDTM_v20250829.sas                                                  ***;
***                                                                                                 ***;
*** Purpose:            Program to Generate SDTM datasets.                                          ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         06Aug2025                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Last SVN Commit details                                                                         ***;
***-------------------------------------------------------------------------------------------------***;
*** Updated by:         $Author:: manivannan     $:                                                 ***;
*** Updated on:         $Date:: 2024-06-24 22:20:18 -0700 (Mon, 24 Jun 2024)   $:                   ***;
*** Version No:         $Rev:: 111    $:                                                            ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%setenv(sponsor =Covis Pharma,
        study   =Feraheme Imaging Supplemental,
        dbver2  =raw_v20250729\sdtm_v20250829);

%include "&proot\SDTM\SDTM_Macros.sas"; 

%macro yes_pt(yesdsn);  
 
  %imp_gdoc(sheet    =&yesdsn,
            gdoc_key =1EAf_6-H0aNTMCktK5P6KHy1pX-kKbWbjz794FTNvNlI, 
            outlib   =sdtmspec)

  %sdtm_create(speclib        =sdtmspec,
               specds         =&yesdsn,
               outlib         =SDTM,
               pgmpath        =&proot\Sdtm,
               source_id_vars =usubjid,studyid=);
%mend;

/*Spec and cr_ program creation */
%yes_pt(DM);
%yes_pt(SUPPDM);
%yes_pt(SV);
%yes_pt(SE);
%yes_pt(EX);
%yes_pt(SUPPEX);
%yes_pt(AE);
%yes_pt(SUPPAE);
%yes_pt(TU);
%yes_pt(SUPPTU);
%yes_pt(TR);
%yes_pt(RS);

/*Deleting previously generated files */
%delete_all_type_files_in_folder(&droot.\&dbpath., sas7bdat);
%delete_all_type_files_in_folder(&droot.\&dbpath.\XPT, xpt);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Logs, log);
%delete_all_type_files_in_folder(&droot.\&dbpath.\Logs, html);


%let sdtm_specs_gdoc_key = 1EAf_6-H0aNTMCktK5P6KHy1pX-kKbWbjz794FTNvNlI;

%inc "&proot\Sdtm\_runall-TrialDS.sas";

/*Individual Domain Program call*/
%inc "&proot\Sdtm\cr_dm.sas";
%shortlen(sdtm.dm,"Demographics");

%inc "&proot\Sdtm\cr_suppdm.sas";
%shortlen(sdtm.suppdm,"Supplemental Qualifiers for DM");

%inc "&proot\Sdtm\cr_sv.sas"; 
%shortlen(sdtm.sv,'Subject Visits');

%inc "&proot\Sdtm\cr_se.sas";
%shortlen(sdtm.se,'Subject Elements');

%inc "&proot\Sdtm\cr_ex.sas";
%shortlen(sdtm.ex,"Exposure");

%inc "&proot\Sdtm\cr_suppex.sas";
%shortlen(sdtm.suppex,"Supplemental Qualifiers for EX");

%inc "&proot\Sdtm\cr_ae.sas";
%shortlen(sdtm.ae,"Adverse Events");

%inc "&proot\Sdtm\cr_suppae.sas";
%shortlen(sdtm.suppae,"Supplemental Qualifiers for AE");

%inc "&proot\Sdtm\cr_tu.sas";
%shortlen(sdtm.tu,"Tumor/Lesion Identification");

%inc "&proot\Sdtm\cr_supptu.sas";
%shortlen(sdtm.supptu,"Supplemental Qualifiers for TU");

%inc "&proot\Sdtm\cr_tr.sas";
%shortlen(sdtm.tr,"Tumor/Lesion Results");

%inc "&proot\Sdtm\cr_rs.sas";
%shortlen(sdtm.rs,"Disease Response");

/*Creating xpt files*/
%sas2xpt(SDTM);

/*Checking the Log files*/
%logchk(&droot.&dbpath.\Logs);
