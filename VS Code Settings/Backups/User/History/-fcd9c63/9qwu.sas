DM"log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-adsl-043.sas  
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
*
* PURPOSE:     QC of ADSL-043    
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:   
*             
************************************************************************************;  
%let pgm=qd-adsl-043; 
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
enrlfl saffl  COMPLFL/*scrrffl bsfl plfl bafl*/ icdt arm   trt01p trt01a trtsdt TR01SDT  trtstm trtsdtm trtedt trtetm trtedtm per1day dsterm 
dsdecod dsstdt dthdt dthfl;

*===============================================================================
* 1a. Bring in DM.  
*===============================================================================; 
data dm(rename=(age1=age race1=race sex1=sex ethnic1=ethnic));*ethnic1=ethnic ethnic;
length sex1 $3 race1 RACEOTH $50  ethnic1$25   AGEU$8 ;
set raw43.dm(drop=ETHNIC   sex  );
format _All_;
informat _all_;
age1=age;
AGEU="Years";
sex1=substr(strip(SEX_DEC),1,1);
sexn=input(sex1,sex.);
if lengthc(strip(RACE)) = 1 then RACE1=strip(RACE_DEC);
if lengthc(strip(RACE)) gt  1 then do;
		RACE1='OTHER';
		RACEOTH=strip(RACE_DEC);
		end;
if (upcase(strip(RACE_DEC))    in ('OTHER','OTH' )  ) then RACEOTH='OTHER';
racen=input(race1,race.);
ethnic1=strip(ETHNIC_DEC);
ethnicn=input(ethnic1,ethnic.);
BRTHYY=DMBRTYR;
if not missing(DMIADT) then  ICDT=input(put(DMIADT,yymmdd10.),E8601DA10.); 
else if not missing(DMICDT) then  ICDT=input(put(DMICDT,yymmdd10.),E8601DA10.); 
drop race age;
format icdt E8601DA10.;
run;
/****Enrolled pop*****/
data enr_sub;
length enrlfl$1;
set raw43.dat_asub;
format _all_;
informat _All_;
if strip(upcase(STATUSID_DEC))='ENROLLED' then ENRLFL='Y';
if enrlfl='Y';
run;
proc sort data=enr_sub;by subnum;run;
data enr_sub;
set enr_sub;
if last.subnum;
by subnum;
run;
/****Screened pop******/ 

data scrn_sub;
set raw43.dat_asub;
format _all_;
informat _all_;
if strip(upcase(STATUSID_DEC))='SCREENED' then SFLL='Y';
if SFLL='Y';
run;
/***screen failure pop****/
data sf;
length SCRRFFL$1;
set raw43.sf;
format _all_;
informat _all_;
SCRRFFL=strip(upcase(SFYN));
run;
proc sort data=sf;by subnum;run;
data sf;
set sf;
if last.subnum;
by subnum;
run;
/****treatment information ******/
data ex;
set raw43.ex;
 format _all_;
 informat _all_;
run;
proc sort data=ex;by subnum EXDT EXTM;run;
data ex_st;
	set ex;
	if first.subnum;
	by subnum EXDT EXTM;
	trtsdt=input(put(EXDT,yymmdd10.),E8601DA10.);
	trtstm=input(put(EXTM,E8601TM.),E8601TM.);
	if not missing(trtsdt) and not missing(trtstm) then 
	trtsdtm=input(put(trtsdt,E8601DA10.)||"T"||put(trtstm,tod5.),  e8601dt17.);
	format trtsdt E8601DA10. trtstm E8601TM. trtsdtm e8601dt17.;
run;
data ex_et;
	set ex;
	if last.subnum;
	by subnum EXDT EXTM;
	trtedt=input(put(EXDT,yymmdd10.),E8601DA10.);
	trtetm=input(put(EXTM,E8601TM.),E8601TM.);
	if not missing(trtedt) and not missing(trtetm) then 
	trtedtm=input(put(trtedt,E8601DA10.)||"T"||put(trtetm,tod5.),  e8601dt17.);
	format trtedt E8601DA10. trtetm E8601TM. trtedtm e8601dt17.;
 run;
/****death information******/
 data ae;
 set raw43.ae;
 format _all_;
 informat _all_;
 if strip(upcase(AEOUT_DEC))='DEATH' then dthfl='Y';
 if not missing(AESTDTX) then dthdt=input(put(input(AESTDTX,anydtdte.), e8601da10.), e8601da10.);
 format dthdt e8601da10.;
 if dthfl='Y';
 run;


proc sort data = raw43.et out = aedth;
by subnum;
where ETDDT ne .;
format _all_;
informat _all_;
run;

data aedth;
	set aedth;
	by subnum;
	dthfl = 'Y';
	if not missing(ETDDT) then dthdt = input(compress(ETDDT),date9.);
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
length dsterm dsdecod $ 90 ;
	set raw43.et;
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
length dsterm   DSDECOD    $90;
	set raw43.es;
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
length STATUSID_DEC arm $200 TRT01P TRT01A $80        ;
merge scrn_sub ex_st ex_et sf enr_sub ae_ eot eos dm(in=a);
by subnum;
if a;
if not missing(trtsdt) then SAFFL='Y';
else SAFFL='N';
if enrlfl='Y' then do; ;
	    arm = 'Setmelanotide'; 
/*        actarm = 'Setmelanotide'; */
        trt01p = 'RM-493 5.0';   
end;
if not missing(TRTSDT) and SAFFL='Y' then do;
		TR01SDT=TRTSDT;
		TRT01A='RM-493 5.0'; 
		end;
if enrlfl='N' then do; 
 call missing(arm, actarm, trt01p, trtsdt, trtstm, trtsdtm, trtedt ,trtetm,trtedtm); 
 end; 
if trtedt^=. then per1day = trtedt - trtsdt + 1;
if DSTERM='COMPLETED STUDY' or DSDECOD='COMPLETED STUDY' then COMPLFL='Y';
else COMPLFL='N';
 
run;

data fin;
length studyid $ 15 usubjid $35 subjid$20 siteid$10 COUNTRY countryl$50;
retain &keepvar;
set all;
studyid = 'RM-493-043';
	siteid = strip(put(SITENUM,best.)); 
	subjid = substr(subnum, 5); 
	usubjid=strip(studyid)||"-"|| strip(subjid);
	/***added USA per confirmation from rhythm***/
	COUNTRYL  ='USA';
	COUNTRY  ='USA';
keep &keepvar;
format   DSSTDT  ICDT       TR01SDT    E8601DA. TRTSDTM   TRTEDTM E8601DT.;
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
data qdadsl43; 	
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
 
data qdadsl43 (label='Subject Level Analysis Dataset 43 Study');
  	retain &keepvar;
   	set qdadsl43;  
	by usubjid;   
	informat _all_; 
   	keep &keepvar; 
run;   

proc compare data=adam.adsl_043 compare=qdadsl43 listall;   
run;

