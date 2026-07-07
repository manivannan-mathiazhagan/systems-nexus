/**************************************************************************
 Program : adamski_autoexec.sas
 Purpose : Local environment setup for Adamski development and testing.
 Author  : Manivannan Mathialagan

 NOTE:
   - This file is for local development only.
   - Do NOT commit this file.
**************************************************************************/

/* SAS Packages location */
%let SASPACKAGES =P:\BSP_LocalDev\Manivannan.Mathialag\zzzz_My_SAS_Files\My GitHub\SAS_PACKAGES;

filename packages "&SASPACKAGES";

%include packages(SPF/SPFinit.sas);

/* Install if required */
%installPackage(sasjscore,      mirror=PharmaForest);
%installPackage(valivali,       mirror=PharmaForest);
%installPackage(adamski,        mirror=PharmaForest);
%installPackage(saslogchecker,  mirror=PharmaForest);

/* Load packages */
%loadPackage(sasjscore);
%loadPackage(valivali);
%loadPackage(adamski);
%loadPackage(saslogchecker);