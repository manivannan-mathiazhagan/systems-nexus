 dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-1-5-1-cm.sas   
* DATE:       31DEC2024
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Prior Medications 
*               (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER: keerthana Bommagani   
*   DATE:       22-Jul-2025  
*   PURPOSE:    Updating Program to display UNCODED and N count.      
************************************************************************************;   
%let pgm=t-14-1-5-1-cm; 
%let pgmnum=14.1.5.1; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmb; 
  
%include "&protdir\macros\m-setup.sas";    

*...............................
* Determine treatment flag.  
*...............................;   
/*%mtrt(pop=saffl)*/


*...............................
* Determine treatment flag.  
*...............................;   

data adsl;
	set ads.adsl;
  	if  SAFFL='Y' and trt01pn ne .;
/*   if trt01an=. then trt01an=3;*/
   	trt=trt01pn; 
 	output;
 
	trt = 3;
	output;
run;
 
proc freq data=adsl noprint;  
   	tables trt/out=total; 

data dummy;
	do trt = .,1,2,3;
	output;
	end;

data total;
	merge dummy total (in=master);
	by trt;
	if not master then count = 0; 
	run;
data _null_;
   	set total;    
   	if trt = 1 then call symput("col1",compress(put(count,3.))); 
   	if trt = 2 then call symput("col2",compress(put(count,3.))); 
/*   	if trt = 3 then call symput("col3",compress(put(count,3.))); */
	if trt = 3 then call symput("col3",compress(put(count,3.))); 
run;   

proc delete data=dummy;
run;
%put &col1 &col2 &col3 ; 

*=============================================================================== 
* 1. Bring in required dataset(s).  
*===============================================================================;   
data all_1; 
   	set ads.adcm (where=(saffl='Y' and trtan ne . and priconfl eq 'Prior'));   
   	by usubjid;  
 
	trt = trtan;
   	any = 'Y';   
	if cmclas = ' ' then cmclas = 'Uncoded';
	if cmdecod = ' ' then cmdecod = CMTRT; 
   	output;  
	   	
	trt = 3; 
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
   	if trt = 3 then do; pct = round((count/&col3)*100,.1); result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; end;  
run;
  
*===============================================================================
* 3. Create dummy records. 
*===============================================================================;    
proc sort data=all_2 out=dummy (keep=cmclas cmdecod) nodupkey;
   	by cmclas cmdecod;
data dummy;
   	set dummy;
   	by cmclas cmdecod;
   	do trt = 1,2,3;  
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
   	length stat $10 formal $200;
	space = '';
  
  	if cmclas  = ' ' and cmdecod  = ' ' then formal = 'At Least One Prior Medication';   
   	if cmclas ^= ' ' and cmdecod  = ' ' then formal = trim(cmclas); else 
   	if cmclas ^= ' ' and cmdecod ^= ' ' then formal = ' ' || trim(cmdecod);  
   	stat = 'n (%)';  
run; 
 
*===============================================================================
*  b. Sort by Overall Frequency of ATC and then PT (alphabetical for ties).
*===============================================================================; 
data final;
  	set final;
  	by cmclas cmdecod;   
	cnt99 = cnt3; 		
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

   	if cmclas = ' ' and cmdecod = ' ' then  
       cmclas = formal; 
run;

proc sort data=final;
   	by n1 cmclas n2 cmdecod;  
run;

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

   	proc report data=final split='~' nowd missing spanrows
		style(report)=[rules=groups cellspacing=0];  
       	column n1 cmclas n2 cmdecod formal space stat %if &i=1 %then %do; col1 col2 %end; col3;   
      
      	define n1       / order order=internal noprint;  
      	define cmclas   / order order=internal noprint; 
      	define n2       / order order=internal noprint;  
      	define cmdecod  / order order=internal noprint;  
        define formal   / style=[cellwidth=40% just=left] "Anatomic Therapeutic Class Level 4~  Preferred Term" flow;    
       	define stat     / style=[cellwidth=11% just=left] "Statistic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=15% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=15% just=left] " Placebo~ (N=&col2)";
	  	%end; 
  		define col3     / style=[cellwidth=15% just=left] " Overall~ (N=&col3)"; 
		define space    / style=[cellwidth=1%] " ";      
   
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
 
