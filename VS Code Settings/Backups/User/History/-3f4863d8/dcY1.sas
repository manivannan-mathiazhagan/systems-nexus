dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\_Restricted\Tables\t-14-1-3-1-mh.sas   
* DATE:       04NOV2024
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Medical History
*               (Intention to Treat Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER:keerthana Bommagani    
*   DATE:      04 AUG 2025    
*   PURPOSE:   Updating Program to add UNCODED      
************************************************************************************;   
%let pgm=t-14-1-3-1-mh; 
%let pgmnum=14.1.3.1; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu; 
  
%include "&protdir\macros\m-setup.sas";    
         
*...............................
* Determine treatment flag.  
*...............................;    
%mtrt(pop=ittfl) 

*=============================================================================== 
* 1. Bring in required dataset(s).  
*===============================================================================;   
data all_1; 
   	set ads.admh (where=(ittfl='Y' AND mhcat='MEDICAL HISTORY')); 
   	by usubjid;  
	trt = trtpn;
 
   	any = 'Y';   
	if mhbodsys = ' ' then mhbodsys = 'Uncoded';
	if mhdecod = ' ' then mhdecod =coalescec(MHTERM,'Not Reported');

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
%freq(order=2,var=mhbodsys,level=%str(mhbodsys)) 
%freq(order=3,var=mhdecod,level=%str(mhbodsys mhdecod))

*=============================
* Set together.
*=============================;
data all_2;
  	set any (in=inany) mhbodsys mhdecod;
  	length result $12; 

   	if trt = 1 then do; pct = round((count/&col1)*100,.1); result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; end; else 
   	if trt = 2 then do; pct = round((count/&col2)*100,.1); result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; end; else 
   	if trt = 3 then do; pct = round((count/&col3)*100,.1); result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; end;  
run;
  
*===============================================================================
* 3. Create dummy records. 
*===============================================================================;    
proc sort data=all_2 out=dummy (keep=mhbodsys mhdecod) nodupkey;
   	by mhbodsys mhdecod;
data dummy;
   	set dummy;
   	by mhbodsys mhdecod;
   	do trt = 1,2,3;  
  		output;
  	end;  
run;
 
proc sort data=dummy;
   	by mhbodsys mhdecod trt;  
proc sort data=all_2;
   	by mhbodsys mhdecod trt;  
data all_3;
   	merge dummy all_2 (in=master);
   	by mhbodsys mhdecod trt;  
   	if not master then do; result = '  0'; count = 0; end;
run;

*===============================================================================
* 4. Transpose. 
*===============================================================================;  
proc transpose data=all_3 out=all_41 prefix=col;
   	by mhbodsys mhdecod;
   	id trt;
   	var result;    
proc transpose data=all_3 out=all_42 prefix=cnt;
   	by mhbodsys mhdecod;
   	id trt;
   	var count;   
proc transpose data=all_3 out=all_43 prefix=pct;
   	by mhbodsys mhdecod;
   	id trt;
   	var pct;     
data all_4;
   	merge all_41 all_42 all_43;
   	by mhbodsys mhdecod;
run; 
 
 
*** Adjust SPLIT lines ***;
data _null_;
	set all_4;  
	call symput('splwidth',compress("45")); 
run;
   
data all_4 (drop=mhdecod rename=(mhdecox=mhdecod));
	set all_4;
	%macro x; 
	%if _n_ > 1 %then %do; 
	   %m_split(varname=mhdecod,varout=mhdecox,splwidth=&splwidth,indent=1,splchar=%str(!n ),splbrk=%str( -+/)); 
	%end;
	%mend x;
	%x
run;
 
*===============================================================================
* 5a. Prepare Proc Report.
*===============================================================================; 
proc sort data=all_4;
	by mhbodsys mhdecod;
data final;
   	set all_4;
   	by mhbodsys mhdecod; 
   	length stat $10 formal $200;
	space = '';
 
	if mhbodsys = ' ' and mhdecod = ' ' then formal = 'Patients with at Least One Medical History Event';  
 
   	if mhbodsys ^= ' ' and mhdecod  = ' ' then formal = trim(mhbodsys); else 
   	if mhbodsys ^= ' ' and mhdecod ^= ' ' then formal = ' ' || trim(mhdecod);  
   	stat = 'n (%)';  
run; 
 
*===============================================================================
*  b. Sort by Overall Frequency of SOC and then PT (alphabetical for ties),  
*     per e-mail, "RE: Karuna ISMC Update:  11FEB2021", 12FEB2021. 
*===============================================================================; 
data final;
  	set final;
  	by mhbodsys mhdecod;   
	cnt99 = cnt3; 		
run;
 
proc sort data=final out=x1;
   	where mhbodsys ^= ' ' and mhdecod = ' ';
   	by descending cnt99 mhbodsys; 
data x1 (keep=mhbodsys n1);
   	set x1;
   	by descending cnt99 mhbodsys;   
   	n1 = _n_; 
data x1;
  	set x1;
	if mhbodsys = 'Uncoded' then n1=9999;
proc sort data=x1;
   	by mhbodsys;
data final;
   	merge final x1;
   	by mhbodsys;
run;

proc sort data=final out=x2;
   	where mhbodsys ^= ' ' and mhdecod ^= ' ';
   	by mhbodsys descending cnt99 mhdecod;
data x2 (keep=mhbodsys mhdecod n2);
   	set x2;
   	by mhbodsys descending cnt99 mhdecod; 
   	n2 = _n_;
proc sort data=x2;
   	by mhbodsys mhdecod;
data final;
   	merge final x2;
   	by mhbodsys mhdecod; 

   	if mhbodsys = ' ' and mhdecod = ' ' then  
       mhbodsys = formal; 
run;

proc sort data=final;
   	by n1 mhbodsys n2 mhdecod;  
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
     	column n1 mhbodsys n2 mhdecod formal space stat %if &i=1 %then %do; col1 col2 %end; col3;   
    
      	define n1       / order order=internal noprint;  
      	define mhbodsys / order order=internal noprint;   
      	define n2       / order order=internal noprint;    
		define mhdecod  / order order=internal noprint;  
        define formal   / order order=internal style=[cellwidth=35% just=left] "System Organ Class/~  Preferred Term" flow;   
       	define stat     / style=[cellwidth=11% just=left] "Statistic"; 
	  	%if &i=1 %then %do; 
 			define col1     / style=[cellwidth=15% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=15% just=left] " Placebo~ (N=&col2)"; 
	  	%end; 
  		%if &i=2 %then %do;define col3     / style=[cellwidth=15% just=left] "  Total~  (N=&col3)";%end;  
  		define space    / style(column)=[cellwidth=1%] " "; 
   
		compute n1;
    		if n1>0 then do;
      			call define(_row_,'style','style={protectspecialchars=off pretext="\line "}');
    		end;
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
