dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Listings\ql-16-2-6-ex.sas
* DATE:        12/18/2024
* PROGRAMMER:  uks
*
* PURPOSE:     Prior and Concomitant Medications
*              (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER:  
*  DATE:       
*  PURPOSE:    
*************************************************************************************;
%let pgm= l-16-2-6-ex;
%let pgmnum=16.2.6; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;


data adex;
set ads.adex;
where ittfl = 'Y';
run;

proc sort;by subjid trtp trtpn trtsdt adt ady asttm aentm;run;
proc transpose data=adex out=ex1;
by subjid trtp trtpn trtsdt adt ady asttm aentm;
id paramcd;
var avalc; 
run;  


data final; 
length col2 $200;
set ex1;
trt='OVERALL' ;
if adt ne . and trtsdt ne . then ady=(adt-trtsdt)+(adt>=trtsdt);  	
if adt ne . and ady ne . then col3 = strip(put(adt,e8601da10.)) || "(" || strip(put(ady,best.)) || ")"; 
if injadm ne '' and reasnd ne '' then col2 = strip(injadm) || ': ' || strip(reasnd); 
else if injadm ne '' then col2 = strip(injadm);
if voladm ne '' and lovol ne ' ' then col10 = input(voladm,best.) - input(lovol,best.); 
run;

proc sort data=final; 
	by trtpn  trt subjid adt asttm ;
run; 
data qc ;
set final; 
array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep trt subjid col2 adt asttm aentm easyn injnum voladm lovol col10;
run;

proc compare base=qclis.&pgmqc  compare=qc listall;
run;
