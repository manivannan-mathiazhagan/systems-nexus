DM"log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-adsl.sas  
* DATE:        02July2025
* PROGRAMMER:  Manivannan Mathialagan (copied by laurie from previous deliveries)
*
* PURPOSE:     QC of ADSL   
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:    
*
************************************************************************************; 
%let pgm=qd-adsl; 
%let pgmnum=0;  
 
%let protdir=&rmhoiss90;

%include "&protdir\macros\m-setup.sas";
libname chk "P:\Rhythm\DSUR\ADSdata\CLIENT ADS NOT USED";
options nofmterr;

proc format;

	value $ cnrty12c    '001' = 'Germany'
                        '003' = 'France'
                        '004' = 'Canada'
                        '006' = 'United States'
                        '007' = 'Spain'
                        '008' = 'Belgium';

     value $ cnrty12l   '001' = 'DEU'
                        '003' = 'FRA'
                        '004' = 'CAN'
                        '006' = 'USA'
                        '007' = 'ESP'
                        '008' = 'BEL';

	value $ cnrty15c    '001' = 'Germany'
                        '002' = 'France'
                        '003' = 'The Netherlands'
                        '004' = 'United Kingdom'
                        '007' = 'Reunion (Reunion Island)'
                        '008' = 'Canada';

     value $ cnrty15l   
	'Canada'='CAN'
	'France'='FRA'
	'Germany'='DEU'
	'Greece'='GRC'
	'Israel'='ISR'
	'Japan'='JPN'
	'Netherlands','Netherland','The Netherlands'='NLD'
	'Puerto Rico'='PRI'
	'Spain'='ESP'
	'United Kingdom'='GBR'
	'United States'='USA'
	'Belgium'='BEL';

     value $ cnrty16l  
'CAN'='Canada'
'FRA'='France'
'DEU'='Germany'
'GRC'='Greece'
'ISR'='Israel'
'JPN'='Japan'
'NLD'='Netherlands'
'PRI'='Puerto Rico'
'ESP'='Spain'
'GBR'='United Kingdom'
'USA'='United States'

'BEL'='Belgium';



invalue  rac
'AMERICAN INDIAN OR ALASKAN NATIVE'=1
'ASIAN'=2
'BLACK OR AFRICAN AMERICAN'=3
'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER'=4
'WHITE'=5
'OTHER'=6
'NOT REPORTED'=7
'MISSING'=99;	

run;


%let cutoff = &cutdt;

%let adslvar = %str(studyid usubjid subjid siteid INDEX22 INDEX42 brthdt brthyy age ageu agegr1 agegr1n agegr2 agegr2n 
              sex sexn race racen raceoth ethnic ethnicn country countryl sbfl ptfl hofl ho30fl saffl bridgefl arm arm2 
              armn arm2n trtpg trtpg2 trtag trtag2 trtsdt trtstm trtsdtm trtedt trtetm trtedtm tdur tdurm tdurmcat tdurmctn 
              bdur bdurm bdurmcat BDURMCTN status dsdecod dsstdt dthdt trt01p trt02p trt03p trt04p trt05p trt06p trt07p trt08p trt09p 
	          tr01sdt tr02sdt tr03sdt tr04sdt tr05sdt tr06sdt tr07sdt tr08sdt tr09sdt /*complfl*/ status22 status42 DSDECO22  
              DSDECO42   dsstdt: HEIGHTBL WEIGHTBL   BMIBL   TSTATUS TDSDECOD  BSTATUS   BDSDECOD     );


 

*===============================================================================
*  1. Add remainder for individual studies.   
*===============================================================================; 
*** Set all the ADSLxx ***;
			  
data adsl_037;
set adam.adsl_037;
usubjid=tranwrd(usubjid,'RM493','RM-493-037');

 run;
 
libname ads040 "P:\Projects\Rhythm\HO ISS\Biostats\ADSdata\Individual Studies\040 Toplines";
data adsl;
length ageu $15 race raceoth dsterm EOTSTT$200 SITEID    $10 ACTARMCD$200; 
	set adam.adsl_001(drop=randnum age) adam.adsl_002(drop=randnum age) adam.adsl_003(drop=randnum) adam.adsl_006(drop=randnum)
adam.adsl_008(drop=randnum) adam.adsl_009(drop=randnum) adam.adsl_010(drop=randnum) adam.adsl_011 
adam.adsl_012(drop=randnum) adam.adsl_014(drop=randnum) adam.adsl_015(drop=randnum)  adam.adsl_018(drop=randnum)
adam.adsl_019(drop=randnum) adam.adsl_022 adam.adsl_023  adam.adsl_026(drop=randnum) adam.adsl_029 
adam.adsl_030  adam.adsl_032 adam.adsl_033 adam.adsl_034(drop=country rename=(countryl=country)) 
adam.adsl_035   adsl_037 ads040.adsl adam.adsl_041  adam.adsl_042 adam.adsl_043;*  ;
if country = 'United States' then do; country = 'USA'; countryl = 'United States'; end;
if  SAFFL = 'Y' or studyid='RM-493-041';

	studyid=tranwrd(studyid,'RM493','RM-493');
	usubjid=tranwrd(usubjid,'RM493','RM-493');
run;

libname s001 "P:\Projects\Rhythm\RM-493-001\Biostats\CSR\SDTMdata";
libname s002 "P:\Projects\Rhythm\RM-493-002\Biostats\CSR\SDTMdata";

proc sort data=s001.dm out=dm1 (keep=usubjid age  );
	by usubjid; 
	run; 
proc sort data=s002.dm out=dm2 (keep=usubjid age );
	by usubjid; 
	run;

proc sort data=adsl  ;
	by usubjid; 
	run;
data adsl;
	merge adsl (in=a) dm1 dm2;
	by usubjid; 
	run;


/***linking 22 and 30 and 42****/
libname sdtm_022 "P:\Projects\Rhythm\RM-493-022\Biostats\CSR\SDTMdata";

data s022;
set sdtm_022.suppdm;
where QNAM="INDEXSN";
run;

proc sort data=s022(keep=usubjid qval rename=(qval=indexsn)); 
	by usubjid;
	run;
	proc sort data=adsl;by usubjid;run;
 
data adsl;
	merge adsl (in=a) s022;
	by usubjid;
	if a;
run; 
libname raw42 "P:\Projects\Rhythm\HO ISS\Biostats\RAWdata\RM-493-042"; 
data sdm42; 
length USUBJID  $60 SITEID    $10;
	set raw42.ic (encoding=any); 
	format _all_;
	informat _all_;
	studyid='RM-493-042';
	subjid=strip(participant_id);
	subjid=substr(subjid,5);
	siteid=substr(subjid,1,3); 
	usubjid=trim(studyid)||'-'|| subjid;  
run;

proc sort data=sdm42 out=suppdm42 (keep=usubjid indexid rename=(indexid=indexsn)); 
	by usubjid;
	run;
	proc sort data=adsl;by usubjid;run;
data adsl(drop=agegr1);
	merge adsl (in=a) suppdm42;
	by usubjid;
	if a;
run; 
data adsl ; 
 length race raceoth  $50 country countryl $50 ETHNIC agegr1 agegr2$25   USUBJID  $60;
set adsl (rename=( arm=arm_ armcd=armcd_ actarm=actarm_ actarmcd=actarmcd_ race=race_  raceoth=raceoth_  country=country_ countryl=countryl_ ethnic=ethnic_));
	enrlfl = 'Y';
 	race = race_;
	raceoth = raceoth_; 
/***country*****/	

	if studyid in ('RM-493-001','RM-493-002','RM-493-003','RM-493-006','RM-493-008','RM-493-009','RM-493-010','RM-493-019'
'RM-493-029','RM-493-030','RM-493-032','RM-493-033' ,'RM-493-043') then do;
		country='United States';
		COUNTRYL='USA';
		end;

	if studyid in ('RM-493-041') then do;
		country='Argentina';
		COUNTRYL='ARG';
		end;
	if studyid='RM-493-011' then country='Germany';

	if studyid='RM-493-012' then do;
  	        if siteid='001' then country='Germany';
  	   else if siteid='003' then country='France';
  	   else if siteid='004' then country='Canada';	  
  	   else if siteid='006' then country='United States';
   	   else if siteid='007' then country='Spain';
   	   else if siteid='008' then country='Belgium';
	end;

	if studyid in('RM-493-014') then do;
       country='';	
	   if siteid in('044' '045' ) then country='Canada';
	   else if siteid in('049' '062' '077' ) then country='Germany';
	   else if siteid in('019') then country='Spain';
	   else if siteid in('052' '075') then country='France';
	   else if siteid in('014' '021' '032') then country='United Kingdom';
	   else if siteid in('055') then country='Greece';
	   else if siteid in('078') then country='Israel';
	   else if siteid in('048') then country='Netherlands';
	   else  if country='' then  country='United States';
	end;

	if studyid='RM-493-015' then do;
   	        if siteid='001' then country='Germany';
   	   else if siteid='002' then country='France';
   	   else if siteid='003' then country='The Netherlands';	  
  	   else if siteid='004' then country='United Kingdom';
  	   else if siteid='007' then country='Reunion (Reunion Island)';
  	   else if siteid='008' then country='Canada';
	end;

	if studyid='RM-493-019' then do;
	   trtsdt=tr01sdt;
	   trtedt=max(tr01edt,tr02edt,tr03edt,tr04edt,tr05edt);
	end; 

	if studyid='RM-493-022' then do; 
	   if siteid in('001' '007')then country='Germany';
  	   else if siteid in('002' '003' '004' '005' '006' '009'  '012' '016' '019' '020' '021' '024' '025' '026' '028' '029' '034' '035' '036' '039') then country='United States';
  	   else if siteid in ('022' '018') then country='Canada';
 	   else if siteid in('008' ) then country='Netherlands';
	   else if siteid in( '014') then country='Reunion (Reunion Island)';*'Saint-Denis Cedex';
	   else if siteid in( '010' '011' '037' ) then country='United Kingdom';
   	   else if siteid in ( '015' '030' '038') then country='France';
   	   else if siteid in ('032') then country='Greece';
  	   else if siteid in ('033') then country='Israel';
 	   else if siteid in ('027') then country='Puerto Rico';
  	   else if siteid in ('017') then country='Spain';	 
	   else if siteid in ('013') then country='Belgium';
		   *else put "WARN" "ING: MISSING COUNTRY CODE FOR SITEID = " siteid;
	end;

	if studyid in('RM-493-026' 'RM-493-023' 'RM-493-035') then country='United States';

	if studyid='RM-493-023' then do;
  	        if siteid in('001' '002' '003' '007' '012' '013' '014')  then country='United States';
 	   else if siteid='004' then country='United Kingdom';
   	   else if siteid='005' then country='Spain';
  	   else if siteid='006' then country='Canada';
	end;
	
	if country='USA' then country = 'United States'; 	
	if country='GRC' then country = 'Greece';
	if country='JPN' then country = 'Japan';
	if country='ESP' then country = 'Spain';
	if country='GBR' then country = 'United Kingdom';
	if country='CAN' then country = 'Canada';
	if country='PRI' then country = 'Puerto Rico';
	if country='ISR' then country = 'Israel';
	if country='DEU' then country = 'Germany';
	if country='NLD' then country = 'Netherlands';
	if country='FRA' then country = 'France'; 
	if country='BEL' then country = 'Belgium';
	if country='REU' then country = 'Reunion';
	if country='ARG' then country = 'Argentina';
	if country ne '' then countryl = put(country,cnrty15l.); 
 if studyid= 'RM-493-034' then do;
 if country_='USA' then country ='United States'; 	
 if country_='Spain' then country ='Spain'; 	
 if country_='Germany' then country='Germany'; 	
 if country_='Greece' then country='Greece'; 	
 if country_='United Kingdom' then country='United Kingdom'; 	
 if country_='Israel' then country='Israel'; 	
 if country_='Netherlands' then country='Netherlands'; 	
 if country_='Canada' then country='Canada'; 
 if country_ ne '' then countryl = put(country,cnrty15l.);  

   end;

 
	if studyid='RM-493-040' then do;

if COUNTRY_ ='CAN' then country  ='Canada';
if COUNTRY_ ='FRA' then country    ='France';
if COUNTRY_ ='DEU'  then country  ='Germany';
if COUNTRY_ ='GRC'   then country   ='Greece';
if COUNTRY_ ='ISR' then country ='Israel';
if COUNTRY_ ='JPN'   then country ='Japan';
if COUNTRY_ ='NLD'   then country ='Netherlands';
if COUNTRY_ ='PRI'   then country ='Puerto Rico';
if COUNTRY_ ='ESP'   then country ='Spain';
if COUNTRY_ ='GBR'   then country ='United Kingdom';
if COUNTRY_ ='USA'   then country ='United States';
 if COUNTRY_  ='CAN' then country  ='Canada'; 
 if country ne '' then countryl = put(country,cnrty15l.);  
 end;
	if studyid='RM493-019' then do;
	   trtsdt=tr01sdt;
	   trtedt=max(tr01edt,tr02edt,tr03edt,tr04edt,tr05edt);
	end; 
	/****sex/n****/
	if sex = 'M' then sexn = 1;
	if sex = 'F' then sexn = 2;
	/***ethnic*****/
    if upcase(ethnic_)='HISPANIC OR LATINO' then do;
			ethnic='HISPANIC OR LATINO';
			ethnicn=1;
			end;
    if upcase(ethnic_)='NOT HISPANIC OR LATINO' then do;
			ethnic='NOT HISPANIC OR LATINO';
			ethnicn=2;
			end;
    if upcase(ethnic_)='NOT REPORTED' then do;
			ethnic='NOT REPORTED';
			ethnicn=3;
			end;
    if upcase(ethnic_) in  ('','UNKNOWN') then do;
			ethnic='MISSING';
			ethnicn=99;
			end;
 /****race*********/
    if upcase(race_)='AMERICAN INDIAN OR ALASKA NATIVE' then do;
			race='AMERICAN INDIAN OR ALASKA NATIVE';
			racen=1;
			end;
    if upcase(race_)='ASIAN' then do;
			race='ASIAN';
			racen=2;
			end;
    if upcase(race_)='BLACK OR AFRICAN AMERICAN' then do;
			race='BLACK OR AFRICAN AMERICAN';
			racen=3;
			end;
    if upcase(race_) in  ('NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER') then do;
			race='NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER';
			racen=4;
			end;
    if upcase(race_)='WHITE' then do;
			race='WHITE';
			racen=5;
			end;
    if upcase(race_)='OTHER' then do;
			race='OTHER';
			racen=6;
			end;
    if upcase(race_)='NOT REPORTED' then do;
			race='NOT REPORTED';
			racen=7;
			end;
    if upcase(race_) in  ('','UNKNOWN') then do;
			race='MISSING';
			racen=99;
			end;
	/****age grouping*****/
			
	ageu = 'YEARS'; 
  	if . < age < 6 then do;agegr1 = '<6 years';AGEGR1N    = 1;end;
	if 6 <= age < 12 then do;agegr1 = '6 - <12 years'; AGEGR1N    = 2; end;
	if 12 <= age < 18 then do; agegr1 = '12 - <18 years'; AGEGR1N    = 3; end;
	if 18 <= age  then do; agegr1 = '>=18 years'; AGEGR1N    = 4; end; 
	if  age lt  18  then do;agegr2='<18 years';AGEGR2N   =1;end;
	if  age ge  18  then do;agegr2='>=18 years';AGEGR2N   =2;end;
	if not missing(dsstdt) then dsstdt=dsstdt;
	else dsstdt=max(eotdt,eosdt); 
 	dsdecod=upcase(dsdecod); 
	dcsreas=upcase(dcsreas);
	if dcsreas ne ' ' and dsdecod=' ' then dsdecod=dcsreas;
	dsdecod_  = dsdecod; 
	if find(dsdecod_,'ADVERSE' ,'i' ) gt 0 then dsdecod = 'Adverse Event';
	else if dthdt ne .  or upcase(dsdecod_)='DEATH' then dsdecod = 'Death';  
	else if dsdecod_  in ( 'LACK OF EFFICACY'  ) then dsdecod = 'Lack of Efficacy'; 
	else if dsdecod_  = ('LOST TO FOLLOW-UP ') then dsdecod = 'Lost to Follow-Up'; 
	else if dsdecod_  in ('LACK OF COMPLIANCE (NON-COMPLIANCE WITH THE STUDY PROTOCOL)' 'LACK OF SUBJECT COMPLIANCE WITH THE PROTOCOL' 'NON-COMPLIANCE WITH STUDY DRUG' ) then dsdecod = 'Non-Compliance with Study Drug'; 
	else if dsdecod_ in ('PHYSICIAN DECISION' 'INVESTIGATOR DECISION') then dsdecod = 'Physician Decision';  
	else if dsdecod_ in ('PROTOCOL DEVIATION' 'PROTOCOL VIOLATION' ) then dsdecod = 'Protocol Deviation'; 
	else if dsdecod_ in ('SITE TERMINATED BY SPONSOR') then dsdecod = 'Site Terminated by Sponsor'; 
	else if dsdecod_ in ('STUDY TERMINATED BY SPONSOR' 'TERMINATED BY SPONSOR') then dsdecod = 'Study Terminated by Sponsor'; 
	else if find(dsdecod_,'WITHDRAWAL BY SUBJECT','I') gt 0 then dsdecod = 'Withdrawal by Subject'; 
    else if find(dsdecod_,'WITHDR','I' ) gt 0 then dsdecod = 'Withdrawal by Parent/Guardian';
	else if find(dsdecod_,'OTHER','i') gt 0 then dsdecod = 'Other';  
	else if dsdecod_  ne ''  then dsdecod = 'Other'; 
	if complfl ='Y' or compfl='Y' then dsdecod='';


run; 

data adsl_;
length arm $200 TRTPG TRTAG status$20;
set adsl;
if saffl = 'Y' OR studyid = 'RM-493-041';
/*******Drop RM-493-018 and RM-493-037 
	* Only include RM-493-026, for Cohort 3 and 7*****/
if studyid in ('RM-493-018' 'RM-493-037') then delete;
if studyid in ('RM-493-026') and cohort not in ('Cohort 3' 'Cohort 7') then delete; 

/****additional flags****/
if SAFFL='Y' then SBFL='Y';
else  SBFL='N';
 
if studyid in ('RM-493-010' 'RM-493-011' 'RM-493-012' 'RM-493-014' 'RM-493-015'
'RM-493-019' 'RM-493-022' 'RM-493-023' 'RM-493-030' 'RM-493-033'
'RM-493-034' 'RM-493-035' 'RM-493-040'  'RM-493-042' 'RM-493-043') then PTFL='Y';
else PTFL='N';
if studyid in ( 'RM-493-030' 'RM-493-040')  OR (studyid='RM-493-022' and substr(usubjid,12,2)='30') OR (studyid='RM-493-042' and substr(usubjid,12,2)='30')
then HOFL='Y';else HOFL='N';

if studyid in ('RM-493-040') and tr02sdt ne . then do;
 	   bridgefl = 'Y';
	   trtpg2 = 'Bridging Visit'; 
	   trtag2 = 'Bridging Visit';
	   arm2 = 'Bridging Visit';
	   arm2n=3; 
	   end;
else do;
	   BRIDGEFL='N';
	   trtpg2 = ' '; 
	   trtag2 = ' ';
	   arm2 = ' ';
	   arm2n =.;
	   end;
	   /****assign status****/


status = 'ONGOING';
if compfl='Y' or complfl='Y' then do; status = 'COMPLETE'; dsdecod = ''; end; else
if dsdecod ne '' or dthdt ne . then status = 'DISCONTINUED';  
if status = 'ONGOING' and dsdecod = '' and substr(studyid,8,3) not in ('035' '040' '041' '042') and trtedt ne . then status = 'COMPLETE';  

 
/***treatment information ****/
if trt01p='Missing' then trt01p=' ';
if trt02p='Missing' then trt02p=' ';
if trt03p='Missing' then trt03p=' ';
if trt04p='Missing' then trt04p=' ';
if trt05p='Missing' then trt05p=' ';
if trt06p='Missing' then trt06p=' ';
if trt07p='Missing' then trt07p=' ';
if trt08p='Missing' then trt08p=' ';
if trt09p='Missing' then trt09p=' ';

If STUDYID in ('RM-493-035' ,'RM-493-041')  then TRTPG = 'Blinded';
if studyid not in ('RM-493-035' ,'RM-493-041')  then do;
if find(trt01p,'Placebo') gt 0 and 
	(trt02p='' or find(trt02p,'Placebo') gt 0) and   (trt03p='' or find(trt03p,'Placebo') gt 0) and
	(trt04p='' or find(trt04p,'Placebo') gt 0) and   (trt05p='' or find(trt05p,'Placebo') gt 0) and
	(trt06p='' or find(trt06p,'Placebo') gt 0) and   (trt07p='' or find(trt07p,'Placebo') gt 0) and
	(trt08p='' or find(trt08p,'Placebo') gt 0) and   (trt09p='' or find(trt09p,'Placebo') gt 0)   
then trtpg='Placebo';
else TRTPG='Setmelanotide';

end; 
TRTAG=TRTPG;
arm=TRTPG;
if arm='Setmelanotide' then armn=1;
if arm='Placebo' then armn=2;
if arm='Blinded' then armn=4;
run;
 
/****now split and merge back �	For STUDYID, USUBID, SUBJID, SITEID, BRTHDT, BRTHYY, AGE AGEU, AGEGR1, AGEG1N,AGEGR2,
AGEGR2N, SEX, SEXN, RACE, RACEN, RACEOTH, ETHNIC, ETHNICN, COUNTRY, COUNTRYL,TRTSDT, TRTSTM, TRTSDTM
****/
 
data adsl22 (keep =usubjid indexsn STUDYID SUBJID SITEID SITEID BRTHYY AGE AGEU AGEGR1 AGEGR1N AGEGR2 AGEGR2N SEX 
SEXN RACE RACEN RACEOTH ETHNIC ETHNICN COUNTRY COUNTRYL TRTSDT TRTSTM TRTSDTM DTHDT   dsdecod TRTEDT TRTETM TRTEDTM
DSSTDT DSDECOD status
rename=(usubjid=usubjid22 indexsn=indexsn22 TRTSDT=TRTSDT22 TRTSTM=TRTSTM22 TRTSDTM=TRTSDTM22 dthdt=dthdt22 dsdecod=dsdecod22 
  DSSTDT=DSSTDT22 TRTSDT=TRTSDT22 TRTEDT=TRTEDT22 TRTETM=TRTETM22 TRTEDTM=TRTEDTM22 DSDECOD=DSDECOD22 status=status22))
adsl42(keep =usubjid indexsn TRTSDT TRTSTM TRTEDT TRTSDTM TRTETM TRTEDTM   DSDECOD DSSTDT DTHDT  status
rename=(usubjid=usubjid42 indexsn=indexsn42 TRTEDT=TRTEDT42 TRTETM=TRTETM42 TRTEDTM=TRTEDTM42  DSDECOD=DSDECOD42
DSSTDT=DSSTDT42 DTHDT=DTHDT42 TRTSDT=TRTSDT42 TRTSTM=TRTSTM42 TRTSDTM=TRTSDTM42 status=status42)) adsl_all;*(keep =usubjid INDEXSN) ;
set adsl_;
/*if usubjid in ('RM-493-022-30-41-001','RM-493-042-041-001');*/
if studyid='RM-493-022' then output adsl22;
else if studyid='RM-493-042' then output adsl42;
else output adsl_all;
run;
/****22 study****/
data adsl22x;
length usubjid $60;
set adsl22;
last=scan(indexsn22,-1,'-');
 if substr(indexsn22,1,3) ='011' then usubjid ='RM-493-011-001-'||strip(last);
 else usubjid  = 'RM-493-'||strip(indexsn22); 

run;
/**linking 42 to 22****/
data adsl42x;
length   usubjid22$60  ;
set adsl42;
if scan(indexsn42,1,'-')='22';
	usubjid22 = 'RM-493-0' || strip(indexsn42); 
run;

proc sort data=adsl22x;by USUBJID22 ;run;
proc sort data=adsl42x;by USUBJID22 ;run;
/****22-42-30 study*****/
data adsl_22_42;
	length usubjid $60 ARM$200 TRTPG TRTAG$20; 
merge  adsl42x (in=a)  adsl22x;
by USUBJID22;
if a;
	ARM='Stemelanotide';
	ARMN=1;
	TRTPG='Stemelanotide';
	TRTAG='Stemelanotide'; 
	if trtedt42 lt trtedt22 then do;
	trtedt42=trtedt22;
	trtedtm42=trtedtm22;
	trtetm42=trtetm22;
	end;
run;
/*****Separating 33 subjects from 42 dataset*****/
/***33-42study******/
data adsl33_42;
	set adsl42 ;	
	length usubjid $60 ARM$200 TRTPG TRTAG$20;  
	where (scan(indexsn42,1,'-'))='033';
	usubjid = 'RM-493-' || strip(indexsn42);
	ARM='Stemelanotide';
	ARMN=1;
	TRTPG='Stemelanotide';
	TRTAG='Stemelanotide';

run;    
proc sort data=adsl_all;
	by usubjid;
	run;
proc sort data=adsl22x;
	by usubjid;
	run; 
proc sort data=adsl_22_42;
	by usubjid;
	run;
proc sort data=adsl33_42;
	by usubjid;
	run;
/***merge back****/ 

proc sql;
create table adsl_fin as
SELECT 
a.*, 
 
        /* Keep flags to simulate IN= behavior */
        case when b.usubjid is not null then 1 else 0 end as s_all,
        case when c.usubjid is not null then 1 else 0 end as s_30_22,
        case when d.usubjid is not null then 1 else 0 end as s_33_42,

 


		  case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then ''
            when b.usubjid is not null and c.usubjid is   null then ''
            else coalescec(b.indexsn22, c.indexsn22)
        end as indexsn22,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and d.usubjid is   null then .
            else coalesce(b.trtedt22, c.trtedt22)
        end as trtedt22,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and d.usubjid is   null then .
            else coalesce(b.trtedtm22, c.trtedtm22)
        end as trtedtm22,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then ''
            when b.usubjid is not null and c.usubjid is   null then ''
            else coalescec(b.status22, c.status22)
        end as status22,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then ''
            when b.usubjid is not null and d.usubjid is   null then ''
            else coalescec(b.dsdecod22, c.dsdecod22)
        end as dsdecod22,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and d.usubjid is   null then .
            else coalesce(b.DSSTDT22, c.DSSTDT22)
        end as dsstdt22,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and d.usubjid is   null then .
            else coalesce(b.dthdt22, c.dthdt22)
        end as dthdt22,
  		



		  case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then ''
            when b.usubjid is not null and c.usubjid is   null then ''
            else coalescec(b.indexsn42, d.indexsn42)
        end as indexsn42,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and c.usubjid is   null then .
            else coalesce(b.trtedt42, d.trtedt42)
        end as trtedt42,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and c.usubjid is   null then .
            else coalesce(b.trtedtm42, d.trtedtm42)
        end as trtedtm42,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then ''
            when b.usubjid is not null and c.usubjid is   null then ''
            else coalescec(b.status42, d.status42)
        end as status42,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then ''
            when b.usubjid is null and c.usubjid is not null then ''
            else coalescec(b.dsdecod42, d.dsdecod42)
        end as dsdecod42,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and c.usubjid is   null then .
            else coalesce(b.dsstdt42, d.dsstdt42)
        end as dsstdt42,
        case 
            when b.usubjid is null and c.usubjid is null and d.usubjid is null then .
            when b.usubjid is not null and c.usubjid is   null then .
            else coalesce(b.dthdt42, d.dthdt42)
        end as dthdt42 
 
 FROM adsl_all
 a
LEFT JOIN adsl_22_42 b 
    ON a.usubjid = b.usubjid
LEFT JOIN adsl22x c
    ON a.usubjid = c.usubjid
LEFT JOIN adsl33_42 d
    ON a.usubjid = d.usubjid 
;
quit;




 data adsl_finx (where=(studyid='RM-493-011'));
set adsl_fin;
keep studyid usubjid dsdecod: status: DSSTDT: DTHDT:;
format trtedt22 trtedt42 trtedt e8601da.  ;  
run; 
 
 
data adsl_final(rename=(indexsn22=INDEX22 indexsn42=INDEX42  DSDECOD22=DSDECO22 DSDECOD42=DSDECO42 status2x_=STATUS22  
status4x_=status42)   );
length TDURMCAT bdurmcat status2x_ status4x_ status$20 ho30fl$1 ; 

 set adsl_fin;
 status2x_=status22;
status4x_=status42;
countryl=upcase(countryl);
/***Take the below from last 42 study****/
if not missing(status42 ) then status=status42;
else if not missing(status22) then status=status22;

/*Status=coalescec(Status42,Status22,Status);*/
DSDECOD=coalescec(dsdecod42,dsdecod22,dsdecod);
DSSTDT=coalesce(DSSTDT42,DSSTDT22,DSSTDT);
DTHDT=coalesce(DTHDT42,DTHDT22,DTHDT); 
if status ne 'DISCONTINUED' then do;
dsdecod='';
dsstdt=.;
end;
if status22 ne 'DISCONTINUED' then do;
dsdecod22='';
dsstdt22=.;
end;
if status42 ne 'DISCONTINUED' then do;
dsdecod42='';
dsstdt42=.;
end;

tstatus = status;
tdsdecod = DSDECOD;
if studyid = 'RM-493-040' then do; 
if dctreas ne '' then tstatus = Upcase('DISCONTINUED');  
else if eotsttpb eq 'Ongoing' then tstatus = Upcase('ONGOING');  
else tstatus = Upcase('COMPLETE');  
tdsdecod = dctreas;  
end;
/****assign status****/


/*if  complfl='Y' or COMPLFL='Y' or dsdecod='' then status= 'COMPLETE' ; */
/*else if dsdecod not in('COMPLETED','COMPLETE'  ,'')  or dthdt ne . then status='DISCONTINUED';*/
/*else if complfl='N'  then status= 'ONGOING' ;  */
/***Death flag*****/ 
if dthdt ne .  or upcase(dsdecod)='DEATH' then dthfl = 'Y';
else dthfl = ''; 
/***COMBINE all date/time variables and take the max available one for edt***/
if tr01sdt ne . then trtsdt = tr01sdt;
if tr01sdtm ne . then trtsdtm = tr01sdtm;   
if not missing(trtedt) and not missing(trtetm) then 
trtedtm=input(put(trtedt,E8601DA.)||"T"||put(trtetm,tod.), e8601dt.);
if not missing(trtsdt) and not missing(trtstm) then 
trtsdtm=input(put(trtsdt,E8601DA.)||"T"||put(trtstm,tod.), e8601dt.);
trsdt=max(  tr09sdt,tr08sdt,tr07sdt,tr06sdt,tr05sdt,tr04sdt,tr03sdt,tr02sdt,tr01sdt,trtsdt ,trtsdt);
tredt=max(trtedt42,trtedt22,tr09edt,tr08edt,tr07edt,tr06edt,tr05edt,tr04edt,tr03edt,tr02edt,tr01edt,trtedt);
tredtm=max(trtedtm42,trtedtm22 ,tr09edtm,tr08edtm,tr07edtm,tr06edtm,tr05edtm,tr04edtm,tr03edtm,tr02edtm,tr01edtm,trtedtm);
edtm = max(dhms(trtedt,0,0,0),trtedtm,tredtm,dhms(tredt,0,0,0) );
trtedt = datepart(edtm);
trtetm = timepart(edtm);
trtedtm = edtm;
if timepart(edtm)=0 then do; trtetm = .; trtedtm = .; end;  
if timepart(TRTSDTM)=0 then do; trtstm = .; trtsdtm = .; end;  
if studyid='RM-493-032' then do;
trtsdtm=input(put(trtsdtm,e8601dt17.), e8601dt17.);
 trtstm=input(put(trtstm,time5.),time5.);
 end;
 
 /****HOFL *****/
 
if  scan(indexsn22,1,'-')='030' or scan(indexsn42,2,'-')='30'  then ho30fl = 'Y';
else ho30fl='N';
 	/****trt duration/category/Num****/
if trtsdt ne . and trtedt ne . then tdur = trtedt - trtsdt + 1;
if studyid = 'RM-493-040' then do; tdur = tr01edt - tr01sdt + 1; end;

tdurm = tdur/30.4375;
	if .  <  tdurm < 1   then do;
				tdurmcat = '<1 month';
				tdurmctn=1;
				end;
	 if 1  <= tdurm < 3   then do;
				tdurmcat = '1 to <3 months';
				tdurmctn=2;
				end; 
	 if 3  <= tdurm < 6   then do;
				tdurmcat = '3 to <6 months'; 
				tdurmctn=3;
				end; 
	 if 6  <= tdurm < 12  then do;
				tdurmcat = '6 to <12 months';
                tdurmctn=4;
				end; 
	 if 12 <= tdurm < 18  then do;
				tdurmcat = '12 to <18 months'; 
				tdurmctn=5;
				end; 
	 if tdurm >= 18 then do;
				tdurmcat = '>=18 months';
				tdurmctn=6;
				end;  
tstatus = status;
tdsdecod =Upcase(dsdecod);
if studyid = 'RM-493-040' then do; 
if dctreas ne '' then tstatus = 'DISCONTINUED';  
else if eotsttpb eq 'Ongoing' then tstatus = 'ONGOING';  
else tstatus = 'COMPLETE';  
tdsdecod = Upcase(dctreas);  
end;

if tdsdecod='COMPLETED' then tdsdecod='';
/***********briding visit,duration for study-040 *****/
	if studyid = 'RM-493-040' and bridgefl = 'Y' then do;  
	bdur = tr02edt - tr02sdt + 1; 
	bdurm = bdur/30.4375;
	if .  <  bdurm < 1   then do;
	bdurmcat = '<1 month';
	bdurmctn=1;
	end;
 	if 1  <= bdurm < 3   then do;bdurmcat = '1 to <3 months'; bdurmctn=2; end;  
	if 3  <= bdurm < 6   then do;bdurmcat = '3 to <6 months';bdurmctn=3;  end;
	if 6  <= bdurm < 12  then do;bdurmcat = '6 to <12 months';bdurmctn=4;end;  
	if 12 <= bdurm < 18  then do;bdurmcat = '12 to <18 months';bdurmctn=5; end; 
	if       bdurm >= 18 then do;bdurmcat = '>=18 months';bdurmctn=6;end;
	if dcsreas ne '' then bstatus = 'DISCONTINUED'; 
	else if eotsttdb eq 'Ongoing' then bstatus = 'ONGOING';
	else bstatus = 'COMPLETE'; 
	bdsdecod = dcsreas;
    end;
	format _all_;  
	informat _all_ ;    
format trtedt trtsdt dthdt dsstdt BRTHDT TR01SDT TR02SDT TR03SDT TR04SDT TR05SDT TR06SDT TR07SDT TR08SDT TR09SDT trtedt dsstdt22
dsstdt42 e8601da.  
TRTSTM trtetm e8601tm. trtsdtm trtedtm e8601dt.   ; 
  
drop status22 status42;

run;

proc datasets lib = work;
	modify adsl_final;
	informat _all_;

	run;
quit;

proc sort data=adsl_final;by studyid usubjid;run; 

***	assign attrib - labels	***;
data qdadsl;
	set adsl_final;
	by studyid usubjid;
attrib
AGE	label='Age'
AGEGR1	label='Pooled Age Group 1'
AGEGR2	label='Pooled Age Group 2'
AGEGR1N	label='Pooled Age Group 1 (N)'
AGEGR2N	label='Pooled Age Group 2 (N)'
AGEU	label='Age Units'
ARM	label='Description of Planned Arm'
ARM2	label='Description of Planned Arm (Bridging)'
ARM2N	label='Description of Planned Arm (Bridging)(N)'
ARMN	label='Description of Planned Arm (N)'
BRIDGEFL	label='Bridging Visit Flag'
BRTHDT	label='Date of Birth'
BRTHYY	label='Year of Birth'
COUNTRY	label='Country'
COUNTRYL	label='Country Listings'
DSDECOD	label='Standard Disposition Term'
DSSTDT	label='Date of Disposition'
DTHDT	label='Date of Death'
ETHNIC	label='Ethnicity'
ETHNICN	label='Ethnicity (N)'
HO30FL	label='Hypo Obesity for 022/042 from 030 Study'
HOFL	label='Healthy Obese Flag'
INDEX22	label='Index Unique Subject ID/022 Study'
INDEX42	label='Index Unique Subject ID/042 Study'
PTFL	label='All Patient Flag'
RACE	label='Race'
RACEN	label='Race (N)'
RACEOTH	label='Race Other, Specify'
SAFFL	label='Safety Population Flag'
SBFL	label='All Subject Flag'
SEX	label='Sex'
SEXN	label='Sex (N)'
SITEID	label='Study Site Identifier'
STATUS	label='Status'
STUDYID	label='Study Identifier'
SUBJID	label='Subject Identifier for the Study'
TDURM	label='Treatment Duration (months)'
TDURMCAT	label='Treatment Duration Category (months)'
TDURMCTN	label='Treatment Duration Category (months) (N)'
TR01SDT	label='Date of First Exposure in Period 01'
TR02SDT	label='Date of First Exposure in Period 02'
TR03SDT	label='Date of First Exposure in Period 03'
TR04SDT	label='Date of First Exposure in Period 04'
TR05SDT	label='Date of First Exposure in Period 05'
TR06SDT	label='Date of First Exposure in Period 06'
TR07SDT	label='Date of First Exposure in Period 07'
TR08SDT	label='Date of First Exposure in Period 08'
TR09SDT	label='Date of First Exposure in Period 09'
TRT01P	label='Planned Treatment for Period 01'
TRT02P	label='Planned Treatment for Period 02'
TRT03P	label='Planned Treatment for Period 03'
TRT04P	label='Planned Treatment for Period 04'
TRT05P	label='Planned Treatment for Period 05'
TRT06P	label='Planned Treatment for Period 06'
TRT07P	label='Planned Treatment for Period 07'
TRT08P	label='Planned Treatment for Period 08'
TRT09P	label='Planned Treatment for Period 09'
TRTAG	label='Actual Pooled Treatment'
TRTAG2	label='Actual Pooled Treatment (Bridging)'
TRTEDT	label='Date of Last Exposure to Treatment'
TRTEDTM	label='Datetime of Last Exposure to Treatment'
TRTETM	label='Time of Last Exposure to Treatment'
TRTPG	label='Planned Pooled Treatment'
TRTPG2	label='Planned Pooled Treatment (Bridging)'
TRTSDT	label='Date of First Exposure to Treatment'
TRTSDTM	label='Datetime of First Exposure to Treatment'
TRTSTM	label='Time of First Exposure to Treatment'
USUBJID	label='Unique Subject Identifier'
TDUR    label='Treatment Duration (days)'
TSTATUS label='Treatment Status'
TDSDECOD label='Treatment Disposition Term'
BDUR label='Bridging Duration (days)'
BDURM label='Bridging Duration (months)'
BDURMCAT   label='Bridging Duration Category (months)'

BDURMCTN   label='Bridging Duration Category (months) (N)'
 BSTATUS   label='Bridging Status'
BDSDECOD    label='Bridging Disposition Term'
STATUS22  label='Status for P022'
STATUS42  label='Status for P042'
DSDECO22   label='Standard Disposition Term for P022'
DSDECO42   label='Standard Disposition Term for P042'
DSSTDT22  label='Date of Disposition for P022'
DSSTDT42  label='Date of Disposition for P042';

 /*	if usubjid ='RM-493-011-001-001';*/
run;     
%put &protdir;
/***bring advs dataset****/
 %include "&protdir\QC\ADS\qd-advs.sas";


 data finali;
 Merge qdadsl(in=a) qcadvs(in=b);
 by usubjid;
 if a ;
 run;

data qc(label = 'Subject Level Analysis Dataset'  );
retain &adslvar;;
	set finali;
	by studyid usubjid;

	label hofl='Hypothalamic Obesity Population Flag';
	keep &adslvar    ;
	run;
 proc sort data=ads.adsl out=prd ;by studyid siteid usubjid subjid age brthdt trtsdt trtedt;run;
 proc sort data=qc ;by studyid siteid usubjid subjid age brthdt trtsdt trtedt;run;
/*proc compare base=prd compare=qc out=diffs outnoequal  method=absolute  ;*/
/*run;*/
 proc compare data=ads.adsl compare=qc listall; 
/*id studyid siteid usubjid subjid trtsdt trtedt ;*/
run;
