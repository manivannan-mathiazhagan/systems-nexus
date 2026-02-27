dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Listings\ql-16-2-2-dme.sas
* DATE:        26 jan 2025
* PROGRAMMER:  V EMILE
*
* PURPOSE:     demo
*              (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER:  
*  DATE:       
*  PURPOSE:    
*************************************************************************************;
%let pgm= l-16-2-2-dm;
%let pgmnum=16.2.2;
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;


data adsl;
set ads.adsl; 
where ittfl = 'Y';

length cbp hys $3  col3 col8 $200  agec $10 bmic $200;

     if compress(cbpfl)='Y' then cbp='Yes';
else if compress(cbpfl)='N' then cbp='No';

     if compress(hysfl)='Y' then hys='Yes';
else if compress(hysfl)='N' then hys='No';

if cbpsp ne ' ' then col3=trim(cbp)||': ' ||left(trim(cbpsp));
else col3=trim(cbp);

if hyssp ne ' ' then col8=trim(hys)||': ' ||left(trim(hyssp));
else col8=trim(hys);
	
rename 
trt01p=trt 
col3=cbpc
col8=hysc;
bmic=left(put(bmibl,8.1));

agec=left(put(age,2.));

keep subjid trt01an trt01p sex col3 agec race ethnic bmic col8 hysproc  cbpfl cbp hysfl;
run;

proc sort data=adsl;
	by trt subjid;
run; 
data qc ;
label trt = " ";
retain trt subjid sex cbpc agec race ethnic bmic hysc hysproc;
set adsl; 

trt='Overall';
array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep trt subjid sex cbpc agec race ethnic bmic hysc hysproc;
run;


proc compare base=qclis.&pgmqc  compare=qc listall;
run;
