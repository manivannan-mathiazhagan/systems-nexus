DM "log; clear; lst; clear;" ;
************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\Listings\ql-2-demog.sas
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
* PURPOSE:     Listing of Subject Demographic and Baseline Characteristics
*			   (Safety Population)
*
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:	K.Reuter
* DATE:			08MAY2025
* PURPOSE:		update to pull VS variables from ADSL versions 
************************************************************************************;

%let pgm=ql-2-demog; 
%let pgmnum=2;
%let pgmqc=%sysfunc(translate(%substr(&pgm,2),'_','-'));
%let protdir=&rmhoiss;

%include "&protdir\macros\m-setup.sas";

options nomlogic mprint nosymbolgen;

proc sort data=ads.adsl out=adsl1;
	 by usubjid;*studyid usubjid subjid;
	 where saffl="Y";
run;

data adsl2;
	 set adsl1;
	 by usubjid;

 	 length COL1 XX $20. COL2 $200. COL3 $25. COL4 $25. COL5 $25. COL7 $25. COL6 $50. COL8-col10 $25.;

	 if not missing(studyid) then col1=compress(upcase(studyid));

	 if not missing(TRTAG) then col2=compress(upcase(arm));
		
 	 if not missing(SUBJID) then col3=compress(upcase(SUBJID));

	 if studyid in ('RM-493-002' 'RM-493-009' 'RM-493-010') then do;
		xx=substr(usubjid,12);
		col3=compress(upcase(xx));
	 end;

     if sex="F" then col4=compress(upcase("Female")) ;
	 if sex="M" then col4=compress(upcase("Male")) ;

	 if not missing (AGE) then col5=strip(put(AGE,3.0));

	 if not missing(RACE) then col6=compress(upcase(RACE));

	 if not missing(ETHNIC) then col7=compress(upcase(ETHNIC));

	 if not missing(HEIGHTBL) then col8=strip(put(HEIGHTBL,5.1));

	 if not missing(weightbl) then col9=strip(put(round(weightbl,0.1), 6.1));

	 if not missing(BMIBL) then col10=strip(put(BMIBL,5.2));
  run;

proc sort data=adsl2 out=final_&pgmqc;
by col1 armn col2 ;
run;

*==============================================*;
* Comparing production dataset with QC dataset *;
*==============================================*;


proc compare base = qclis.&pgmqc compare = final_&pgmqc (keep=col1-col10) listall; 
*id col1 col2 col3 ; 
run;

/*

proc print data=final_&pgmqc ;
title "qc";
var col1 - col10;
where col1='RM-493-009';
run;

proc print data=qclis.&pgmqc ;
title "list &pgmqc";
var col1 - col10;
where col1='RM-493-009';
run;
