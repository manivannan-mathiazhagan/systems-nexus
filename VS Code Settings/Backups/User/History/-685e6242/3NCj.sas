dm "log;clear;lst;clear";

************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\Listings\ql-16-2-1-ds.sas
* DATE:        29JAN2025
* PROGRAMMER:  Shashi
* PURPOSE:     Participant Disposition (All Screened Subjects)
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:   
* 
*************************************************************************************;
%let pgm=ql-16-2-1-ds;
%let pgmnum=16.2.1; 
%let pgmqc=l_16_2_1_ds;
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas";

data adsl;
set ads.adsl;
where SCRNFL = 'Y' ;
keep  subjid DCSREAS TRT01PN TRT01P TRT01A DCSREAS DCSREASP DCSPER DCSSTT SCRNFL SFFL   RANDTFL RANDNTFL UNBBFL UNBBTFL UNBBNTFL ITTFL SAFFL PPSFL ICSFL CSTPER;
run;
/*data adsl1(keep= subjid DCSREAS DCSREASP DCSPER DCSSTT CSTPER TRT01PN TRT01P status time ITTFL SAFFL PPSFL);*/
/*set adsl;*/
/*array _s [*]    SFFL   RANDTFL RANDNTFL UNBBFL UNBBTFL UNBBNTFL ;*/
/*	do i = 1 to dim(_s);*/
/*		status = _s[i];*/
/*		time = propcase(scan(vname(_s[i]), -1, '_'));*/
/*		subjid = subjid;*/
/*		output;*/
/*	end;*/
/*	*/
/*run;*/


data main;
set adsl;
length col2 $50 col8 $200;

if RANDTFL = 'Y' then col2 = "Randomized, Treated";
else if RANDNTFL = 'Y' then col2 = "Randomized, Not Treated";
else if SFFL = 'Y' then col2 = 'Screen Failure';
else if SCRNFL = 'Y' then col2 = "Screened";


/*if upcase(time)='SFFL' then col2='Screen Failure';*/
/*if upcase(time)='BIOFL' then col2='Biopsy';*/
/*if upcase(time)='RANDTFL' then col2='Randomized, Treated';*/
/*if upcase(time)='RANDNTFL' then col2='Randomized, Not Treated';*/
/*if upcase(time)='UNBBFL' then col2='Unblinded Biopsied';*/
/*if upcase(time)='UNBBTFL' then col2='Unblinded Biopsied, Treated';*/
/*if upcase(time)='UNBBNTFL' then col2='Unblinded Biopsied, Not Treated';*/

col8=catx(':',DCSREAS ,DCSREASP);
if ITTFL='Y' then col3='Yes';else
if ITTFL='N' then col3='No';

if SAFFL='Y' then col5='Yes';else
if SAFFL='N' then col5='No';

if PPSFL='Y' then col4='Yes';else
if PPSFL='N' then col4='No';

trt=strip(trt01p);
if trt= '' then trt='Not Treated';

trtn=trt01pn;
if trtn= . then trtn=3;


keep subjid col:  CSTPER DCSSTT col8  DCSPER trtn trt;
run;

proc sort data=main out=final; 
by trtn trt subjid ;  
run; 

data qc;
set final; 
trt='OVERALL';
TRTn=0;
array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep subjid col2 col3 col4 col5 CSTPER DCSSTT col8  DCSPER  trt trtn;

run;

proc compare base=qclis.&pgmqc compare=qc listall;
run;
