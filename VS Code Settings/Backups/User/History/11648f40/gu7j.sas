************************************************************************************
* VERISTAT INCORPORATED                                                     
************************************************************************************
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Macros\mtrt.sas     
* DATE:       04NOV2023
* PROGRAMMER: Laurie Drinkwater
*
* PURPOSE:    Macro MTRT   
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER:   
*   DATE:         
*   PURPOSE:      
************************************************************************************; 
    
%macro mtrt(pop=);
 
%global col1 col2 col3;
data adsl;
	set ads.adsl;  
	if %upcase("&pop")="ICSFL" then do; if icsfl='Y'; trt=trt01pn; end; 
	if %upcase("&pop")="ITTFL" then do; if ittfl='Y'; trt=trt01pn; end;  
	if %upcase("&pop")="SAFFL" then do; if saffl='Y' and trt01an ne .; trt=trt01an; end;  
 	output;
 
	trt = 3;
	output;

	if %upcase("&pop")="SAFFLBIOFL" AND saffl='Y' and BIOFL = 'Y' and trt01Pn ne . then 
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

%mend mtrt;  
