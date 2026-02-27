DM "log; clear; lst; clear;" ;
************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\Listings\ql-9-dth.sas
* DATE:        21APR2025
* PROGRAMMER:  K.Reuter
* PURPOSE:     Listing of Deaths
*			   (Safety Population)
*
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:	K.Reuter
* DATE:			28APR2025		
* PURPOSE:		per LPREV: For COL2 (treatment group), if DTHFL='Y' but does not have AE death event, 
*				use the last record as the last AE event information.  For 004-004, the last record was 
*				for 'Bridging Visit', so that was the last AE event used for death information.  
* 
* NOTE: 		Use either AE.AEOUT='Death' or ADSL.DTHDT as non-missing. 

************************************************************************************;

%let pgm=ql-9-dth; 
%let pgmnum=9;
%let pgmqc=%sysfunc(translate(%substr(&pgm,2),'_','-'));
%let protdir=&rmhoiss;

%include "&protdir\macros\m-setup.sas";

options nomlogic mprint nosymbolgen;


proc sort data=ads.adsl out=adsl1;
	 by studyid usubjid subjid;
	 where saffl="Y" and dthdt^=.;
run;

proc sort data=ads.adae out=adae1;
	 by studyid usubjid subjid;	 
	 where (saffl="Y" and studyid^="RM-493-041");
	 run;
data adae1;
	 set adae1;
	 by studyid usubjid subjid;
	 * AESDTH  Results in Death;
	 if (upcase(aeout) in ("FATAL" "DEATH")) or (AESDTH="Y") or (upcase(AESEV)="DEATH");
	 run;

proc sort data=ads.adae out=adae2;
	 by studyid usubjid subjid;	 
	 where studyid="RM-493-041";
	 run;
data adae2;
	 set adae2;
	 by studyid usubjid subjid;
	 if (upcase(aeout) in ("FATAL" "DEATH")) or (AESDTH="Y") or (upcase(AESEV)="DEATH");
	 run;	  

data adae1_;
	 set adae1 adae2;
	 by studyid usubjid subjid;
	 run;

data adae1_;
	 merge adsl1 (in=a) adae1 (in=b);
	 by studyid usubjid subjid; 
	 if a OR b;	 
	 if a and not b then uselast="Y";
	 *keep studyid usubjid subjid trtsdt trtedt trtag: astdt astdy arm: aeterm aedecod aeout dthdt;
run;

data adsl2;
 	 set adae1_;
	 by studyid usubjid subjid; 

 	 length COL1 XX $20. COL2 COL3 COL4 COL5 $50. COL6 $250.;

	 if not missing(studyid) then col1=compress(upcase(studyid));

	 if not missing(TRTAG) then do; sorta=armn; col2=compress(upcase(arm)); end;
	 * no AE event, only ADSL dthdt;
	 if uselast="Y" then do;
	 	if arm2^="" then do; sorta=arm2n; col2=compress(upcase(arm2)); end; else
		if arm ^="" then do; sorta=armn; col2=compress(upcase(arm)); end;
	 end;
		
 	 if not missing(SUBJID) then col3=compress(upcase(SUBJID));

	 if studyid in ('RM-493-002' 'RM-493-009' 'RM-493-010') then do;
		xx=substr(usubjid,12);
		col3=compress(upcase(xx));
	 end;

    if not missing(TRTSDT) and not missing(TRTEDT) then col4= compress(upcase(put(TRTSDT,is8601da.)))||"/"|| compress(upcase(put(TRTEDT,e8601da.)));
	if not missing(TRTSDT) and missing(trtedt)  then col4= compress(upcase(put(trtsdt,e8601da.))) ;

	if not missing(dthdt) then col5= strip(put(dthdt,e8601da.));

	*if aeterm eq "" then  aeterm="[NOT CODED]"; 	 	 
    if dthdt=. then col6= strip(compress(upcase(aedecod)));
	if dthdt^=. and (dthdt=astdt or dthdt=aendt) then col6= strip(compress(upcase(aedecod)));
  run;

proc sort data=adsl2 out=final_&pgmqc ;* (keep=col1 - col6 );
by col1 sorta col2 col3 col4 col5 aeterm col6 ;
run;

*==============================================*;
* Comparing production dataset with QC dataset *;
*==============================================*;

proc compare base = qclis.&pgmqc compare = final_&pgmqc (keep=col1-col6) listall; 
*id col1 col2 col3 ;*col4 col5 col6; 
run;
