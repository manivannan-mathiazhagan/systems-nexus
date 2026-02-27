dm "log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\ADS\qd-advs.sas   
* DATE:        16NOV2024
* PROGRAMMER:  v emile
*
* PURPOSE:     Create QD-ADvs dataset     
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER:   vemile 
*   DATE:        add ANL01FL controlling dups
*   PURPOSE:     
*
************************************************************************************;   
%let pgm=qd-advs; 
%let pgmnum=0;  
%let protdir=&difi2201dsmb; 

%include "&protdir\macros\m-setup.sas";

PROC FORMAT;
VALUE TESTCD
1='HR'
2='RR'
3='TEMP'
4='SYSBP'
5='DIABP'
6='HGT'
7='WGT'
8='BMI';

VALUE TESTC
1='Heart Rate'
2='Respiratory Rate'
3='Temperature'
4='Systolic Blood Pressure'
5='Diastolic Blood Pressure'
6='Height'
7='Weight'
8='Body Mass Index';
run;

*===============================================================================
* 1a. Bring in raw vs.  
*===============================================================================; 
%macro getraw(indata);
data &indata;
set raw.&indata (encoding=any);
format _all_;
informat _all_;
length subjid $20 usubjid $35;
subjid=strip(SUBNUM);
usubjid =  'DIFI-22-01-' || strip(put(SITENUM,best.)) || '-' || strip(SUBNUM);  
run;
%mend;

%getraw(vs);  
data vital;
	set vs; 
length vstpt $50;
	if pagename='Vital Signs - Post Procedure' then do;
	vstptnum=2;
	vstpt='Post Procedure';
	end;
	else do;
	vstpt='Pre Procedure';
	vstptnum=1;
	end;
 
LENGTH SYSO DIAO RRO TMO HGO WGO BMIO PULO pulo2 pul  $10 VSORRES $200 VSORRESU $30 vsdtc $19;

if sysstat^=' ' THEN SYSO='ND';
ELSE                 SYSO=LEFT(PUT(sysorres,3.));
if diastat^=' ' THEN diaO='ND';
ELSE                 diaO=LEFT(PUT(diaorres,3.));
if rrstat ^=' ' THEN rro='ND';
ELSE                 rro=LEFT(rrorres);
if hrstat^=' '  THEN PULO='ND';
ELSE                 PULO=LEFT(hRorres);
if hrtstat^=' '  THEN PULO2='ND';
ELSE                  PULO2=LEFT(put(hRtorres,best.));
if tempstat^=' ' THEN tmO='ND';
ELSE                  tmo=LEFT(PUT(temporres,best.));
if HGTstat^=' ' THEN HGO='ND';
ELSE                 HGO=LEFT(PUT(HGTorres,BEST.));
if WGTstat^=' ' THEN WGO='ND';
ELSE                 WGO=LEFT(PUT(WGTorres,BEST.));

if lowcase(WORRESU_DEC)='lb' then wgt=WGTORRES*0.4536;else 
if lowcase(WORRESU_DEC)='kg' then wgt=WGTORRES;

if lowcase(HORRESU_DEC)='in' then hgt=HGTORRES*2.54;else 
if lowcase(HORRESU_DEC)='cm' then hgt=HGTORRES;

if lowcase(TMORRESU_DEC)='f' then tmp=(temporres-32)/1.8;else 
if lowcase(TMORRESU_DEC)='c' then tmp=temporres;

if pulo ne ' '  then pul=pulo;
if pulo2 ne ' ' then pul=pulo2;

adt=vsdat;
atm=vstim;
if vstim=. then vsDTC=strip(put(VSDAT,yymmdd10.));
ELSE aDTC=strip(put(VSDAT,yymmdd10.)) ||'T'||STRIP(PUT(VSTIM,TIME5.));
 
ADTM = dhms(ADT,0,0,VSTIM);

format ADT e8601da. ATM time5. ADTM   e8601dt.;

BMI=wgt/((hgt/100)**2);
bmio=left(put(bmi,best.)); 
bmiu="kg/m&s2";
sbu='mmHg';
pulu='beats/min';
rru='breaths/min';
tempu='C';
	
	array vit[8] PUL   RRO  TMO           SYSO     DIAO    HGO         WGO          bMIO;
	ARRAY VIC[8] pulu  RRU  TMORRESU_DEC  sbu      sbu     HORRESU_DEC wORRESU_DEC  bmiu; 

	do paramn=1 to 8;
		vsorres=vit[paramn];
		vsorresu=VIC[paramn];
	output;
	end;

	KEEP USUBJID vstpt vstptnum adt ATM vsdtc ADTM paramn VSORRES VSORRESU VISNAME VISITID pagename;
run;  

*proc print;
*where usubjid='DIFI-22-01-401-2120012';
*var usubjid visitid visname paramn  vsorres vsorresu;run;


data vital;
	set vital;
	length paramcd $8 param $100 avalu $30 avalc $200;
	paramcd=put(paramn,testcd.);

	IF VSORRES NE ' ';

	***STANDARD UNITS;
	IF paramn=6 then do;
	if UPCASE(VSORRESU)='IN' AND VSORRES^='ND' THEN do;
		AVAL=INPUT(VSORRES,BEST.)*2.54;
		avalu='cm';
		avalc=left(put(aval,6.1));
	end;
	else do;
		AVAL=INPUT(VSORRES,BEST.);
		avalc=left(put(aval,6.1));
	end;
	end;
	ELSE IF paramn=7 then do;
	if UPCASE(VSORRESU)='LB' AND VSORRES^='ND' THEN do;
		AVAL=INPUT(VSORRES,BEST.)*0.4536;
		avalu='kg';
		avalc=left(put(aval,6.1));
	end;
	else do;
		AVAL=INPUT(VSORRES,BEST.);
		avalc=left(put(aval,6.1));
	end;
	end;
	ELSE IF paramn=3 then do;
	if UPCASE(VSORRESU)='F' AND VSORRES^='ND' THEN do;
		res=INPUT(VSORRES,BEST.);
		aval=(res-32)*.5556;
		avalu='C';
		avalc=left(put(aval,6.1));
	end;
	else do;
		if substr(vsorres,1,1)^='N' then AVAL=INPUT(VSORRES,BEST.);
		avalc=left(put(aval,6.1));
	end;
	end;
	else if paramn=8 then do;
		if substr(vsorres,1,1)^='N' then AVAL=INPUT(VSORRES,BEST.);
		avalc=left(put(aval,6.1));
		avalu=left(vsorresu);
		end;
	ELSE do;
		if substr(vsorres,1,1)^='N' then AVAL=INPUT(VSORRES,BEST.);
		avalu=strip(vsorresu);
	end;

	
if substr(vsorres,1,1)='N' then avalc='ND';
else if avalc=' ' then AVALC=LEFT(put(aval,best.));

if avalu ne ' ' then param=strip(put(paramn,testc.)) || ' ('||left(strip(avalu) ||')');

length stvispd $25;
if visitid in (10,20) or index(lowcase(visname),'blinded')>0 then stvispd='Blinded';
ELSE stVISpd='Unblinded';

*IF index(lowcase(visname),'uns')>0  then stvispd=' ';

RUN;

*proc freq;
*tables visitid*visname/list missing;run;
*tables paramcd*aval*avalc/list missing;run;


*proc print;
*where usubjid='DIFI-22-01-401-2120012';
*var usubjid visitid visname paramn param aval avalc vsorres vsorresu;run;

proc sort data=VITAL out=param(keep=paramn paramcd param) nodupkey;
where param ne ' ';
by paramn;
run;


proc sort data=vital out=vitalsigns(drop=param);
	by paramn;
run;

data vital;
	merge param vitalsigns;
	by paramn;
run;

proc sort;
	by usubjid;
run;

proc sort data=ads.adsl out=adsl(keep=&keyvars TRT01: );
by usubjid;
run;

%getraw(bio);
data biopsy;
	set bio;
	if lowcase(bioyn_dec)='yes';
	keep usubjid biodat;
run;
proc sort data=biopsy out=biops;
	by usubjid biodat;
run; 

data biopsy;
set biops;
	by usubjid biodat;
	if first.usubjid;
run; 

data main;
   length trtp trta $100;
   merge VITAL(in=a) adsl(in=b) biopsy;
   by usubjid;
   if a and b;

	trtp = strip(trt01p);
	trtpn = trt01pn;
	trta = strip(trt01a);
	trtan = trt01an;

	if adt<biodat then stvispd='Blinded';
/*	if lowcase(stvispd)='blinded' then do;	 */
    if nmiss(adt,biodt) = 0 and adt >= biodt then ady=adt - biodt + 1; 
  	else if nmiss(adt,biodt) = 0 then ady=adt - biodt ; 
/*	end;*/
/*	else if lowcase(stvispd)='unblinded' then do;*/
/*    if nmiss(adt,trtsdt) = 0 and adt >= trtsdt then ady=adt - trtsdt + 1; */
/*  	else if nmiss(adt,trtsdt) = 0 then ady=adt - trtsdt ; */
/*	end;*/

	format biodat e8601da.;
run;

*proc print;
*where usubjid='DIFI-22-01-404-2120008';
*var usubjid adt biodat stvispd visitid visname;run;


PROC SORT;
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
run;

***BASELINE blinded;
PROC SORT DATA=MAIN OUT=BASELINE1(KEEP=USUBJID paramn PARAMCD PARAM AVAL ADT atm biodat stvispd visitid);
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
	WHERE pagename^='Vital Signs - Post Procedure' and AVAL NE . AND ADT<=biodat and lowcase(stvispd)='blinded' and index(lowcase(visname),'uns')=0;
RUN; 

*proc print;
*where usubjid='DIFI-22-01-404-2120008';
*run;

DATA BASE1;
	SET BASELINE1;
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
	IF LAST.paramn;
	RENAME AVAL=BASE1;
	KEEP USUBJID paramn PARAMCD PARAM AVAL adt visitid atm;
RUN;
PROC SORT;
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
run;

***BASELINE unblinded;
PROC SORT DATA=MAIN OUT=BASELINE2(KEEP=USUBJID paramn PARAMCD PARAM AVAL ADT atm stvispd visitid);
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
	WHERE pagename^='Vital Signs - Post Procedure' and AVAL NE . AND ADT<=trtsdt and lowcase(stvispd)='unblinded' and index(lowcase(visname),'uns')=0;
RUN; 
DATA BASE2;
	SET BASELINE2;
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
	IF LAST.paramn;
	RENAME AVAL=BASE2;
	KEEP USUBJID paramn PARAMCD PARAM AVAL adt visitid atm;
RUN;
PROC SORT;
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
run;

data base;
	merge base1 base2;
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
run;

DATA COMBO1;
	MERGE MAIN BASE;
	BY USUBJID paramn PARAMCD PARAM adt visitid atm;
	*if adt>trtsdt then CHG=AVAL-BASE;
	if adt>biodat then CHG=AVAL-BASE1;
/*	if lowcase(stvispd)='blinded'   and adt>biodat then  CHG=AVAL-BASE1;*/
/*	if lowcase(stvispd)='unblinded' and adt>trtsdt then  CHG=AVAL-BASE2;*/
RUN;
PROC SORT;
	BY USUBJID paramn PARAMCD PARAM ADT visitid;
RUN;
*proc print;
*var usubjid visitid visname stvis paramn paramcd aval base1 base2 chg biodat adt;
run;

DATA BASES1;
	SET BASELINE1;
	BY USUBJID paramn PARAMCD PARAM adt visitid;
	IF LAST.paramn;
	ABLFL1='Y';
RUN;


PROC SORT;
	BY USUBJID paramn PARAMCD PARAM ADT visitid;
RUN;

DATA BASES2;
	SET BASELINE2;
	BY USUBJID paramn PARAMCD PARAM ADT visitid;
	IF LAST.paramn;
	ABLFL2='Y';
RUN;

PROC SORT;
	BY USUBJID paramn PARAMCD PARAM ADT visitid;
RUN;


DATA COMBOu;
	MERGE COMBO1 BASES1 bases2;
	BY USUBJID paramn PARAMCD PARAM ADT visitid;

length  avisit $50;
avisit=strip(visname);
rename visitid=avisitn;
RUN;

data combou;
	set combou;
	base=base1;ablfl=ablfl1;
/*	if lowcase(stvispd)='blinded'   then do;base=base1;ablfl=ablfl1;end;*/
/*	if lowcase(stvispd)='unblinded' then do;base=base2;ablfl=ablfl2;end;*/
run;

proc sort;
	by usubjid paramn paramcd param adt atm avisitn vstptnum;
	run;
data combou;
	set combou;
	by usubjid paramn paramcd param adt atm avisitn vstptnum;
	if FIRST.VSTPTNUM then anl01fl='Y';
	if index(lowcase(avisit),'unsch')>0 then do;
		anl01fl=' ';
		stvispd=' ';
	end;
	if avisitn=10 and ablfl=' ' then anl01fl=' ';
	if base=. or aval=. then anl01fl=' ';

	if aval=. and ablfl='Y' then ablfl=' ';if vstptnum = 2  then ablfl=' ';
	if ablfl='Y' then anl01fl='Y';

IF ADT<=BIODT AND VSTPTNUM=2 AND ANL01FL='Y' THEN ANL01FL=' ';
	
*IF index(lowcase(visname),'uns')>0  then stvispd=' ';
run;
*proc print;
*where usubjid='DIFI-22-01-404-2120008';
*var usubjid avisitn avisit stvispd paramn adt adtm ady trtsdt biodat aval base ablfl ablfl1 ablfl2 anl01fl;run;

*proc freq ;
*tables AVISITN*AVISIT*stVIS/list missing;run;

*=============================================================================== 
* 2. Setting with ADS template for attributes.
*===============================================================================; 
data combo;
set combou atemp.BDS(in=master);
if master then delete;
run;

data combo;
set combo;
   label  
		 vsDTC='Start Date/Time of Adverse Event'
		 VSORRES='Original Result'
		 vsorres='Original Unit'
		 avisitn='Analysis Visit (N)'
		 avisit='Analysis Visit'
		 stvispd='Study Visit Period'
		 anl01fl='Analysis Flag 01'
		 vstpt='Timepoint'
		 vstptnum='Timepoint (N)'
	     ;
		 
run; 
proc sort;
	by usubjid paramn paramcd param adt atm;
	run;

*=============================================================================== 
* 3. Proc Compare.
*===============================================================================; 
data qc;
	set combo;
	keep &keyvars trtp trtpn trta trtan paramn PARAMCD PARAM  aval avalc adt ATM adtm ady avisitn avisit ABLFL base chg stvispd ablfl anl01fl vstpt vstptnum;* ablfl1 ablfl2 base1 base2 ; 
run;   


proc sort;
	by usubjid paramn avisitn vstptnum adt atm adtm  aval;*ablfl anl01fl;
	run;
	
*proc print;
*where usubjid='DIFI-22-01-401-2120023';
*proc print;
*where subjid='404-2120008' AND PARAMCD='HR';
*where subjid='404-2120049' and paramcd IN('RR' 'TEMP');
*WHERE SUBJID='417-2120015' AND PARAMCD='HR';
*where subjid='417-2120016' and paramcd='TEMP';
*where subjid='404-2120008' and paramcd='HR';
*var subjid avisitn avisit vstpt stvispd adt ady  paramn paramcd aval ablfl base chg anl01fl;run;*trtsdt biodt;

proc sort data=ads.advs out=adsadvs;
	   by usubjid paramn avisitn vstptnum  adt atm adtm  aval;*ablfl anl01fl;
run; 
*proc freq;
*tables vstptnum*vstpt/list missing;run;

*proc print;
*where subjid='401-2120023';
*where subjid='404-2120049' and paramcd IN('RR' 'TEMP');
*WHERE SUBJID='417-2120015' AND PARAMCD='HR';
*where subjid='404-2120008' and paramcd='HR';
*var subjid avisitn avisit vstpt stvispd adt atm ady paramn paramcd aval ablfl  base chg anl01fl;;run;

proc compare data=ads.advs comp=qc(label='Vital Signs Analysis dataset' ) listall criterion=0.0001;   
*where subjid='404-2120008';
*id subjid paramn paramcd avisitn vstptnum adt;
run;
