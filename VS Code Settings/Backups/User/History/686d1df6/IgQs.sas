dm 'log; clear; lst; clear;';
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\_Restricted\Tables\t-14-1-5-3-cp.sas
* DATE:        10DEC2024
* PROGRAMMER:  V EMILE          
*
* PURPOSE:     Concomitant Procedures
*              (Safty Population)  
*	
************************************************************************************;
* MODIFICATIONS:
* PROGRAMMER:  Laurie Drinkwater 
* DATE:        31DEC2024       
* PURPOSE:     Finish 14.1.5.3 table.    
*************************************************************************************; 
%let pgm=t-14-1-5-3-cp; 
%let pgmnum=14.1.5.3;;
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmbu; 

%include "&protdir\macros\m-setup.sas"; 
 
%macro mtrtx(pop=);
 
%global col1 col2 col3 col9  ;
data adsl;
	set ads.adsl;  
	if %upcase("&pop")="ICSFL" then do; if icsfl='Y'; trt=trt01pn; end; 
	if %upcase("&pop")="ITTFL" then do; if ittfl='Y'; trt=trt01pn; end;  
	if %upcase("&pop")="SAFFL" then do; if saffl='Y' /*and trt01an ne .*/; 
if trt01an=. then trt01an=3;
trt=trt01an; end;  
 	output; 
	trt = 9;
	output;
run;
 
proc freq data=adsl noprint;  
   	tables trt/out=total0; 
data dummy;
	do trt = 1,2,3,9;
	   output;
	end;
RUN;
PROC SORT;
	BY TRT;
data total;
	merge dummy total0 (in=master);
	by trt;
	if not master then count = 0; 
RUN;

data _null_;
   	set total;  
   	if trt = 1 then call symput("col1",compress(put(count,3.))); 
   	if trt = 2 then call symput("col2",compress(put(count,3.))); 
   	if trt = 3 then call symput("col3",compress(put(count,3.))); 
   	if trt = 9 then call symput("col9",compress(put(count,3.))); 
run;   

proc delete data=dummy;
run;

%mend mtrtx;  

*===============================================================================
* 1. Include required table program. 
*===============================================================================;
*%include "&outdat\macros\mt-14-3-1-ae_NEW.sas";  
*...............................
* Determine treatment flag.  
*...............................;  
%mtrtx(pop=saffl)

*=============================================================================== 
* 1. Bring in required dataset(s).   
*===============================================================================;   
proc sort data=ads.adsl out=adsl(keep=usubjid trt01pn trt01p trt01an trt01a rename=(trt01an=trtan));;
by usubjid;
where saffl = 'Y';* and trt01an ne .;
run;

data adsl;
	set adsl;
	if trtan=. then trtan=3;
run;

data adsl2;
  set adsl;
 if trtan=. then trtan=3;
  trt=trtan;
  output;
  trt=9;
  output;
run;
proc sort data=adsl;
  by usubjid;
run; 

%macro getraw(indata);
data &indata;
set raw.&indata (encoding=any);
format _all_;
informat _all_;
length subjid $20 usubjid $35;
subjid=strip(SUBNUM);
usubjid =  'DIFI-22-01-' || strip(put(SITENUM,best.)) || '-' || strip(SUBNUM);  
run;
%mend;

%getraw(cp); 

data cp;
	set cp;
	procname=upcase(procnam);
	allpt=1;
	keep usubjid allpt procname;
run; 

proc sort data=cp;
	by usubjid;
data all_1 ;
	merge cp (in=in1) adsl (in=in2);
	by usubjid;
	if in1 and in2;  

	trt = trtan;
   	any = 'Y';   
	*length procname $50;
	*if procname = ' ' then procname = '[ Not Coded ]'; 
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
%freq(order=2,var=procname,level=%str(procname))  
  
*=============================
* Set together.
*=============================;
data all_2;
  	set any (in=inany) procname;
  	length result $12; 

   	if trt = 1 then do; pct = round((count/&col1)*100,.1); result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; end; else 
   	if trt = 2 then do; pct = round((count/&col2)*100,.1); result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; end;  else 
   	if trt = 3 then do; pct = round((count/&col3)*100,.1); result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; end;  else 
   	if trt = 9 then do; pct = round((count/&col9)*100,.1); result = put(count,3.) || ' (' || put((count/&col9)*100,5.1) || ')'; end;  
run;

*===============================================================================
* 3. Create dummy records. 
*===============================================================================;    
proc sort data=all_2 out=dummy (keep=procname) nodupkey;
   	by procname;
data dummy;
   	set dummy;
   	by procname;
   	do trt = 1,2,3,9;  
  		output;
  	end;  
run;
 
proc sort data=dummy;
   	by procname trt;  
proc sort data=all_2;
   	by procname trt;  
data all_3;
   	merge dummy all_2 (in=master);
   	by procname trt;  
   	if not master then result = '  0'; 
run;

*===============================================================================
* 4. Transpose. 
*===============================================================================;  
proc transpose data=all_3 out=all_4 prefix=col;
   	by procname;
   	id trt;
   	var result;      
run; 
data all_4;
   	set all_4 end=eof;
   	by procname;  
   	if eof and _n_ = 1 then delete; 
run;

 
*===============================================================================
* 5a. Add EMPTY dataset, if no information is provided.
*===============================================================================;
data empty;
   	length formal $200 col1 $11; 
    cat = 99;  formal = ''; col1 = ''; col2 = ''; col3 = '';col9=' ';
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
	by procname;

data final;
   	set all_4;
   	by procname; 
   	length stat $10 formal $200;
	space = '';
  
	if procname = '' then do; order = 1; formal = 'At Least One Concomitant Procedure'; end; else
	 do; order = 2; formal = trim(procname); end;  
   	stat = 'n (%)'; 
 
   	if cat = 99 then do; stat = ' '; formal = ''; end;   
run; 

proc sort data=final;
	by order procname;
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
       	column order procname formal space stat %if &i=1 %then %do; col1 col2 col3 %end; col9;   
      
      	define order    / order order=internal noprint;  
      	define procname / order order=internal noprint;  
        define formal   / style=[cellwidth=25% just=left] "Procedure Name" flow;    
       	define stat     / style=[cellwidth=8% just=left] "Statistic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=9% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=9% just=left] " Placebo~ (N=&col2)";
  			define col3     / style=[cellwidth=9% just=left] " Not Treated~ (N=&col3)";
	  	%end; 
		%if &i=2 %then %do;
  		define col9     / style=[cellwidth=9% just=left] " Overall~ (N=&col9)";  %end;
		define space    / style=[cellwidth=1%] " ";      
  
 		%if &nobs eq 0 %then %do;   
  		     compute before order; 
        		line +35 "!n !n No subjects met this criteria at time of data extract date. !n !n ";   
			endcomp;  	
		%end; 
		%else %do;
  		   	compute before order;  
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
   	retain formal stat col:; 
   	set final; 
   	keep formal stat col:;      
	%fmtqc;
run; 
 
