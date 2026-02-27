dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-3-2-vs.sas     
* DATE:       02JAN2025
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Summary of Vital Signs 
*               (Intention to Treat Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER:  Santhoshi A
*   DATE:        27JAN2025 
*   PURPOSE:     Updated as per stat comments
************************************************************************************;  
* MODIFICATIONS:   
*   PROGRAMMER: keerthana Bommagani  
*   DATE:       29-Jul-2025   
*   PURPOSE:    Updating Program per stat comments.   
************************************************************************************;  
   
%let pgm=t-14-3-2-vs; 
%let pgmnum=14.3.2; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu;  
 
%include "&protdir\macros\m-setup.sas";    
         
proc format;   
   	
   	   value stat 1 = 'n'
				  2 = 'Mean (SD)'
                  3 = 'SE'
				  4 = '(95% CI)'
				  5 = 'Median' 
				  6 = 'Min, Max';
run;

%macro mtrtx(pop=);

%global col1 col2 col3;
data adsl;
                set ads.adsl;  
                if %upcase("&pop")="ICSFL" then do; if icsfl='Y'; trt=trt01pn; end; 
                if %upcase("&pop")="ITTFL" then do; if ittfl='Y' and not missing (trt01an); trt=trt01an; end;  
                if %upcase("&pop")="SAFFL" then do; if saffl='Y' and trt01an ne .; trt=trt01an; end;  
                output;

                trt = 3;
                output;
run;

proc freq data=adsl noprint;  
                tables trt/out=total; 
data dummy;
                do trt = 1,2,3;
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
run;   

proc delete data=dummy;
run;

%mend mtrtx;  


*...............................
* Determine treatment flag.  
*...............................;  
%mtrtx(pop=SAFFL) 

*===============================================================================
* 1. Bring in required dataset(s). 
*===============================================================================;    
data all_1;
	set ads.advs (where=(ittfl='Y' and stvispd ne '' and anl01fl='Y' and trtan ne .));    
	if ablfl = 'Y' or (ablfl = ' ' and avisitn > 20 and base ne .); * and anl01fl='Y'; 
	if ablfl = 'Y' then do; avisitn = 0; avisit = 'Baseline'; end;
	               else do; avisit = left(scan(avisit,3,'-')); end;
 
	if stvispd = 'Blinded' then stvispdn = 1; 
	if stvispd = 'Unblinded' then stvispdn = 2;
	trt = trtan;
	output;

	trt = 3;
	output;
	keep paramn param stvispdn avisitn avisit trt vstptnum vstpt aval chg avalc ;
run;

data all_1;
set all_1;

where trt ne .;
run; 

proc sort data=all_1; 
	by paramn param stvispdn avisitn avisit trt vstptnum vstpt; 
run;
   
*===============================================================================
* 2.  Proc Univariate.
*===============================================================================;
%macro univ;                                                       

 	proc means data=all_1 noprint;  
      	by paramn param stvispdn avisitn avisit trt vstptnum vstpt;    
      	var aval;
      	output out=temp1 n=n mean=mean median=median std=std min=min max=max stderr=stderr uclm=uclm lclm=lclm ;
  	proc means data=all_1 noprint;    
      	by paramn param stvispdn avisitn avisit trt vstptnum vstpt;  
     	var chg;
     	output out=temp2 n=n mean=mean median=median std=std min=min max=max stderr=stderr uclm=uclm lclm=lclm ;   
   	data temp;
    	set temp1 (in=in1) temp2 (in=in2);
      	by paramn param stvispdn avisitn avisit trt vstptnum vstpt;  
      	keep paramn param stvispdn avisitn avisit order trt value result vstptnum vstpt;
       	length result $19; 

		call missing(result); 
 
      	if in1 then order = 1;
      	if in2 then order = 2; 

		if paramn in (1,2,4,5) then do;
     	   value = 1; result = put(n,3.); output;
           value = 2; call missing(result); if n = 1 and std = . then result = ' ' || compress(put(mean,7.1)) || ' (NA)'; 
                                           else result = ' ' || compress(put(mean,7.1)) || ' (' || compress(put(std,8.2)) || ')'; output;
           value = 3; call missing(result); if stderr ne . then result = '  '||strip(put(stderr,8.2));output;
           value = 4; call missing(result); if . < lclm < 0 then lclm = 0;
		      if lclm ne . and uclm ne . then result = '  ('||strip(put(lclm,7.1))||', '||strip(put(uclm,7.1))|| ')';
			  else if lclm eq . and uclm ne . then result = '  (, '||strip(put(uclm,7.1))||')';
			  else if lclm ne . and uclm eq . then result = '  ('||strip(put(lclm,7.1))||', '||')';
			  else if lclm eq . and uclm eq . then result = 'NA';output;
 	
   		   value = 5; call missing(result); result = ' ' || compress(put(median,7.1)); output; 
   		   value = 6; call missing(result); result = ' ' || compress(put(min,5.0)) || ', ' || compress(put(max,5.0)); output;   
		end;
		if paramn in (3,6,7,8) then do; 
     	   value = 1; result = put(n,3.); output;
           value = 2;call missing(result); if n = 1 and std = . then result = ' ' || compress(put(mean,7.1)) || ' (NA)'; 
                                           else result = ' ' || compress(put(mean,7.1)) || ' (' || compress(put(std,8.2)) || ')'; output; 
           value = 3;call missing(result); if stderr ne . then result = '  '||strip(put(stderr,8.2));output;
           value = 4;call missing(result); if . < lclm < 0 then lclm = 0;
		      if lclm ne . and uclm ne . then result = '  ('||strip(put(lclm,7.1))||', '||strip(put(uclm,7.1))|| ')';
			  else if lclm eq . and uclm ne . then result = '  (, '||strip(put(uclm,7.1))||')';
			  else if lclm ne . and uclm eq . then result = '  ('||strip(put(lclm,7.1))||', '||')';
			  else if lclm eq . and uclm eq . then result = 'NA';output;	
   		   value = 5;call missing(result); result = ' ' || compress(put(median,7.1)); output; 
   		   value = 6;call missing(result); result = ' ' || compress(put(min,7.1)) || ', ' || compress(put(max,7.1)); output;  
		end;
  	run; 

  	proc append base=all_2;
    run; 

%mend univ;
 
%univ 
       
*===============================================================================
* 3.  Create dummy records. 
*===============================================================================;
proc sort data=all_2 out=dummy (keep=paramn param stvispdn avisitn avisit vstptnum vstpt) nodupkey;  
  	by paramn param stvispdn avisitn avisit vstptnum vstpt;   
data dummy;
   	set dummy;
  	by paramn param stvispdn avisitn avisit vstptnum vstpt;
  	do order = 1,2;
	   do value = 1,2,3,4;   
  	      do trt = 1,2,3;  
             output;
    end; end; end;
run; 
    
proc sort data=all_2;
   	by paramn param stvispdn avisitn avisit vstptnum vstpt order value trt;  
data all_3;
   	merge dummy all_2 (in=master);
   	by paramn param stvispdn avisitn avisit vstptnum vstpt order value trt;   
   	if not master and value = 1 then result = '  0';  
data all_3;
   	set all_3;
   	by paramn param stvispdn avisitn avisit vstptnum vstpt order value trt;  
	if avisitn = 0 and order = 2 then delete;
run;
 
*===============================================================================
* 4.  Transpose. 
*===============================================================================;   
proc transpose data=all_3 out=all_4 prefix=col;  
   	by paramn param stvispdn avisitn avisit vstptnum vstpt order value;  
   	id trt;
   	var result;   
run;  
 
*===============================================================================
* 5.  Prepare Proc Report.
*===============================================================================;
data final;
 	set all_4;
   	by paramn param stvispdn avisitn avisit vstptnum vstpt order value;   
	space = '';
  
	length stvispd $25;
	if stvispdn = 1 then stvispd = 'Blinded'; 
	if stvispdn = 2 then stvispd = 'Unblinded'; 

  	length formal $100;   
	if first.order and order = 1 and avisitn = 0 then formal = 'Baseline'; else
	if first.order and order = 1 then formal = ' Actual'; else
	if first.order and order = 2 then formal = ' Change from Baseline';   
 
 	length stat $20;
    stat = put(value,stat.);   
	output;

	if first.order and order = 1 and avisitn ne 0 then do;
	   stat = ''; col1 = ''; col2 = ''; col3 = '';
	   value = 0; formal = strip(avisit); output;
	end;
run; 

proc sort data=final;
	by paramn param stvispd avisitn avisit vstptnum vstpt order value;   
data final;
	set final;
	by paramn param stvispd avisitn avisit vstptnum vstpt order value;  
	if first.paramn then page + 1; else
	if stvispdn = 1 and first.avisit and avisit in ('Week 6') then page + 1; else
	if stvispdn = 2 and first.avisit and avisit in ('Day 0' 'Week 24') then page = 1; 
proc sort data=final;
	by page paramn param stvispd avisitn avisit vstptnum vstpt order value; 
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
       	column page paramn param stvispd avisitn   formal vstptnum vstpt order value space stat %if &i=1 %then %do; col1 col2 %end; col3;
    
   	   	define page     / order order=internal noprint;
	    define paramn   / order order=internal noprint;
   	   	define param    / order order=internal style=[cellwidth=15% just=left] "Parameter" flow;  
		define stvispd  / order order=internal style=[cellwidth=10% just=left] "Study~Period" flow;  
       	define avisitn  / order order=internal noprint;  	
		define formal   / style=[cellwidth=18% just=left] "Visit" flow;  
		define vstptnum  / order order=internal noprint;  	
       	define vstpt  / order order=internal style=[cellwidth=10% just=left] "Time~Point"; 
		define order    / order order=internal noprint;
		define value    / order order=internal noprint;
       	define stat     / style=[cellwidth=9% just=left] "Statistic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=12% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=12% just=left] " Placebo~  (N=&col2)";
	  	%end; %if &i=2 %then %do;
  		define col3     / style=[cellwidth=12% just=left] " Overall~ (N=&col3)";  %end;
		define space    / style=[cellwidth=0.8%] " ";      

		break after page / page; 
 
 		compute after order;  
			line @1 " ";
		endcomp;   
 	run;

	*** paginate ***; 
	%mpgodsl;

%end;
%mend report;
%report

ods rtf close;
ods listing;
 
*===============================================================================
* 7. Create permanent data set for QC compare.
*===============================================================================;
libname qc "&outdat\qc"; 
 
data qc.&pgmqc;
   	retain param stvispd formal stat col: vstptnum vstpt;  
   	set final; 
   	keep param stvispd formal stat col: vstptnum vstpt;     
    %fmtqc;  
run; 
