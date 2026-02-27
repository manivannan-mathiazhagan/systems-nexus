dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\Listings\ql-16-2-9-1-1-dia.sas
* DATE:        03Jul2025
* PROGRAMMER:  Manivannan Mathialagan  
*
* PURPOSE:     14 Day Diary - Bowel Accidents (Intention to Treat Population)
*             
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:    
*************************************************************************************;
%let pgm=ql-16-2-9-1-1-dia;
%let pgmnum=16.2.9.1.1; 
%let pgmqc=l_16_2_9_1_1_dia;
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;

proc sort data=ads.addiary out=diary; 
	by subjid trtp trtpn trtsdt avisitn avisit adt ady;
	where ittfl='Y' and parcat1 eq "14 Day Diary - Bowel Accidents" ;
run;

data final; 
	length col3 $25;
	set diary;
	by subjid trtp trtpn trtsdt avisitn avisit adt ady;
	trtn = trtpn;
	trt = trtp;  
  
	if adt ne . then col3 = strip(put(adt,e8601da10.)) || "!n(" || strip(put(ady,best.)) || ")"; 
run;

proc sort data=final; 
	by trtn trt subjid avisitn diaday adt;  
run;

data final;
set final;

trt='Overall';
run;

data qc;
set final; 
array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep trt subjid avisitn period  diadayc adt col3  accbmync  eventnum   DIATM   AMOUNTC  sensatc sumevent;
run;

proc compare base=qclis.&pgmqc compare=qc listall;
run;




