dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-1-3-2-mh.sas   
* DATE:       04NOV2024
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Medical History - Other
*               (Intention to Treat Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER:   v emile
*   DATE:         1/23/2025
*   PURPOSE:        use vaRIABLES FROM ADSL 
************************************************************************************;   
%let pgm=t-14-1-3-2-mh; 
%let pgmnum=14.1.3.2; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmb; 
  
%include "&protdir\macros\m-setup.sas";    
         
proc format;
   	value order  1 = 'History of Childbirth'
      			 2 = 'Number of Vaginal Births  '
				 3 = 'Number of Cesarean Sections'
      			 4 = 'Does the subject have a known history of autoimmune disease?'
				 5 = 'Does the subject have a known history of diabetes' 
				 6 = 'HbA1c Result Summary'; 
 
 	invalue yn   'Y' = 1
		         'N' = 2
	             ' ' = 3;

   	value yn     1 = '  Yes'
	             2 = '  No'
	             3 = '  Not Reported'; 
				 
	value number 1 = '  1'
		         2 = '  2'
				 3 = '  >2'
				 4 = '  Not Reported';

   	value stat    1 = 'n'
				  2 = 'Mean (SD)' 
				  3 = 'Median' 
				  4 = 'Min, Max';
run;
   
*...............................
* Determine treatment flag.  
*...............................;   
%mtrt(pop=ittfl)

*=============================================================================== 
* 1. Bring in required dataset(s). 
*===============================================================================; 
data adsl;
	set ads.adsl (where=(ittfl='Y'));
	by usubjid; 
	trtpn = trt01pn;
*	KEEP USUBJID TRTPN;
run;
PROC SORT DATA=ADS.ADMH OUT=ADMH(KEEP=USUBJID TRTPN TRTP TRTAN TRTA CHLDBRFL   VAGNUM   CESNUM   AUTOFL   DIAHISFL   HBA1CRES);
	BY USUBJID;
	WHERE ITTFL='Y' AND MHTERM=' ';
RUN;
*
CHLDBRFL
CMYN
DIAHISFL
HBA1CRES
VAGNUM;
data all_1;
	set ADMH;
	by usubjid;  
	trt = trtpn; 

	chldbrfn = input(chldbrfl,yn.);  
	autofn = input(autofl,yn.);
	diahisfn = input(diahisfl,yn.);
 
	if vagnum > 2 then vagnum = 3; else
	if vagnum = . then vagnum = 4;
	if cesnum > 2 then cesnum = 3; else
	if cesnum in( . 0) then cesnum = 4;
	output;
	trt = 3;
	output;	
run;  

proc sort data=all_1;
	by trt usubjid;
run;
     
*===============================================================================
* 2a. Proc Freq.
*===============================================================================;
%macro freq(order=,var=);
       
   	proc freq data=all_1 noprint; 
		by trt;
      	tables &var / out=temp missing;  
  	run; 

    data temp;
     	set temp;  		
       	keep order value trt result;
       	length result $20;

       	order = &order;  
       	value = &var;     
       	if trt = 1 then result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; 
       	if trt = 2 then result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; 
       	if trt = 3 then result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')';   
 	run;

  	proc append base=all_2;
   	run;     

%mend freq;    
 
%freq(order=1,var=chldbrfn) 
%freq(order=2,var=vagnum)   
%freq(order=3,var=cesnum)   
%freq(order=4,var=autofn)  
%freq(order=5,var=diahisfn)    
 
*===============================================================================
*  b. Proc Univariate.
*===============================================================================; 
%macro univ(order=,var=);                                                       
 
 	proc univariate data=all_1 noprint;   
		where &var ^= .;
      	by trt; 
      	var &var;
      	output out=temp n=n mean=mean median=median std=std min=min max=max;  
	run;  
 
  	data temp;
      	set temp;  
      	keep order value trt result;
      	length result $20;
 
      	order = &order;    
        value = 1; result = '  ' || compress(put(n,4.)); output;
        value = 2; if n = 1 and std = . then result = '  ' || compress(put(mean,7.2)) || ' (NA)'; 
                                        else result = '  ' || compress(put(mean,7.2)) || ' (' || compress(put(std,8.3)) || ')'; output; 
        value = 3; result = '  ' || compress(put(median,7.2)); output;
        value = 4; result = '  ' || compress(put(min,6.1)) || ', ' || compress(put(max,6.1)); output;  
	run;                                        

	proc append base=all_2;
  	run; 

%mend univ;
      
%univ(order=6,var=hba1cres)    
  
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
     
%dummy(order=%str(1,4,5),value=%str(0,1,2,3))   
%dummy(order=%str(2,3),value=%str(0,1,2,3,4))   
%dummy(order=%str(6),value=%str(1,2,3,4))   
  
proc sort data=all_2;
   	by order value trt;  
proc sort data=dummy;
  	by order value trt;
data all_3;
   	merge dummy all_2 (in=master); 
   	by order value trt;     
	if not master and order in (1,2,3,4,5) and value > 0 then result = '  0';   
	if not master and order in (6) and value = 1 then result = '  0';   
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

	if order <= 4 then page = 1;  
	              else page = 2;

			

   	length stat $15;
	if order in (1,2,3,4,5) and value > 0 then stat = 'n (%)'; else
	if order in (6) then stat = put(value,stat.); 

  	length formal $200;
   	if first.order then formal = put(order,order.); else 
	if order in (1,4,5) then formal = put(value,yn.); else
   	if order in (2,3) then formal = put(value,number.);  

	if order in (1,4,5) and value = 3 and compress(col3) = '0' then delete;
	if order in (2,3) and value = 4 /*and compress(col3) = '0'*/ then delete;
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
	  	%end; 
  		define col3     / style=[cellwidth=15% just=left] " Overall~ (N=&col3)"; 
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
