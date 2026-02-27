dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-3-1-1-ae-sum.sas   
* DATE:       17NOV2024
* PROGRAMMER: Laurie Drinkwater  
*
* PURPOSE:      Summary of Adverse Events
*               (Safety Set) 
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER:   uks
*   DATE:         12/18/2024
*   PURPOSE:      rerun 
*
*   PROGRAMMER:   Laurie Drinkwater
*   DATE:         31DEC2024
*   PURPOSE:      Use BLINVIS as 'Blinded Period' vs 'Unblinded Period', for presentation,  
*                 per e-mail, "RE: Cook MyoSite DSMB:  Table 14.3.1.1", 31DEC2024.
*
*   PROGRAMMER:   Laurie Drinkwater
*   DATE:         02JAN2025
*   PURPOSE:      Change BLINVIS to STVISPD, per e-mail, "RE: Cook MyoSite DSMB:  Table 14.3.1.1", 02JAN2025.
************************************************************************************;   
%let pgm=t-14-3-1-1-ae-sum; 
%let pgmnum=14.3.1.1; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu;  

%include "&protdir\macros\m-setup.sas";     

proc format;				  
     /*value order  1 = 'AE Least 1 AE'
	              2 = 'At Least 1 TEAE' 
                  3 = 'Treatment-Related AEs'   
				  4 = 'AEs Reported as Reason for Discontinuation'
				  5 = 'Maximum Severity of Study Product-related AEs';   

	value relat   1 = ' Study Product-related AEs'
	              2 = ' Study Product-related Serious'
				  3 = ' Injection Procedure-related AEs'
				  4 = ' Injection Procedure-related'
				  5 = ' Biopsy Procedure-related AEs'
				  6 = ' Biopsy Procedure-related Serious';
 
	value disc    1 = ' Serious AEs'
	 	          2 = ' Deaths'
	              3 = ' Study Product-related AEs'
	              4 = ' Study Product-related Serious' 
				  5 = ' Injection Procedure-related AEs'
				  6 = ' Injection Procedure-related' 
				  7 = ' Biopsy Procedure-related AEs'
				  8 = ' Biopsy Procedure-related Serious'; 

	value grade   1 = ' Grade 3'
		          2 = ' Grade 4'
				  3 = ' Grade 5';*/

				  value order  
				  1 = 'AE Least 1 AE'
	              2 = 'At Least 1 TEAE' 
                  3 = 'Treatment-Related AEs'   
				  4 = 'AEs Reported as Reason for Discontinuation'
				  5 = 'Maximum Severity of Study Product-related AEs';   

	value relat   1 = ' SPRAE'
	              2 = ' SPRSAE'
				  3 = ' IJPRAE'
				  4 = ' IJPRSAE'
				  5 = ' BPRAE'
				  6 = ' BPRSAE';
 
	value disc    1 = ' SAE'
	 	          2 = ' Deaths'
	              3 = ' SPRAE'
	              4 = ' SPRSAE' 
				  5 = ' IJPRAE'
				  6 = ' IJPRSAE' 
				  7 = ' BPRAE'
				  8 = ' BPRSAE'; 

	value grade   1 = ' Grade 3'
		          2 = ' Grade 4'
				  3 = ' Grade 5';
run;
     
%macro mtrtx(pop=);
 
%global col1 col2 col3 col9 col12 col22 col32 col92;
data adsl;
	set ads.adsl;  
	if %upcase("&pop")="ICSFL" then do; if icsfl='Y'; trt=trt01pn; end; 
	if %upcase("&pop")="ITTFL" then do; if ittfl='Y'; trt=trt01pn; end;  
	if %upcase("&pop")="SAFFL" then do; if saffl='Y' /*and trt01an ne .*/; 

	*trtemfl='Y';**** we are counting all AEs;

if trt01an=. then trt01an=3;
trt=trt01an; end;  
 	output;
 
	trt = 9;
	output;
run;
 
proc freq data=adsl noprint;  
   	tables trt/out=total0; 
data dummy;
DO STVISPDN=1,2;
	do trt = 1,2,3,9;
	   output;
	end;
	END;
RUN;
PROC SORT;
	BY TRT;
data total;
	merge dummy total0 (in=master);
	by trt;
	if not master then count = 0; 
	****THERE IS NO UNBLINDED NOW - REVISIT WHEN WE HAVE SOME;
	IF STVISPDN=2 THEN COUNT=0;
RUN;

data _null_;
   	set total;  
if stvispdn=1 then do; 
   	if trt = 1 then call symput("col1",compress(put(count,3.))); 
   	if trt = 2 then call symput("col2",compress(put(count,3.))); 
   	if trt = 3 then call symput("col3",compress(put(count,3.))); 
   	if trt = 9 then call symput("col9",compress(put(count,3.))); 
end;

if stvispdn=2 then do; 
   	if trt = 1 then call symput("col12",compress(put(count,3.))); 
   	if trt = 2 then call symput("col22",compress(put(count,3.))); 
   	if trt = 3 then call symput("col32",compress(put(count,3.))); 
   	if trt = 9 then call symput("col92",compress(put(count,3.))); 
end;
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

DATA ADAE;
  SET ADS.ADAE;
  IF AEREL1 IN ('Possibly','Probably','Definitely') THEN AEREL99='Y';
  IF AEREL2 IN ('Possibly','Probably','Definitely') THEN AEREL99='Y';
  IF AEREL3 IN ('Possibly','Probably','Definitely') THEN AEREL99='Y';
RUN;
 
*=============================================================================== 
* 1. Bring in required dataset(s).   
*===============================================================================;   
data all_1; 
  	set adae (where=(saffl='Y' ));*and trtan ne .;
  	by usubjid;   
  	any = 'Y'; 
	if trtan=. then trtan=3;
	trt = trtan;   
	if stvispd = 'Blinded' then stvispdn = 1; 
	if stvispd = 'Unblinded' then stvispdn = 2;
	output;

	trt = 9;
	output;  

run;
   
*===============================================================================
* 2. Proc Freq. 
*===============================================================================;
%macro freq(order=,value=,var=);
         
  	proc sort data=all_1 out=all_1x nodupkey; 
  		where &var; 
    	by trt stvispdn usubjid any;    
  	proc freq data=all_1x noprint; 
    	by trt stvispdn;
   		tables any / out=temp missing;
 	data temp;
     	set temp;
  		keep order value trt stvispdn result count;
    	length result $15;
    	order = &order;
     	value = &value;       
		
		IF STVISPDN=1 THEN DO;
   	if trt = 1 then do; pct = round((count/&col1)*100,.1); result = put(count,3.) || ' (' || put((count/&col1)*100,5.1) || ')'; end; else 
   	if trt = 2 then do; pct = round((count/&col2)*100,.1); result = put(count,3.) || ' (' || put((count/&col2)*100,5.1) || ')'; end; else 
   	if trt = 3 then do; pct = round((count/&col3)*100,.1); result = put(count,3.) || ' (' || put((count/&col3)*100,5.1) || ')'; end;  else 
   	if trt = 9 then do; pct = round((count/&col9)*100,.1); result = put(count,3.) || ' (' || put((count/&col9)*100,5.1) || ')'; end;    
	END;
	IF STVISPDN=2 THEN DO;
   	if trt = 1 then do; pct = round((count/&col1)*100,.1); result = put(count,3.) || ' (' || put((count/&col12)*100,5.1) || ')'; end; else 
   	if trt = 2 then do; pct = round((count/&col2)*100,.1); result = put(count,3.) || ' (' || put((count/&col22)*100,5.1) || ')'; end; else 
   	if trt = 3 then do; pct = round((count/&col3)*100,.1); result = put(count,3.) || ' (' || put((count/&col32)*100,5.1) || ')'; end;  else 
   	if trt = 9 then do; pct = round((count/&col9)*100,.1); result = put(count,3.) || ' (' || put((count/&col92)*100,5.1) || ')'; end;    
	END; 
    run;  

   	proc append base=all_2;
   	run;      

%mend freq;
   
%freq(order=1,value=1,var=%str(any='Y')) 
%freq(order=2,value=1,var=%str(trtemfl='Y')) 

%freq(order=3,value=0,var=%str(AEREL99='Y')) 


%freq(order=3,value=1,var=%str(AEREL99='Y' and aerel1 IN ('Possibly','Probably','Definitely')))  
%freq(order=3,value=2,var=%str(AEREL99='Y' and aerel1 IN ('Possibly','Probably','Definitely') and aeser='Y'))
%freq(order=3,value=3,var=%str(AEREL99='Y' and aerel3 IN ('Possibly','Probably','Definitely')))  
%freq(order=3,value=4,var=%str(AEREL99='Y' and aerel3 IN ('Possibly','Probably','Definitely') and aeser='Y'))  
%freq(order=3,value=5,var=%str(AEREL99='Y' and aerel2 IN ('Possibly','Probably','Definitely')))  
%freq(order=3,value=6,var=%str(AEREL99='Y' and aerel2 IN ('Possibly','Probably','Definitely') and aeser='Y'))  

%freq(order=4,value=0,var=%str(aedisc='Y'))
%freq(order=4,value=1,var=%str(aedisc='Y' and aeser='Y'))
%freq(order=4,value=2,var=%str(aedisc='Y' and aedeath='Y'))
%freq(order=4,value=3,var=%str(aedisc='Y' and AEREL99='Y' and aerel1 IN ('Possibly','Probably','Definitely')))  
%freq(order=4,value=4,var=%str(aedisc='Y' and AEREL99='Y' and aerel1 IN ('Possibly','Probably','Definitely') and aeser='Y'))
%freq(order=4,value=5,var=%str(aedisc='Y' and AEREL99='Y' and aerel3 IN ('Possibly','Probably','Definitely')))  
%freq(order=4,value=6,var=%str(aedisc='Y' and AEREL99='Y' and aerel3 IN ('Possibly','Probably','Definitely') and aeser='Y'))  
%freq(order=4,value=7,var=%str(aedisc='Y' and AEREL99='Y' and aerel2 IN ('Possibly','Probably','Definitely')))  
%freq(order=4,value=8,var=%str(aedisc='Y' and AEREL99='Y' and aerel2 IN ('Possibly','Probably','Definitely') and aeser='Y'))  
  
%freq(order=5,value=1,var=%str(aetoxgrn=3 and aerel1 IN ('Possibly','Probably','Definitely')))
%freq(order=5,value=2,var=%str(aetoxgrn=4 and aerel1 IN ('Possibly','Probably','Definitely')))
%freq(order=5,value=3,var=%str(aetoxgrn=5 and aerel1 IN ('Possibly','Probably','Definitely'))) 

*===============================================================================
* 3. Create dummy recordss. 
*===============================================================================;
%macro dummy(order=,value=);

  	data;  
  		do trt = 1,2,3,9;  
		   do stvispdn = 1,2;
        	  do order = &order;
           	  	  do value = &value; 
        			 output;
   		 end; end; end; end;
	run;

  	proc append base=dummy;
 	run;                   

%mend dummy;

%dummy(order=%str(1,2),value=%str(1))  
%dummy(order=%str(3),value=%str(0,1,2,3,4,5,6))  
%dummy(order=%str(4),value=%str(0,1,2,3,4,5,6,7,8))  
%dummy(order=%str(5),value=%str(0,1,2,3))  

proc sort data=all_2;
  	by order value trt stvispdn;  
proc sort data=dummy;
  	by order value trt stvispdn;
data all_3;
  	merge dummy all_2 (in=master);
   	by order value trt stvispdn; 
   	if not master then result = '  0';
	   if order = 5 and value = 0 then result = ''; 
run;

*===============================================================================
* 4. Transpose. 
*===============================================================================;  
proc transpose data=all_3 out=all_4a prefix=col;  
	where stvispdn = 1;
   	by order value  ;    
   	id trt;
   	var result; 
proc transpose data=all_3 out=all_4b prefix=ucol;  
	where stvispdn = 2;
   	by order value  ;    
   	id trt;
   	var result; 
data all_4;
	merge  all_4b all_4a;
	by order value;
run;  
  

data all_4;
	set all_4;
/*	length stvispd $11;*/
/*	if stvispdn=1 then stvispd='Blinded';*/
/*	else stvispd='Unblinded';*/
run;  
*===============================================================================
* 5. Prepare Proc Report. 
*===============================================================================;
data final;
   	set all_4 end=eof;
   	by order value; 
	space = ''; 

	if order <= 3 or (order = 4 and value <= 6) 
	   then page = 1; 
	   else page = 2;

	*   if order <= 3 then page=1;
*else if order = 4 then page=2;
*	   else page = 3;
 
  	length formal $200;
   	if first.order then formal = put(order,order.); else  
   	if order in (3) then formal = put(value,relat.); else 
   	if order in (4) then formal = put(value,disc.); else 
   	if order in (5) then formal = put(value,grade.);  

   	length stat $10; 
   	stat = 'n (%)';
	  if order = 5 and value = 0 then stat = '';

	if order = 2 then do; order = 1; value = 1.5; end;
	output;

	if eof then do;
	   page = 1;
	   stat = ''; col1 = ''; col2 = ''; col3 = ''; col9 = '';ucol1 = ''; ucol2 = ''; ucol3 = '';ucol9 = '';

	   /*order = 3; value = 2; formal = '      '; output; 
	   order = 3; value = 4; formal = '   '; output; 
	   order = 3; value = 6; formal = '   '; output; */
  
	   /*order = 4; value = 4; formal = '   '; output;
	   order = 4; value = 6; formal = '   '; output; */

	   page = 2;
	   order = 4; value = 6.5; formal = 'AEs Reported as Reason for Discontinuation (continued)'; output;
	   order = 4; value = 8; formal = '   '; output; 
	end;
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
       	column page order value formal  stat %if &i=1 %then %do; ("!S={borderbottomwidth=1}Blinded Treatment Period" col1 col2 col3) %end; col9 space
	                                              %if &i=1 %then %do; ("!S={borderbottomwidth=1}Unblinded Treatment Period" ucol1 ucol2 ucol3) %end; ucol9; 
    
   	   	define page     / order order=internal noprint;
       	define order    / order order=internal noprint;
       	define value    / order order=internal noprint; 	
		define formal   / style=[cellwidth=20% just=left] "Parameter" flow;  
       	define stat     / style=[cellwidth=5% just=left] "Stat~istic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=8% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=8% just=left] " Placebo~  (N=&col2)";
  			define col3     / style=[cellwidth=8% just=left] " Not~Treated~ (N=&col3)";
	  	%end; %if &i=2 %then %do;
  		define col9     / style=[cellwidth=8% just=left] "Blinded Overall~ (N=&col9)"; %end;
	  	%if &i=1 %then %do;
 			define ucol1     / style=[cellwidth=8% just=left] "Iltamiocel~  (N=&col12)"; 
  			define ucol2     / style=[cellwidth=7% just=left] " Placebo~  (N=&col22)";
  			define ucol3     / style=[cellwidth=7% just=left] " Not~Treated~ (N=&col32)";
	  	%end; %if &i=2 %then %do;
  		define ucol9     / style=[cellwidth=8% just=left] "Unblinded Overall~ (N=&col92)"; %end;
		define space    / style=[cellwidth=0.8%] " ";      

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
   	retain formal stat col1 col2 col3 col9 ucol1 ucol2 ucol3 ucol9;       
   	set final; 
	if page=2 and formal=' ' then delete;
	if page=2 and formal='AEs Reported as Reason for Discontinuation (continued)' then delete;
   	keep formal stat col1 col2 col3 col9 ucol1 ucol2 ucol3 ucol9;     
	%fmtqc; 
run; 
