dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-1-6-ex.sas   
* DATE:       06JAN2025
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Study Product Exposures
*               (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER: keerthana Bommagani  
*   DATE:       29-Jul-2025   
*   PURPOSE:    Updating Program per stat comments.   
************************************************************************************;  
  
%let pgm=t-14-1-6-ex; 
%let pgmnum=14.1.6; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu; 
  
%include "&protdir\macros\m-setup.sas";    
         
options mprint mlogic symbolgen;
proc format;
   	value order  0 = 'Number of subjects reaching Day 0 Visit?'
				 1 = 'Was Injection Administered?'
      			 2 = 'If No, Reason Not Administered [1]'
				 3 = 'Injection Duration (min) [2]'
      			 4 = 'Number of Injections performed'
				 5 = 'Total Volume Administered (mL) [3]' 
				 6 = 'Total Volume Available for Administration (mL)'
				 7 = 'Leftover Volume' 
				 8 = 'Study Product Compliance [4]';

	invalue yn 'Y' = 1
		       'N' = 2;

	value yn  1 = '  Yes'
		      2 = '  No';

	invalue reas 'Resuspension volume not within specification' = 1
		         'Patient Decision' = 2
		         'Physician Decision' = 3
		         'Unable to produced product for patient' = 4
		         'Other' = 5;

	value reas 1 = '  Resuspension volume not within specification'
		       2 = '  Patient Decision'
		       3 = '  Physician Decision'
		       4 = '  Unable to produced product for patient'
		       5 = '  Other';
 
   	   value stat 1 = 'n'
				  2 = 'Mean (SD)'
                  3 = 'SE'
				  4 = '(95% CI)'
				  5 = 'Median' 
				  6 = 'Min, Max';
run;
   
*...............................
* Determine treatment flag.  
*...............................;   
%macro mtrt_bio(pop=);
 
%global col1 col2 col3;
data adsl;
	set ads.adsl;  
	

	if saffl='Y' and BIOFL = 'Y' and trt01Pn ne . then 
	do; 
		trt=trt01Pn; 
		output;
 		trt = 3;
		output; 
	end; 
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

%mend mtrt_bio;  

%mtrt_bio;

*=============================================================================== 
* 1. Bring in required dataset(s). 
*===============================================================================;  
data all_1;
	set ads.adex (in=a where=(SAFFL='Y')); 
	by usubjid; 
	if PARAMN eq 2 and substr(AVALC,1,5) eq "Other" then AVALC = "Other";
	else AVALC = AVALC;
	trt = trtpn;

	if paramn in (1,8) then aval = input(avalc,yn.);
	if paramn in (2)   then aval = input(avalc,reas.);
	
	output;

	trt = 3;
	output;	
run;   
proc freq data=all_1 noprint;
tables paramn*param/out=chk;
run;
proc sort data=all_1;
	by trt usubjid;
run;
      
*===============================================================================
* 2a. Proc Freq.
*===============================================================================;
proc freq data=all_1 noprint;
	    where paramn = 1; 
		by trt;
      	tables studyid / out=temp missing;  
  	run;  
 
    data temp;
     	set temp;  		
       	keep order value trt result;
       	length result $20;

       	order = 0;  
       	value = 0;     
       	if trt = 1 then result = put(count,3.); /*|| ' (' || put((count/&col1)*100,5.1) || ')'; */
       	if trt = 2 then result = put(count,3.);/*|| ' (' || put((count/&col2)*100,5.1) || ')';*/ 
       	if trt = 3 then result = put(count,3.); /*|| ' (' || put((count/&col3)*100,5.1) || ')';*/  

		if order = 2 then result = put(count,3.) || ' (' || put((count/percent)*100,5.1) || ')';  
 	run;

  	proc append base=all_2;
   	run;

data dummy1;
	do trt = 1,2,3;
	   output;
	end;
RUN;

proc freq data=all_1 noprint;  
where paramn eq 1 and aval ne .;
   	tables trt/out=inj; 
	run;

data tot_inj;
	merge dummy1 inj (in=master);
	by trt;
	if not master then count = 0; 
	run;

data _null_;
   	set tot_inj;    
   	if trt = 1 then call symput("inj1",compress(put(count,3.))); 
   	if trt = 2 then call symput("inj2",compress(put(count,3.))); 
   	if trt = 3 then call symput("inj3",compress(put(count,3.))); 
run;  
 
proc freq data=all_1 noprint;  
where paramn eq 1 and aval eq  2;
   	tables trt/out=inj_n; RUN;

data tot_inj_N;
	merge dummy1 inj_n (in=master);
	by trt;
	if not master then count = 0; 
data _null_;
   	set tot_inj_N;    
   	if trt = 1 then call symput("inj_N1",compress(put(count,3.))); 
   	if trt = 2 then call symput("inj_N2",compress(put(count,3.))); 
   	if trt = 3 then call symput("inj_N3",compress(put(count,3.))); 
run;  
%macro freq(order=,var=);
      
   	proc freq data=all_1 noprint;
	    where paramn = &order and aval ne .; 
		by trt;
      	tables aval / out=temp missing;  
  	run;  
 
    data temp;
     	set temp;  		
       	keep order value trt result;
       	length result $20;

       	order = &order;  
       	value = aval; %if &order eq 1 or &order eq 8 %then %do;
		if trt = 1 then result = put(count,3.) || ' (' || put((count/&inj1)*100,5.1) || ')'; 
       	if trt = 2 then result = put(count,3.) || ' (' || put((count/&inj2)*100,5.1) || ')'; 
       	if trt = 3 then result = put(count,3.) || ' (' || put((count/&inj3)*100,5.1) || ')'; 
	%end;
	%else  %if &order eq 2 %THEN %do; 
       	if trt = 1 then result = put(count,3.) || ' (' || put((count/&inj_N1)*100,5.1) || ')'; 
       	if trt = 2 then result = put(count,3.) || ' (' || put((count/&inj_N2)*100,5.1) || ')'; 
       	if trt = 3 then result = put(count,3.) || ' (' || put((count/&inj_N3)*100,5.1) || ')';  
		%end;
%else %do; 
       	if trt = 1 then result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; 
       	if trt = 2 then result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; 
       	if trt = 3 then result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')';  
		%end;
/*		if order = 2 then result = put(count,3.) || ' (' || put((count/percent)*100,5.1) || ')';  */
 	run;

  	proc append base=all_2;
   	run;     

%mend freq;   
 
%freq(order=1) 
%freq(order=2) 
%freq(order=8)
	  
*===============================================================================
*  b. Proc Univariate.
*===============================================================================; 
%macro univ(order=,var=);                                                       
 
 	proc means data=all_1 noprint;   
		where paramn = &order and aval ne .;
      	by trt; 
      	var aval;
      	output out=temp n=n mean=mean median=median std=std min=min max=max stderr=stderr uclm=uclm lclm=lclm ;;  
	run;  
 
  	data temp;
      	set temp;  
      	keep order value trt result ;
      	length result $20;
 
      	order = &order;   
		if order in (3,4) then do; 
           value = 1; result = '  ' || compress(put(n,3.)); output;
           value = 2; if n = 1 and std = . then result = '  ' || compress(put(mean,6.1)) || ' (NA)'; 
                                           else result = '  ' || compress(put(mean,6.1)) || ' (' || compress(put(std,7.2)) || ')'; output; 
		   value = 3; if stderr ne . then result = '  '||strip(put(stderr,7.2));output;
           value = 4; if . < lclm < 0 then lclm = 0;
		      if lclm ne . and uclm ne . then result = '  ('||strip(put(lclm,6.1))||', '||strip(put(uclm,6.1))|| ')';
			  else if lclm eq . and uclm ne . then result = '  (, '||strip(put(uclm,6.1))||')';
			  else if lclm ne . and uclm eq . then result = '  ('||strip(put(lclm,6.1))||', '||')';
			  else if lclm eq . and uclm eq . then result = 'NA';output;
 
           value = 5; result = '  ' || compress(put(median,6.1)); output;
           value = 6; result = '  ' || compress(put(min,4.1)) || ', ' || compress(put(max,4.1)); output;   	 
		end; 
		else do;  
           value = 1; result = '  ' || compress(put(n,3.)); output;
           value = 2; if n = 1 and std = . then result = '  ' || compress(put(mean,7.1)) || ' (NA)'; 
                                           else result = '  ' || compress(put(mean,7.1)) || ' (' || compress(put(std,8.2)) || ')'; output;
           value = 3; if stderr ne . then result = '  '||strip(put(stderr,8.2));output;
           value = 4; if . < lclm < 0 then lclm = 0;
		      if lclm ne . and uclm ne . then result = '  ('||strip(put(lclm,7.1))||', '||strip(put(uclm,7.1))|| ')';
			  else if lclm eq . and uclm ne . then result = '  (, '||strip(put(uclm,7.1))||')';
			  else if lclm ne . and uclm eq . then result = '  ('||strip(put(lclm,7.1))||', '||')';
			  else if lclm eq . and uclm eq . then result = 'NA';output;
  
           value = 5; result = '  ' || compress(put(median,7.1)); output;
           value = 6; result = '  ' || compress(put(min,6.1)) || ', ' || compress(put(max,6.1)); output;   	 
		end;  		 
	run;          

	proc append base=all_2;
  	run; 

%mend univ;
      
%univ(order=3)  
%univ(order=4)  
%univ(order=5)  
%univ(order=6)  
%univ(order=7)  
  
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

%dummy(order=%str(0),value=%str(0))
%dummy(order=%str(1,8),value=%str(0,1,2))   
%dummy(order=%str(2),value=%str(0,1,2,3,4,5))     
%dummy(order=%str(3,4,5,6,7),value=%str(1,2,3,4,5,6))   
  
proc sort data=all_2;
   	by order value trt;  
proc sort data=dummy;
  	by order value trt;
data all_3;
   	merge dummy all_2 (in=master); 
   	by order value trt;     
	if not master and order in (1,2,8) and value > 0 then result = '  0';   
	if not master and order in (3,4,5,6,7) and value = 1 then result = '  0';   

if order=6 then orderx=7;
if order=7 then orderx=6;
if order not in (6 7) then orderx=order;
run;  
proc sort;by  orderx value;run;
  
*===============================================================================
* 4. Transpose. 
*===============================================================================;  
proc transpose data=all_3 out=all_4 prefix=col;   
   	by orderx value;
   	id trt;
   	var result; 
run;   
 
*===============================================================================
* 5. Prepare Proc Report.
*===============================================================================;
data final;
 	set all_4;
 	by orderx value;  

	if orderx <= 3 then page = 1; else
	if orderx <= 6 then page = 2;
	              else page = 3; 

   	length stat $15;
	if orderx in (1,2,8) and value > 0 then stat = 'n (%)'; else
	if orderx in (3,4,5,6,7) then stat = put(value,stat.); else
	if orderx in (0) then stat = "N1";

  	length formal $200;
   	if first.orderx then formal = put(orderx,order.); else 
	if orderx in (1) then formal = put(value,yn.); else
   	if orderx in (2) then formal = put(value,reas.); else  
	if orderx in (8) then formal = put(value,yn.); 
	
run;

proc sort data=final;
	by page orderx value;
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
       	column page orderx value formal space stat %if &i=1 %then %do; col1 col2 %end; %if &i=2 %then %do; col3 %end; ;   
   
   	   	define page     / order order=internal noprint;
       	define orderx    / order order=internal noprint;
       	define value    / order order=internal noprint; 	
		define formal   / style=[cellwidth=40% just=left] "Parameter" flow;  
       	define stat     / style=[cellwidth=11% just=left] "Statistic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=15% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=15% just=left] " Placebo~ (N=&col2)";
	  	%end; %if &i=2 %then %do;
  		define col3     / style=[cellwidth=15% just=left] " Overall~ (N=&col3)";  %end;
		define space    / style=[cellwidth=1%] " ";      

		break before page / page; 
 
 		compute before orderx;  
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
