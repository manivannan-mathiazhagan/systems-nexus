DM "log; clear; lst; clear;" ;
************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\Listings\ql-8-ae-int.sas
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
* PURPOSE:     Listing of Subjects Who Had Study Drug Interrupted Due to Adverse Event  
*			   (Safety Population)
*
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:	
* DATE:			
* PURPOSE:		 
************************************************************************************;

%let pgm=ql-8-ae-int; 
%let pgmnum=8;
%let pgmqc=%sysfunc(translate(%substr(&pgm,2),'_','-'));
%let protdir=&rmhoiss;

%include "&protdir\macros\m-setup.sas";
%include "&protdir\qc\listings\macros\qcae.sas";

options nomlogic mprint nosymbolgen;

%qcae (cond_1=%str(where saffl="Y"; ), 
	   cond_2=%str(where (saffl="Y" and studyid^="RM-493-041" and aintfl="Y") or (studyid="RM-493-041" and aintfl="Y")  ; ));

