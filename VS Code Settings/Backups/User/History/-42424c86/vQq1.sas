DM "log; clear; lst; clear;" ;
************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\Listings\ql-1-disp.sas
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
* PURPOSE:     Listing of Subject Disposition
*			   (Safety Population)
*
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:	
* DATE:			
* PURPOSE:		 
************************************************************************************;

%let pgm=ql-1-disp; 
%let pgmnum=1;
%let pgmqc=%sysfunc(translate(%substr(&pgm,2),'_','-'));
%let protdir=&rmhoiss90;

%include "&protdir\macros\m-setup.sas";

options nomlogic mprint nosymbolgen;


proc sort data=ads.adsl out=adsl1;
	 by studyid usubjid subjid;
	 where saffl="Y";
run;

data adsl2;
 	 set adsl1;
	 by studyid usubjid subjid; 

 	 length COL1 XX $20. COL2 $50. COL3 COL4 $30. COL5 $1. COL6 COL7 $20.  COL8 $100.;

	 if not missing(studyid) then col1=compress(upcase(studyid));

	 if not missing(TRTAG) then col2=compress(upcase(arm));
		
 	 if not missing(SUBJID) then col3=compress(upcase(SUBJID));

	 if studyid in ('RM-493-002' 'RM-493-009' 'RM-493-010') then do;
		xx=substr(usubjid,12);
		col3=compress(upcase(xx));
	 end;

    if not missing(TRTSDT) and not missing(TRTEDT) then col4= compress(upcase(put(TRTSDT,is8601da.)))||"/"|| compress(upcase(put(TRTEDT,e8601da.)));
	if not missing(TRTSDT) and missing(trtedt)  then col4= compress(upcase(put(trtsdt,e8601da.))) ;

	if status="ONGOING" then col5="Y";
	else col5="N";

	if col5="Y" then do;
		col6=""; col7=""; col8="";
	end;
	else do;
		if status="COMPLETE" then col6=compress(upcase(put(trtedt,e8601da.))) ;
		if status="DISCONTINUED" then do;
		col6="";
		col7=compress(upcase(put(dsstdt,e8601da.))) ;
		col8=compress(upcase(dsdecod));
		end;
	end;
  run;

proc sort data=adsl2 out=final_&pgmqc (keep=col1 - col8 );
by col1 armn col2 ;
run;

*==============================================*;
* Comparing production dataset with QC dataset *;
*==============================================*;


proc compare base = qclis.&pgmqc compare = final_&pgmqc (keep=col1-col8) listall; 
*id col1 col2 col3 ;*col4 col5 col6; 
run;

/*

proc print data=final_&pgmqc ;
title "qc";
var col1 - col6;
run;

proc print data=qclis.&pgmqc ;
title "list &pgmqc";
var col1 - col6;
run;
