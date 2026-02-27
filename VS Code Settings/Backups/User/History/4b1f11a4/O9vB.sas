dm "log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\ADS\qd-adae.sas   
* DATE:        04NOV2024
* PROGRAMMER:  Shashi
*
* PURPOSE:     Create QD-ADAE dataset     
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER:  v emile
*   DATE:        1/15/2025
*   PURPOSE:     completion
*
************************************************************************************;   
%let pgm=qd-adae; 
%let pgmnum=0;  
%let protdir=&difi2201dsmb; 

%include "&protdir\macros\m-setup.sas";


*===============================================================================
* 1a. Bring in raw AE.  
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

***visit 7 date blinded visits;

%getraw(sv);  
proc sort data=sv out=sv(keep=usubjid visitid visname visdat);
	by usubjid visitid;
	*where visitid=110;***visit 7, 100 is visit 6 last blinded visit;
run;

*proc freq data=raw.des_vdef;
*tables visitid*visname/list missing;run;

*proc freq data=sv;
*tables visitid*visname/list missing;run;


proc sort data=raw.dat_mc_meddra out=meddra(drop= VISNAME  PAGENAME VISITID  VISITSEQ
PAGEID  PAGESEQ  TABNAME LASTMDT DELETED CODEDT  CODINGMETHOD DICTIONARY_VERSION) nodupkey;
by term;
where colname='AETERM';
run;
data meddra;
	set meddra;
	length aeterm aebodsys aedecod $200;
	aeterm=left(upcase(term));
    aebodsys = left(soc_term);
	aedecod = left(pt_term);

	keep aeterm aebodsys aedecod;
run;
proc sort DATA=MEDDRA OUT=MEDDRA NODUPKEY;
	by aeterm;
run;

%getraw(ae); 

data ae1;
set ae(rename=(AETERM=AETERM_) drop=AESEV AEOUT AEACN aerel1 aerel2 aerel3 ) ;
 length AESTDTC AEENDTC  AEHOSDTC AEHOEDTC  $19 aetoxgr $7 aeterm med5othsp preexspo SAETERM $200 AESER $3 
 /*AETOXGR $1*/ aeacn  $100 AEOUT  aerel1c aerel2c aerel3c $50;

ASTDT=AESTDAT;
AENDT=AEENDAT;
AESTDTC=strip(put(AESTDAT,yymmdd10.));
AEENDTC=strip(put(AEENDAT,yymmdd10.));
if upcase(ONGOYN_DEC)='YES' then AEENRF='ONGOING';

   aeterm = strip(upcase(aeterm_));
   

   aetoxgr=strip(aesev_dec);
   AETOXGRn=input(scan(AESEV_DEC,2,' '),1.);
   AESER=strip(AESERYN_DEC);
   AEOUT=strip(AEOUT_DEC);
   AEACN=strip(AEACN_DEC);
   AEREL1=strip(AEREL1_DEC);
   AEREL2=strip(AEREL2_DEC);
   AEREL3=strip(AEREL3_DEC);
   AEDISC=DISCOTYN_DEC;
   aerel1c=strip(aerel1_dec);
   aerel2c=strip(aerel2_dec);
   aerel3c=strip(aerel3_dec);  
   med5othsp=strip(MEDOTHSP);
   preexspo=strip(preexsp);
SAETERM=STRIP(SAEDESC);

rename 
SIDEYN_DEC=SIDEYND
TRTE_DEC=trted
PREEXYN_DEC=PREEXYND;


AEHOSDTC=strip(put(HOSSTDAT,yymmdd10.));
AEHOEDTC=strip(put(HOSENDAT,yymmdd10.));

	
if AESTDTC~='' and length(AESTDTC) LT 7 then put "WARN" "ING: Need to add imputation: " usubjid=;

format astdt aendt e8601da.;
keep usubjid AESTDTC AEENDTC  astdt aendt AEENRF aeseq aeterm  AETOXGR aetoxgrn  TRTE_DEC CPNUM 
MEDICAL1 MEDICAL2 MEDICAL3 MEDICAL5 med5othsp AEOUT  AEACN aerel1c aerel2c aerel3c
PREEXYN_DEC PREEXSPo AESER AEDEATH AESLIF AESDIS AESHOS AEHOSDTC AEHOEDTC AESCON 
AEINTER  AESMIE  SAETERM  SIDEYN_DEC AEDISC AECOUNT;    
run;

proc sort;
	by aeterm;
run;

data ae1;
	merge ae1(IN=IN1) meddra;
	by aeterm;
	IF IN1;
run;


proc sort data=ae1;
	by usubjid ;
run;

proc sort data=ads.adsl out=adsl(keep=&keyvars TRT01: );by usubjid;run;

data main;
   length trtp trta $100;
   merge ae1(in=a) adsl(in=b);
   by usubjid;
   if a and b;

	trtp = strip(trt01p);
	trtpn = trt01pn;
	trta = strip(trt01a);
	trtan = trt01an;
	 
   * if nmiss(astdt,trtsdt) = 0 and astdt >= trtsdt then astdy=astdt - trtsdt + 1; 
  *	else if nmiss(astdt,trtsdt) = 0 then astdy=astdt - trtsdt ; 

	*if nmiss(aendt,trtsdt) = 0 and aendt >= trtsdt then aendy=aendt - trtsdt + 1; 
  	*else if nmiss(aendt,trtsdt) = 0 then aendy=aendt - trtsdt ; 

	
    if nmiss(astdt,biodt) = 0 and astdt >= biodt then astdy=astdt - biodt + 1; 
  	else if nmiss(astdt,biodt) = 0 then astdy=astdt - biodt ; 

	if nmiss(aendt,biodt) = 0 and aendt >= biodt then aendy=aendt - biodt + 1; 
  	else if nmiss(aendt,biodt) = 0 then aendy=aendt - biodt ; 

	if  . < trtsdt <= astdt  then TRTEMFL="Y";

	  if nmiss(aendt,astdt)=0 then ADUR=(aendt-astdt)+1;

	  
	rename PREEXSPo=PREEXSP;
LENGTH AEREL1 AEREL2 AEREL3 $3 AEREL $100;
	if lowcase(aerel1c)='not related' then Aerel1='NR';
	if lowcase(aerel1c)='unlikely'    then Aerel1='UNL';
    if lowcase(aerel1c)='possibly'    then Aerel1='POS';
    if lowcase(aerel1c)='probably'    then Aerel1='PRO';
    if lowcase(aerel1c)='definitely'  then Aerel1='DEF';
    if lowcase(aerel1c)='unknown'     then Aerel1='UNK';

	
	if lowcase(aerel2c)='not related' then Aerel2='NR';
	if lowcase(aerel2c)='unlikely'    then Aerel2='UNL';
    if lowcase(aerel2c)='possibly'    then Aerel2='POS';
    if lowcase(aerel2c)='probably'    then Aerel2='PRO';
    if lowcase(aerel2c)='definitely'  then Aerel2='DEF';
    if lowcase(aerel2c)='unknown'     then Aerel2='UNK';

	
	if lowcase(aerel3c)='not related' then Aerel3='NR';
	if lowcase(aerel3c)='unlikely'    then Aerel3='UNL';
    if lowcase(aerel3c)='possibly'    then Aerel3='POS';
    if lowcase(aerel3c)='probably'    then Aerel3='PRO';
    if lowcase(aerel3c)='definitely'  then Aerel3='DEF';
    if lowcase(aerel3c)='unknown'     then Aerel3='UNK';

	AEREL=CATX('/',AEREL1,AEREL2,AEREL3);

LENGTH AEOUTc $25;
if lowcase(aeout)='recovered'               then aeoutc='ReD';
if lowcase(aeout)='recovering'              then aeoutc='RnG';
if lowcase(aeout)='not recovered'           then aeoutc='NReD';
if lowcase(aeout)='recovered with sequelae' then aeoutc='ReDw';
if lowcase(aeout)='fatal'                   then aeoutc='DTH';
if lowcase(aeout)='lost to follow-up'       then aeoutc='LFU';



	/*unbldt='27dec2024'd;*2024-12-27;*/
      unbldt='28feb2025'd;****************  CHECK LATER FOR WHEN WE HAVE VISITN 7;

	***SB:28feb2025 In SV currently there is no visit 7 so ***;
	length Stvispd $25;
	if astdt <=unbldt then STVISPD='Blinded';
	ELSE STVISPD='Unblinded';
	format unbldt e8601da.;

run;  

*=============================================================================== 
* 2. Setting with ADS template for attributes.
*===============================================================================; 
data temp;
set main(drop=AEREL1 AEREL2 AEREL3) atemp.adae(in=master);
if master then delete;
run;

data main1;
set temp;

rename
SAETERM=SAEdesc
preexynd=preexyn
trted=trte
MED5OTHsp=MEDOTHsp
sideynd=sideyn
AEREL1C=AEREL1
AEREL2C=AEREL2
AEREL3C=AEREL3
;

   label 
   stvispd='Study Visit Period'
         AEOUT='Outcome'
		 AESTDTC='Start Date/Time of Adverse Event'
		 AEENDTC='End Date/Time of Adverse Event'
		 AEDEATH ='Death'
		 AESLIF='Life Threatening'
		 AESCON='Congenital Anomaly or Birth Defect'
		 AESHOS='Requires or Prolongs Hospitalization'
		 AESMIE='Other Medically Important Serious Event'
		 AESDIS='Persist or Signif Disability/Incapacity'
		 
		 aerel1c='Relationship to Study Product'
		 aerel2c='Relationship to Biopsy Procedure'
		 aerel3c='Relationship to Injection Procedure'
		 AeTOXGR='Standard Toxicity Grade'
		 AeTOXGRN='Standard Toxicity Grade (N)'
         
		 ADUR='Analysis Duration'
		 AEENRF='End Relative to Reference Period'
		 TRTED    ='Treatment of Event'
		 SAETERM='SAE Description'
		 MED5OTHsp='Other Specify'
/*		 PREEXSPO='Pre-existing condition specify'*/
PREEXYND='Pre-existing Condition?'
SIDEYND='Expected/Foreseeable side-effect?'		
AEHOEDTC='Date of Discharge'
AEHOSDTC='Date of Hospitalization' 
AEINTER ='Require Medical or Surgical Intervention'
AEDISC='AE Leading to Discontinuation'
AEREL='All Relationship'
preexsp='Specify'
aeoutc='Outcome Code'
	     ;
run;  

*=============================================================================== 
* 3. Proc Compare.
*===============================================================================; 
data qc;
retain &keyvars trtp trtpn trta trtan aeseq aeterm trtemfl aebodsys aedecod  astdt astdy aestdtc AEENRF aendt aendy aeendtc
		            AETOXGR AETOXGRN TRTE CPNUM MEDICAL1 MEDICAL2 MEDICAL3 MEDICAL5 medothsp AEOUT aeoutc  
					AEACN aerel1 aerel2 aerel3 aerel
PREEXYN PREEXSP AESER AEDEATH AESLIF AESDIS AESHOS AEHOSDTC AEHOEDTC AESCON AEINTER  
AESMIE  SAEdesc  SIDEYN AEDISC AECOUNT STVISPD;
	set main1;
	if aeterm ne ' ';
	keep &keyvars trtp trtpn trta trtan aeseq aeterm trtemfl aebodsys aedecod  astdt astdy 
	aestdtc AEENRF aendt aendy aeendtc
		            AETOXGR AETOXGRN TRTE CPNUM MEDICAL1 MEDICAL2 MEDICAL3 MEDICAL5 medothsp 
					AEOUT  AEOUTC AEACN aerel1 aerel2 aerel3 aerel
PREEXYN PREEXSP AESER AEDEATH AESLIF AESDIS AESHOS AEHOSDTC AEHOEDTC AESCON AEINTER  AESMIE  
SAEdesc  SIDEYN AEDISC AECOUNT STVISPD;
run;  
proc sort;by  usubjid aestdtc aeendtc aebodsys aedecod aeterm;run;
proc sort data=ads.adae out=prod;by  usubjid aestdtc aeendtc aebodsys aedecod aeterm;run;

proc compare data=ads.adae comp=qc(label='Adverse Event Analysis dataset' ) listall;   
run;
