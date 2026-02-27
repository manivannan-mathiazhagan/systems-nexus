dm "log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-adae.sas  
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
*
* PURPOSE:     QC of ADAE.    
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:    
*
************************************************************************************;  
%let pgm=qd-adae; 
%let pgmnum=0;  
 
%let protdir=&rmhoiss; 
%include "&protdir\macros\m-setup.sas";
libname chk "P:\Rhythm\DSUR\ADSdata\CLIENT ADS NOT USED";
libname sdtm22 "P:\Projects\Rhythm\RM-493-022\Biostats\CSR\SDTMdata";
libname sdtm06 "P:\Projects\Rhythm\HO ISS\Biostats\SDTMdata\RM-493-006";
libname ads040 "P:\Projects\Rhythm\HO ISS\Biostats\ADSdata\Individual Studies\040 Toplines";
options nofmterr;

%let adaevar = %str(studyid SUBJID usubjid SITEID age ageu AGEGR1  AGEGR1N  AGEGR1 AGEGR2  AGEGR2N SBFL PTFL HOFL ARM  ARMN
TRTP sex sexn race raceoth racen ethnic ethnicn saffl P022FL  P042FL BRIDGEFL
 aeseq trta aeterm aept aellt aehlt aehlgt aesoc aedecod aebodsys astdt aendt ASTDY
 AENDY aeacn aesev asev asevn aestdtc aeendtc aeser aeshosp aerel aeout aescong aesdth aesdisab aeslife aesmie aetoxgr aeacnoth  
					 AESICAT AEENRF ASERFL ARELFL AWDFL AINTFL AESIFL ADTHFL trtemfl ASERFL ARELFL AWDFL AINTFL); *pstudy22 ptrtsdt ptrtedt;


%let adslvar = %str(studyid SUBJID usubjid SITEID age ageu sex sexn race raceoth racen ethnic ethnicn  AGEGR1  AGEGR1N  AGEGR1 AGEGR2  AGEGR2N SBFL PTFL HOFL HO30FL ARM  ARMN ARM2 
					 dthdt trtsdt trtedt trtstm trtetm trtsdtm saffl dsdecod dsstdt trt01p trt02p trt03p trt04p trt05p trt06p trt07p trt08p trt09p  TR01SDT  TR02SDT  TR03SDT  TR04SDT  TR05SDT  TR06SDT  TR07SDT  TR08SDT  TR09SDT INDEX22  INDEX42 BRIDGEFL


);

*===============================================================================
* 1a. Bring in ADAE_ALL, for the legacy study.   
*===============================================================================; 
*** get the data of the legacy study  ****;
data aeleg;
	set adsind.adae_all;
	where studyid in ('RM493-001' 'RM493-002' 'RM493-008' 'RM493-009' 'RM493-010');*'RM493-006';
	legfl = 'Y';
run;

data ADAE6;
set sdtm06.ae;
run;

*** Adjust length ***;
%macro type(in=,out=);
	data &out;
		length aerel aeout $100 trta $200;
		%if &in=adsind.ADAE_035 %then %do;
		set &in (rename=(aerel=aerel_ aeout=aeout_ trta=trta_));  %end;
		%else %do;
		set &in (rename=(aerel=aerel_ aeout=aeout_ trta=trta_));  %end;
		aerel = aerel_;
		aeout = aeout_;
		trta = trta_;
		%if &out=ADAE18 %then %do; drop race; %end;
/*		%if &out=ADAE35 %then %do; drop trta_; %end;*/
		format _ALL_;
		drop aerel_ aeout_ trta_;
	run;
%mend type;

%type(in=AELEG,out=AELEG) 
%type(in=adsind.ADAE_003,out=ADAE3) 
%type(in=adsind.ADAE_011,out=ADAE11) 
%type(in=adsind.ADAE_012,out=ADAE12) 
%type(in=adsind.ADAE_014,out=ADAE14) 
%type(in=adsind.ADAE_015,out=ADAE15) 
%type(in=adsind.ADAE_018,out=ADAE18) 
%type(in=adsind.ADAE_019,out=ADAE19) 
%type(in=adsind.ADAE_022,out=ADAE22) 
%type(in=adsind.ADAE_023,out=ADAE23) 
%type(in=adsind.ADAE_026,out=ADAE26) 
%type(in=adsind.ADAE_029,out=ADAE29) 
%type(in=adsind.ADAE_030,out=ADAE30) 
%type(in=adsind.ADAE_032,out=ADAE32) 
%type(in=adsind.ADAE_033,out=ADAE33) 
%type(in=adsind.ADAE_034,out=ADAE34)  
%type(in=adsind.ADAE_035,out=ADAE35)  
%type(in=adsind.ADAE_037,out=ADAE37)  
/*%type(in=adsind.ADAE_040,out=ADAE40) */
%type(in=adsind.ADAE_041,out=ADAE41)
%type(in=adsind.ADAE_042,out=ADAE42) 
%type(in=adsind.ADAE_043,out=ADAE43)
   
*===============================================================================
*  b. Add remainder for individual studies.   
*===============================================================================;  
data aeall;
length aetoxgr $100 actarmcd $ 200 aeacnoth $ 600 aeser $ 50 aesev $ 300 usubjid $200 
 aesmie $ 9 ageu $15 siteid $200 AESDISAB $20 AESCONG $20 AESDTH $20 AESLIFE $20 AESHOSP $20 ASEV $100 aerel $200 aeout $200;
	set aeleg adae3(in=a) adae11 adae12 adae14 adae15 adae18 adae19(in=b) 
	    adae22 adae23 adae26 adae29 adae30 adae32
		adae33 adae34 adae35 adae37 adae41 adae42 adae43 adae6 ads040.adae;
	if a or b then legfl = 'Y'; 

	if studyid='RM-493-040' then TRTEMFL40=TRTEMFL;
	rename AESDISAB= AESDISAB_ AESCONG=AESCONG_ AESDTH=AESDTH_ AESLIFE=AESLIFE_ AESHOSP=AESHOSP_ AEOUT=AEOUT_;
run;
 
proc sort data = aeall; by usubjid aeterm ; run;

*===============================================================================
*  c. Merge PSTUDY.
*===============================================================================; 
*** get the end date for the parent study subjects as they were enrolled into RM - 022  ***;
data pstudy(rename = (trtedt = ptrtedt trtsdt = ptrtsdt));
	set aeall;
	by usubjid aeterm;
	if first.usubjid;
	where studyid in ('RM493-011' 'RM493-012' 'RM493-014' 'RM493-015' 'RM493-023');
	pstudy22 = 'Y';
	keep usubjid trtedt trtsdt pstudy22;
run;

proc sort data = pstudy; by usubjid; run;

data aeall1;
	merge aeall(in=a) pstudy(in=b);
	by usubjid;
	if a;
	 studyid=strip(tranwrd(studyid, 'RM493', 'RM-493'));
	 usubjid=strip(tranwrd(usubjid, 'RM493', 'RM-493'));
	 if studyid='RM-493-037' then  usubjid=strip(tranwrd(usubjid, 'RM-493', 'RM-493-037'));
	 if studyid='RM-493-006' then  usubjid=strip(tranwrd(usubjid, 'RM-493-006', 'RM-493-006-001'));
run;

****ADAE022 INDEX22;

Data ind;
set sdtm22.suppdm;
if qnam='INDEXSN';
index22=qval;
studyid='RM-493-022';
keep studyid usubjid index22;
run; 
proc sort ; by usubjid; run;
proc sort data = aeall1; by usubjid; run;
 data aeall12;
	merge aeall1(in=a) ind(in=b);
	by usubjid;
	if a;
	run;

****ADAE042 INDEX42;

data ind42;
set raw42.ic;
length studyid $15 usubjid $35 subjid $50 index42 $200;
 studyid='RM-493-042';
 subjid=strip(PARTICIPANT_ID);
 subjid=strip(tranwrd(subjid, '042-', ''));
 *subjid="0"||strip(substr(subject,7));
 usubjid=trim(studyID)||'-'||subjid;

 index42=INDEXID;
 keep studyid usubjid index42;
run;

proc sort ; by usubjid; run;
proc sort data = aeall12; by usubjid; run;
 data aeall13;
	merge aeall12(in=a) ind42(in=b);
	by usubjid;
	if a;
	run;



proc sort data = ads.adsl out = ind22(keep = studyid usubjid INDEX22); by INDEX22; run;

data ind22;
set ind22;
if index22 ^=' ';
rename studyid=studyid22 usubjid=usubjid22;
run;

proc sort data = aeall13; by index22; run;
 data aeall14;
	merge aeall13(in=a) ind22(in=b);
	by index22;
	if a;

	if b then do; studyid=studyid22; usubjid=usubjid22; p022fl='Y'; end;
	run;


proc sort data = ads.adsl out = ind242(keep = studyid usubjid INDEX42); by INDEX42; run;

data ind242;
set ind242;
if index42 ^=' ';
rename studyid=studyid42 usubjid=usubjid42;
run;

proc sort data = aeall14; by index42; run;
proc sort data = ind242; by index42; run;
 data aeall15;
	merge aeall14(in=a) ind242(in=b);
	by index42;
	if a;

	if b then do; studyid=studyid42; usubjid=usubjid42; P042FL='Y'; end;
	run;
*===============================================================================
*  d. Merge ADSL.
*===============================================================================; 
proc sort data = aeall15; by studyid usubjid; run;
proc sort data = ads.adsl out = adsl(keep = &adslvar); by studyid usubjid; run;

data aeall2;
	merge aeall15(in=a drop = sex sexn race raceoth racen ethnic ethnicn hofl country countryl
					 dthdt trtsdt trtedt trtstm trtetm trtsdtm saffl dsdecod dsstdt age ageu SUBJID ARM SITEID trtp AEENRF TR02SDT INDEX22  INDEX42  AGEGR1 AGEGR1N) 
		  adsl(in=b);
	by studyid usubjid;
	if (saffl='Y' OR studyid = 'RM-493-041') AND (aeterm ne '' or aedecod ne '');

	 if studyid='RM-493-006' then do; ASTDT=input(aestdtc,??e8601da.);
	 AENDT=input(aeendtc,??e8601da.);end;
/*    if AErel='PROBABLY RELATED' then AEREL='POSSIBLY RELATED';*/
run;

data aeall2(rename = (aerel1 = aerel aerel1n = aerel1n ));
length tstartc tendc $ 10 trtemfl $ 1 aerel1 AEOUT $ 100 trta trtp  $200 AESDISAB AESCONG AESDTH AESLIFE $1 AESHOSP $3 AEENRF $7;
	set aeall2;
	by studyid usubjid;
	if upcase(aerel) in ('DEFINITELY RELATED' 'Y' 'YES' 'RELATED') then do; aerel1 = "DEFINITELY RELATED";  aerel1n= 1;end;
	if index(upcase(aerel), 'PROBAB') > 0 then  do; aerel1 = 'PROBABLY RELATED'; aerel1n= 2; end;
	else if index(upcase(aerel), 'POSSIB') > 0 then do; aerel1 = 'POSSIBLY RELATED'; aerel1n= 3;end;
	else if index(upcase(aerel), 'UNLIKELY') > 0 then do;aerel1 = 'UNLIKELY RELATED'; aerel1n= 4;end;
	else if upcase(aerel) = 'NOT RELATED' then do; aerel1 = aerel; aerel1n = 5; end;
	else if upcase(aerel) in ('NONE') then do; aerel1 = 'NOT RELATED'; aerel1n = 5; end;
	**18dec2023 As per client comment: Please take a conservative approach to call AEREL=RELATED when the status is UNKNOWN for subjects with SAFFL=Y;
	else if upcase(aerel) = 'UNKNOWN' and SAFFL='Y' then do; aerel1 = 'RELATED'; aerel1n = 1; end;
	else if upcase(aerel) = 'UNKNOWN' then do; aerel1 = aerel; aerel1n = 9; end;

	if aestdtc ne '' then tstartc = substr(aestdtc, 1, 10);


	if index(tstartc, '-UN') or index(tstartc, '-XX') then tstartc = tranwrd(tranwrd(tranwrd(tstartc, '-XX', ''), '-UN', ''), 'K-U', ''); 
	if index(tstartc, '-00') then tstartc = tranwrd(tstartc, '-00', '');
	if tstartc = 'XXXX' then tstartc = '';

	if aeendtc ne '' then tendc = substr(aestdtc, 1, 10);
	if index(tendc, '-UN') or index(tendc, '-XX') then tendc = tranwrd(tranwrd(tranwrd(tendc, '-XX', ''), '-UN', ''), 'K-U', '');
    if index(tendc, '-00') then tendc =tranwrd(tendc, '-00', '');
    if tendc = 'XXXX' then tendc = '';
   

	if length(tstartc) < 10 and tstartc ne '' then syear = input(scan(tstartc,1,'-'), 4.);
	if length(tstartc) = 7 and tstartc ne '' then smon = input(scan(tstartc,2,'-'), 2.);

	if length(tendc) < 10 and tendc ne '' then eyear = input(scan(tendc,1,'-'), 4.);
	if length(tendc) = 7 and tendc ne '' then emon = input(scan(tendc,2,'-'), 2.);

	if legfl = '' then 
	do;
		trtemfl = 'Y';
		format ASTDT AENDT e8601da.;

		*** derive Treatment Emergent flag  ***;
		if trtsdt ne . and astdt ne . and trtedt ne . then 
		do; 
			if astdt < trtsdt or astdt > trtedt + 28 then do; trtemfl = ''; flag = 'Y'; end;
		end;
		if length(tstartc) = 7  then 
		do; 
			if syear < year(trtsdt) or syear > year(trtedt) then trtemfl = '';
			if syear = year(trtsdt) and  smon < month(trtsdt) then trtemfl = '';
			if syear = year(trtsdt) and  smon = month(trtsdt) then 
			do;
				if length(tendc) = 10 and aendt > trtedt then trtemfl = '';
				else if length(tendc) = 7 then
					do; 
						if eyear > year(trtedt) then trtemfl = '';
						else if eyear = year(trtedt) and emon > month(trtedt) then trtemfl = '';
					end;
			end;
		end;

		if length(tstartc) = 4 then 
		do; 
			if syear < year(trtsdt) or syear > year(trtedt) then do; trtemfl = ''; end;
			else if year(trtsdt) = syear and length(tendc) = 7 then 
			do; 
				if eyear > year(trtedt) then trtemfl = '';
				else if eyear = year(trtedt) and emon > month(trtedt) then do; trtemfl = ''; end;
			end;
		end;

     	if tstartc = '' and tendc = '' then trtemfl = '';
		if upcase(aerel) in ('RELATED' 'POSSIBLY RELATED' 'PROBABLY RELATED' 'DEFINITELY RELATED') then trtemfl = 'Y';
	end;
	
	if trtsdt ne . and astdt ne . and trtedt ne . and trtsdt <= astdt <= (trtedt + 28) then trtemfl = 'Y'; **updated the flag for legacy study 003 **;
	*if cmiss(aestdtc, trtsdt, trtedt) = 0 and syear <= year(trtsdt) <= year(trtedt) and month(trtsdt) <= smon <= month(trtedt) then trtemfl = 'Y';
	if cmiss(aestdtc, trtsdt, trtedt) = 0 and year(trtsdt) <= syear <= year(trtedt) and month(trtsdt) <= smon <= month(trtedt) then trtemfl = 'Y';

	if trtemfl = 'Y' and cmiss(aestdtc, trtsdt, trtedt) = 0 and astdt = . and syear < year(trtsdt) then trtemfl = '';
	if trtemfl = 'Y' and nmiss(trtsdt, astdt) = 0 and astdt < trtsdt and legfl = '' then trtemfl = '';	
	if trtemfl = 'Y' and trtsdt ne . and astdt = . and syear < year(trtsdt) and legfl = '' then trtemfl = '';
	if cmiss(aestdtc, trtedt) = 0 and syear = year(trtedt) and smon > month(trtedt) then trtemfl = '';
	if trtsdt = . then trtemfl = '';
/*	if astdt = . then trtemfl = '';*/
	if flag = 'Y' then trtemfl = '';

	*** if the subject is a rollover subject from 11/12/14/15/23 then if AE's should be considered as treatment is the AE was ongoing on both study  ***;
	if studyid = 'RM-493-022' and aestdtc ne '' and ptrtedt ne . and pstudy22 = 'Y' then 
		do;
			if astdt ne . and astdt <= (ptrtedt + 28) and astdt >=ptrtsdt then trtemfl = 'Y';
			else if astdt = . and syear <= year(ptrtedt) and syear >= year(ptrtsdt) then trtemfl = 'Y';
		end;

		if trtsdt ne . and astdt ne . and trtedt ne . and astdt > (trtedt + 28) then  trtemfl = ' '; 

		if trtsdt^=. and syear = year(trtsdt) and  smon >= month(trtsdt) and astdt <= (trtedt + 28) then trtemfl = 'Y';

/*			if tstartc = '' and tendc = '' then trtemfl = '';*/
/*		if upcase(aerel) in ('RELATED' 'POSSIBLY RELATED' 'PROBABLY RELATED' 'DEFINITELY RELATED') then trtemfl = 'Y';*/
/*	end;*/

	aedecod = propcase(aedecod);
	aeterm = propcase(aeterm);
	aesoc = propcase(aesoc); 
	aellt = propcase(aellt); 
	aehlt = propcase(aehlt); 
	aept = propcase(aept);
	aehlgt = propcase(aehlgt);
	aeout = upcase(aeout_);
	aeacn = upcase(aeacn);
	aeacnoth = upcase(aeacnoth);
	aebodsys = propcase(aebodsys);
	AESDISAB= AESDISAB_; 
    AESCONG=AESCONG_; AESDTH=AESDTH_; AESLIFE=AESLIFE_; AESHOSP=AESHOSP_;
	 AETOXGR=upcase(AETOXGR);
/*	 AEOUT=AEOUT_;*/




tr02sdtc = put(tr02sdt,yymmdd10.);

 aestdtc_=substr(aestdtc,1,10);

Arm1=arm;
  
if AEBVFL = 'Y' and ((length(aestdtc_)=10 and aestdtc_ >= tr02sdtc) or (length(aestdtc_)=7 and aestdtc_ >= substr(tr02sdtc,1,7)) 
or (length(aestdtc_)=4 and aestdtc_ >= substr(tr02sdtc,1,4))) then ARM1='Bridging Visit';

/*else if studyid ='RM-493-040' and (tr02sdtc < aestdtc_)  or arm2= ' ' then  Arm1=arm;*/
/*else if arm1=' ' then Arm1='Setmelanotide';*/


    TRTP=Arm1;
	trta=arm1;


			***********************************ASTDY AENDY***************************;
	if nmiss(astdt,trtsdt) = 0 then astdy = astdt - trtsdt + (astdt >= trtsdt);
	if nmiss(aendt,trtsdt) = 0 then aendy = aendt - trtsdt + (aendt >= trtsdt);

		if AEONGO='ONGOING' and AENDT=. then AEENRF='ONGOING';

		if P022FL=' ' then P022FL='N';
if P042FL=' ' then P042FL='N';
	
	drop aerel aereln arm;

	*keep usubjid aestdtc aeendtc aeterm trtsdt trtedt aerel trtemfl syear smon astdt;
run;


proc sort data = aeall2; by studyid usubjid aestdtc aeendtc aeterm aedecod; run;

data aeall22;
	set aeall2(drop = aeseq);
	by studyid usubjid aestdtc aeendtc aeterm aedecod;

	arm=trtp;

	if arm='Setmelanotide' then armn=1;
	else if arm='Placebo' then armn=2;
	else if arm='Bridging Visit' then armn=3;
	else if arm='Blinded' then armn=4;
/*	if index(trtal, 'RM') > 0 then trta = trtal;*/
/*	if trtal = 'Off treatment' then trta = 'Off treatment';*/
/*	if trtal = 'Placebo' then trta = 'Placebo';*/
/*	if trtal = 'BLINDED' then trta = 'BLINDED'; */

	if AESDTH='Y' then ADTHFL='Y'; else ADTHFL='N'; 

	if aerel = '' then do; aerel = 'NOT RELATED'; aereln = 5; end;

/*	if index(trta, 'RM-493') > 0  then trta = 'RM-493';*/
/*	if index(trta, 'Placebo') > 0 then trta = 'Placebo'; */

	if AEDECOD=' ' then AEDECOD='[ Not Coded ]';
	if AEBODSYS=' ' then AEBODSYS='[ Not Coded ]';


run;

data aesi;
set raw.aesi;
if esi ne ' ';
keep aedecod esi;
run;
proc sort data = aesi nodupkey; by aedecod; run;
proc sort data = aeall22; by aedecod; run;

data aeall3;
merge aeall22(in=a) aesi;
by aedecod;
if a;
AESICAT=ESI;
if AESICAT^=' ' or aebodsys in ('Gastrointestinal Disorders' 'Psychiatric Disorders') then do; AESICAT=ESI; AESIFL='Y';end; else AESIFL='N';

If AESER = 'Y' then ASERFL = 'Y';else ASERFL = 'N';
If AEREL in  ('RELATED', 'DEFINITELY RELATED', 'PROBABLY RELATED', 'POSSIBLY RELATED') then ARELFL='Y';else ARELFL='N';
if AEACN in ("DRUG PERMANENTLY DISCONTINUED (NOT GIVEN ON THE DOSING DAY, DO NOT INTEND TO CONTINUE TREATMENT)", 'INJECTION DISCONTINUED PERMANENTLY'
'DRUG WITHDRAWN' 'INJECTION INTERRUPTED\INJECTION DISCONTINUED PERMANENTLY') then AWDFL='Y';else AWDFL='N';
if AEACN in ('INJECTION INTERRUPTED' 'DOSE INTERRUPTED' 'DRUG INTERRUPTED') then AINTFL='Y';else AINTFL='N';

If AETERM=' ' and  AEDECOD=' ' and AESTDTC=' ' then delete;


if studyid='RM-493-006' and AEREL='PROBABLY RELATED' then AEREL='POSSIBLY RELATED';


if asev^=' ' and aesev=' ' then aesev=asev;
if studyid='RM-493-040' then aesev=' ';

asev=aesev;

if aesev in ('LIFE THREATENING' 'DEATH') then asev='SEVERE';

if (studyid='RM-493-034')  then do;
	* Redefine AE Severirt and toxicity;
          if  AETOXGR = 'GRADE 1'  then do; ASEV='MILD'; end;
	 else if  AETOXGR = 'GRADE 2'   then do; ASEV='MODERATE';  end;
	 else if  AETOXGR = 'GRADE 3'  then do; ASEV='SEVERE';  end;
	 else if  AETOXGR = 'GRADE 4'  then do; ASEV='SEVERE'; end; end;

if  (studyid='RM-493-040') then do;
	* Redefine AE Severirt and toxicity;
          if  AETOXGR = '1'  then do; ASEV='MILD'; end;
	 else if  AETOXGR = '2'   then do; ASEV='MODERATE';  end;
	 else if  AETOXGR = '3' then do; ASEV='SEVERE';  end;
	 else if  AETOXGR = '4'  then do; ASEV='SEVERE'; end;
     else if  AETOXGR = '5'  then do; ASEV='SEVERE';  end; 
end;

if studyid='RM-493-003' and AESEV=' ' then ASEV='SEVERE'; 

if asev= 'MILD' then asevn=1;
else if asev= 'MODERATE' then asevn=2;
else if asev= 'SEVERE' then asevn=3;



if studyid='RM-493-040' then TRTEMFL=TRTEMFL40;

run;
proc sort data = aeall3;by studyid usubjid aestdtc aeendtc aeterm aedecod aept; run;

data qdadae;
     set aeall3;
	 by studyid usubjid aestdtc aeendtc aeterm aedecod aept;

		 if first.usubjid then aeseq = 1;
	else aeseq + 1;
/*     if a then delete; */
	 keep &adaevar;
run; 


proc sort data = qdadae; by studyid usubjid aestdtc aeendtc aeterm aedecod; run;

proc sql;
	alter table qdadae modify usubjid char(60), aesev char(100), aeser char(100), trta char(200), aetoxgr char(8), aeacnoth char(200),
	aesmie char(9);
quit;

*===============================================================================
* 4. Proc COMPARE.  
*===============================================================================;  
data qdadae(label = 'Adverse Event Analysis Dataset');
retain &adaevar;
	set qdadae;
	by studyid usubjid aestdtc aeendtc aeterm aedecod;
	
	if trta='BLINDED' then trta='Blinded';
	attrib 	studyid   					label = 'Study Identifier'
            usubjid             		label = 'Unique Subject Identifier'
			aeterm						label = 'Adverse event term';
			
	keep &adaevar ;
run;                   
 
proc compare data=ads.adae compare=qdadae listall;
attrib _all_ label = '';
format _all_;
informat _all_;
/*id studyid usubjid aeterm;*/
run;

data prod;
set ads.adae;
if usubjid='RM-493-014-011-004';run;

data qc;
set qdadae;
if usubjid='RM-493-014-011-004';run;
	
