************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************; 
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\Macros\mt-14-3-1-ae.sas     
* DATE:       31DEC2024
* PROGRAMMER: Laurie Drinkwater
*
* PURPOSE:      Macros for Tables 14.3.1.* series. 
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER:   
*   DATE:         
*   PURPOSE:     
************************************************************************************;  

*...............................
* Determine treatment flag.  
*...............................;  
%mtrt(pop=saffl)

*=============================================================================== 
* 1. Bring in required dataset(s).  
*===============================================================================;   
data all_1; 
   	set ads.adae (where=(saffl='Y' and trtan ne . and trtemfl='Y'));
   	by usubjid; 
   	&subgrp;   

	trt = trtan;
   	any = 'Y';   
	if aebodsys = ' ' then aebodsys = '[ Not Coded ]';
	if aedecod = ' ' then aedecod = '[ Not Coded ]'; 	
	if stvispd = 'Blinded' then stvispdn = 1; 
	if stvispd = 'Unblinded' then stvispdn = 2;
   	output;  
	   	
	trt = 3; 
	output;  
run;  
      
*===============================================================================
* 2. Proc Freq.
*===============================================================================; 
%macro freq(order=,var=,level=);

	proc sort data=all_1 out=&var;
   		by &level trt stvispdn usubjid; 
  	data &var;     
		set &var;
    	by &level trt stvispdn usubjid;										
   		if last.usubjid; 											
 	proc freq data=&var noprint;
   		by &level;
   		tables trt*stvispdn / out=&var missing;
  	run;       

%mend;
   
%freq(order=1,var=aebodsys,level=%str(aebodsys)) 
%freq(order=2,var=aedecod,level=%str(aebodsys aedecod))

*=============================
* Set together.
*=============================;
data all_2;
  	set aebodsys aedecod;
  	length result $12; 
 
   	if trt = 1 then do; pct = round((count/&col1)*100,.1); result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; end; else 
   	if trt = 2 then do; pct = round((count/&col2)*100,.1); result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; end; else 
   	if trt = 3 then do; pct = round((count/&col3)*100,.1); result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; end;   
run;
  
*===============================================================================
* 3. Create dummy records. 
*===============================================================================;    
proc sort data=all_2 out=dummy (keep=aebodsys aedecod) nodupkey;
   	by aebodsys aedecod;
data dummy;
   	set dummy;
   	by aebodsys aedecod;
   	do trt = 1,2,3;  
	   do stvispdn = 1,2;
  		  output;
  	end; end;
run;
 
proc sort data=dummy;
   	by aebodsys aedecod trt stvispdn;  
proc sort data=all_2;
   	by aebodsys aedecod trt stvispdn;  
data all_3;
   	merge dummy all_2 (in=master);
   	by aebodsys aedecod trt stvispdn;  
   	if not master then do; result = '  0'; count = 0; end;
run;
 
*===============================================================================
* 4. Transpose. 
*===============================================================================;  
proc transpose data=all_3 out=all_41 prefix=col;
	where stvispdn = 1;
   	by aebodsys aedecod;
   	id trt;
   	var result;    
proc transpose data=all_3 out=all_42 prefix=cnt;
	where stvispdn = 1;
   	by aebodsys aedecod;
   	id trt;
   	var count;   
proc transpose data=all_3 out=all_43 prefix=pct;
	where stvispdn = 1;
   	by aebodsys aedecod;
   	id trt;
   	var pct;     
run;
  
proc transpose data=all_3 out=uall_41 prefix=ucol;
	where stvispdn = 2;
   	by aebodsys aedecod;
   	id trt;
   	var result;    
proc transpose data=all_3 out=uall_42 prefix=ucnt;
	where stvispdn = 2;
   	by aebodsys aedecod;
   	id trt;
   	var count;   
proc transpose data=all_3 out=uall_43 prefix=upct;
	where stvispdn = 2;
   	by aebodsys aedecod;
   	id trt;
   	var pct;     
run;


data all_4;
   	merge all_41 all_42 all_43 
		  uall_41 uall_42 uall_43;
   	by aebodsys aedecod;
run; 

data all_4;
   	set all_4 end=eof;
   	by aebodsys aedecod;  
   	if eof and _n_ = 1 then delete; 
run;
 
*===============================================================================
* 5a. Add EMPTY dataset, if no information is provided.
*===============================================================================;
data empty;
   	length formal $200 col: ucol: $11; 
    cat = 99;  formal = '';
   	col1 = ' '; cnt1 = .; pct1 = .; 
	col2 = ' '; cnt2 = .; pct2 = .;
	col3 = ' '; cnt3 = .; pct3 = .;
	
   	ucol1 = ' '; ucnt1 = .; upct1 = .; 
	ucol2 = ' '; ucnt2 = .; upct2 = .;
	ucol3 = ' '; ucnt3 = .; upct3 = .;
run;

data all_4;
   	set  all_4 empty; 
   	if _n_ = 1 then call symput('nobs','0');  
   	           else call symput('nobs','1'); 
   	if cat = 99 and _n_ > 1 then delete;  
run; 
  
*===============================================================================
*  b. Prepare Proc Report.
*===============================================================================; 
proc sort data=all_4;
	by aebodsys aedecod;
data final;
   	set all_4;
   	by aebodsys aedecod; 
   	length stat $10 formal $200;
	space = '';
  
   	if aebodsys ^= ' ' and aedecod  = ' ' then formal = trim(aebodsys); else 
   	if aebodsys ^= ' ' and aedecod ^= ' ' then formal = ' ' || trim(aedecod);  
   	stat = 'n (%)'; 
 
   	if cat = 99 then do; stat = ' '; formal = ''; end;   
run; 
  
*===============================================================================
*  c. Sort by Overall Frequency of SOC and then PT (alphabetical for ties). 
*===============================================================================; 
data final;
  	set final;
  	by aebodsys aedecod;   
	cnt99 = cnt3; 		
run;
 
proc sort data=final out=x1;
   	where aebodsys ^= ' ' and aedecod = ' ';
   	by descending cnt99 aebodsys; 
data x1 (keep=aebodsys n1);
   	set x1;
   	by descending cnt99 aebodsys;   
   	n1 = _n_; 
proc sort data=x1;
   	by aebodsys;
data final;
   	merge final x1;
   	by aebodsys;
run;

proc sort data=final out=x2;
   	where aebodsys ^= ' ' and aedecod ^= ' ';
   	by aebodsys descending cnt99 aedecod;
data x2 (keep=aebodsys aedecod n2);
   	set x2;
   	by aebodsys descending cnt99 aedecod; 
   	n2 = _n_;
proc sort data=x2;
   	by aebodsys aedecod;
data final;
   	merge final x2;
   	by aebodsys aedecod; 

   	if aebodsys = ' ' and aedecod = ' ' then  
       aebodsys = formal; 
run;

proc sort data=final; 
   	by n1 aebodsys n2 aedecod;  
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
       	column n1 aebodsys n2 aedecod formal space stat %if &i=1 %then %do; ("!S={borderbottomwidth=1}Blinded Treatment Period" col1 col2) %end; col3 space
	                                                    %if &i=1 %then %do; ("!S={borderbottomwidth=1}Unblinded Treatment Period" ucol1 ucol2) %end; ucol3;  
      
      	define n1       / order order=internal noprint;  
      	define aebodsys / order order=internal noprint; 
      	define n2       / order order=internal noprint;  
      	define aedecod  / order order=internal noprint;  
		define formal   / style=[cellwidth=26% just=left] "System Organ Class~ Preferred Term" flow;  
       	define stat     / style=[cellwidth=8% just=left] "Statistic"; 
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=10% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=10% just=left] " Placebo~  (N=&col2)";
	  	%end; %if &i=2 %then %do;
  		define col3     / style=[cellwidth=10% just=left] " Overall~ (N=&col3)"; %end;
	  	%if &i=1 %then %do;
 			define ucol1     / style=[cellwidth=10% just=left] "Iltamiocel~  (N=&col1)"; 
  			define ucol2     / style=[cellwidth=10% just=left] " Placebo~  (N=&col2)";
	  	%end; %if &i=2 %then %do;
  		define ucol3     / style=[cellwidth=10% just=left] " Overall~ (N=&col3)"; %end;
		define space    / style=[cellwidth=0.8%] " ";     
   
 		%if &nobs eq 0 %then %do;   
  		     compute before aebodsys; 
        		line +35 "!n !n No subjects met this criteria at time of data extract date. !n !n ";   
			endcomp;  	
		%end; 
		%else %do;
  		   	compute before aebodsys;  
		  		line @1 " ";
		   	endcomp;  
		%end;   
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
   	retain formal stat col1 col2 col3 ucol1 ucol2 ucol3;   
   	set final; 
   	keep formal stat col1 col2 col3 ucol1 ucol2 ucol3;  
	%fmtqc;
run; 
 
