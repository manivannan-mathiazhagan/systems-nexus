DM"log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-adsl-035.sas  
* DATE:        004APRIL2025
* PROGRAMMER:  Indira Ravula (based on Laxmi Choudhary structure/QD-ADSL-037)
*
* PURPOSE:     QC of ADSL-035    
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:   
*             
************************************************************************************;  
options nofmterr;
%let pgm=d-adsl-035; 
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
				 'NOT REPORTED' = 7
				 'OTHER' = 6
				 'MISSING'=99;

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
data dm(rename=(age1=age race1=race RACEOTH1=RACEOTH sex1=sex ethnic1=ethnic));*ethnic1=ethnic ethnic;
length sex1 $3 race1 RACEOTH $50  ethnic1$25  siteid AGEU$8  ;;
set raw35.dm(drop=siteid) ;
format _All_;
informat _all_;
age1=AGE;
AGEU="Years";
sex1=strip(SEX_STD);
sexn=input(SEX_STD,sex.);
RACE1=strip(upcase(DMRACE));
if strip(upcase(DMRACE))='AMERICAN INDIAN OR ALASKA NATIVE' then race1='AMERICAN INDIAN OR ALASKAN NATIVE';
if strip(upcase(DMRACE))in (' ',  'UNKNOWN' ) then RACE1='MISSING';
RACEOTH1=strip(upcase(RACEOTH));
racen=input(RACE1,??race.);
ethnic1=strip(ETHNIC_STD);
ethnicn=input(ethnic1,ethnic.);
BRTHYY=BRTHYR_YYYY;
 drop RACEOTH age sex ethnic; 
 siteid=scan(sitenumber,2,'-');
 run; 
/****Get country*****/
data countr  ; 
set raw35.country; 
run; 
proc sort data=countr;by siteid;run;
proc sort data=dm;by siteid;run;
data dm1;
merge countr dm(in=a);
by siteid;
if a;
run;


 /***informed consent date***/
 data ic;
	 set raw35.ic;
	 icdt=   input(scan(put(ICSDAT_INT,datetime.),1,":"),date9.) ;
	 format icdt E8601DA10.;
	 if not missing(icdt) then ENRLFL='Y';
	 else ENRLFL='N';
 run;
proc sort data=ic;by subject ICSDAT_INT ICVDAT_INT;run;

data ic;
set ic;
if first.subject;
by subject ICSDAT_INT ICVDAT_INT;
run; 
data ie;
set raw35.ie;
if folder='SCR' ;
if IEYN_STD='N' then SCRRFFL='Y';
Else SCRRFFL='N';
run;
proc sort data=ie;by subject ICDAT_INT IEADAT;run;

data ie;
set ie;
if last.subject;
by subject ICDAT_INT IEADAT;
run; 
/****Enrolled pop*****/
/*data enr_sub;*/
/*length enrlfl$1;*/
/*set raw35.ex;*/
/*format _all_;*/
/*informat _All_;*/
/*if strip(upcase(folder))='ENROLL' then ENRLFL='Y'; */
/*if ENRLFL='Y'; */
/*run; */
/*proc sort data=enr_sub;by SUBJECT;run;*/
/*data enr_sub;*/
/*set enr_sub;*/
/*if last.SUBJECT;*/
/*by SUBJECT;*/
/*run;*/

/***safety pop****/ 
proc sort data=raw35.ex out=sf(where=(strip(upcase(EXPERF))='YES'));by subject exstdat;run;
data ex_st;
set sf;
if first.SUBJECT;
by SUBJECT EXSTDAT; 
if not missing(EXSTDAT_INT) then trtsdt= input(scan(put(EXSTDAT_INT,e8601dt.),1,'T') ,E8601DA10.);
if not missing(EXSTTIM) then trtstm=  input(EXSTTIM,time.) ;
if not missing(trtsdt) and not missing(trtstm) then 
trtsdtm=input(put(trtsdt,E8601DA.)||"T"||put(trtstm,tod.), e8601dt.);
format trtsdtm e8601dt. trtstm time5.  trtsdt E8601DA. ;
run;
proc sort data=sf;by SUBJECT EXSTDAT;run;
data ex_et;
set sf;
if last.SUBJECT;
by SUBJECT EXSTDAT; 
if not missing(EXSTDAT_INT) then trtedt= input(scan(put(EXSTDAT_INT,e8601dt.),1,'T') ,E8601DA10.);
if not missing(EXSTTIM) then trtetm=  input(EXSTTIM,time.) ;
if not missing(trtedt) and not missing(trtetm) then 
trtedtm=input(put(trtedt,E8601DA.)||"T"||put(trtetm,tod.), e8601dt.);
format trtedtm e8601dt. trtetm time5.  trtedt E8601DA. ;
run;
/****death information******/
 data ae;
 set raw35.ae;
 format _all_;
 informat _all_;
 if AESDTH=1 then dthfl='Y';
 if not missing(AESTDAT)    then dthdt=   input(scan(put(AESTDAT , E8601DT.), 1,'T' ), E8601DA.)   ; 
 if dthfl='Y'  ;
 format dthdt  E8601DA. AESTDAT E8601DT.;
 run;
proc sort data= ae;by subject dthdt;run;
data ae;
set ae;
if last.subject;
by subject dthdt;
run;

 
 
 /***subject status*****/
 

data eot;
length dsterm dsdecod $ 200 ;
	set raw35.ds2 ;
	format _all_;
	informat _all_; 
 if not missing(DSENDAT2)    then DSSTDT=   input(scan(put(DSENDAT2 , E8601DT.), 1,'T' ), E8601DA.)   ;
 format dsstdt E8601DA.;
 dsdecod=strip(upcase(DSDECOD2_STD));
 dsterm=strip(upcase(DSDECOD2_STD));
  run; 
  proc sort data=eot   ;by subject dsstdt;run;
  data eot;
  set eot;
  if last.subject;
  by subject dsstdt;
  run;

  proc sort data=ex_st  ;by subject ;run;
  proc sort data=ex_et   ;by subject ;run; 
/*  proc sort data=enr_sub ;by subject ;run;*/
  proc sort data=ie   ;by subject ;run;
  proc sort data=ic ;by subject ;run;
  proc sort data=ae   ;by subject ;run;
  proc sort data=dm   ;by subject ;run;
  proc sort data=eot   ;by subject ;run;

data all;
length   arm $200 TRT01P TRT01A $80        ;
merge   ex_st ex_et  /* enr_sub */ ie ic ae eot   dm1(in=a drop=siteid);
by subject;
if not missing(trtsdt) then SAFFL='Y';
else SAFFL='N';
if missing(ENRLFL) then ENRLFL='N';
if missing(SCRRFFL) then SCRRFFL='N';


if enrlfl='Y' then do; ;
	    arm = 'BLINDED'; 
/*        actarm = 'Setmelanotide'; */
        trt01p = ' ';   
end;
if not missing(TRTSDT) and SAFFL='Y' then do;
		TR01SDT=.;
		TRT01A=' '; 
		end;
if enrlfl='N' then do; 
 call missing(arm, actarm, trt01p, trtsdt, trtstm, trtsdtm, trtedt ,trtetm,trtedtm); 
 end; 
if trtedt^=. then per1day = trtedt - trtsdt + 1;
if DSTERM='COMPLETED' or DSDECOD='COMPLETED' then COMPLFL='Y';
else COMPLFL='N';
 if ENRLFL='N' then do;
	SAFFL='N';	
	COMPLFL='N';
  	end;
run;

data fin;
length studyid $ 15 usubjid $35 subjid$20 siteid$10 COUNTRY countryl$50;
retain &keepvar;
set all(drop=studyid siteid);
if  DSDECOD='COMPLETED' then do;
DSDECOD='';
DSTERM='';
end;
studyid = 'RM-493-035';
	siteid = strip(scan(SITENUMBER,2,'-')); 
	subjid = substr(SUBJECT, 5); 
	usubjid=strip(studyid)||"-"|| strip(subjid);
keep &keepvar;
format   DSSTDT  ICDT       TR01SDT    E8601DA. TRTSDTM   TRTEDTM E8601DT. TRTSTM TRTETM E8601TM.;
run;
*===============================================================================
* 3. Provide ATTRIB labels. 
*===============================================================================;  
/*libname atemp "P:\Rhythm\ADaM Standards\SASData\CDISCtemplates"; */
/**/
/* */
/*data fin; */
/*	set template.occds(in=master drop=sex usubjid  subjid siteid country:    ) fin; */
/*   	if master then delete;*/
/*	informat _all_; */
/*run; */
  
data qdadsl35; 	
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
 
data qdadsl35 (label='Subject Level Analysis Dataset 35 Study');
  	retain &keepvar;
   	set qdadsl35;  
	by usubjid;   
	informat _all_; 
   	keep &keepvar; 
run;   

proc compare data=adam.adsl_035 compare=qdadsl35 listall;   
run;
