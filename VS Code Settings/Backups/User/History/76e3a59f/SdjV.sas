DM"log; clear; lst; clear;";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:     P:\Projects\Rhythm\HO ISS\Day90 Update\QC\ADS\qd-advs.sas  
* DATE:        004APRIL2025
* PROGRAMMER:  Indira Ravula (based on Laxmi Choudhary structure/QD-ADSL-037)
*
* PURPOSE:     QC of ADVS   
*
************************************************************************************;
* MODIFICATIONS: 
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:   
*             
************************************************************************************;  

options nofmterr;
%let pgm=qd-advs; 
%let pgmnum=0;  
 
%let protdir=&rmhoiss; 
%include "&protdir\macros\m-setup.sas"; 

%macro type(in=,out=);
libname sdtmvs "P:\Projects\Rhythm\HO ISS\Biostats\ADSdata\Individual Studies\Individiaul VS Studies\&in.";
	data &out;
		set sdtmvs.vs; 
		format _ALL_;
	run;
%mend type;

%type(in=sdtm1,out=vs1_)
%type(in=sdtm2,out=vs2_)
%type(in=sdtm3,out=vs3)
%type(in=sdtm6,out=vs6)
%type(in=sdtm8,out=vs8)
%type(in=sdtm9,out=vs9)
%type(in=sdtm10,out=vs10)
%type(in=sdtm11,out=vs11)
%type(in=sdtm12,out=vs12)
%type(in=sdtm14,out=vs14)
%type(in=sdtm15,out=vs15)
%type(in=sdtm18,out=vs18)
%type(in=sdtm22,out=vs22)
%type(in=sdtm23,out=vs23)
%type(in=sdtm26,out=vs26)
%type(in=sdtm29,out=vs29)
%type(in=sdtm30,out=vs30)
%type(in=sdtm32,out=vs32)
%type(in=sdtm33,out=vs33)
%type(in=sdtm34,out=vs34)
/*%type(in=sdtm35,out=vs35)*/
%type(in=sdtm37,out=vs37)
%type(in=sdtm40,out=vs40)
/*%type(in=sdtm41,out=vs41)*/
/*%type(in=sdtm42,out=vs42)*/
/*%type(in=sdtm43,out=vs43)*/

proc sort data = ads.adsl out = adsl(keep= studyid usubjid trtsdt trtedt trtsdtm trtedtm); by usubjid; run;

 


/****41 study VS*****/

libname sdtm41 "P:\Projects\Rhythm\HO ISS\Biostats\RAWdata\RM-493-041";
data r41(keep=studyid siteid usubjid visit: vstestcd vsorres vsorresu vsstresc vsstresu vsstresn vsdt:);
format _all_;
informat _all_;
set sdtm41.hw(encoding=any);
if VISNAME='Screening (Days -28 to -1)' then do;
visit='SCREENING';
visitnum=0;
end;
if VISNAME='Study Week 1' then do;
visit='Week 1';
visitnum=1;
end;
studyid='RM-493-041';
subjid=strip(subnum);
subjid=substr(subjid,5);
siteid=strip(put(sitenum,best.));
usubjid=trim(studyid)||'-'|| subjid; 
vsdtc = put(hwdt,yymmdd10.); 
vsdt  = hwdt; 
if not missing(HEIGHT) then do;
vstestcd='HEIGHT';
vstest='height';
vsorres=put(HEIGHT,best.);
vsstresn=HEIGHT;
vsstresc=strip(put(height,best.));
vsorresu='cm';
vsstresu='cm';
output;
end;
if not missing(weight) then do;
vstestcd='WEIGHT';
vstest='weight';
vsorres=put(weight,best.);
vsstresn=weight;
vsstresc=strip(put(weight,best.));
vsorresu='cm';
vsstresu='cm';
output;
end;
run;
/****43 Study****/
libname sdtm43 "P:\Projects\Rhythm\HO ISS\Biostats\RAWdata\RM-493-043";
data r43(keep=studyid siteid usubjid visit: vstestcd vsorres vsorresu vsstresc vsstresu vsstresn vsdt:);
set sdtm43.hw;
if VISNAME='Screening (Days -28 to -1)' then do;
visit='SCREENING';
visitnum=0;
end;
if VISNAME='Study Week 1' then do;
visit='Week 1';
visitnum=1;
end;
studyid='RM-493-043';
subjid=strip(subnum);
subjid=substr(subjid,5);
siteid=strip(put(sitenum,best.));
usubjid=trim(studyid)||'-'|| subjid;
vsdtc = put(hwdt,yymmdd10.); 
vsdt  = hwdt; 
if not missing(HEIGHT) then do;
vstestcd='HEIGHT';
vstest='height';
vsorres=put(HEIGHT,best.);
vsstresn=HEIGHT;
vsstresc=strip(put(height,best.));
vsorresu='cm';
vsstresu='cm';
output;
end;
if not missing(weight) then do;
vstestcd='WEIGHT';
vstest='weight';
vsorres=put(weight,best.);
vsstresn=weight;
vsstresc=strip(put(weight,best.));
vsorresu='cm';
vsstresu='cm';
output;
end;
run;
 /*****pulling 037 study***/
libname sdtm37 "P:\Projects\Rhythm\RM-493-037\Biostats\CSR\SDTMdata";
libname sdtm22 "P:\Projects\Rhythm\RM-493-022\Biostats\CSR\SDTMdata";


data rawvs37 rawvsoth; 
               set sdtm37.vs;
               if substr(usubjid,1,10) = 'RM-493-037' then output rawvs37;
                                                      else output rawvsoth;
run;       

data dm37 (keep=usubjid subjid);
               set sdtm37.dm;
               by usubjid;
               subjid = substr(subjid,4); 
data rawvs37;
               merge rawvs37 (in=a) dm37;
               by usubjid;
               if a;
run;

data dm22 (keep=usubjid subjid qval rename=(qval=indexsn));
               merge sdtm22.dm (in=a) sdtm22.suppdm (where=(qnam='INDEXSN'));
               by usubjid;
               if a; 
run;
               
proc sort data=rawvs37; 
               by subjid;  
proc sort data=dm22;  
               by subjid;  
data rawvs37;
               merge rawvs37 (in=a drop=usubjid) dm22 (drop=usubjid);
               by subjid;
               if a; 
data r37;
               set rawvs37; 
               length usubjid $60;
               usubjid = 'RM-493-037-' || strip(indexsn);
               drop indexsn subjid; 
run;

 
data vsallxx;
length VSSPID VSGRPID VSPOS VSLOC VSLAT VSTPTREF VSRFTDTC studyid usubjid $200.;
	set vs1_ vs2_ vs3 vs6 vs8 vs9 vs10 vs11 vs12 vs14 vs15 vs18   vs22    vs23 vs26 vs29 vs30 vs32 vs33 vs34   r37 vs40 r41 r43;
format _all_;
	informat _all_;  
	*if vsstresn ne . and usubjid='RM-493-034-030-005'   ;
	studyid = tranwrd(studyid,'RM493-','RM-493-'); 
	usubjid = tranwrd(usubjid,'RM493-','RM-493-');
 	*** Adjust USUBJID ***;
	if studyid = 'RM-493-003' then usubjid = substr(usubjid,1,11) || '0' || substr(usubjid,12,2) || '-' || substr(usubjid,14);
	if studyid = 'RM-493-006' then usubjid = substr(usubjid,1,11) || '001-' || substr(usubjid,12);
	if studyid = 'RM-493-009' then usubjid = substr(usubjid,1,11) || '0' || substr(usubjid,12,2) || '-' || substr(usubjid,14); 
	if studyid = 'RM-493-010' then usubjid = substr(usubjid,1,11) || '0' || substr(usubjid,12,2) || '-' || substr(usubjid,14); 
	if studyid = 'RM-493-011' then usubjid = substr(usubjid,1,15) || '0' || substr(usubjid,19);  
	if studyid = 'RM-493-026' then usubjid = substr(usubjid,1,15) || substr(usubjid,17);  
	if studyid = 'RM-493-032' then usubjid = substr(usubjid,1,11) || substr(usubjid,16,3) || '-' || substr(usubjid,19,3);  
run;
data vs35;  
	set raw35.vs (encoding=any drop=studyid siteid) 
	    raw35.vs1 (encoding=any drop=studyid siteid);   
	if folderseq in (1,2,37) and (vshegt ne . or vshegt1 ne . or vswght ne . or vswght1 ne .);  
 
	length studyid $15 subjid $15 usubjid $60 siteid $8;
	studyid='RM-493-035';
	subjid=strip(subject);
	subjid=substr(subjid,5);
	siteid=substr(sitenumber,5,3);
	usubjid=trim(studyid)||'-'|| subjid; 
run;

proc sort data=vs35;
	by usubjid folderseq;
data vs35;
	merge vs35 (in=a) adsl (in=b keep=usubjid trtsdt trtsdtm  );
	by usubjid;
	if a and b and trtsdt ne . and ((vsdtm ne . and trtsdtm ne . and vsdtm<=trtsdtm) or (vsdtm eq . and vsdat<=trtsdt) or (trtsdtm eq . and vsdat<=trtsdt));
data vs35 (keep=usubjid studyid visitnum visit vsdtc vstestcd vsstresc vsstresn vsstresu  );
	set vs35;   
	by usubjid; 
 
	length visit $75 vsdtc $19 vstestcd $8 vsstresc $200 vsstresu $100;
	visit = foldername;
	if foldername = 'Screening (In-person)' then visitnum=0;
	if foldername = 'Baseline Visit 1 (In-Person)' then visitnum=1; 
	vsdtc = put(datepart(vsdat),yymmdd10.);
	
	if vshegt eq . and vshegt1 ne . then vshegt = vshegt1;
	if vswght eq . and vswght1 ne . then vswght = vswght1; 

	if vshegt ne . then do;
	   vstest   = 'Height';
	   vstestcd = 'HEIGHT';
	   vsstresu = 'cm';
	   vsstresn = vshegt;
	   vsstresc = strip(put(vsstresn,best.));
	   output;
	end;
	if vswght ne . then do;
	   vstest   = 'Weight';
	   vstestcd = 'WEIGHT';
	   vsstresu = 'kg';
	   vsstresn = vswght;
	   vsstresc = strip(put(vsstresn,best.));
	   output;
	end;
run;
 
data vsallx (drop=usubjid rename=(usubjidX=usubjid));
	set vsallxx vs35;
	length usubjidX $60;
	usubjidX = usubjid;
run;
data vsallx;
set vsallx;

if vsdtc ne '' and length(VSDTC) ge 10 then vsdt=input(scan(vsdtc,1,'T'),yymmdd10.);
if vsdtc ne '' and length(VSDTC) ge 10 then vstm=input(scan(vsdtc,2,'T'),time.);

    if length(vsdtc) > 10 then vsdtm=input(put(vsdt,E8601DA.)||"T"||put(vstm,tod.), e8601dt.); 
 format vsdt yymmdd10. vsdtm e8601dt. vstm time5.;
 keep studyid usubjid siteid vstestcd visit: vsdtc vstm vsdt vsdtm visit: vsorres vsstresc vsstresn vsstat studyid VSSTRESU;
 run;
/****merge with ADSL ***/
proc sort data = vsallx; by usubjid; run;

data vsall2;
 	merge vsallx(in=a) adsl(in=b);
	by usubjid;
	if a and b;
run;
 %macro meanx(out1=,con1=,byvar=,out2=);
proc sort data=vsall2 out=&out1(&con1);
by &byvar;
run;
proc means data=&out1 nway mean noprint;*(where=(usubjid='RM-493-012-008-001'));
by &byvar;
var vsstresn;
	output out=&out2   mean=mean_d;
run;
%mend; 
/*******a)	Set the MEAN average, except for 034 and 035 studies *****/
 %meanx(out1=rall,con1=%str(where=(vstestcd in ('HEIGHT' 'WEIGHT') and vsstresn ne . and vsstat ne 'NOT DONE' 
and studyid not in ('RM-493-034' 'RM-493-035'))),
 byvar=studyid usubjid trtsdt trtsdtm vstestcd visitnum visit vsdtc,out2=vsavg_rall);
 
/*****b)	Set the MEAN average, for 034 and 035 studies, with multiple visitnum *****/

 %meanx(out1=r345,con1=%str(where=(vstestcd in ('HEIGHT' 'WEIGHT') and vsstresn ne . and vsstat ne 'NOT DONE'  and  studyid   in ('RM-493-034' 'RM-493-035'))) ,
 byvar=studyid usubjid trtsdt trtsdtm trtedt vstestcd visitnum visit vsdt ,out2=vsavg_345);

 /****bring Unique records to 34/35 studies to get common variables****/
 proc sort data=r345;by  usubjid trtsdt trtsdtm vstestcd visitnum visit vsdtc;run;
data r345_Unique;
set r345;
if last.visitnum;
by usubjid trtsdt trtsdtm vstestcd visitnum visit vsdtc;
run;

data vsavg_345;
merge vsavg_345 r345_Unique;
by usubjid trtsdt trtsdtm vstestcd visitnum visit vsdt;
run;
/*******c)	Set a and b together. ******************/


data d1;
set vsavg_rall vsavg_345;
 run;

 
proc sort data=d1;
	by usubjid trtsdt trtsdtm vstestcd visitnum visit vsdtc;
data d1;
	set d1;
	if vsdtc ne '' and length(VSDTC) ge 10 then vsdt=input(scan(vsdtc,1,'T'),yymmdd10.);
if vsdtc ne '' and length(VSDTC) ge 10 then vstm=input(scan(vsdtc,2,'T'),time.);
if not missing(vsdt) and not missing(vstm) then 
vsdtm=input(put(vsdt,E8601DA.)||"T"||put(vstm,tod.), e8601dt.); 
 format vsdt yymmdd10. vsdtm e8601dt. vstm time5.;
 	by usubjid trtsdt trtsdtm vstestcd visitnum visit vsdtc;
	if last.vsdtc; 
run;


/*e)	Determine BASLEINE for HEIGHT and WEIGHT, sort by usubjid trtsdt trtsdtm vstestcd vsdt vsdtm
And pick the last VSTESTCD.*/

/***set baseline value for derived results*****/
data d1;
set d1;
if ((vsdtm ne . and trtsdtm ne . and vsdtm<=trtsdtm) or (vsdtm eq . and vsdt<=trtsdt) or (trtsdtm eq . and vsdt<=trtsdt)) ;
run;
proc sort data=d1;
by usubjid trtsdt trtsdtm vstestcd vsdt vsdtm;
run;
data flag1;
set d1;
by usubjid trtsdt trtsdtm vstestcd vsdt vsdtm;
if last.vstestcd  then vsblfl='Y';
if vsblfl='Y';
keep usubjid trtsdt trtsdtm vstestcd mean_d;
run;
 
 
/*************	Determine BASLEINE for MHEIGHT and MWEIGHT, sort by usubjid trtsdt trtsdtm vstestcd vsdt vsdtm
And pick the last VSTESTCD.***************/
 

data vsallx;*(where=(usubjid='RM-493-012-008-001'));
set vsall2;
if vstestcd in ('MWEIGHT' 'WEIGHTAV' 'WGTAVG') and vsstat ne 'NOT DONE' and vsstresn ne .;
 if vsdtc ne '' and length(VSDTC) ge 10 then vsdt=input(scan(vsdtc,1,'T'),yymmdd10.);
if vsdtc ne '' and length(VSDTC) ge 10 then vstm=input(scan(vsdtc,2,'T'),time.);
if not missing(vsdt) and not missing(vstm) then 
vsdtm=input(put(vsdt,E8601DA.)||"T"||put(vstm,tod.), e8601dt.); 
 format vsdt yymmdd10. vsdtm e8601dt. vstm time5.;
 run;

data flag_1;
	set vsallx;
	if   ((vsdtm ne . and trtsdtm ne . and vsdtm<=trtsdtm) or (vsdtm eq . and vsdt<=trtsdt) or (trtsdtm eq . and vsdt<=trtsdt));
 run; 
 proc sort data=flag_1;
	by usubjid trtsdt trtsdtm vstestcd vsdt vsdtm ; run;
data flag_1;
	set flag_1;
	by 	usubjid trtsdt trtsdtm vstestcd vsdt vsdtm  ; 
	if last.vstestcd then VSBLFL="Y";
	if VSBLFL="Y";
	vstestcd='WEIGHT';
	keep usubjid trtsdt trtsdtm vstestcd vsstresn;
run; 
/****bring 41 data and merge with ADSL****/

proc sort data=r41;by usubjid ;run; 
data r411;
length usubjid $200;
merge  adsl(in=b) r41(in=a);
by usubjid;
if a and b;
run;

proc sort data=r411;by usubjid trtsdt trtsdtm vstestcd vsdtc  ;run;
data r411(rename=(usubjid_=usubjid));
length usubjid_$35;
set r411;
usubjid_=usubjid;
if last.vstestcd;
by usubjid trtsdt trtsdtm vstestcd vsdtc  ;
drop usubjid;
run;
data flag1(rename=(usubjid_=usubjid));
length usubjid_$35;
set flag1;
usubjid_=usubjid;
drop usubjid;
run;
data flag_1(rename=(usubjid_=usubjid));
length usubjid_$35;
set flag_1;
usubjid_=usubjid;
drop usubjid;
run;
proc sort data=flag1;by usubjid trtsdt trtsdtm vstestcd;run;
proc sort data=flag_1;by usubjid trtsdt trtsdtm vstestcd;run;
proc sort data=r411;by usubjid trtsdt trtsdtm vstestcd;run;

data all  ;
length usubjid $35;
merge flag1 (in=a ) flag_1(in=b  )  r411  ;
by usubjid trtsdt trtsdtm vstestcd;
if missing(vsstresn) then vsstresn = mean_d ; 
/*usubjid_=usubjid;*/
/*label usubjid_='Unique Subject Identifier';*/
drop mean_d   ;
 run;
 
proc transpose data=all out=all_t suffix=bl;
var vsstresn;
by usubjid ;
id vstestcd;
run;

data qcadvs(label='Vital Signs Analysis Dataset');
set all_t;
if nmiss(heightbl, weightbl) = 0 then bmibl = weightbl/((heightbl/100)**2);   
label heightbl='Baseline Height (cm)'
weightbl='Baseline Weight (kg)'
bmibl='Baseline BMI (kg/m2)';
keep usubjid heightbl weightbl bmibl ;
run;

/*proc compare data=ads.advs compare=qc listall; 
id studyid siteid usubjid subjid trtsdt trtedt ;
run;
*/
