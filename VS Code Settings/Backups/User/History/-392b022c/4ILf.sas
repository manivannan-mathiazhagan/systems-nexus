DM "log; clear; lst; clear;" ;
************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\Listings\ql-7-ae-wth.sas
* DATE:        25APR2025
* PROGRAMMER:  K.Reuter
* PURPOSE:     Listing of Subjects Who Discontinued From Study Drug Due to Adverse Event  
*			   (Safety Population)
*
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:	
* DATE:			
* PURPOSE:		 
************************************************************************************;

%let pgm=ql-7-ae-wth; 
%let pgmnum=7;
%let pgmqc=%sysfunc(translate(%substr(&pgm,2),'_','-'));
%let protdir=&rmhoiss;

%include "&protdir\macros\m-setup.sas";
%include "&protdir\qc\listings\macros\qcae.sas";

options nomlogic mprint nosymbolgen;

%qcae (cond_1=%str(where saffl="Y"; ), 
	   cond_2=%str(where (saffl="Y" and studyid^="RM-493-041" and awdfl="Y") or (studyid="RM-493-041" and awdfl="Y")  ; ));

