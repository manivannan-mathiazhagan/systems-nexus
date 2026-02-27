DM"log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-adsl-042.sas  
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
*
* PURPOSE:     QC of ADSL-042    
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:   
*             
************************************************************************************;  
%let pgm=qd-adsl-042; 
%let pgmnum=0;  
 
%let protdir=&rmhoiss90;

%include "&protdir\macros\m-setup.sas";
libname chk "P:\Rhythm\DSUR\ADSdata\CLIENT ADS NOT USED";
options nofmterr;

proc format;
	invalue sex 'M' = 1
				'F' = 2;

	invalue race 'AMERICAN INDIAN OR ALASKAN NATIVE' = 1
				 'ASIAN' = 2
				 'BLACK OR AFRICAN AMERICAN' = 3
				 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' = 4
				 'WHITE' = 5
				 'NOT REPORTED' = 98
				 'OTHER' = 99;

	invalue ethnic 	'HISPANIC OR LATINO' = 1
					'NOT HISPANIC OR LATINO' = 2
					'NOT REPORTED' = 3
					'UNKNOWN' = 4;
	
	invalue trtact 	'RM-493 1.5' = 37.15
					'RM-493 1.0' = 37.1
					'RM-493 0.5' = 37.05
					'RM-493 0.25' = 37.025
					'RM-493 2.0' = 37.2
					'RM-493 2.5' = 37.25
					'RM-493 0.75' = 37.075
					'RM-493 3.0' = 37.3;
					
	value $country	'USA' = 'United States' 
					'PRI' = 'Puerto Rico'
					'CAN' = 'Canada';
run;
 
%let cutoff = &cutdt;


%let keepvar=  studyid usubjid subjid siteid age ageu sex sexn race racen raceoth ethnic ethnicn country countryl brthyy 
enrlfl saffl  COMPLFL/*scrrffl bsfl plfl bafl*/ icdt arm   trt01p trt02p trt01a trt02a trtsdt TR01SDT  TR02SDT trtstm trtsdtm trtedt trtetm trtedtm per1day dsterm 
dsdecod dsstdt dthdt dthfl;

*===============================================================================
* 1a. Bring in DM.  
*===============================================================================; 
data dm(rename=(age1=age race1=race sex1=sex ethnic1=ethnic RACEOTH1=RACEOTH));*ethnic1=ethnic ethnic;
length sex1 $3 race1 RACEOTH $50  ethnic1$25   AGEU$8 ;
set raw42.dm ;
format _All_;
informat _all_;
age1=AGEY;
AGEU="Years";
BRTHYY=DMBRTYR;
RACE1=put(RACE,SASFORMAT38SASF41.); 
racen=input(race1,race.);
RACEOTH1=upcase(strip(RACEOTH));
ethnic1=strip(put(ETHNIC,SASFORMAT28SASF22.));
ethnicn=input(ethnic1,ethnic.);
sex1=substr(strip(put(SEX,SASFORMAT45SASF18.)),1,1);
sexn=SEX;
drop race   SEX RACEOTH ethnic RACE;
run;
data ic;
set raw42.ic;
format _All_;
informat _all_;
 if not missing(DMICDT) then ICDT= input(strip(DMICDT),yymmdd12.);
 if not missing(ICDT) then enrlfl='Y';
 else enrlfl='N'; 
keep icdt dmicdt enrlfl PARTICIPANT_ID SITE_ABBREVIATION;
run;
proc sort data=ic;by PARTICIPANT_ID icdt;run;
data ic;
set ic;
if first.PARTICIPANT_ID;
by PARTICIPANT_ID icdt;
run;

/****Enrolled pop*****/

data ie;
set raw42.ieec;
format _All_;
informat _all_;
if strip(upcase(IEEC))='Y' then SCRRFFL='N';
else if strip(upcase(IEEC))='N' then SCRRFFL='Y';
keep SCRRFFL PARTICIPANT_ID SITE_ABBREVIATION IEEC;
run;
/****treatment information ******/
data ex;
set raw42.ex;
 format _all_;
 informat _all_;
 if strip(upcase(EXPERF)) in ('Y','YES');
 date= input(EXSTDAT,yymmdd10.) ;
 time= input(EXSTTIM,time.) ;
 if not missing(date) and not missing(time) then 
 datetime=input(put(date,E8601DA.)||"T"||put(time,tod.),  e8601dt.);
 format date E8601DA. time E8601TM. datetime E8601DT19.;
/* if PARTICIPANT_ID='042-002-002';*/
run;
proc sort data=ex;by PARTICIPANT_ID   EXSTDAT   EXSTTIM;run;
data ex_st(rename=(date=TRTSDT time=TRTSTM datetime=TRTSDTM));
	set ex;
	if first.PARTICIPANT_ID;
	by PARTICIPANT_ID   EXSTDAT   EXSTTIM;
 run;
data ex_et(rename=(date=TRTEDT time=TRTETM datetime=TRTEDTM));;
	set ex;
	if last.PARTICIPANT_ID;
	by PARTICIPANT_ID EXSTDAT EXSTTIM; 
 run;
/****death information******/
 data ae(where=(DTHFL='Y'));
 set raw42.ae;
 format _all_;
 informat _all_;
 if AESER_OUT_DEATH=1 then do;
 DTHDT=input(strip(AESTDTX),yymmdd12.);
 DTHFL='Y';
 end;
 KEEP  PARTICIPANT_ID SITE_ABBREVIATION DTHFL DTHDT;
run;
PROC SORT DATA=AE;
BY PARTICIPANT_ID DTHDT;
RUN;
DATA AE;
SET AE;
IF LAST.PARTICIPANT_ID;
BY PARTICIPANT_ID DTHDT;
RUN;
 

 

 /***subject status*****/
 

data eot(rename=(dsdecod1=dsdecod));
length dsterm dsdecod1 $200 ;
	set raw42.es;
 	 dsterm=put(DSDECOD,SASFORMAT27SASF38.);
     DSSTDT=input(strip(ESDT),yymmdd12.); 
	 dsdecod1=put(DSDECOD,SASFORMAT27SASF38.);;
 	 keep PARTICIPANT_ID SITE_ABBREVIATION   DSSTDT dsdecod1 dsterm ESDSC;
	 TRT01P='RM-493';
	 TRT01A='RM-493';
 	 run;

	/***treatment arm information*****/
	 data ex;
	 set raw42.ex;
	 informat _all_;
	 format _all_;
/*	 if PARTICIPANT_ID='042-006-004';*/
	 if strip(upcase(EXPERF)) in ('Y','YES');
 	 TR01SDT= input(EXSTDAT,yymmdd10.) ;
 	 if EXDOSE=3 then do;
	 TRT01P='RM-493 3.0';
	 TRT01A='RM-493 3.0';
	 output;
	 end;
	 if EXDOSE=2 then do;
	 TRT01P='RM-493 2.0';
	 TRT01A='RM-493 2.0';
	 output;
	 end;
	 if EXDOSE=1 then do;
	 TRT01P='RM-493 1.0';
	 TRT01A='RM-493 1.0';
	 output;
	 end;
keep tr:  PARTICIPANT_ID SITE_ABBREVIATION EXDOSE EXSTDAT;
	 run;
	 proc sort data=ex;	 by PARTICIPANT_ID SITE_ABBREVIATION EXSTDAT;run;

	 data ex;
	 set ex;
	 by PARTICIPANT_ID SITE_ABBREVIATION  ;
	 if first.PARTICIPANT_ID;
	 run;

data ex1;
set raw42.ex; 

 	 TR02SDT= input(DCDOSDT,yymmdd10.) ;
	 if DCDOS=3 then do;
	 TRT02P='RM-493 3.0';
	 TRT02A='RM-493 3.0';
	 output;
	 end;
	 if DCDOS=2 then do;
	 TRT02P='RM-493 2.0';
	 TRT02A='RM-493 2.0';
	 output;
	 end;
	 if DCDOS=1 then do;
	 TRT02P='RM-493 1.0';
	 TRT02A='RM-493 1.0';
	 output;
	 end;
	 keep tr:  PARTICIPANT_ID SITE_ABBREVIATION EXPERF DCDOS DCDOSDT;
	 run;
	 data ex1;
	 set ex1;
	 by PARTICIPANT_ID SITE_ABBREVIATION DCDOSDT;
	 if last.PARTICIPANT_ID;
	 run;

  proc sort data=ex;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=ex1;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
	 data ex_;
	 merge ex ex1;
	 by SITE_ABBREVIATION PARTICIPANT_ID   ;
	 run;

  proc sort data=ic;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=ie;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=ex_st;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=ex_et;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=ex_;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=ae;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=eot;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
  proc sort data=dm;	 by SITE_ABBREVIATION PARTICIPANT_ID   ;run;
data all;
length   arm $200 TRT01P TRT01A $80        ;
merge ic ie ex_st ex_et ex_ ae  eot   dm(in=a);
by SITE_ABBREVIATION PARTICIPANT_ID;
if a;
arm = 'Setmelanotide'; 
if trtedt^=. then per1day = trtedt - trtsdt + 1;
run;
 
data fin;
length studyid $ 15 usubjid $35 subjid$20 siteid$10 COUNTRY countryl TRT02P TRT02A$50;
retain &keepvar;
set all;
    studyid = 'RM-493-042';
 	siteid = strip(put(input(SITE_ABBREVIATION,best.),z3.)); 
	subjid = substr(PARTICIPANT_ID, 5); 
	usubjid=strip(studyid)||"-"|| strip(subjid);
	/***added USA per confirmation from rhythm***/
	COUNTRYL  ='USA';
	COUNTRY  ='USA';
	 if strip(upcase(ESDSC)) in ('YES','Y') then COMPLFL='Y';
	 else COMPLFL='N';
	if enrlfl='Y' and not missing(TRTSDT) then SAFFL='Y';
	Else SAFFL='N';
	 if enrlfl='N' then do; 
	 call missing(arm, actarm, trt01p, trtsdt, trtstm, trtsdtm, trtedt ,trtetm,trtedtm); 
	 end; 
	 if enrlfl ='N' or SAFFL='N' then do;
	 COMPLFL='N';
	 end;

keep &keepvar;
format   DSSTDT  ICDT  icdt    DTHDT TR01SDT  TR02SDT DSSTDT E8601DA. TRTSDTM   TRTEDTM E8601DT.  ; 
run;
*===============================================================================
* 3. Provide ATTRIB labels. 
*===============================================================================;  
/*libname atemp "P:\Rhythm\ADaM Standards\SASData\CDISCtemplates"; */

 
/*data fin; */
/*	set template.occds(in=master drop=sex usubjid  subjid siteid country:    ) fin; */
/*   	if master then delete;*/
/*	informat _all_; */
/*run; */
/*  */
proc sort data=fin;by siteid usubjid ;run;
data qdadsl42; 	
	set fin;
 	if dthdt=. then dthfl='';
	format dthdt trtsdt trtedt E8601DA.   ;
 
	attrib	
	age label='Age'
	AGEU	label=	'Age Units'
ARM	label=	'Description of Planned Arm'
BRTHYY	label=	'Year of Birth'
COMPLFL	label=	'Completers Population Flag'
COUNTRY	label=	'Country'
COUNTRYL	label=	'Country Listings'
DSDECOD	label=	'Standardized Disposition Term'
DSSTDT	label=	'Date of Disposition'
DSTERM	label=	'Reported Term for the Disposition Event'
DTHDT	label=	'Date of Death'
DTHFL	label=	'Death Flag'
ENRLFL	label=	'Enrolled Population Flag'
ETHNIC	label=	'Ethnicity'
ETHNICN	label=	'Ethnicity (N)'
ICDT	label=	'Date of Informed Consent'
PER1DAY	label=	'Person Days in period 1'
RACE	label=	'Race'
RACEN	label=	'Race (N)'
RACEOTH	label=	'Race Other, Specify'
SAFFL	label=	'Safety Population Flag'
/*SCRRFFL	label=	'Screen Failure Flag'*/
SEX	label=	'Sex'
SEXN	label=	'Sex (N)'
SITEID	label=	'Study Site Identifier'
STUDYID	label=	'Study Identifier'
SUBJID	label=	'Subject Identifier for the Study'
TR01SDT	label=	'Date of First Exposure in Period 01'
TRT01A	label=	'Actual Treatment for Period 01'
TRT01P	label=	'Planned Treatment for Period 01'
TRTEDT	label=	'Date of Last Exposure to Treatment'
TRTEDTM	label=	'Datetime of Last Exposure to Treatment'
TRTETM	label=	'Time of Last Exposure to Treatment'
TRTSDT	label=	'Date of First Exposure to Treatment'
TRTSDTM	label=	'Datetime of First Exposure to Treatment'
TRTSTM	label=	'Time of First Exposure to Treatment'
USUBJID	label=	'Unique Subject Identifier'
TR02SDT label='Date of First Exposure in Period 02'
TRT02P  label='Planned Treatment for Period 02'
TRT02A  label='Actual Treatment for Period 02';
run;

*===============================================================================
* 4. Proc COMPARE.  
*===============================================================================;   
 
data qdadsl42 (label='Subject Level Analysis Dataset 42 Study');
  	retain &keepvar;
   	set qdadsl42;  
	by usubjid;   
	informat _all_; 
   	keep &keepvar; 
run;   

proc compare data=adam.adsl_042 compare=qdadsl42 listall;   
run;

