dm "log;clear;lst;clear";

************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\Listings\ql-16-2-7-4-lb.sas
* DATE:        01/21/2024
* PROGRAMMER:  uks
* PURPOSE:     Clinical Laboratory Results - Chemistry (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER: Manisha Tharval
*  DATE:       28-Jan-2025
*  PURPOSE:    Updated as per STAT email.
* 
*************************************************************************************;
%let pgm=ql-16-2-7-4-lb;
%let pgmnum=16.2.7.4; 
%let pgmqc=l_16_2_7_4_lb_chem;
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas";

data adlb;
length trt $100 dt tm dy dtm col3  col7 $200;
set ads.adlb;
where saffl = 'Y' and parcat1 = 'CHEMISTRY';

trt = strip(trta);
trtn = trtan;
if trt = '' then do; trt = 'Not Treated'; trtn = 3; end;

if avisitn not in (10 15 20 170 220 240) then avisit = left(scan(avisit,3,'-')); 
if avisitn = 240 then avisit = left(scan(avisit,1,'-'));
if avisitn = 170 then avisit = left(scan(avisit,1,' '));

if adt ^= . then dt = strip(put(adt,e8601da.));
if atm ^= . then tm = strip(put(atm,time5.));
if ady ^= . then dy = strip(put(ady,best.));

dtm = catx('/',dt,tm);
    if n(adt,trtsdt)=2 then adyx=(adt-trtsdt)+(adt>=trtsdt);  	

if dtm ^= '' and dy ^= '' then col3 = strip(dtm) || ' (' || strip(adyx) || ')';

/*if aval ^= . then col6 = strip(put(aval,best.)); */

if chg ^= . then col7 = strip(put(chg,5.1)); 

keep trtn trt subjid avisitn avisit adt atm paramn param lborres lborresu lbstresu aval col: CLSIG;
run;

proc sort data=adlb out=final; 
by trtn trt subjid adt atm avisitn avisit paramn;  
run; 

data qc;
set final; 
trt='OVERALL';
trtn=0;
array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep trt subjid avisit param lborres lborresu lbstresu aval col: CLSIG;
run;

proc compare base=qclis.&pgmqc compare=qc listall;
run;
