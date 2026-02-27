dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\_Restricted\Tables\t-14-1-2-dm.sas   
* DATE:       04NOV2024
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Demographics and Baseline Characteristics 
*               (Intention to Treat Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER:keerthana Bommagani    
*   DATE:      04 AUG 2025    
*   PURPOSE:   Updating Program to add SE & 95%CI      
************************************************************************************;   
%let pgm=t-14-1-2-dm; 
%let pgmnum=14.1.2; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu; 
  
%include "&protdir\macros\m-setup.sas";    
         
proc format;
   	value order  1 = 'Sex'
      			 2 = 'Childbearing Potential'
				 3 = 'Race'
      			 4 = 'Ethnicity'
				 5 = 'Has the Subject had a Hysterectomy?' 
				 6 = 'Age'
				 7 = 'BMI (kg/m^2)'; 
 
 	invalue sex  'Female' = 1
		         ' '      = 2;

   	value sex     1 = '  Female'
	              2 = '  Not Specified'; 

	invalue cbp   'Y' = 1
		          'N' = 2;
	invalue cbpsp 'Early menopause'        = 3
		          'Menopause'              = 4
				  'Post menopause'         = 5
				  'Bilateral oophorectomy' = 6;

	value cbpsp   1 = '  Yes'
		          2 = '  No' 
	              3 = '    Early menopause'
				  4 = '    Menopause'
				  5 = '    Post menopause'
				  6 = '    Bilateral oophorectomy';

	invalue race 'American Indian or Alaska Native'          = 1
		         'Asian'                                     = 2
				 'Black or African American'                 = 3
		         'Native Hawaiian or other Pacific Islander' = 4
				 'White'                                     = 5
		         'More than one race'                        = 6
				 'Prefer not to disclose'                    = 7;

	value race    1 = '  American Indian or Alaska Native'
	              2 = '  Asian'
	              3 = '  Black or African American'
	              4 = '  Native Hawaiian or Other Pacific Islander'
	              5 = '  White'
	              6 = '  More than one race'
				  7 = '  Prefer not to disclose';
				
	invalue ethnic 'Hispanic or Latino'     = 1
		           'Not Hispanic or Latino' = 2
				   'Prefer not to disclose' = 3; 
	
	value ethnic  1 = '  Hispanic or Latino' 
				  2 = '  Not Hispanic or Latino'
				  3 = '  Prefer not to disclose'; 
 
	invalue hys   'N' = 1
	              'Y' = 2;

	invalue hyssp 'Partial' = 3
		          'Total'   = 4
				  'Radical' = 5;

	invalue hysproc 'Abdominal Hysterectomy'    =  8
		            'Vaginal Hysterectomy'      =  9
					'Laparoscopic Hysterectomy' = 10; 

	value hyssp   1 = '  No'
		          2 = '  Yes' 
	              3 = '    Partial'
		          4 = '    Total'
				  5 = '    Radical'
				  6 = '    Not Reported'
				  7 = '  If Yes, Type of Hysterectomy Procedure'
				  8 = '    Abdominal Hysterectomy'
				  9 = '    Vaginal Hysterectomy'
				 10 = '    Laparoscopic Hysterectomy'
				 11 = '    Not Reported';

   	value stat    1 = 'n'
				  2 = 'Mean (SD)' 
				  3 = 'SE'
				  4 = '(95% CI)'
				  5 = 'Median' 
				  6 = 'Min, Max';
run;
   
*...............................
* Determine treatment flag.  
*...............................;   
%mtrt(pop=ittfl)

*=============================================================================== 
* 1. Bring in required dataset(s). 
*===============================================================================;  
data all_1;
	set ads.adsl (in=a where=(ittfl='Y')); 
	by usubjid; 
	trt = trt01pn; 
	sexn = input(sex,sex.); 
	cbpfn = input(cbpfl,cbp.);
	cbpspn = input(cbpsp,cbpsp.);
	racen = input(race,race.);
	ethnicn = input(ethnic,ethnic.); 
	hysfn = input(hysfl,hys.);
	hysspn = input(hyssp,hyssp.); 
	hysprocn = input(hysproc,hysproc.);
	   if hysfn = 2 and hysspn = . then hysspn = 6;
	   if hysfn = 2 and hysprocn = . then hysprocn = 11;
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
     
	data all_1x;
		set all_1;
		by trt;
	    %if &var=cbpspn %then %do; if cbpfn = 2 and cbpspn in (3,4,5,6); %end;  
	    %if &var=hysspn %then %do; if hysfn = 2 and hysspn in (3,4,5,6); %end;  
	    %if &var=hysprocn %then %do; if hysprocn in (8,9,10,11); %end; 
   	proc freq data=all_1x noprint; 
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
 
%freq(order=1,var=sexn) 
%freq(order=2,var=cbpfn) 
%freq(order=2,var=cbpspn)  
%freq(order=3,var=racen)   
%freq(order=4,var=ethnicn)  
%freq(order=5,var=hysfn)    
%freq(order=5,var=hysspn)
%freq(order=5,var=hysprocn)
 
*===============================================================================
*  b. Proc Univariate.
*===============================================================================; 
%macro univ(order=,var=);                                                       
 
 	proc means data=all_1 noprint;   
		where &var ^= .;
      	by trt; 
      	var &var;
      	output out=temp n=n mean=mean median=median std=std min=min max=max stderr=stderr uclm=uclm lclm=lclm ;  
	run;  
 
  	data temp;
      	set temp;  
      	keep order value trt result;
      	length result $20;
 
      	order = &order;   
		if order in (6) then do; 
           value = 1; result = '  ' || compress(put(n,4.)); output;
           value = 2; if n = 1 and std = . then result = '  ' || compress(put(mean,6.1)) || ' (NA)'; 
                                           else result = '  ' || compress(put(mean,6.1)) || ' (' || compress(put(std,7.2)) || ')'; output; 
           value = 3; if stderr ne . then result = '  '||strip(put(stderr,7.2));output;
           value = 4; if . < lclm < 0 then lclm = 0;
		      if lclm ne . and uclm ne . then result = '  ('||strip(put(lclm,6.1))||', '||strip(put(uclm,6.1))|| ')';
			  else if lclm eq . and uclm ne . then result = '  (, '||strip(put(uclm,6.1))||')';
			  else if lclm ne . and uclm eq . then result = '  ('||strip(put(lclm,6.1))||', '||')';
			  else if lclm eq . and uclm eq . then result = 'NA';output;
 
           value = 5; result = '  ' || compress(put(median,6.1)); output;
           value = 6; result = '  ' || compress(put(min,4.0)) || ', ' || compress(put(max,4.0)); output;   	 
		end; 
		else do;  
           value = 1; result = '  ' || compress(put(n,4.)); output;
           value = 2; if n = 1 and std = . then result = '  ' || compress(put(mean,8.3)) || ' (NA)'; 
                                           else result = '  ' || compress(put(mean,8.3)) || ' (' || compress(put(std,9.4)) || ')'; output;
           value = 3; if stderr ne . then result = '  '||strip(put(stderr,9.4));output;
           value = 4; if . < lclm < 0 then lclm = 0;
		      if lclm ne . and uclm ne . then result = '  ('||strip(put(lclm,8.3))||', '||strip(put(uclm,8.3))|| ')';
			  else if lclm eq . and uclm ne . then result = '  (, '||strip(put(uclm,8.3))||')';
			  else if lclm ne . and uclm eq . then result = '  ('||strip(put(lclm,8.3))||', '||')';
			  else if lclm eq . and uclm eq . then result = 'NA';output;
  
           value = 5; result = '  ' || compress(put(median,8.3)); output;
           value = 6; result = '  ' || compress(put(min,7.2)) || ', ' || compress(put(max,7.2)); output;   	 
		end;  		 
	run;                           

	proc append base=all_2;
  	run; 

%mend univ;
      
%univ(order=6,var=age)  
%univ(order=7,var=bmibl)  
  
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
     
%dummy(order=%str(1),value=%str(0,1,2))   
%dummy(order=%str(2),value=%str(0,1,2,3,4,5,6))  
%dummy(order=%str(3),value=%str(0,1,2,3,4,5,6,7))  
%dummy(order=%str(4),value=%str(0,1,2,3)) 
%dummy(order=%str(5),value=%str(0,1,2,3,4,5,6,7,8,9,10,11))   
%dummy(order=%str(6,7),value=%str(1,2,3,4,5,6))   
  
proc sort data=all_2;
   	by order value trt;  
proc sort data=dummy;
  	by order value trt;
data all_3;
   	merge dummy all_2 (in=master); 
   	by order value trt;     
	if not master and order in (1,2,3,4,5) and value > 0 then result = '  0';   
	if not master and order in (6,7) and value = 1 then result = '  0';  
	   if order = 5 and value = 7 then result = ''; 
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
	else  if order in (5,6) then page = 2;
	else page=3;

   	length stat $15;
	if order in (1,2,3,4,5) and value > 0 then stat = 'n (%)'; else
	if order in (6,7) then stat = put(value,stat.);
	if order in (5) and value in (7) then stat = ''; 

  	length formal $200;
   	if first.order then formal = put(order,order.); else 
	if order in (1) then formal = put(value,sex.); else
   	if order in (2) then formal = put(value,cbpsp.); else 
   	if order in (3) then formal = put(value,race.); else 
   	if order in (4) then formal = put(value,ethnic.); else 
	if order in (5) then formal = put(value,hyssp.); 
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
		%if &i=2 %then %do;
  		define col3     / style=[cellwidth=15% just=left] " Overall~ (N=&col3)"; 
		%end; 
		define space    / style=[cellwidth=1%] " ";      

		break after page / page; 
 
 		compute after order;  
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
