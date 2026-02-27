dm "log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-adae-035.sas  
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
*
* PURPOSE:     QC of ADAE 035.    
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:    
*
************************************************************************************;  
%let pgm=qd-adae-035; 
%let pgmnum=0;  
 
%let protdir=&rmhoiss90;

%include "&protdir\macros\m-setup.sas";
libname chk "P:\Rhythm\DSUR\ADSdata\CLIENT ADS NOT USED";
options nofmterr;

proc format;
	invalue mon   'JAN' = 01 
				  'FEB' = 02 
				  'MAR' = 03 
				  'APR' = 04 
				  'MAY' = 05 
				  'JUN' = 06 
				  'JUL' = 07 
				  'AUG' = 08 
				  'SEP' = 09 
				  'OCT' = 10 
				  'NOV' = 11 
				  'DEC' = 12; 

	invalue aesev 'MILD' = 1
				  'MODERATE' = 2
				  'SEVERE'= 3
				  'LIFE-THREATENING' = 4;
				  
	value acn30f
		1 = ' '
		2 = 'Concomitant Medications'
		3 = 'Concurrent Procedures'
		4 = 'Discontinued Study';
run;


%let cutoff = &cutdt;
 
*===============================================================================
* 1. Bring in AE.  
*===============================================================================; 
data ae (drop=aeterm_);
length studyid $ 15 usubjid $ 35 subjid $ 50 aeterm $200;
	set raw35.ae(drop = siteid studyid rename=(aeterm=aeterm_));
	where aeterm_ ne '';
	studyid = 'RM-493-035';
	subjid = substr(subject, 5);
	if cmiss(studyid, subjid) = 0 then usubjid = catx('-', studyid, subjid);
	if length(aeterm_) > 200 then put "WARN" "ING: Need to review AETERM_: " usubjid=aeterm_=; 
	aeterm = upcase(aeterm_);
run;  

*===============================================================================
* 2. Merge together.   
*===============================================================================; 
proc sort data=ae;by usubjid;run; 
data ae1;
length aeterm $200 aestdtc aeendtc $ 19;
	merge ae(in=a) adam.adsl_035(in=b);
	by usubjid;
	if a and b;
	if length(compress(aestdat_raw))=7 then aestdat_raw='UN '||strip(aestdat_raw);
	if length(aestdat_raw) = 10 and length(scan(aestdat_raw, 1)) = 1 then do; aestdat_raw = '0' || aestdat_raw; t = 1; end;
	if length(aeendat_raw) = 10 and length(scan(aeendat_raw, 1)) = 1 then do; aeendat_raw = '0' || aeendat_raw; t = 2; end;
 
	aestdat_raw = upcase(aestdat_raw);
	if aestdat_raw ne '' and index(aestdat_raw, ' UN') = 0 then aestdtc = catx('-', scan(aestdat_raw, 3,' '), put(input(scan(aestdat_raw, 2,' '), mon.), z2.), scan(aestdat_raw, 1,' '));
	if aestdat_raw ne '' and index(aestdat_raw, 'UN UNK') > 0 then aestdtc = catx('-', scan(aestdat_raw, 3,' '), 'UN', 'UN');
	else if aestdat_raw ne '' and index(aestdat_raw, ' UN') > 0 then aestdtc = catx('-', scan(aestdat_raw, 3,' '), put(input(scan(aestdat_raw, 2,' '), mon.), z2.), 'UN');
  
	aeendat_raw = upcase(aeendat_raw);
	if aeendat_raw ne '' and index(aeendat_raw, ' UN') = 0 then aeendtc = catx('-', scan(aeendat_raw, 3,' '), put(input(scan(aeendat_raw, 2,' '), mon.), z2.), scan(aeendat_raw, 1,' '));
	if aeendat_raw ne '' and index(aeendat_raw, 'UN UNK') > 0 then aeendtc = catx('-', scan(aeendat_raw, 3,' '), 'UN', 'UN');
	else if aeendat_raw ne '' and index(aeendat_raw, ' UN') > 0 then aeendtc = catx('-', scan(aeendat_raw, 3,' '), put(input(scan(aeendat_raw, 2,' '), mon.), z2.), 'UN');

	astdt = input(aestdtc, ??yymmdd10.);
	aendt = input(aeendtc, ??yymmdd10.);

	if astdt > &cutdt then chk = 'Y';
	if chk = 'Y' then delete; *drop the records if after cutoff date;

	format astdt aendt e8601da.;
run;

data ae1;
length trta trtp$ 200;
	set ae1;
	by usubjid;

	if aestdtc ne '' then do;
		aesmon = input(scan(aestdtc, 2, '-'), ??2.); 
		aesyear = input(scan(aestdtc, 1, '-'), 4.);
		aesday = input(scan(aestdtc, 3, '-'), ??2.); 
		trtsdtc = put(trtsdt, yymmdd10.); 

		if aesday ne . and aesmon ne . and aesyear ne . then taestart = mdy(aesmon, aesday, aesyear);
		else if aesday = . and aesmon = . then taestart = mdy(01, 01, aesyear);
		*else if aesday = . then taestart = intnx('month',mdy(aesmon, 01, aesyear), 0, 'b'); 
		else if aesday = . then taestart = mdy(aesmon, 01, aesyear);
		if index(aestdtc, '-UN-UN') > 0 and substr(aestdtc, 1,4) = substr(trtsdtc, 1,4) then taestart = trtsdt;
		else if index(aestdtc, '-UN') > 0  and substr(aestdtc, 1,7) = substr(trtsdtc, 1,7) then taestart = trtsdt;
	end;
  
	if nmiss(taestart, trtsdt) = 0 then aestdy = taestart - trtsdt + (taestart >= trtsdt);
	if astdt = . then aestdy = .;

	trtp = trt01p; 
	trta = trt01p;    
/*	  if . < trtedt < taestart then do; trtp = ''; trta='Off treatment'; end; */
/*	  if . < taestart < trtsdt then do; trtp = ''; trta='Off treatment'; end; */
  
	format taestart e8601da.;
run;
 
   
data ae2 (rename = (_aescong = aescong _aesdisab = aesdisab _aesdth = aesdth _aeshosp = aeshosp _aeslife = aeslife _aesoth = aesoth));
length aept aellt aehlt aehlgt aesoc aedecod aebodsys aerel $ 200 aeser $1 aeongo $7 aetoxgr $ 10 aeout $ 35 aesev $ 16 aeacn aeacnoth $200;
	set ae1(rename = (aeout = aeout_ aetoxgr = aetoxgr_ aeser = aeser_ aeongo = aeongo_ aeacn = aeacn_)); 
	by usubjid;

	aept = propcase(aeterm_pt);
	aedecod = strip(aeterm_pt);
	aellt = propcase(aeterm_llt);
	aehlt = propcase(aeterm_hlt);
	aehlgt = propcase(aeterm_hlgt); 
	aesoc = propcase(aeterm_soc);
	aebodsys = propcase(aeterm_soc);
	if upcase(aeser_) = 'YES' then aeser = substr(aeser_, 1,1);
	if upcase(aeser_) = 'NO' then aeser = substr(aeser_, 1,1);
	if upcase(aeongo_) = 'YES' then aeongo = 'ONGOING';
	else aeongo = ' ';

	aeout = aeout_;  

	aetoxgr = left(scan(aetoxgr_,1,'-'));  
	aesev = left(upcase(scan(aetoxgr_,2,'-')));  
	if AETOXGR_STD=4 then aesev=upcase('Life-Threatening');
	aetoxgrn = aetoxgr_std;
	aesevn = input(aesev,aesev.);    
	if not missing(AEACNINT_STD) then aeacn= strip(AEACN_STD)||":"||strip(AEACNINT_STD);
	else aeacn= strip(AEACN_STD);

	aeptcd = input(aeterm_pt_code, best.);
	aesoccd = input(aeterm_soc_code, best.);
	aebdsycd = aesoccd;
	aehlgtcd = input(aeterm_hlgt_code, best.);
	aelltcd = input(aeterm_llt_code, best.);
	aehltcd = input(aeterm_hlt_code, best.);
	aehlgtcd = input(aeterm_hlgt_code, best.);

	aerel = upcase(aerel);
	if aeser = 'Y' then aesern = 1;
	else aesern = 2;

	if aesdisab_raw = '1' then _aesdisab = 'Y';
    else if aesdisab_raw = '0' then _aesdisab = 'N';

    if aesdth_raw = '1' then _aesdth = 'Y';
    else if aesdth_raw = '0' then _aesdth = 'N';

    if aeshosp_raw = '1' then _aeshosp = 'Y';
    else if aeshosp_raw = '0' then _aeshosp = 'N';

    if aeslife_raw = '1' then _aeslife = 'Y';    
	else if aeslife_raw = '0' then _aeslife = 'N';

	if aescong_raw = '1' then _aescong = 'Y';
    else if aescong_raw = '0' then _aescong = 'N';
	
	if aesoth_raw = '1' then _aesoth = 'Y';
    else if aesoth_raw = '0' then _aesoth = 'N'; 

	if AEACNOCM = 1 then cm = 'Concomitant Medications';
	if aeACNOcp = 1 then cp = 'Concurrent Procedures'; 
	if AEOTHER=  1  then DO;
	IF NOT MISSING(AEACNOOT) THEN ot = 'Other :'||STRIP(AEACNOOT);  
	ELSE OT='Other';
	END;
	if AEACNON= 1 then non = 'NONE';
	   aeacnoth = UPCASE(catx(', ', cm, cp,ot,non));  

	if index(aestdtc, '-UN') > 0 then do; aestdtc = tranwrd(aestdtc, '-UN', ''); chk = 'Y'; end;
	if index(aeendtc, '-UN') > 0 then do; aeendtc = tranwrd(aeendtc, '-UN', ''); chk1 = 'Y'; end;
 	drop aesdisab aesdth aeshosp aeslife aescong aesoth;
	
	if nmiss(astdt,trtsdt) = 0 then astdy = astdt - trtsdt + (astdt >= trtsdt);
	if nmiss(aendt,trtsdt) = 0 then aendy = aendt - trtsdt + (aendt >= trtsdt);
run;   
 
/***treatment emergent flag***/

data ae2;
set ae2;
if aestdtc ne '' then do;
		aesmon = input(scan(aestdtc, 2, '-'), ??2.); 
		aesyear = input(scan(aestdtc, 1, '-'), 4.);
		aesday = input(scan(aestdtc, 3, '-'), ??2.); 
		trtsdtc = put(trtsdt, yymmdd10.); 

		if aesday ne . and aesmon ne . and aesyear ne . then taestart = mdy(aesmon, aesday, aesyear);
		else if aesday = . and aesmon = . then taestart = mdy(01, 01, aesyear);
		else if aesday = . then taestart = mdy(aesmon, 01, aesyear);
		if index(aestdtc, '-XX-XX') > 0 and substr(aestdtc, 1,4) = substr(trtsdtc, 1,4) then taestart = trtsdt;
		else if index(aestdtc, '-XX') > 0  and substr(aestdtc, 1,7) = substr(trtsdtc, 1,7) then taestart = trtsdt;
	end;
	if taestart ne . then do; if trtsdt <= taestart <= trtedt then do; trta = trt01p; trtemfl = 'Y';end;end; 
run;
*===============================================================================
* 3. Provide ATTRIB labels. 
*===============================================================================;  
libname atemp "P:\Rhythm\ADaM Standards\SASData\CDISCtemplates"; 
/*proc sort data=ae2 out=qdadae35 NODUPKEY;*/
/*	by usubjid aebodsys aedecod aeterm aestdtc aeendtc;  */
 data qdadae35; 
	set  ae2;  
	attrib AEACN	label= 'Action Taken with Study Treatment'
AEACNOTH	label= 'Other Action Taken'
AEBDSYCD	label= 'Body System or Organ Class Code'
AEBODSYS	label= 'Body System or Organ Class'
AEDECOD	label= 'Dictionary-Derived Term'
AEENDTC	label= 'End Date/Time of Adverse Event'
AEHLGT	label= 'High Level Group Term'
AEHLT	label= 'High Level Term'
AEHLTCD	label= 'High Level Term Code'
AEHLGTCD	label= 'High Level Group Term Code'
AELLT	label= 'Lowest Level Term'
AELLTCD	label= 'Lowest Level Term Code'
AENDT	label= 'Analysis End Date'
AEONGO	label= 'Ongoing Adverse Event'
AEOUT	label= 'Outcome of Adverse Event'
AEPTCD	label= 'Preferred Term Code'
AEREL	label= 'Causality'
AESCONG	label= 'Congenital Anomaly or Birth Defect'
AESDISAB	label= 'Persist or Signif Disability/Incapacity'
AESDTH	label= 'Results in Death'
AESER	label= 'Serious Event'
AESERN	label= 'Serious Event (N)'
AESEV	label= 'Severity/Intensity'
AESEVN	label= 'Severity/Intensity (N)'
AESHOSP	label= 'Requires or Prolongs Hospitalization'
AESLIFE	label= 'Is Life Threatening'
/*AESMIE	label= ''*/
AESOC	label= 'Primary System Organ Class'
AESOCCD	label= 'Primary System Organ Class Code'
AESTDTC	label= 'Start Date/Time of Adverse Event'
AESTDY	label= 'Study Day of Start of Adverse Event'
AETERM	label= 'Reported Term for the Adverse Event'
AETOXGR	label= 'Standard Toxicity Grade'
AETOXGRN	label= 'Standard Toxicity Grade (N)'
ARM	label= 'Description of Planned Arm'
ASTDT	label= 'Analysis Start Date'
BRTHYY	label= 'Year of Birth'
COUNTRY	label= 'Country'
COUNTRYL	label= 'Country Listings'
DSDECOD	label= 'Standardized Disposition Term'
ENRLFL	label= 'Enrolled Population Flag'
ICDT	label= 'Date of Informed Consent'
SAFFL	label= 'Safety Population Flag'
/*SCRRFFL	label= 'Screen Failure Flag'*/
STUDYID	label= 'Study Identifier'
SUBJID	label= 'Subject Identifier for the Study'
USUBJID	label= 'Unique Subject Identifier'
TRTP    label='Planned Treatment'
TRTA    label='Actual Treatment'
 astdy label='Analysis Start Relative Day'
aendy label='Analysis End Relative Day'; 
/*TRTEMFL label='Treatment Emergent Analysis Flag';*/
	format aeterm aerel aeout aeacn; 
run; 
 
*===============================================================================
* 4. Proc COMPARE.   
*===============================================================================; 	
%let keep=%str(studyid usubjid subjid country countryl brthyy  enrlfl saffl icdt 
			   arm trtsdt trtstm trtsdtm trtedt TRTEDTM TRTETM   trtp trta per1day  
			     /*dsdecod dsstdt scrrffl  armcd actarmcd actarm  AESMIE*/ dthfl dthdt

			   trtp trta aeterm aellt aehlt aehlgt aesoc aedecod aebodsys aeptcd aesoccd aebdsycd aehltcd aehlgtcd aelltcd     
			   aestdtc astdt aeendtc aendt aeongo  
			   aeser aesern aesev aeacn aeacnoth aerel aesern aesevn aetoxgr aetoxgrn aeout
			   aeshosp aescong aesdisab aesdth aeslife astdy   aendy /*aestdy trtemfl*/ ); 
proc sort data=qdadae35;
	by usubjid aebodsys aedecod aeterm astdt aendt;  run;
data qdadae35(label='Adverse Event Analysis Dataset 035'); 
	retain &keep;
	set qdadae35;
	by  usubjid aebodsys aedecod aeterm astdt aendt;  
	informat _all_; 		
	keep &keep;
run;
/*proc sort data=adam.adae_035 out=prd;	by;  run;*/



proc compare data=adam.adae_035 compare=qdadae35 listall;  
format aetoxgr; 
run;
