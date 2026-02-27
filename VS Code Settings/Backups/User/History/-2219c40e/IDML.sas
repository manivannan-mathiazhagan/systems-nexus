dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\qt-14-1-6-ex.sas
* DATE:        1/21/2025 
* PROGRAMMER:  v emile
*
* PURPOSE:     exposure
*              (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER:  POORNIMA KANNAN
*  DATE:        29JUL2025
*  PURPOSE:     ADD: SE & 95% CI
*************************************************************************************;
%let pgm=t-14-1-6-ex;
%let pgmnum=14.1.6; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;

proc format;
	invalue reas 'Resuspension volume not within specification' = 1
		         'Patient Decision' = 2
		         'Physician Decision' = 3
		         'Unable to produced product for patient' = 4
		         'Other' = 5;
run;

proc sort data=ads.adex out=adic2(keep=usubjid trtp trtpn paramn param aval avalc studyid);
	by trtpn trtp;
	where saffl = 'Y' and paramn ^=9;
run; 

	data adic2;
		set adic2;
		if PARAMN eq 2 and substr(AVALC,1,5) eq "Other" then AVALC = "Other";
		else AVALC = AVALC;
		     if paramn=2 then param=trim(param)||'[1]';		
		else if paramn=3 then param=trim(param)||'[2]';	
		else if paramn=7 then do;param=trim(param)||'[3]';nparamn=5;end;
 		else if paramn=5 then do;nparamn=6;end;
        else if paramn=6 then do;nparamn=7;end;
		else if paramn=8 then param='Study Product Compliance [4]';
		
		if nparamn=. then nparamn=paramn;
		drop paramn;
run;
data adic2;
	set adic2;
	rename nparamn=paramn;
	output;
	trtpn=9;
	output;
run;

proc sort;
	by trtpn paramn ;

proc means data=adic2 noprint;
where paramn not in(1 2 8);
   	var aval;
   	output out=univ n=n mean=mean median=median std=std  min=min max=max lclm=lclm uclm=uclm stderr=stderr;
   	by trtpn paramn;
run;
	
data univ;
   	set univ;
   	attrib text1-text6  length=$20; 

	if paramn^=30 then do;
      	text1   = put(n,4.);
		if std ne . then 
      	text2   = put(mean,6.1)||' ('||	left(put(std,7.2)||')'); 
		else 
		text2   = put(mean,6.1)|| '(NA)';
      	if stderr ne . then text3 = strip(put(stderr,7.2));	  	
		if . < lclm < 0 then lclm = 0;
		if lclm ^= . and uclm ^= . then text4 = '('||strip(put(lclm,6.1))||', '||strip(put(uclm,6.1))||')';
		else if lclm = . and uclm ^= . then text4 = '(, '||strip(put(uclm,6.1))||')';
		else if lclm ^= . and uclm = . then text4 = '('||strip(put(lclm,6.1))||',)';
		else if lclm = . and uclm = . then text4 = '(NA)';
      	text5   = put(median,6.1);      
      	text6   = put(min,6.1) ||', '|| left(put(max,6.1));
	end;
	else do;
		text1   = put(n,4.);
		if std ne . then 
      	text2   = put(mean,6.1)||' ('||	left(put(std,7.2)||')'); 
		else 
		text2   = put(mean,6.1)|| '(NA)'; 
      	if stderr ne . then text3 = strip(put(stderr,7.2));	  	
		if . < lclm < 0 then lclm = 0;
		if lclm ^= . and uclm ^= . then text4 = '('||strip(put(lclm,6.1))||', '||strip(put(uclm,6.1))||')';
		else if lclm = . and uclm ^= . then text4 = '(, '||strip(put(uclm,6.1))||')';
		else if lclm ^= . and uclm = . then text4 = '('||strip(put(lclm,6.1))||',)';
		else if lclm = . and uclm = . then text4 = '(NA)';
      	text5   = put(median,6.1);      
      	text6   = put(min,6.) ||', '|| left(put(max,6.));
	end;
run;

data univ;
    	set univ;
      	array stat{6} text1-text6;
 		do i=1 to 6;
       number=stat{i};
       counter=i;
	   cat=1;
       output;
    end;

proc sort data=univ;
     by paramn  cat counter;
    run;

proc transpose data=univ out=tran1 prefix=col;
     by paramn  cat counter;
     var number;
     id trtpn;
    run;
run;


/*%qcntotal;*/

data adic3;
	set adic2;
	if paramn in(1 2 8);
	if lowcase(avalc)='yes' then aval=1;
	if lowcase(avalc)='no' then aval=2;
	if aval ne .;
run;

proc sort data=adic3;
	by trtpn paramn ;

proc freq data=adic3 noprint;
        tables aval/out=freq(keep=trtpn paramn param aval count);
        by trtpn paramn param;
run;

proc sort data=freq nodup;by trtpn paramn param count ;run;

proc freq data=adic2 noprint;
where paramn eq 1;
        tables studyid/out=freq1(keep=trtpn paramn param  count);
        by trtpn paramn param;
run; 

proc freq data=adic2 noprint;
where paramn eq 2 and avalc ne '';
        tables studyid/out=freq1__(keep=trtpn paramn param  count avalc);
        by trtpn paramn param avalc;
run; 

proc sort data=adic2 out=param(keep=paramn param) nodupkey;
	by paramn;
	WHERE PARAMN^=9;
run; 

data miss(rename=(count=total));
	set freq1(keep=trtpn count );
		do paramn=1, 8;
        do aval=0 to 5;
        output;
       	end;
		end;
run;

proc sort data=freq out=freq___(where=(paramn=1 and aval=2) rename=(count=total));by trtpn;run;

data miss2;
	set freq___ (keep=paramn trtpn total);
		do paramn=2;
        do aval=0 to 5;
        output;
       	end;
		end;
run;

data miss3;
	set miss miss2;
proc sort;by  paramn;
run;

data miss3;
	merge miss3 param;
	by paramn;

data miss3;
	set miss3;
	if paramn not in(2) and aval >2 then delete;
run;

proc sort data=miss3;
        by trtpn paramn aval;
run;

data freqa;
set freq freq1(in=a) freq1__(in=b);
if a then aval = 0;
if b then aval=input(avalc,reas.);
run;
   
proc sort data=freqa out=freq;
        by trtpn paramn aval;
run;

data all;
        merge miss3 freq;
        by trtpn paramn aval; 
        length number $25;
        if count ne . and paramn eq 1 and aval eq 0 then 
		number=put(count,3.); else if count^=. then
        number=put(count,3.) || ' (' || PUT(100*(count/total),5.1) || ')';
        else
        number='  0';
        cat=1;
		counter=aval;
        format _all_;
run;

proc sort data=all;
        by cat paramn param  counter;
run;

proc transpose data=all out=tran2 prefix=col;
        by cat paramn param  counter;
        var number;
        id trtpn;
run; 

proc format;
value ynf 1='Yes'
		  2='No';

value reasf
		1='Resuspension volume not within specification'
		2='Patient Decision'
		3='Physician Decision'
		4='Unable to produced product for patient'
		5='Other';

run;

data tran1;
	merge tran1(in=in1) param;
	by paramn;
	if in1;
run;
	   data tran2_0;
	   set tran2;
	   if paramn eq 1 and COUNTER eq 0;
	   paramn = 0;
	   param="Number of subjects reaching Day 0 Visit?";
	   counter=1;
	   run;

data final; 
	set tran1 tran2 tran2_0;

	length parameters $200 stat $15;
	     if paramn in(1 8) then parameters=put(counter,ynf.);	
	     if paramn in(2)   then parameters=put(counter,reasf.);

	if paramn in (1 2 8) then stat='n (%)';
	else if paramn eq  0 then stat='N1';
	else do;
		     if counter=1 then stat='n';
		else if counter=2 then stat='Mean (SD)';
		else if counter=3 then stat='SE';
		else if counter=4 then stat='(95%CI)';
		else if counter=5 then stat='Median';
		else if counter=6 then stat='Min,Max';
	end;

	IF COUNTER=. THEN DELETE;
if paramn=2 and counter ne 0 and col1='' then col1='  0';
if counter IN(0) then DO;
		PARAMETERS=PARAM;
		COL1=' ';
		COL2=' ';
		COL9=' ';
		stat=' ';
	END;

	
if PARAMN NOT IN(1 2 8) AND counter=1 then 	PARAMETERS=PARAM;

	if compress(col1) in('()' ',' '(NA)') then col1=' ';
	if compress(col2) in('()' ',' '(NA)') then col2=' ';
	if compress(col9) in('()' ',' '(NA)') then col9=' ';

	RENAME COL9=COL3
	PARAMETERS=FORMAL;
run; 
proc sort data=final; 
	by cat paramn counter;
run;  
data qc ;
retain cat paramn FORMAL counter col1 col2 col3;
set final; 
array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep   FORMAL stat  col1 col2 col3;
run; 
*proc print;
*libname qctab "P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\QC";
/*proc print data=qctab.&pgmqc;run;*/

proc compare base=qctab.&pgmqc  compare=qc listall;
run;
