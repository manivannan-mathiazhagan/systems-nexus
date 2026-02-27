dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-1-7-br.sas   
* DATE:       06JAN2025
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Tissue Procurement
*               (Intention to Treat Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER: Keerthana Bommagani 
*   DATE:       22JUL2025   
*   PURPOSE:    Updated program to display biopsies count    
************************************************************************************;   
%let pgm=t-14-1-7-br; 
%let pgmnum=14.1.7; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu; 
  
%include "&protdir\macros\m-setup.sas";    
         
proc format;
   	value order  1 = 'Number of subjects with any biopsy' 
      			 2 = 'Number of subjects with repeated biopsies'
				
				 3 = 'Location of Muscle Biopsy [2]'
      			 4 = 'Muscle biopsy wound closed by [2]'; 

	value bio  2 = '  Number of subjects with 2 biopsies'
	           3 = '  Number of subjects with 3 biopsies'
			   4 = '  Number of subjects with 4 biopsies';

	value muscle 1 = '  Left vastus lateralis'
		         2 = '  Right vastus lateralis';

	value wound 1 = '  Adhesive strips'
		        2 = '  Sutures'
				3 = '  Other';
run;
 
*...............................
* Determine treatment flag.  
*...............................;   
%mtrt(pop=ittfl)

*=============================================================================== 
* 1. Bring in required dataset(s). 
*===============================================================================;  
data all_1;
	set ads.adbr (in=a where=(ittfl='Y')); 
	by usubjid; 
	trt = trtpn;
	dummy = 1; 
	output;

	trt = 3;
	output;
run;   

proc sort data=all_1;
	by trt usubjid; 
run;
  
*===============================================================================
* 1a. Proc Freq: OVERALL
*===============================================================================;
%global bio1 bio2 bio3; 

%macro freq(order=,var=);
       
	proc sort data=all_1 out=all_1x nodupkey;
		by trt usubjid;
   	proc freq data=all_1x noprint; 
		by trt;
      	tables dummy / out=temp missing;  
  	run;  
 
    data temp;
     	set temp;  		
       	keep order value trt result;
       	length result $20;

       	order = 1;   
       	value = 1;      
       	if trt = 1 then do; result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; call symput("bio1",compress(put(count,3.))); end;
       	if trt = 2 then do; result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; call symput("bio2",compress(put(count,3.))); end;
       	if trt = 3 then do; result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; call symput("bio3",compress(put(count,3.))); end;  
 	run;
 
  	proc append base=all_2;
   	run;     

%mend freq;   
 	
%freq;

%global mus1 mus2 mus3; 

%macro freq2(order=,var=);
       data all_1x;
	   set all_1;
		where paramn eq 2 and avalc ne "";
	;run;
	proc sort data=all_1x ;
	
		by trt usubjid;
   	proc freq data=all_1x noprint; 
		by trt;
      	tables dummy / out=temp missing;  
  	run;  
 
    data temp;
     	set temp;  		
       	keep order value trt result;
       	length result $20;

       	order = 1;   
       	value = 1;      
       	if trt = 1 then do; result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; call symput("mus1",compress(put(count,3.))); end;
       	if trt = 2 then do; result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; call symput("mus2",compress(put(count,3.))); end;
       	if trt = 3 then do; result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; call symput("mus3",compress(put(count,3.))); end;  
 	run;
    

%mend freq2;   
 
%freq2;

%put &mus1 &mus2 &mus3; 

 data all_1_0(where =( paramn ne 1)) all_1_n (where =( paramn eq 1));
	set all_1;
  run;

  proc sql noprint;
  	create table bio_cnt as select distinct usubjid,trt,paramn,paramcd,sum(aval) as aval from all_1_n group by usubjid,trt,paramn,paramcd;
	quit;
	data all_1;
	set all_1_0 bio_cnt;
	run;
 proc sort;
	by trt;	run;
*===============================================================================
*  b. Proc Freq.
*===============================================================================;
%macro freq(order=,val=,var=);
     %if &order eq 1 and &val eq 2 %then %do;
	 proc sql noprint;
	 create table temp as select distinct trt, sum(aval) as count from all_1 where paramn eq 1 group by trt ;quit;
%end;
%else %do; 
   	proc freq data=all_1 noprint;
	    where &var;  
		by trt;
      	tables aval / out=temp missing;  
  	run;  
   %end;
    data temp;
     	set temp;  		
       	keep order value trt result;
       	length result $20;

       	order = &order;  
       	value = &val;      
       if order le 2 then do;	
		if trt = 1 then result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; 
       	if trt = 2 then result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; 
       	if trt = 3 then result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; 
		end;
		else do;
		if trt = 1 then result = put(count,3.) || ' (' || put((count/&mus1)*100,5.1) || ')'; 
       	if trt = 2 then result = put(count,3.) || ' (' || put((count/&mus2)*100,5.1) || ')'; 
       	if trt = 3 then result = put(count,3.) || ' (' || put((count/&mus3)*100,5.1) || ')'; 
		end;
/*******number of biosies row should be 0. not captured in current database ***/ 
		   if order = 1 and value = 2 then result = put(count,3.);
		   else result = result;
/*		   if order = 2 and value in (1 2 3) then result = /*put(count,3.)*/
 	run;

  	proc append base=all_2;
   	run;     

%mend freq;   
 
%freq(order=1,val=2,var=%str(paramn=1 and aval=1)) 
%freq(order=1,val=3,var=%str(paramn=1 and aval=1))  

%freq(order=2,val=1,var=%str(paramn=1 and aval gt 1 )) 
%freq(order=2,val=2,var=%str(paramn=1 and aval=2)) 
%freq(order=2,val=3,var=%str(paramn=1 and aval=3)) 
%freq(order=2,val=3,var=%str(paramn=1 and aval=4)) 

%freq(order=3,val=1,var=%str(paramn=2 and aval=1))
%freq(order=3,val=2,var=%str(paramn=2 and aval=2))
 
%freq(order=4,val=1,var=%str(paramn=4 and aval=1))
%freq(order=4,val=2,var=%str(paramn=5 and aval=1))
%freq(order=4,val=3,var=%str(paramn=6 and aval=1))
	      
*===============================================================================
* 3. Create dummy records. 
*===============================================================================;
%macro dummy(order=,value=);

	data;  
  		do trt = 1,2,3;  
   			do order = &order;
        		do value = &value;
        			output;
     	end; end; end;    
	run;

  	proc append base=dummy;
   	run;                   

%mend dummy;
     
%dummy(order=%str(1),value=%str(1,2))   
%dummy(order=%str(2),value=%str(1,2,3,4))     
%dummy(order=%str(3),value=%str(0,1,2))      
%dummy(order=%str(4),value=%str(0,1,2,3))   
  
proc sort data=all_2;
   	by order value trt;  
proc sort data=dummy;
  	by order value trt;
data all_3;
   	merge dummy all_2 (in=master); 
   	by order value trt;     
	if not master and value > 0 then result = '  0';       
run;   
  
*===============================================================================
* 4. Transpose. 
*===============================================================================;  
proc transpose data=all_3 out=all_4 prefix=col;   
   	by order value;
   	id trt;
   	var result; 
run;   
  
*===============================================================================
* 5. Prepare Proc Report.
*===============================================================================;
data final;
 	set all_4;
 	by order value;  

	page = 1;  

   	length stat $15;
	if order in (1,2) then stat = 'n (%)'; else
	if order in (3,4) and value > 0 then stat = 'n (%)';  

  	length formal $200;
   	if first.order then formal = put(order,order.); else 
	if order in (1)  and value=2 then do; formal = 'Total number of biopsies [1]'; stat = 'n'; end; else
	if order in (1) and value=3 then do;formal = 'Number of subjects with 1 biopsy';; end; else
   	if order in (2) then formal = put(value,bio.); else  
	if order in (3) then formal = put(value,muscle.); else
	if order in (4) then formal = put(value,wound.); 
run;

proc sort data=final;
	by page order value;
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
       	column page order value formal space stat %if &i=1 %then %do; col1 col2 %end; col3;   
   
   	   	define page     / order order=internal noprint;
       	define order    / order order=internal noprint;
       	define value    / order order=internal noprint; 	
		define formal   / style=[cellwidth=40% just=left] "Parameter" flow;  
       	define stat     / style=[cellwidth=11% just=left] "Statistic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=15% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=15% just=left] " Placebo~ (N=&col2)";
	  	%end; %if &i=2 %then %do;
  		define col3     / style=[cellwidth=15% just=left] " Overall~ (N=&col3)"; %end;
		define space    / style=[cellwidth=1%] " ";      

		break before page / page; 
 
 		compute before order;  
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
