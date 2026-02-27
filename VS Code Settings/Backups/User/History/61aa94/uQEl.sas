 dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\_Restricted\Tables\t-14-1-5-2-cm.sas   
* DATE:       31DEC2024
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Concomitant Medications
*               (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER: keerthana Bommagani   
*   DATE:       04-AUG-2025  
*   PURPOSE:    Updating Program to display UNCODED.      
************************************************************************************;      
%let pgm=t-14-1-5-2-cm; 
%let pgmnum=14.1.5.2; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu; 
  
%include "&protdir\macros\m-setup.sas";    

*...............................
* Determine treatment flag.  
*...............................;   



data adsl;
	set ads.adsl;
   if  SAFFL='Y';
   if trt01an=. then trt01an=3;
   trt=trt01an; 
 	output;
 
	trt = 9;
	output;
run;
 
proc freq data=adsl noprint;  
   	tables trt/out=total; 
data dummy;
	do trt = 1,2,3,9;
	   output;
	end;
data total;
	merge dummy total (in=master);
	by trt;
	if not master then count = 0; 
data _null_;
   	set total;    
   	if trt = 1 then call symput("col1",compress(put(count,3.))); 
   	if trt = 2 then call symput("col2",compress(put(count,3.))); 
   	if trt = 3 then call symput("col3",compress(put(count,3.))); 
	if trt = 9 then call symput("col9",compress(put(count,3.))); 
run;   

proc delete data=dummy;
run;
%put &col1 &col2 &col3 &col9; 



*=============================================================================== 
* 1. Bring in required dataset(s).  
*===============================================================================;   
data all_1; 
   	set ads.adcm (where=(saffl='Y' /*and trtan ne .*/ and  priconfl eq 'Concomitant') rename=(cmdecod=cmdecod_));   
   	by usubjid;  
    if trtan=. then trtan=3;
	trt = trtan;
   	any = 'Y';
	length cmdecod $400;
	cmdecod=catx('',cmdecod_,cmdecod1);
	if cmclas = ' ' then cmclas = 'Uncoded';
	if cmdecod = ' ' then cmdecod = CMTRT; 
   	output;  
	   	
	trt = 9; 
	output;  
run;  
      
*===============================================================================
* 2. Proc Freq.
*===============================================================================; 
%macro freq(order=,var=,level=);

	proc sort data=all_1 out=&var;
   		by &level trt usubjid; 
  	data &var;     
		set &var;
    	by &level trt usubjid;										
   		if last.usubjid; 											
 	proc freq data=&var noprint;
   		by &level;
   		tables trt / out=&var missing;
  	run;       

%mend;
  
%freq(order=1,var=any,level=%str(any)) 
%freq(order=2,var=cmclas,level=%str(cmclas)) 
%freq(order=3,var=cmdecod,level=%str(cmclas cmdecod))

*=============================
* Set together.
*=============================;
data all_2;
  	set any (in=inany) cmclas cmdecod;
  	length result $12; 

   	if trt = 1 then do; pct = round((count/&col1)*100,.1); result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; end; else 
   	if trt = 2 then do; pct = round((count/&col2)*100,.1); result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; end; else 
   	if trt = 3 then do; pct = round((count/&col3)*100,.1); result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; end; else  
	if trt = 9 then do; pct = round((count/&col9)*100,.1); result = put(count,3.) || ' (' || put((count/&col9)*100,5.1) || ')'; end;  
run;
  
*===============================================================================
* 3. Create dummy records. 
*===============================================================================;    
proc sort data=all_2 out=dummy (keep=cmclas cmdecod) nodupkey;
   	by cmclas cmdecod;
data dummy;
   	set dummy;
   	by cmclas cmdecod;
   	do trt = 1,2,3,9;  
  		output;
  	end;  
run;
 
proc sort data=dummy;
   	by cmclas cmdecod trt;  
proc sort data=all_2;
   	by cmclas cmdecod trt;  
data all_3;
   	merge dummy all_2 (in=master);
   	by cmclas cmdecod trt;  
   	if not master then do; result = '  0'; count = 0; end;
run;

*===============================================================================
* 4. Transpose. 
*===============================================================================;  
proc transpose data=all_3 out=all_41 prefix=col;
   	by cmclas cmdecod;
   	id trt;
   	var result;    
proc transpose data=all_3 out=all_42 prefix=cnt;
   	by cmclas cmdecod;
   	id trt;
   	var count;   
proc transpose data=all_3 out=all_43 prefix=pct;
   	by cmclas cmdecod;
   	id trt;
   	var pct;     
data all_4;
   	merge all_41 all_42 all_43;
   	by cmclas cmdecod;
run; 
  
*===============================================================================
* 5a. Prepare Proc Report.
*===============================================================================; 
proc sort data=all_4;
	by cmclas cmdecod;
data final;
   	set all_4;
   	by cmclas cmdecod; 
   	length stat $10 formal $400;
	space = '';
/*  	%wrap(oldvar=cmclas,	newvar=CMCLAS_,  rowsize=40,use=1,split=@);*/
/*	%wrap(oldvar=cmdecod,	newvar=CMDECOD_,  rowsize=40,use=2,split=@,indent=1);*/
  	if CMCLAS  = ' ' and CMDECOD = ' ' then formal = 'At Least One Concomitant Medication';   
   	if CMCLAS ^= ' ' and CMDECOD = ' ' then formal = trim(CMCLAS); 
   	if CMCLAS ^= ' ' and CMDECOD^= ' ' then formal = ' ' || trim(CMDECOD);  
   	stat = 'n (%)';  
run; 
 
*===============================================================================
*  b. Sort by Overall Frequency of ATC and then PT (alphabetical for ties).
*===============================================================================; 
data final;
  	set final;
  	by cmclas cmdecod;   
	cnt99 = cnt9; 		
run;
 
proc sort data=final out=x1;
   	where cmclas ^= ' ' and cmdecod = ' ';
   	by descending cnt99 cmclas; 
data x1 (keep=cmclas n1);
   	set x1;
   	by descending cnt99 cmclas;   
   	n1 = _n_; 
data x1;
  	set x1;
	if cmclas = 'Uncoded' then n1=9999;
proc sort data=x1;
   	by cmclas;
data final;
   	merge final x1;
   	by cmclas;
run;

proc sort data=final out=x2;
   	where cmclas ^= ' ' and cmdecod ^= ' ';
   	by cmclas descending cnt99 cmdecod;
data x2 (keep=cmclas cmdecod n2);
   	set x2;
   	by cmclas descending cnt99 cmdecod; 
   	n2 = _n_;
proc sort data=x2;
   	by cmclas cmdecod;
data final;
   	merge final x2;
   	by cmclas cmdecod; 
	
   	if CMCLAS_  = ' ' and CMDECOD_  = ' ' then  
       cmclas_ = formal; 
run;

proc sort data=final;
   	by n1 n2 FORMAL;  
run;
/**/
/**** creating page numbers for needed number of records per page ***;*/
/*%pagebrk(indata=final,*/
/*        unique=n1 n2 FORMAL,*/
/*        wrapvars=FORMAL,*/
/*		KEEPONPG=N1,*/
/*        idwrap=@,*/
/*        skipvar=N1,*/
/*        skipline=1,REPLACE=Y,replaceval=!{newline 1},*/
/*        linesavl=20);*/

*===============================================================================
* 6. Produce Proc Report.
*===============================================================================; 
%calltf(); 

options orientation=landscape nobyline;
ods listing close;
    
%macro report;
%do i=1 %to 2;
 		
	%if &i=1 %then %do; ods rtf style=style1 file="&outdat\&pgm..rtf"; %end;
	%if &i=2 %then %do; ods rtf style=style1 file="&outdat\open session\&pgm..rtf"; %end;

   	proc report data=FINAL split='~' nowd missing spanrows
		style(report)=[rules=groups cellspacing=0];  
       	column /*_page _page2*/ n1 cmclas n2 cmdecod formal stat %if &i=1 %then %do; col1 col2 col3 %end; col9 %if &i=1 %then %do; space %end; ;  

/*		define _page    / group order order=internal noprint; */
/*    	define _page2   / group order order=internal noprint;	*/
      	define n1       / order order=internal noprint;  
      	define cmclas   / order order=internal noprint; 
      	define n2       / order order=internal noprint;  
      	define cmdecod  / order order=internal noprint;  
        define formal   / style=[cellwidth=30% just=left] "Anatomic Therapeutic Class Level 4~  Preferred Term" flow;    
       	define stat     / style=[cellwidth=5% just=left] "Stat-~istic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=12% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=12% just=left] " Placebo~ (N=&col2)";
			define col3     / style=[cellwidth=12% just=left] " Not Treated~ (N=&col3)";
	  	%end; %if &i=2 %then %do;
  		define col9     / style=[cellwidth=12% just=left] " Overall~ (N=&col9)";  %end;
		%if &i=1 %then %do;
		define space    / style=[cellwidth=1%] " ";      
   		%end;
  		compute before cmclas;  
		   line @1 " ";
		endcomp;  
 	run;

%end;
%mend report;
%report

ods rtf close;
ods listing;

*===============================================================================
* 7. Create permanent data set for QC compare.
*===============================================================================;
data qctab.&pgmqc; 
   	retain formal stat col:; 
   	set final; 
   	keep formal stat col:;      
	%fmtqc;
run; 
 
