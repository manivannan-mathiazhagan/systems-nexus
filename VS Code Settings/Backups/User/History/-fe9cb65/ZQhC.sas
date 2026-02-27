DM"log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-adsl-041.sas  
* DATE:        12OCT2023
* PROGRAMMER:  IR  
*
* PURPOSE:     QC of ADSL-041.    
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:   
*             
************************************************************************************; 
options nofmterr; 
%let pgm=d-adsl-041; 
%let pgmnum=0;  
 
%let protdir=&rmhoiss; 
%include "&protdir\macros\m-setup.sas"; 

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
					'CAN' = 'Canada'
					'ARG'='Argentina';
run;
 
%let cutoff = &cutdt;


*===============================================================================
* 1a. Bring in DM.  
*===============================================================================; 
data dm(rename=(age1=age race1=race sex1=sex ethnic1=ethnic));*ethnic1=ethnic ethnic;
length sex1 $3 race1 RACEOTH $50  ethnic1$25   AGEU$8 ;
set raw41.dm(drop=ETHNIC race sex  );
format _All_;
informat _all_;
age1=age;
AGEU="Years";
sex1=substr(strip(SEX_DEC),1,1);
sexn=input(sex1,sex.);
RACE1=strip(RACE_DEC);
if upcase(strip(race_dec)) in ('OTHER','OTH' ) then RACEOTH='OTHER';
racen=input(race1,race.);
ethnic1=strip(ETHNIC_DEC);
ethnicn=input(ethnic1,ethnic.);
/*COUNTRY='ARG';*/
/*COUNTRYL='ARG';*/
BRTHYY=DMBRTYR;
if not missing(DMASSDT) then ICDT=input(put(DMASSDT,yymmdd10.),E8601DA10.);
else if not missing(DMASGDT) then ICDT=input(put(DMASGDT,yymmdd10.),E8601DA10.);
else if not missing(DMICDT) then ICDT=input(put(DMICDT,yymmdd10.),E8601DA10.);
 drop age;;
 format ICDT E8601DA10.;
run;
/****Get country*****/
proc import datafile="&protdir\RAWdata\RM-493-041\(WCT) Rhythm RM-493-041 Manual Data Request 001 - Production Extract.csv"
    out=count
    dbms=csv
    replace;
    getnames=yes;
run;
data countr;
length country COUNTRYL $ 50 ;
set count;
SUBNUM=strip(scan(SITE_SUBJECT_NUMBER_SUBJECT_STAT,2,'|'));
country=strip(scan(SITE_SUBJECT_NUMBER_SUBJECT_STAT,6,'|'));
COUNTRYL=COUNTRY;
run;

proc sort data=countr;by SUBNUM;run;
proc sort data=dm;by SUBNUM;run;
data dm1;
merge dm(in=a)  countr;
by SUBNUM ;
if a ;
 run;

/*****flags****/

/****Enrolled & Screen failure pop*****/
data enr_sub;
length enrlfl$1;
set raw41.sf;
format _all_;
informat _All_;
if strip(upcase(SFYN))='N' then ENRLFL='Y';
else enrlfl='N';
if strip(upcase(SFYN))='Y' then SCRRFFL='Y';
else SCRRFFL='N';
run;
proc sort data=enr_sub;by subnum;run;
data enr_sub;
set enr_sub;
if last.subnum;
by subnum;
run;
 
/****Screened pop******/ 

data scrn_sub;
set raw41.dat_asub;
format _all_;
informat _all_;
if strip(upcase(STATUSID_DEC))='SCREENED' then SFLL='Y';
if SFLL='Y';
run;
proc sort data=scrn_sub;by subnum;run;
data scrn_sub;
set scrn_sub;
if last.subnum;
by subnum;
run;
/****treatment information *******/
 
  data ex;   
 set raw41.exdx;
 format _all_;
 informat _all_; 
 TRTSDT=input(put(DXCDT,yymmdd10.),E8601DA10.);
 trtstm=input(put(EXDXCTM,time5.),time5.);
 if not missing(DXCDT) and not missing(EXDXCTM) then 
trtsdtm=input(put(DXCDT,yymmdd10.)||"T"||put(EXDXCTM,time5.), e8601dt.);
trtedt=trtsdt;
trtetm=trtstm;
trtedtm=trtsdtm;
/*if not missing(trtsdt) then SAFFL='Y';*/
format trtsdt e8601da. trtstm e8601dt. trtsdtm e8601dt.;
run;


proc sort data=ex;by subnum trtsdt trtstm trtsdtm;run ;
data ex_st(keep= subnum trtsdt trtstm trtsdtm TRTSDT trtstm);
set ex;
if first.subnum;
by subnum trtsdt trtstm trtsdtm;
run;
data ex_et(keep= subnum trtedt trtetm trtedtm);
set ex;
if last.subnum;
by subnum trtsdt trtstm trtsdtm; 
run;
/****death information******/
 data ae;
 set raw41.ae;
 format _all_;
 informat _all_;
 if strip(upcase(AEOUT_DEC))='DEATH' then dthfl='Y';
 if not missing(AESTDTX) then dthdt=input(put(input(AESTDTX,yymmdd10.), e8601da10.), e8601da10.);
 format dthdt e8601da10.;
 if dthfl='Y';
 run;

proc sort data = raw41.et out = aedth;
by subnum;
where ETDDT ne .;
format _all_;
informat _all_;
run;

data aedth;
	set aedth;
	by subnum;
 	dthfl = 'Y';
	if nmiss(ETDDT) = 0 then dthdt =   input(put(ETDDT,yymmdd10.), e8601da10.) ;
	if first.subnum;
	keep subnum dthdt dthfl;
	format dthdt e8601da.;
run;

data ae_;
merge aedth ae;
by subnum dthdt;
run;

 /***subject status*****/
 

data eot;
length dsterm dsdecod $ 90  ;
	set raw41.et;
	format _all_;
	informat _all_;
	if strip(upcase(ETDSC))='Y' then DSTERM='COMPLETED TREATMENT';
	else if strip(upcase(ETDSC))='N' then DSTERM=Upcase('Discontinued Treatment');
	else if strip(upcase(ETDSC))=' ' and missing(ETDT) then DSTERM=Upcase('Ongoing');
  	DSSTDT =input(put(ETDT,yymmdd10.),E8601DA.) ;
if strip(upcase(ETDSC))='N'  then do;
	if not missing(ETPT_DEC) then do;
	DCTREAS=strip(ETPT_DEC);
    end;
  	if not missing(ETAE) then do;
	DCTREAS=strip(ETAE);
    end; 
	if not missing(ETDDT) then do;
	DCTREAS='DEATH';
	DSSTDT =input(put(ETDDT,yymmdd10.),E8601DA.) ;
	end;
 end;
	dsdecod=dsterm; 
run; 
data eos;
length dsterm dsdecod $ 90  ;
	set raw41.es;
	format _all_;
	informat _all_;
	if strip(upcase(ESDSC))='Y'   then DSTERM='COMPLETED STUDY';
	else if strip(upcase(ESDSC))='N' then DSTERM=Upcase('Discontinued STUDY');
	else if strip(upcase(ESDSC))=' ' and missing(ESDT) then DSTERM=Upcase('Ongoing Study');
  	DSSTDT =input(put(ESDT,yymmdd10.),E8601DA.) ;
if strip(upcase(ESDSC))='N'  then do;
	if not missing(ESPT_DEC) then do;
	DSTERM=strip(ESPT_DEC);
    end;
  	if not missing(ESAE) then do;
	DSTERM=Upcase("Adverse Event");
    end; 
	if not missing(ESDDT) then do;
	DSTERM='DEATH';
	DSSTDT =input(put(ESDDT,yymmdd10.),E8601DA.) ;
	end;
 end;
	dsdecod=dsterm; 
run; 
data all;
length STATUSID_DEC arm$200 trt01P trt01A $80;
merge enr_sub scrn_sub ex_st ex_et /*ex01*/ ae_ eot eos dm1(in=a);
by subnum;
if a;
SAFFL='N';
/*if not missing(trtsdt) then SAFFL='Y';*/
/*else SAFFL='N';*/
if enrlfl='Y' then do; ;
	    arm = 'BLINDED'; 
       
end;
if not missing(TRTSDT)   then do;
 		TRT01A='RM-493 3.0'; 
		  trt01p = 'RM-493 3.0';  
TR01SDT=TRTSDT; 
end;
if enrlfl='N' then do; 
 call missing(arm, actarm, trt01p, trtsdt, trtstm, trtsdtm, trtedt ,trtetm,trtedtm); 
 end; 
if trtedt^=. then per1day = trtedt - trtsdt + 1;
if DSTERM='COMPLETED STUDY' or DSDECOD='COMPLETED STUDY' then COMPLFL='Y';
else COMPLFL='N';
 
run; 
%let keepvar=  studyid usubjid subjid siteid age ageu sex sexn race racen raceoth ethnic ethnicn country countryl brthyy 
enrlfl saffl  COMPLFL/*scrrffl bsfl plfl bafl*/ icdt arm   trt01p trt01a trtsdt TR01SDT  trtstm trtsdtm trtedt trtetm trtedtm per1day dsterm 
dsdecod dsstdt dthdt dthfl;
data fin;
length usubjid $35 subjid $20 siteid$10 STUDYID   $15 ;
retain &keepvar;
set all;
studyid = 'RM-493-041';
	siteid = strip(put(SITENUM,best.)); 
	subjid = substr(subnum, 5); 
	usubjid=strip(studyid)||"-"|| strip(subjid);
 keep &keepvar;
format   DSSTDT  ICDT       TR01SDT    E8601DA. TRTSDTM   TRTEDTM E8601DT. TRTSTM TRTETM     E8601TM.  ;
run;
*===============================================================================
* 3. Provide ATTRIB labels. 
*===============================================================================;  
/*libname atemp "P:\Rhythm\ADaM Standards\SASData\CDISCtemplates"; */
/**/
/* */
/*data fin; */
/*	set template.occds(in=master drop=sex usubjid country: subjid siteid  ) fin; */
/*   	if master then delete;*/
/*	informat _all_; */
/*run; */
 
libname template 'P:\Projects\Rhythm\ADaM Standards\SASData\CDISCtemplates';
data qdadsl41; 	
	set fin;
	by usubjid;

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
;
run;

*===============================================================================
* 4. Proc COMPARE.  
*===============================================================================;   
 
data qdadsl41 (label='Subject Level Analysis Dataset 41 Study');
  	retain &keepvar;
   	set qdadsl41;  
	by usubjid;   
	informat _all_; 
   	keep &keepvar; 
run;   

proc compare data=adam.adsl_041 compare=qdadsl41 listall;   
run;

