dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Listings\ql-16-2-3-1-mh.sas
* DATE:        22 JAN 2025
* PROGRAMMER:  V EMILE
*
* PURPOSE:     MH
*              (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER:  
*  DATE:       
*  PURPOSE:    
*************************************************************************************;
%let pgm= l-16-2-3-1-mh;
%let pgmnum=16.2.3.1;
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;


proc sort data=ads.admh out=admh1;
	by subjid;
where ittfl = 'Y' and mhcat ne "MEDICAL HISTORY";
run;

data admh1;
	set admh1;
length col2 col4 $200;

if chldbrfl ne ' ' then col2=compress(CHLDBRFL||'/'||put(VAGNUM,2.)||'/'||put(CESNUM,2.));
else if chldbrfl=' ' then col2='N';

if DIAHISFL='Y' then   col4=catx("/",compress(DIAHISFL),STRIP(put(HBA1CRES,5.1)));
else col4=compress(DIAHISFL);

keep subjid trtp trtpn col2 autofl col4 DIAHISFL HBA1CRES chldbrfl mhstdtc mhendtc mhbodsys mhdecod;
run;
proc sort;
	by subjid trtpn;
run; 
*proc print;
*where subjid='401-2120023';run;



proc sort data=ads.admh out=admh2(drop=CHLDBRFL VAGNUM  CESNUM HBA1CRES DIAHISFL autofl);
	by subjid trtpn;
where ittfl = 'Y' and mhterm ne ' ';
run;

data admh;
	merge admh1 admh2(in=in2);
	by subjid trtpn;
/*	if in2;*/
run;

*proc print;
*where subjid='401-2120023';
*var subjid autofl;run;

*CHLDBRFL    VAGNUM    CESNUM    AUTOFL    DIAHISFL    HBA1CRES;

data qc; 
length col6 col7 $30 col5 $600;
set admh;
rename trtp =trt ;   

col5=catx('/',mhBODSYS,mhdecod,mhterm);

if astdy ne . then col6 = strip(mhstdtc) || "(" || strip(put(astdy,best.)) || ")"; 
else col6 = strip(mhstdtc);
if  aendy ne . then col7 = strip(mhendtc) || "(" || strip(put(aendy,best.)) || ")"; 
else col7 = strip(mhendtc);
run;

*data qc;
*	set qc;
*	output;
*	trtpn=3;
*	trt='Overall';
*	output;
*run;

proc sort data=qc; 
	by trtpn trt subjid mhstdtc mhendtc mhbodsys mhdecod;
run; 
data qc ;
LABEL TRT = " ";
retain trt subjid col2 autofl col4 col5 col6 col7;
set qc; 

trt='Overall';
*if compress(col2) in(' ' '//') then col2='N';
*if compress(col4) in(' ' '//') then col4='N'; 
array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep trt subjid col2 autofl col4 col5 col6 col7;
run; 

 
proc compare base=qclis.&pgmqc  compare=qc listall;
run;
