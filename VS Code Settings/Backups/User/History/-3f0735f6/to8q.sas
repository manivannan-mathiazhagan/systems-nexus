dm "log; clear; lst; clear;";

*************************************************************************************************************;
* VERISTAT INCORPORATED
*************************************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\ADS\qd-adsl.sas
* DATE:        31OCT2024
* PROGRAMMER:  shashi            
* PURPOSE:     QC ADSL.
* 
*************************************************************************************************************;
* MODIFICATIONS:
*   DATE:        
*   PROGRAMMER:  
*   PURPOSE:      
* 
*************************************************************************************************************;

%let pgm=qd-adsl;
%let pgmnum=0;
%let protdir=&difi2201dsmb;

%include "&protdir\macros\m-setup.sas";


proc datasets library=work memtype=data kill nolist; 
quit;


proc format;
invalue trt
'Iltamiocel'=1
'Placebo'=2;
run;

*===============================================================================
* 1. Bring in RAW.DIA.  
*===============================================================================; 
data cm;
	set raw.dia (encoding=any); 
	format _all_;  
	length usubjid $35; 
	usubjid =  'DIFI-22-01-' || strip(put(sitenum,best.)) || '-' || strip(subnum);
run;

%macro getraw(indata);
data &indata;
set raw.&indata (encoding=any);
format _all_;
informat _all_;
length subjid $20 usubjid $35;
subjid=strip(put(SITENUM,best.)) || '-' || strip(SUBNUM); ***keep as sitenum||subnum vemile 11/16/2024;
usubjid =  'DIFI-22-01-' || strip(put(SITENUM,best.)) || '-' || strip(SUBNUM);  
run;
%mend;




*============================================================================================================;
* Get DM.
*============================================================================================================;

%getraw(dm);
%getraw(ds);

data dm1;
length studyid $15 siteid $8 race $50   ethnic $25 sex $6 CBPFL $1  racesp HYSSP HYSPROC cbpsp $200;
set dm (drop=  sex ETHNIC RACE CBPSP );

studyid="DIFI-22-01";

siteid=strip(put(SITENUM,best.));

race=strip(RACE_DEC);
RACESP=strip(RACEOTH);
sex=strip(SEX_DEC);
ethnic=strip(ETHNIC_DEC);
CBPFL=strip(CBPYN_DEC);
CBPSP=strip(CBPSP_DEC);

if lowcase(HYSYN_DEC)='yes' then HYSFL='Y';
else hysfl='N';
HYSSP=strip(HYSTYP_DEC);
HYSPROC=strip(HYSTPROC_DEC);

keep studyid siteid usubjid subjid YOB  sex   race RACESP  ethnic CBPFL CBPSP HYSFL HYSSP HYSPROC ;* LMCDAT FSH: EST: HYS:;
run;

proc sort nodupkey;by usubjid;run;

data inf;
set ds;
if DSSTDAT~=.;
RFICDT=DSSTDAT;
ICSFL='Y';
format RFICDT e8601da.;
keep usubjid  RFICDT   ICSFL EXCL4YN_dec   ;
run;

proc sort nodupkey;by usubjid;run;

****study Disc***;

data eos;
set ds;
if complyn_dec~='';
length dcsreasp dcsreas EOSSTT $200;

if upcase(complyn_dec)='NO' then do;
	dcsreas=strip(dsdecod_dec);
	dcsreasp=strip(dsdecodo);
	EOSDT=DSENDAT;
    EOSSTT="DISCONTINUED";
end;
if upcase(COMPLYN_DEC)='YES' then EOSSTT='COMPLETED';

format EOSDT e8601da.;

keep usubjid EOSDT EOSSTT dcsreas dcsreasp;
run;
proc sort nodupkey;
by usubjid;
run; 

data demog;
merge dm1(in=a) inf;
by usubjid;
if a;
age = intck('YEAR',yob,RFICDT,'c');  
length ageu $8;
ageu='YEARS';
run;

data disp;
set ds;
if DSENDAT~=.;
if DSENDAT ^=.  then put "WARN" "ING: Need to add dctreas: " subjid=DSDECOD_DEC=;
run;

***eligible for rand***;
data rand_eli;
set ds;
if PAGENAME='Randomization' and upcase(RANDYN_DEC)='YES';
keep usubjid RANDYN_DEC;
run;

***death**;
data dth;
length DTHCAUS  $100;
set ds; 
if  DTHDAT ^=.;
if DTHDAT ^=.  then put "WARN" "ING: Need to add dhdt: " subjid=DTHCAUSE=;
DTHDT=DTHDAT;
format DTHDT e8601da.;
dthcaus=left(dthcause);
keep usubjid DTHDT DTHCAUS ; 

run;
proc sort nodupkey;by usubjid;run;


*============================================================================================================;
* Get TRT dates.
*============================================================================================================;

%getraw(inj);

data ex;
set inj;
TRTSDT=INJDAT;
TRTSTM=INJSTTIM;

TRTEDT=INJDAT;
TRTETM=INJENTIM;

TRTSDTM = dhms(TRTSDT,0,0,TRTSTM);
TRTEDTM = dhms(TRTEDT,0,0,TRTETM);
format TRTSDT TRTEDT e8601da. TRTSTM TRTETM e8601tm. TRTSDTM  TRTEDTM e8601dt.;
keep usubjid TRT: ;

run;

proc sort nodupkey;by usubjid;run;

*============================================================================================================;
* Get Vitals data
*============================================================================================================;

%getraw(vs);

data vital;
set vs;
where VSDAT^=. ;
vsdate=VSDAT;
if WORRESU_DEC='lb' then wgt=WGTORRES*0.4536;else 
if WORRESU_DEC='kg' then wgt=WGTORRES;

if HORRESU_DEC='in' then hgt=HGTORRES*2.54;else 
if HORRESU_DEC='cm' then hgt=HGTORRES;

bmi=wgt/hgt;

format vsdate e8601da. ;

keep usubjid vsdate hgt  wgt   ;
run; 
proc sort data=vital out=vital;
by usubjid vsdate ;
where WGT~=.;
run;


****Biopsied***;
%getraw(bio);
data biopd;
set bio;
if upcase(BIOYN_DEC)='YES';
biopsyfl='Y';
keep usubjid  biodat;
run;
proc sort nodupkey ;by usubjid;run;

proc sort data=ex out=trt(keep=usubjid trtsdt );
by usubjid;
run;
data trt;
	merge trt biopd;
	by usubjid;
run;

data hwtr;
merge vital(in=a) trt(in=b);
by usubjid;
if a and b;
run;

proc sort data=hwtr;
by usubjid  vsdate ;
run;

data hwbs;
set hwtr;
by usubjid  vsdate ;

*if ( vsdate<=trtsdt)   then bsflg=1;
if ( vsdate<=biodat)   then bsflg=1;
else bsflg = 2;
run; 

proc sort data=hwbs;
by usubjid  bsflg;
run;

*proc print;
*format biodat date9.;
*where usubjid='DIFI-22-01-411-2120007';run;

data hwbsfl;
set hwbs;
by usubjid  bsflg;

if bsflg=1 and last.bsflg then ablfl='Y';

if ablfl='Y';
run;

data vitals_main;
set hwbsfl;

if hgt^=. and wgt^=. then BMIBL=wgt/((hgt/100)**2); 

rename hgt=HEIGHTBL wgt=WEIGHTBL;
keep usubjid hgt wgt BMIBL;
run;

proc sort nodupkey;by usubjid;run;

****Biopsied***;
%getraw(bio);
data biop;
set bio;
if upcase(BIOYN_DEC)='YES';
biopsyfl='Y';
keep usubjid biopsyfl;
run;
proc sort nodupkey ;by usubjid;run;

****Screen failure***;
%getraw(Dat_asub);

data asub;
	set dat_asub;
	IF INDEX(UPCASE(REASON),'RANDOMIZATION')>0;
	REASON=LEFT(REASON);
	RANDID=SUBSTR(REASON,27);
	keep usubjid RANDID;
run;
proc sort;
	by usubjid;
%getraw(Dat_sub);
data sub;
	set dat_sub;
	rename STATUSID_DEC=status;
	length sfreas $200;
	sfreas=left(reason);
	keep usubjid STATUSID_DEC sfreas;
run;
proc sort;
	by usubjid;
run;
 
data extern;
merge sub asub;
*set sub;
by usubjid;
run; 
proc sort;
	by usubjid randid;run;
data extern;
	set extern;
	by usubjid;
	if last.usubjid;
run;

proc sort data=extern out=sf(keep=usubjid STATUS SFREAS)nodupkey;by usubjid;
where upcase(STATUS) in ('SCREEN FAILURE');
run;

proc sort data=extern out=rand(keep=usubjid STATUS)nodupkey;by usubjid ;
where upcase(STATUS) in ('RANDOMIZED');
run;


%getraw(Dat_rand);

***visits;
%getraw(sv);

data blinded;
	set sv;
	length cstper $25 dcsper $50;
	if visitid<=100 then CSTPER='Blinded';  ***month 12;
	else CSTPER='Unblinded';
	
	
    if lowcase(CSTPER)='unblinded' and visitid <=160 then dcsper='Discontinued Prior to Month 24';

	

	keep usubjid visname visitid visyn_dec  CSTPER dcsper;
run;
proc sort;
	by usubjid;
run;

data blindeds ;
	set blinded;
	by usubjid;
PROC SORT data=blindeds out=blind;
	BY USUBJID CSTPER;
RUN;
data blind;
	set blind;
	by usubjid;
	if last.usubjid;
	keep usubjid CSTPER dcsper;
run;


**clinical assessment;
%getraw(cln);

proc sort data=cln out=cln12 nodupkey;
	by usubjid;
	where visitid=100;
run;

proc sort data=vs out=vs12 nodupkey;
	by usubjid;
	where visitid=100;
run;
data cln12;
	set vs12 cln12;
	reached12='Y';
	

run;

*============================================================================================================;
* Merge all.
*============================================================================================================;

data main;
merge demog(in=a)  dth  ex vitals_main  biop  extern biopsy blind cln12 eos;
by usubjid;
if a;

length arm  trt01a trt01p $100 DCFREAS $200 ACTARM $20 DCSSTT $25;

if icsfl=' ' then icsfl='N';
if a then SCRNFL='Y';
saffl='N';
sffl='N';
ITTFL='N';
randfl='N';


if lowcase(status)='screen failure' then SFFL='Y'; 
if lowcase(status)='randomized' then do;ITTFL='Y';randfl='Y';end;

PPsfl='N';
COMPLFL='N';
if trtsdt~=. then ONTRTFL='Y';

if lowcase(bioyn_dec)='yes' then biofl='Y';
else biofl='N';


if  randfl='Y' and biofl='Y' then saffl='Y'; *trtsdt^=.  ***randomized pts who underwent tissue procurement;

    *.......................................................................
	* Determine DUMMY treatment.   
	*.......................................................................; 
 	if substr(usubjid,22,1) in ('1','3','5','7','9') 
	   then arm = 'Iltamiocel'; 
	   else arm = 'Placebo'; 
	actarm = arm;


if randid ne ' ' then do;
trt01p=arm;
trt01pn = input(trt01p,trt.);
end;
if trtsdt ne . then do;
trt01a=ACTARM;
trt01an = input(trt01a,trt.);
end;

else if sffl='Y' then do;
	trt01p='Screen Failure';
	trt01pn=3;
end;

if nmiss(trtsdt,trtedt) = 0  then trtdur=trtedt - trtsdt + 1; 
DCFREAS='';


randtfl='N';
RANDNTFL='N';
UNBBFL='N';
UNBBTFL='N';
UNBBNTFL='N';
IF RANDFL='Y' THEN DO;
if trtsdt ne . then randtfl='Y';
if trtsdt=.    then randntfl='Y';
if lowcase(CSTPER)='unblinded' and biofl='Y'   then unbbfl='Y';
if lowcase(CSTPER)='unblinded' and trtsdt ne . then unbbtfl='Y';
if lowcase(CSTPER)='unblinded' and trtsdt=.    then unbbntfl='Y';


if dcsreas ne ' ' then DCSSTT='Discontinued';
else DCSSTT='Ongoing';

if reached12=' ' and dcsreas='' then ongoing='Y';
if reached12=' ' and dcsreas~='' then dcsper='Discontinued Prior to Month 12';

END;

if biofl^='Y' then biodat=.;

format biodat e8601da.;
run;
*proc print ;
*var usubjid STATUS  randid randfl trtsdt sffl arm trt01a trt01an trt01p trt01pn;run;

*============================================================================================================;
* Setting with ADS template for attributes.
*============================================================================================================;

data tempadsl;
set main atemp.adsl(in=master);
if master then delete;
run;

data main1;
set tempadsl;
/*length DCSRM12 $200;*/

   label 
	      rficdt = 'Date of Informed Consent'
	      dthdt = 'Date of Death'
			sffl = 'Screen Failure Population Flag'

		   HEIGHTBL = 'Baseline Height (cm)' 
		   WEIGHTBL = 'Baseline Weight (kg)' 
		   BMIBL = 'Baseline BMI (kg/m^2)'
		   SCRNFL='Screened Population Flag'
		   ACTARM='Description of Actual Arm'
		   SFREAS='Reason for Screen Failure'
		   ONTRTFL='Ongoing Treatment'
		   trtdur='Treatment Duration'
		   RACESP='Race, Specify'
		   ICSFL='Informed Consent Population Flag'
		   CBPFL     ='Child Bearing Potential Flag'
                                HYSFL='Hysterectomy Performed Flag'
                                HYSSP='Hysterectomy Performed, Specify'
                                HYSPROC='Type of Hysterectomy Procedure'
		BIOFL ='Biopsy Population Flag'
PPSFL='Per Protocol Popuation Flag'
 ONTRTFL='On-Treatment Flag'
 cbpsp='Child Bearing Potential, Specify'
 DCSREAS ='Reason for Discontinuation from Study'
            DCSREASP='Reason Spec for Discont from Study'
/*DCSRM12='Reason for Discontinuation thru Month 12'*/
RANDTFL   ='Randomized, Treated Population Flag'
RANDNTFL  ='Randomized, Not Treated Population Flag'
UNBBFL    ='Unblinded Biopsied Population Flag'
UNBBTFL   ='Unblinded Biopsied, Treated Pop Flag'
UNBBNTFL  ='Unblinded Biopsied, Not Treated Pop Flag'
cstper='Current Study Period'
DCSSTT='Discontinuation Status'
ongoing='Ongoing, Not Reached M12 Evaluation Asmt'
dcsper='Discontinuation Period'
biodat='Muscle Biopsy Tissue Procurement Date'
 EOSDT='End of Study Date'
;

rename biodat=biodt;
*DTHCAUS='Cause of Death'
            
		    eotdt="Date of Completion/Discontinuation"
			dctreas = 'Reason for Discont from Treatment'
			dctreasp = 'Reason Specify for Discont of Treatment';	
run;
 

*============================================================================================================;
* compare
*============================================================================================================;


data qc;
	set main1;

keep studyid siteid usubjid subjid age ageu  sex   race RACESP ethnic rficdt     sffl   SCRNFL RANDFL ICSFL saffl ITTFL  PPSFL COMPLFL
biofl cbpfl cbpsp hysfl hyssp hysproc
trt01a trt01an trt01p trt01pn trtsdt  TRTSDTM trtedt   TRTEDTM  biodt 
       HEIGHTBL WEIGHTBL BMIBL   dcsreas dcsreasp  DTHDT 
RANDTFL RANDNTFL UNBBFL UNBbTFL UNBbNTFL CSTPER DCSSTT ongoing dcsper EOSDT ;
;*SFREAS;
run; 

proc sort; by usubjid;run;
*proc print ;
*var usubjid randfl sffl trt01pn trt01p trt01an trt01a biodat;run;
*proc print data=ads.adsl;
*var usubjid randfl sffl  trt01pn trt01p trt01an trt01a;run;

ods listing;
proc compare base=ads.adsl  compare=qc(label="Subject-Level Analysis Dataset")  listall;*criterion=0.001*;
id subjid;
run; 
