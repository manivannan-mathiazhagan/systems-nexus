dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-3-3-lb-hem.sas     
* DATE:       06JAN2025
* PROGRAMMER: Laurie Drinkwater  
* PURPOSE:    Clinical Laboratory Results and Change from Baseline - Hematolog
*             (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:   
*   PROGRAMMER: Manisha Tharval
*   DATE:       27-Jan-2025
*   PURPOSE:    Updating as per updated ADLB. 
*
************************************************************************************; 
* MODIFICATIONS:   
*   PROGRAMMER: keerthana Bommagani  
*   DATE:       30-Jul-2025   
*   PURPOSE:    Updating Program to add SE and 95%CI.   
************************************************************************************;  
    
%let pgm=t-14-3-3-lb-hem;
%let pgmnum=14.3.3; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu;    
 
%include "&protdir\macros\m-setup.sas";    
          
proc format;   
   	   value stat 1 = 'n'
				  2 = 'Mean (SD)'
				 1.2= 'n(%)'
				 1.5= 'n(%)'
                  3 = 'SE'
				  4 = '(95% CI)'
				  5 = 'Median' 
				  6 = 'Min, Max';
run;

*...............................
* Determine treatment flag.  
*...............................;  
%mtrt(pop=saffl) 

*===============================================================================
* 1. Bring in required dataset(s). 
*===============================================================================;    
data all_1;
	set ads.adlb (where=(saffl='Y' and trtan ne . and parcat1 = 'HEMATOLOGY' and anl01fl='Y' and stvispd^=''));    
	if ablfl = 'Y' or (ablfl = ' ' and avisitn > 20 and base ne .); 
	if ablfl = 'Y' then do; avisitn = 0; avisit = 'Baseline'; end;
	               else do; avisit = left(scan(avisit,3,'-')); end;
 
	if strip(upcase(CLSIG))='NORMAL' then CLSIGn=1;
	if find(upcase(CLSIG),'ABNORMAL','i')>0 then CLSIGn=2;
	if stvispd = 'Blinded' then stvispdn = 1; 
	if stvispd = 'Unblinded' then stvispdn = 2;

	if param ^= '' and lbstresu ^= '' then param = strip(param) || ' (' || strip(lbstresu) || ')';

	trt = trtan;
	output;

	trt = 3;
	output;
run;   

proc sort data=all_1 nodupkey out=all_1_no;*(where=(ablfl ne 'Y')); 
	by usubjid CLSIGn paramn param avisitn avisit trt;   
run;
proc sort data=all_1_no;by  paramn param avisitn avisit trt;run;
proc freq data=all_1_no ;
table CLSIGn/out=all_6;
by  paramn param avisitn avisit trt;
run; 
  
*===============================================================================
* 2.  Proc Univariate.
*===============================================================================;
%macro univ;                                                       
proc sort data=all_1;      	by paramn param stvispdn avisitn avisit trt;    run;
 	proc means data=all_1 noprint;  
      	by paramn param stvispdn avisitn avisit trt;    
      	var aval;
      	output out=temp1 n=n mean=mean median=median std=std min=min max=max stderr=stderr uclm=uclm lclm=lclm;
  	proc means data=all_1 noprint;    
      	by paramn param stvispdn avisitn avisit trt;  
     	var chg;
     	output out=temp2 n=n mean=mean median=median std=std min=min max=max stderr=stderr uclm=uclm lclm=lclm;   

		proc sql;
		 create table i as select distinct N ,paramn ,param ,stvispdn,avisitn,avisit,trt from temp1 
         order by paramn, param ,stvispdn ,avisitn, avisit ,trt;    
		quit;
   	    data temp;
    	set temp1 (in=in1) temp2 (in=in2);
      	by paramn param stvispdn avisitn avisit trt;  
      	keep paramn param stvispdn avisitn avisit order trt value result;
       	length result $19; 

      	if in1 then order = 1;
      	if in2 then order = 2; 

		if paramn in (101,102,103,104) then do;
     	   value = 1; result = put(n,3.); output;
           value = 2; if mean ^= . and std = . then result = ' ' || compress(put(mean,8.1)) || ' (NA)'; 
                      else if mean ^= . and std ^= . then result = ' ' || compress(put(mean,8.1)) || ' (' || compress(put(std,9.2)) || ')'; output; 
           value = 3;  if stderr ne . then result = '  '||strip(put(stderr,9.2));output;
           value = 4;  if . < lclm < 0 then lclm = 0;
		      if lclm ne . and uclm ne . then result = '  ('||strip(put(lclm,8.1))||', '||strip(put(uclm,8.1))|| ')';
			  else if lclm eq . and uclm ne . then result = '  (, '||strip(put(uclm,8.1))||')';
			  else if lclm ne . and uclm eq . then result = '  ('||strip(put(lclm,8.1))||', '||')';
			   else if lclm eq . and uclm eq . then result = 'NA';output;

   		   value = 5; result = ' ' || compress(put(median,8.1)); output; 
   		   value = 6; if min ^= . and max ^= . then result = ' ' || compress(put(min,8.1)) || ', ' || compress(put(max,8.1)); output;
		end;
  	run; 

  	proc append base=all_2;
    run; 

%mend univ;
 
%univ 
data all_6i;
length result $19;
merge i(in=a  ) all_6;
by  paramn param avisitn avisit trt;
result=put(count,3.)||"("||put((count/n)*100,5.1) ||")" ;
if CLSIGn=1 then value =1.2;
if CLSIGn=2 then value =1.5;
order=1 ;

run;
    data all_2;
	set all_2 all_6i;
	if VALUE NE .;
	run;
*===============================================================================
* 3.  Create dummy records. 
*===============================================================================;
proc sort data=all_2 out=dummy (keep=paramn param stvispdn avisitn avisit  ) nodupkey;  
  	by paramn param stvispdn avisitn avisit  ;   run ;
data dummy;
   	set dummy;
  	by paramn param stvispdn avisitn avisit  ;
  	do order = 1,2;  
  	      do trt = 1,2,3;  
	   do value = 1,1.2,1.5,2,3,4,5,6; 
             output;
    end; end; end;
run; 
proc sort data=all_2;
   	by paramn param stvispdn avisitn avisit order value trt;  
proc sort data=dummy;
   	by paramn param stvispdn avisitn avisit order value trt;run;  
data all_3;
   	merge dummy all_2 (in=master);
   	by paramn param stvispdn avisitn avisit order value trt;   
   	if not master and value = 1 then result = '  0';  
    else if not master and value in (2,3,4) then result = ' ';run;
data all_3;
   	set all_3;
   	by paramn param stvispdn avisitn avisit order value trt;  
	if avisitn = 0 and order = 2 then delete;
/*	if avisitn = 0  and value = 1.5 then delete;*/
	if avisitn ne 0  and order=2 and value in (1.2, 1.5) then delete;
run;
 
*===============================================================================
* 4.  Transpose. 
*===============================================================================;   
proc sort data=all_3;   	by paramn param stvispdn   avisitn avisit order value;  
 
proc transpose data=all_3 out=all_4 prefix=col;  
   	by paramn param stvispdn   avisitn avisit order value;  
   	id trt;
   	var result;   
run;  
  
*===============================================================================
* 5.  Prepare Proc Report.
*===============================================================================;
proc sort data=all_4;   	by paramn param stvispdn avisitn avisit order value;    
data final;
 	set all_4;
   	by paramn param stvispdn avisitn avisit order value;   
	space = '';
  
	length stvispd $25;
	if stvispdn = 1 then stvispd = 'Blinded'; 
	if stvispdn = 2 then stvispd = 'Unblinded'; 

  	length formal $100;   
	if first.order and order = 1 and avisitn = 0 then formal = 'Baseline'; else
	if first.order and order = 1 and value=1 then formal = ' Actual'; else
	if  order = 1 and value=1.2   then formal = '   Normal '; 
	if  order = 1 and value=1.5   then formal = '   Abnormal ';else
	if first.order and order = 2 then formal = ' Change from Baseline';   
 
 	length stat $20;
    stat = put(value,stat.);   
	output;
	if first.order  and order = 1 and avisitn ne 0 then do;
	   stat = ''; col1 = ''; col2 = ''; col3 = '';
	   value = 0; formal = strip(avisit); output;
	end;
run; 

proc sort data=final;
	by paramn param stvispd avisitn avisit order value;   
data final;
	set final;
	by paramn param stvispd avisitn avisit order value;
array col col1 col2 col3;
do over col;
if  value in (1.2,1.5) and missing(col) then col='  0';
end; 
	if first.paramn then page + 1; else
	if stvispdn = 1 and first.avisit and avisit in ('Week 6') then page + 1; else
	if stvispdn = 2 and first.avisit and avisit in ('Day 0' 'Week 24') then page = 1;
label  stvispdn = 'Study Visit Period';
proc sort data=final;
	by page paramn param stvispd avisitn avisit order value; 
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
       	column page paramn param stvispd avisitn order formal space stat %if &i=1 %then %do; col1 col2 %end; col3;
    
   	   	define page     / order order=internal noprint;
	    define paramn   / order order=internal noprint;
   	   	define param    / order order=internal style=[cellwidth=20.5% just=left] "Parameter" flow;  
		define stvispd  / order order=internal style=[cellwidth=9.5% just=left] "Study~Period" flow;  
       	define avisitn  / order order=internal noprint;  	
		define order    / order order=internal noprint;
		define formal   / style=[cellwidth=18% just=left] "Visit" flow;  
       	define stat     / style=[cellwidth=10% just=left] "Statistic";  
	  	%if &i=1 %then %do;
 			define col1     / style=[cellwidth=13.5% just=left] "Iltamiocel~  (N=&col1)"; 
  			define col2     / style=[cellwidth=13.5% just=left] " Placebo~  (N=&col2)";
	  	%end; 
  		define col3     / style=[cellwidth=13.5% just=left] " Overall~ (N=&col3)";  
		define space    / style=[cellwidth=0.5%] " ";      

		break after page / page; 
 		compute before paramn;  
			line @1 " ";
		endcomp;
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
libname qc "&outdat\qc"; 
 
data qc.&pgmqc;
   	retain param stvispd formal stat col:;  
   	set final; 
   	keep param stvispd formal stat col:;     
    %fmtqc;  
run; 
