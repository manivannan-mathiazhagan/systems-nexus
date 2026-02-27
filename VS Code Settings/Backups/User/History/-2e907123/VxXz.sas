DM "log; clear; lst; clear;" ;
************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Biostats\QC\Tables\qt-1-1-1-ds-sb.sas
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
* PURPOSE:     Subject Disposition - All Subjects
*			   (Safety Population)
*
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:	
* DATE:			
* PURPOSE:		 
************************************************************************************;

%let pgm=qt-1-1-1-ds-sb; 
%let pgmnum=1.1.1;
%let pgmqc=%sysfunc(translate(%substr(&pgm,2),'_','-'));
%let protdir=&rmhoiss;

%include "&protdir\macros\m-setup.sas";

%include "&protdir\qc\tables\macros\QCTone.sas";

options nomlogic mprint nosymbolgen;

* SBFL  All Subject Flag;

%QCTone (subs=%str(sbfl="Y"));
