dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\Listings\ql-16-2-7-2-vs.sas
* DATE:        01/21/2024
* PROGRAMMER:  uks
*
* PURPOSE:     Vital Signs (Intention to Treat Set)
*             
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER:    vemile
*  DATE:       1/28/2025
*  PURPOSE:    completion
*************************************************************************************;
%let pgm= l-16-2-7-2-vs;
%let pgmnum=16.2.7.2; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;

Data advs;
set ads.advs;
where saffl = 'Y' ;
if trtan = . then trtan = 3;

	if avisitn not in(10 15 20 170) then avisit = left(scan(avisit,3,'-'));
	if avisitn=170 then avisit='Unscheduled';
	
if adtm ne . then col3 = strip(put(adt,e8601da10.)) || strip(put(atm,time5.)) || "(" || strip(put(ady,best.)) || ")"; else
if adt ne .  then col3 = strip(put(adt,e8601da10.)) || "(" || strip(put(ady,best.)) || ")";   
if paramn in(1 2 4 5) then col7=put(chg,6.);
else col7 = strip(put(chg,5.1)); 

if compress(col7)='0.0' then col7='0';
run;
proc sort data=advs out =final; 
by trtan trta subjid  avisitn avisit adt atm vstptnum  paramn;  
run;  

data qc ;
length trt $100. col3 col7 $200.;
retain trtan        SUBJID       AVISIT               COL3    vstpt                PARAM                           avalc      COL7;
 set final;  
 
trt='Overall';
	array ch _character_;
	do over ch;
	 ch=compress(ch);
	ch=upcase(ch);
	end;
keep	 tRT        SUBJID       AVISIT               COL3     vstpt               PARAM                           avalc      COL7;
   run;
   
proc compare base=qclis.&pgmqc  compare=qc  listall;
*id subjid ;
run;
