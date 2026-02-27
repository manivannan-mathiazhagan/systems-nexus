dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\_Restricted\Tables\t-14-1-4-ic.sas   
* DATE:       05NOV2024
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Incontinence History
*               (Intention to Treat Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER: keerthana Bommagani  
*   DATE:       04-AUG-2025   
*   PURPOSE:    Updating Program to add SE & 95%CI.   
************************************************************************************;  
   
%let pgm=t-14-1-4-ic; 
%let pgmnum=14.1.4; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu; 
  
%include "&protdir\macros\m-setup.sas";    
          
proc format;
	value order 1 = 'Duration of Fecal Incontinence (years)  '
		        2 = 'Prior Treatments for Fecal Incontinence [1]';

	value fecal 1 = '  Dietary Modification'
	            2 = '  Fiber Supplements' 
				3 = '  Antidiarrheal Medications'
	            4 = '  Biofeedback' 
				5 = '  Pelvic floor muscle training or physiotherapy'
	            6 = '  Rectal Irrigation or Enemas' 
				7 = '  Anal Plugs'
/*			  7.5 = '  '*/
	            8 = '  Injectable Bulking Agents' 
				9 = '  Sacral Nerve Stimulation'
	           10 = '  Anal Sphincter Repair' 
			   11 = '    1 repair'
	           12 = '    2 repairs' 
			   13 = '    >2 repairs'
	           14 = '  Anterior End-to-End' 
			   15 = '  Anterior Overlapping'
			   16 = '  Plication'
			   17 = '  Other';
		    
	invalue yn 'Y' = 1
		       'N' = 2;

   	
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
	set ads.adic (in=a where=(ittfl='Y' and anl01fl='Y')) ; 
	by usubjid; 
	trt = trtpn;  

/*	if paramn in (15) then paramn = 99; */
	if paramn in (8,12) then delete; 
	if paramn in (9) then paramn = 8;
	if paramn in (10) then paramn = 9;

	if paramn in (11) then paramn = 10;
    if paramn in (13) then paramn = 11;  
	if paramn in (14) then paramn = 12;
    if paramn in (15) then paramn = 13; 
	if paramn in (16) then paramn = 14;
	if paramn in (17) then paramn = 15;
	if paramn in (18) then paramn = 16;
	if paramn in (19) then paramn = 17;

/*	if paramn in (16,17,18) then paramn = paramn-1;*/
	if paramn~=0 then aval = input(avalc,yn.);


/*	if paramn in (99) then do;*/
/*	   avaln = aval;*/
/*	   if avaln = 1 then do; paramn = 11; aval = 1; end;*/
/*	   if avaln = 2 then do; paramn = 12; aval = 1; end;*/
/*	   if avaln > 2 then do; paramn = 13; aval = 1; end;  */
/*	end;*/
	output; 

	trt = 3;
	output;	
run;   
      
*===============================================================================
* 2a. Proc Freq.
*===============================================================================;
%macro freq;
       
	proc sort data=all_1;
   		by paramn param trt usubjid;
          
   	proc freq data=all_1 noprint; 
   		by paramn param trt;   
      	tables aval / out=temp missing; 
        where paramn~=0 and aval=1;  
  	run;  

    data temp;
     	set temp (where=(aval=1));    		
       	keep order value trt result  ;
       	length result $20;

       	order = 2;  
       	value = paramn;     
       	if trt = 1 then result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; 
       	if trt = 2 then result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; 
       	if trt = 3 then result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')';   
 	run;

  	proc append base=all_2;
   	run;     

%mend freq;     

%freq 
 
*===============================================================================
*  b. Proc Univariate.
*===============================================================================; 
%macro univ;                                                       
 
	proc sort data=all_1 out=all_1x nodupkey; 
   		by trt  usubjid; 
    where paramn=0; 
 	proc means data=all_1x noprint; 
   		by trt;  
      	var aval;
      	output out=temp n=n mean=mean median=median std=std min=min max=max stderr=stderr uclm=uclm lclm=lclm ;;  
	run;  
 
  	data temp;
      	set temp;  
      	keep order value trt result;
      	length result $20;
 
      	order = 1;    
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
        value = 6; result = '  ' || compress(put(min,4.1)) || ', ' || compress(put(max,4.1)); output;   	 
	run;                                        

	proc append base=all_2;
  	run; 

%mend univ;
      
%univ   
 
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
     
%dummy(order=%str(1),value=%str(1,2,3,4,5,6))   
%dummy(order=%str(2),value=%str(0,1,2,3,4,5,6,7,/*7.5,*/8,9,10,11,12,13,14,15,16,17))  

proc sort data=all_2;
   	by order value trt;  
proc sort data=dummy;
  	by order value trt;
data all_3;
   	merge dummy all_2 (in=master); 
   	by order value trt;     
	if not master and order in (1) and value = 1 then result = '  0';  
	if not master and order in (2) and value > 0 and value ne 7.5 then result = '  0';   
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
 	set all_4 end=eof;
 	by order value;  
 
	if order = 2 and value >= 14 then page = 2; 
	                            else page = 1; 

   	length stat $15;
	if order in (1) then stat = put(value,stat.); else
	if order in (2) and value > 0 and value ne 7.5 then stat = 'n (%)';  

  	length formal $200;
   	if first.order then formal = put(order,order.); else
	if order eq 2 then formal = put(value,fecal.);  
	output;

/*	if eof then do;*/
/*	   order = 2; value = 16.5; formal = 'Prior Treatments for Fecal Incontinence [1] (continued)'; stat = ''; col1 = ''; col2 = ''; col3 = ''; output;*/
/*	end;*/
run;

proc sort data=final;
	by /*page*/ order value;
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
