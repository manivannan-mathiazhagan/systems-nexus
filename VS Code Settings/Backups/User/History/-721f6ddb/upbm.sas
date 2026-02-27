DM "log; clear; lst; clear;" ;
************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\Listings\ql-4-ae-rel.sas
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
* PURPOSE:     Listing of Treatment-Related Adverse Events 
*			   (Safety Population)
*
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:	
* DATE:			
* PURPOSE:		 
* NOTE: 		copied/modified from P:\Projects\Rhythm\BBS sNDA\Biostats\ISS\QC\Listings
*				query to LPREV to confirm TRTEMFL 4/24
*				TRTEMFL=Y confirmed by STAT/CK 25APR
************************************************************************************;

%let pgm=ql-4-ae-rel; 
%let pgmnum=4;
%let pgmqc=%sysfunc(translate(%substr(&pgm,2),'_','-'));
%let protdir=&rmhoiss;

%include "&protdir\macros\m-setup.sas";
%include "&protdir\qc\listings\macros\qcae.sas";

options nomlogic mprint nosymbolgen;

%qcae (cond_1=%str(where saffl="Y"; ), 
	   cond_2=%str(where (saffl="Y" and studyid^="RM-493-041" and arelfl="Y" AND TRTEMFL="Y") or (studyid="RM-493-041" and arelfl="Y" AND TRTEMFL="Y") ; ));

