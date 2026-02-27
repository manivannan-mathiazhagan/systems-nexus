dm "log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\ADS\qd-adlb.sas   
* DATE:        19NOV2024
* PROGRAMMER:  v emile
*
* PURPOSE:     Create QD-ADlb dataset     
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER:  v emile
*   DATE:        05 MAY 2025
*   PURPOSE:     KEEP NORMAL RANGES IN ADLB
*
************************************************************************************;   
%let pgm=qd-adlb; 
%let pgmnum=0;  
%let protdir=&difi2201dsmb; 

 
%include "&protdir\macros\m-setup.sas";
proc format;
value  $nrtest

 'Blood Urea Nitrogen (BUN)/UREA'='UREA'
 'Hematocrit'='HCT'
 'Hemoglobin'='HGB'
 'Platelet count'='PLAT'
 'Serum Creatinine'='CREAT'
 'White Blood Cell (WBC) count'='WBC';

run;


*===============================================================================
* 1a. Bring ALL RAW DATA
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


***CHEMISTRY;
%getraw(lbc);

proc sort data=lbc out=lbc;
by sitenum subnum visitid visname ;
run;

data chem;
	set lbc;

if visitid=170 and lowcase(lbcperf_dec)='no' then delete;

length lbyn $3 adtc $19 PARCAT1 $100 lbreasnd $200 lbsig $50;
lbreasnd=strip(reasnd);

PARCAT1='CHEMISTRY';
lbyn=strip(lbCperf_dec);
adt=dat;
atm=tim;
if tim=. then aDTC=strip(put(DAT,yymmdd10.));
ELSE aDTC=strip(put(DAT,yymmdd10.)) ||'T'||STRIP(PUT(TIM,TIME5.));
ADTM = dhms(ADT,0,0,TIM);

format ADT e8601da. ATM e8601tm. ADTM   e8601dt.;

  array one   [2] orres1 orres2 ;
  	
  array two   [2] UNIT1_dec unit2_dec;

  array THREE  [2] clsig1_dec  CLSIG2_DEC;

  array vcd $8     vsname1-vsname2('UREA','CREAT');

  array vcdn $30   vsnames1-vsnames2 ('Urea Nitrogen','Creatinine');
								
   do lbseq=1 to 2; 
	lbtestcd=vcd[lbseq];
	lbtest=vcdn[lbseq];
	lborresN=one[lbseq]; 
	LBORRESU=TWO[lbseq]; 
	lbsig=THREE[lbseq];  
   output;
end;

	KEEP USUBJID LBYN REFID lbreasnd adt ATM adtc ADTM parcat1 lbseq LBTESTCD LBTEST LBORRESN LBORRESU LBSIG VISNAME VISITID;
run; 
*proc print;
*var usubjid visitid visname lbyn lborresn lbREASND;run;


*** HEMATOLOGY;
%getraw(lbh);
data HEM;
	set lbH;
if visitid=170 and lowcase(lbhperf_dec)='no' then delete;

length lbyn $3 adtc $19 PARCAT1 $100 lbreasnd $200;

lbreasnd=strip(reasnd);
PARCAT1='HEMATOLOGY';
lbyn=strip(lbHperf_dec);
adt=dat;
atm=tim;
if tim=. then aDTC=strip(put(DAT,yymmdd10.));
ELSE aDTC=strip(put(DAT,yymmdd10.)) ||'T'||STRIP(PUT(TIM,TIME5.));
ADTM = dhms(ADT,0,0,TIM);

format ADT e8601da. ATM e8601tm. ADTM   e8601dt.;

  array one   [4] orres1 orres2 orres3 orres4;
  	
  array two   [4] UNIT1_dec unit2_dec UNIT3_dec unit4_dec;

  array THREE  [4] clsig1_dec  CLSIG2_DEC clsig3_dec  CLSIG4_DEC;

  array vcd $8     vsname1-vsname4('HCT','HGB','PLAT','WBC');

  array vcdn $30   vsnames1-vsnames4 ('Hematocrit','Hemoglobin', 'Platelet','Leukocytes');
								
   do LBSEQ=1 to 4; 
	lbtestcd=vcd[LBSEQ];
	lbtest=vcdn[LBSEQ];
	lborresN=one[LBSEQ]; 
	LBORRESU=TWO[LBSEQ]; 
	lbsig=THREE[LBSEQ];  
   output;
end;
KEEP USUBJID LBYN REFID lbREASND adt ATM adtc ADTM parcat1 LBSEQ LBTESTCD LBTEST LBORRESN LBORRESU LBSIG VISNAME VISITID;
run;  

*proc print;
*var usubjid visitid visname lbyn lborresn lbREASND;run;


data chemhem;
	set chem hem;
	
if parcat1='CHEMISTRY' THEN paramn=200+lbseq; 
ELSE paramn=100+lbseq; 

if LBTESTCD in ('PLAT' 'WBC') and  upcase(LBORRESU)="OTHER" then do;
if LBTESTCD='PLAT' then LBORRESU="K/uL";
if LBTESTCD='WBC' then LBORRESU="10^3/mm^3";
end;
run;

proc sort;
	by usubjid;
run;

***NORMAL RANGES;
data normal;
	set raw.dat_lbsn; 

	LENGTH LBTESTCD $8   NLBCAT $40;
	LBTESTCD=PUT(TESTC_DEC,$NRTEST.);
	origunt=unitc_dec;
	UNITC_DEC=UPCASE(UNITC_DEC);
	
	IF ENDDATE=. THEN ENDDATE=TODAY();


IF LBTESTCD IN('PLAT' 'HCT' 'HGB' 'WBC') THEN NLBCAT='HEMATOLOGY';
ELSE IF LBTESTCD IN('CREAT' 'UREAN') THEN NLBCAT='CHEMISTRY';
RUN;
proc sort;
	by labnum NLBCAT TESTC_DEC genderc_dec ;
run;

*PROC PRINT;
*WHERE RNGLOW=.;
*WHERE  NLBCAT='CHEMISTRY' AND LBTESTCD='C5B9';
*format testc_dec $15.;
*VAR LABNUM NLBCAT TESTC_DEC genderc_dec AGEUNIT rnglow rnghigh agelow agehigh effdate;* ruleid LBTESTCD lbstresu  NORMUNIT unitc_dec NRSEX effdate enddate AGEUNIT NRAGELO NRAGEHI  LBSTNRLO LBSTNRHI;;RUN;*testc_dec AGELOW AGEHIGH ;

PROC SORT data=normal;
	BY UNITC_DEC;

*- extract Preffered Units for LABS; 
data units; 
  set STDS.preferred_units;
  length unitc_dec $16;
  unitc_dec=upcase(trim(lborresu));
  drop lborresu;
run; 
proc sort data=units; 
  by unitc_dec; 
run;
 

*- add preffered units to labs table;
data NORMALU;
  merge NORMAL(in=a) units(in=b);
  by UNITC_DEC;
  if a; 
  	
	IF UNITC_DEC IN('THOU/�L' '10^3/�L') THEN PREUNT1C='10^9/L';
	
	IF UPCASE(UNITC_DEC) IN('% (PER 100 WBCS)' '/ 100 WBCS' '/ 100 WBCS') THEN PREUNT1C='%';

	LENGTH PR $25;
	PR=UPCASE(PREUNT1C);
RUN;


PROC SORT;
	BY   LBTESTCD PR;
run;

data si (drop=lborresu  LBTEST CONV_FCX);
  length PR $20 ;
	set STDS.siconv;
	pr=upcase(lborresu);
run;  
proc sort data=si;  
  by lbtestcd pr; 
run;  

* create final table;
data NORMALSI (drop=pr);
 merge NORMALU(in=a) si;
 by lbtestcd pr;
 if a;
 	
IF  RNGLOW=. AND RNGHIGH^=. THEN RNGLOW=0; 

 lbstnrlo=rnglow*conv_fct;
 lbstnrhi=rnghigh*conv_fct;
nrstresu=lbstresu;
 rename preunt1c=NORMUNIT;

      if upcase(genderc_dec)='FEMALE' THEN NRSEX='F';
 ELSE IF  upcase(genderc_dec)='MALE' THEN NRSEX='M';

drop testc  unitc GENDERC GENDERC_DEC   CONV_FCT ORIGUNT ORIGUNT TESTC_DEC ;
run;



DATA NORMALSI;
	SET NORMALSI;
		
	lbstresu=nrstresu;

	length LBORNRLO LBORNRhi $25;
	LBORNRLO=left(put(RNGLOW,best.));
	LBORNRHI=left(put(RNGHIGH,best.));
	FORMAT LABNUM;
RUN;


PROC SORT;
	BY LABNUM LBTESTCD NRSEX EFFDATE;

data both;
	set normalsi;
	if nrsex=' ';
run;
data bothgen;
	set both;
	NRSEX='M';
	OUTPUT;
	NRSEX='F';
	OUTPUT;
RUN;
data single;
	set normalsi;
	if nrsex^=' ';
run;

DATA LABNORM;
	SET SINGLE BOTHGEN;
RUN; 

title 'qc';
libname prodnr "P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\ADS";

*data prodnr.prodnr;
*	set labnorm1;
 
*	LENGTH NRSEX $1;
*	NRSEX=LEFT(TRIM(GENDERC));
*	drop testc_dec testc ageunit GENDERC;
*	FORMAT EFFDATE ENDDATE DATE9.;
*proc sort;
*	by labnum lbcat lbtestcd nrsex AGELOW effdate enddate agelow;
run;

*proc compare base=prodnr compare=PERIQC listall;
*id labnum lbcat lbtestcd NRSEX AGELOW;* EFFDATE ENDDATE AGELOW;
*run;

***check for duplicates;
PROC SQL; 
 CREATE TABLE mess7 AS 
   SELECT nlbcat,LBTESTCD,NrSEX,unitc_dec,AGELOW,AGEHIGH,effdate,enddate,LABNUM, count(*) as x
       FROM  LABNORM
       GROUP BY nlbcat,LBTESTCD,NRSEX,unitc_dec,AGELOW,AGEHIGH,effdate,enddate,LABNUM
       HAVING count(*) > 1;
QUIT;  

data labnorm;
set labnorm;

if lbtestcd='UREA' then nlbcat= 'CHEMISTRY';
if agelow= . then agelow=0;
if agehigh= . then agehigh=150;

run;

proc sort data=ads.adsl out=dm(keep=usubjid sex age);
	by usubjid;
	run;

data labs;
	merge chemhem(in=in1) dm(keep=usubjid sex age);
	by usubjid;
	if in1;
	if lowcase(sex)='female' then sex='F';
	else if lowcase(sex)='male' then sex='M';
	length unitc_dec $16;
	unitc_dec=upcase(lborresu);	
run; 
*-------------------------**** derive SI results ------------------------------------------;
proc sort;
	by unitc_dec;
run;
 
data labssu;
	merge labs(in=in1) units;
	by unitc_dec;
	if in1;
		
	IF lbtestcd='RBC' AND UNITC_DEC IN ('MIL/�L')then preunt1c='10^12/L';
	IF UNITC_DEC IN('% (PER 100 WBCS)' '/ 100 WBCS'  '/ 100 WBCs') THEN PREUNT1C='%';
 
	IF UNITC_DEC IN('THOU/�L' '10^3/�L' '10^3/µL') THEN PREUNT1C='10^9/L';

	LENGTH PR $25;
	pr=upcase(preunt1c);
	prefunt=preunt1c;
	drop preunt1c;
run; 

*PROC freq;
*tables prefunt*unitc_dec/list missing;
*RUN;

proc sort;
	by lbtestcd pr;
RUN;

data labssi;
	merge labssu(in=in1) si;
	by lbtestcd pr;
	if in1;
	
  	lbstresn=lborresn*conv_fct;

	RENAME LBORRESU=ORIGUNT;

	length  lborres $200;
	 
	IF  LBORRESN NE . THEN LBORRES=LEFT(TRIM(PUT(LBORRESN,BEST.)));
	
	IF lowcase(LByn)='no' THEN do;
		LBORRES='ND';
	END;

	*if lbstresu='10^9/L' then lbstresu='x10^9/L';
run;

*proc print;
*WHERE LBTESTCD IN('HCT');* AND parcat1='HEMATOLOGY';
*WHERE parcat1='URINALYSIS' AND USUBJID='CVN-102-102-104-006';
*WHERE LBSTRESN=. and lborresN ne .;* and parcat1='CEREBROSPINAL FLUID';
*var USUBJID VISITid VISname adt lbtestcd LBTEST  lborres lborresn pr UNITC_DEC ORIGUNT lbstresn LBSTRESU lbyn;run;
  

proc sql;  
 create table LOCALES as select   
  c.*, r.agelow, r.agehigh, r.nrsex, r.nrSTRESU, r.LBSTNRLO, r.LBSTNRHI, r.LBORNRLO,R.LABNUM, r.LBORNRHI,r.effdate,r.enddate
 from LabsSi as c   
 left join LABnorm as r 
  on  
c.parcat1=r.nlbcat and C.refid = R.LABNUM AND c.sex = r.nrsex and c.lbtestcd = r.lbtestcd and (upcase(c.lbstresu)=upcase(r.nrstresu)) 
and (r.agelow <= c.age <= r.agehigh) and (r.effdate <= c.adt <= r.enddate);
quit;


%getraw(sv);

data sv7;
	set sv;
	if visitid<100;
	keep usubjid  visdat;;
run;
proc sort nodupkey;
	by usubjid;
run;

proc sort data=locales;
	by usubjid;
run;


data locales;
	merge locales(in=in1) sv7;
	by usubjid;
	if in1;
	
	length  param $100 avalc $200;

	param=strip(lbtest);

	*if lbstresu ne ' ' then param=strip(lbtest) || ' ('||left(strip(lbstresu) ||')');

if lbstresn ne . then AVALC=strip(put(lbstresn,best.));
if lowcase(lbyn)='no' then avalc='ND';

rename 
lbstresn=aval
lbtestcd=paramcd;


length stvispd $25;
if adt<visdat then stvispd='Blinded';
else stvispd='Unblinded';

if visitid in (10,20) or index(lowcase(visname),'blinded')>0 then stvispd='Blinded';
ELSE stVISpd='Unblinded';
*IF index(lowcase(visname),'uns')>0  then stvispd=' ';

	drop PR   PREFUNT CONV_FCT age sex unitc_dec AGELOW  AGEHIGH  NRSEX  NRSTRESU refid labnum lbtest  ;  *refid is labnum in edc data;
run;
proc sort;
	by paramcd;
*proc print;
*where  PARAMCD in('HGB') ;
*var usubjid visitid visname stvispd paramcd lbyn aval avalc lbstresu lborres origunt;run;
*401-2120022;

proc sort data=locales out=param(keep=paramn paramcd param);
where param ne ' ';
by paramn;
run;

proc sort data=param nodupkey; by paramn; run;

proc sort data=locales out=locales(drop=param);
	by paramn;
run;

data final;
	merge param locales;
	by paramn;
run;

proc sort;
	by usubjid;
run; 

proc sort data=ads.adsl out=adsl(keep=&keyvars TRT01: );
by usubjid;
run;

data main;
   length trtp trta $100 lbnrind $30;
   merge final(in=a) adsl(in=b);
   by usubjid;
   if a and b;

	trtp  = strip(trt01p);
	trtpn = trt01pn;
	trta  = strip(trt01a);
	trtan = trt01an;

	 
    *if nmiss(adt,trtsdt) = 0 and adt >= trtsdt then ady=adt - trtsdt + 1; 
  	*else if nmiss(adt,trtsdt) = 0 then ady=adt - trtsdt ; 

	
	if adt<=biodt then stvispd='Blinded';
	*else stvispd='Unblinded';

	*if lowcase(stvispd)='blinded' then do;	 
    if nmiss(adt,biodt) = 0 and adt >= biodt then ady=adt - biodt + 1; 
  	else if nmiss(adt,biodt) = 0             then ady=adt - biodt ; 
	*end;
	*else if lowcase(stvispd)='unblinded' then do;
    *if nmiss(adt,trtsdt) = 0 and adt >= trtsdt then ady=adt - trtsdt + 1; 
  	*else if nmiss(adt,trtsdt) = 0              then ady=adt - trtsdt ; 
	*end;

	IF AVAL NE . AND LBSTNRLO NE . AND LBSTNRHI NE . THEN DO;

		IF AVAL LT LBSTNRLO THEN LBNRIND="LOW";
		ELSE IF AVAL GT LBSTNRHI THEN LBNRIND="HIGH";
		ELSE IF LBSTNRLO LE AVAL  LE LBSTNRHI THEN LBNRIND="NORMAL";

END;
run;

PROC SORT;
	BY USUBJID paramn PARAMCD PARAM;
run;
*proc print;
*where subjid='412-2120002';* and paramcd='HCT';
*var subjid adt visname trtsdt biodt ady stvispd trtsdt;run;



***BASELINE blinded;
PROC SORT DATA=MAIN OUT=BASELINE1(KEEP=USUBJID paramn PARAMCD PARAM AVAL ADT atm biodt stvispd);
	BY USUBJID paramn PARAMCD PARAM;
	WHERE AVAL NE . AND ADT<=biodt and lowcase(stvispd)='blinded' and index(lowcase(visname),'uns')=0;
RUN; 
DATA BASE1;
	SET BASELINE1;
	BY USUBJID paramn PARAMCD PARAM;
	IF LAST.paramn;
	RENAME AVAL=BASE1;
	KEEP USUBJID paramn PARAMCD PARAM AVAL;
RUN;
PROC SORT;
	BY USUBJID paramn PARAMCD PARAM;
run;

***BASELINE unblinded;
PROC SORT DATA=MAIN OUT=BASELINE2(KEEP=USUBJID paramn PARAMCD PARAM AVAL ADT atm stvispd);
	BY USUBJID paramn PARAMCD PARAM;
	WHERE AVAL NE . AND ADT<=trtsdt and lowcase(stvispd)='unblinded' and index(lowcase(visname),'uns')=0;
RUN; 
DATA BASE2;
	SET BASELINE2;
	BY USUBJID paramn PARAMCD PARAM;
	IF LAST.paramn;
	RENAME AVAL=BASE2;
	KEEP USUBJID paramn PARAMCD PARAM AVAL;
RUN;
PROC SORT;
	BY USUBJID paramn PARAMCD PARAM;
run;

data base;
	merge base1 base2;
	BY USUBJID paramn PARAMCD PARAM;
run;

DATA COMBO1;
	MERGE MAIN BASE;
	BY USUBJID paramn PARAMCD PARAM;
	*if adt>trtsdt then CHG=AVAL-BASE;
	if lowcase(stvispd)='blinded'   and adt>biodt then  CHG=AVAL-BASE1;
	if lowcase(stvispd)='unblinded' and adt>trtsdt then  CHG=AVAL-BASE2;
RUN;
PROC SORT;
	BY USUBJID paramn PARAMCD PARAM ADT;
RUN;
*proc print;
*var usubjid visitid visname stvis paramn paramcd aval base1 base2 chg biodt adt;
run;

DATA BASES1;
	SET BASELINE1;
	BY USUBJID paramn PARAMCD PARAM;
	IF LAST.paramn;
	ABLFL1='Y';
RUN;


PROC SORT;
	BY USUBJID paramn PARAMCD PARAM ADT atm;
RUN;

DATA BASES2;
	SET BASELINE2;
	BY USUBJID paramn PARAMCD PARAM;
	IF LAST.paramn;
	ABLFL2='Y';
RUN;

PROC SORT;
	BY USUBJID paramn PARAMCD PARAM ADT atm;
RUN;


DATA COMBOu;
	MERGE COMBO1 BASES1 bases2;
	BY USUBJID paramn PARAMCD PARAM ADT atm;

length  avisit $50;
avisit=strip(visname);
rename visitid=avisitn;
RUN;

data combou;
	set combou;
	if lowcase(stvispd)='blinded'   then do;base=base1;ablfl=ablfl1;end;
	if lowcase(stvispd)='unblinded' then do;base=base2;ablfl=ablfl2;end;
run;


proc sort;
	by usubjid paramn paramcd param adt atm;
	run;
data fcombou;
	set combou;
	by usubjid paramn paramcd param adt atm;
	if FIRST.adt then anl01fl='Y';
	if index(lowcase(avisit),'unsch')>0 then do;
		anl01fl=' ';
		stvispd=' ';
	end;
	if avisitn=10 and ablfl=' ' then anl01fl=' ';
	if base=. or aval=. then anl01fl=' ';

	if aval=. and ablfl='Y' then ablfl=' ';
	if ablfl='Y' then anl01fl='Y';

*IF index(lowcase(visname),'uns')>0  then stvispd=' ';
	drop base;
run;

proc sort data=combou out=bases(keep=usubjid paramn paramcd param base) nodupkey;
	where base ne .;
	by  usubjid paramn paramcd param;
run;
data combou;
	merge fcombou bases;
	by usubjid paramn paramcd param;
run;

*=============================================================================== 
* 2. Setting with ADS template for attributes.
*===============================================================================; 
data combo;
set combou ;*atemp.BDS(in=master);
*if master then delete;
rename 
adtc=lbdtc
lbsig=clsig;

length lborresu $100;
	if lowcase(origunt)='other' then lborresu='Other: Not Reported';
	else lborresu=trim(origunt);

	if LBORRES='' then LBORRES='ND';

run;

data combo;
set combo;
   label  
		 lbDTC='Start Date/Time of Adverse Event'
		 avisitn='Analysis Visit (N)'
		 avisit='Analysis Visit'
		 stvispd='Study Visit Period'
		 clsig='Clinically Significant'
		 paramcd='Parameter Code'
		 anl01fl='Analysis Flag 01'
		 lborres='Result or Finding in Original Units'
		 lborresu='Original Units'
		 trtp = 'Planned Treatment'
		 trtpn = 'Planned Treatment (N)'
		 trta = 'Actual Treatment'
		 trtan = 'Actual Treatment (N)'
		 parcat1= 'Parameter Category 1'
		 param = 'Parameter'
		 paramn = 'Parameter (N)'
		 adt = 'Analysis Date'
		 ady = 'Analysis Relative Day'
		 atm = 'Analysis Time'
		 adtm = 'Analysis Date/Time'
		 ablfl = 'Baseline Record Flag'
		 aval = 'Analysis Value'
		 base = 'Baseline Value'
		 chg = 'Change from Baseline'


	     ;

		 if adt=. and avisitn=170 then delete; ***remove unscheduled records if not done;
		 IF AVAL=. THEN do;
				AVALC=' ';
				anl01fl=' ';
		end;

run; 

proc sql noprint;
alter table combo modify lbstresu char (40), lborres char (40), lborresu char (40), parcat1 char (40), param char (40);
quit;

proc sort;
	by usubjid paramn paramcd param adt atm;
	run;
*=============================================================================== 
* 3. Proc Compare.
*===============================================================================; 
data qc;
	set combo;
	format atm time5.;
	
	keep &keyvars trtp trtpn trta trtan parcat1 paramn PARAMCD PARAM aval LBSTRESU  adt ATM ady adtm avisitn avisit ABLFL clsig base chg stvispd anl01fl lborres lborresu lbstnrlo lbstnrhi lbnrind; 
run; 
*proc print;
*where USUBJID='DIFI-22-01-412-2120017';
*where USUBJID='DIFI-22-01-401-2120053';
*where usubjid='DIFI-22-01-412-2120017';
*where subjid='412-2120005' and paramcd='UREA';

*where subjid='401-2120053' and paramcd='HCT';
*where subjid='412-2120002' and paramcd='HCT';
*var usubjid paramn PARAMCD param adt atm avisitn avisit aval  LBSTRESU BASE ABLFL anl01fl lborres LBORRESU CHG;
run;

proc sort;
	by usubjid paramn paramcd adt;;run;
*proc freq;
*tables parcat1*paramn*paramcd*param/list missing;run;

proc sort data=ads.adlb out=adsadlb;
	by usubjid paramn paramcd adt; ;run; 


*proc print;
*where USUBJID='DIFI-22-01-401-2120053';
*where usubjid='DIFI-22-01-412-2120003';
*where usubjid='DIFI-22-01-412-2120017';
*where subjid='412-2120002' and paramcd='HCT';
*where subjid='412-2120005' and paramcd='UREA';
*var usubjid paramn paramcd param adt atm ady trtsdt avisitn avisit aval BASE ABLFL anl01fl LBORRES LBORRESU chg;
run;

*proc freq;
*tables parcat1*paramn*paramcd*param/list missing;run;

proc compare data=ads.adlb comp=qc(label='Laboratory Analysis dataset' ) listall;   
/*id subjid  paramcd adt;*/
*var aval;
run;
