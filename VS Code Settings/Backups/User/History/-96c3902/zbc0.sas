dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Listings\l-16-2-9-1-2-dia.sas
* DATE:        26 JUN 2025
* PROGRAMMER:  v emile
*
* PURPOSE:     14 DAY DIARY - BOWEL movement in toilet
*              (Intention to Treat Set)
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER: 
*  DATE:       
*  PURPOSE:     
*************************************************************************************;
%let pgm=l-16-2-9-1-2-dia;
%let pgmnum=16.2.9.1.2; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;

*===============================================================================
* 1. Bring in required dataset(s).  
*===============================================================================; 
proc sort data=ads.addiary out=diary;
	by subjid trtp trtpn trtsdt avisitn avisit adt ady diaday;
	where parcat1='14 Day Diary - Bowel Movements' and ittfl = 'Y'  and trtpn ne .;;
run;

data final; 
	length col3 $25;
	set diary;
	by subjid trtp trtpn trtsdt avisitn avisit adt ady;
	trtn = trtpn;
	trt = trtp;  
  
	if adt ne . then col3 = strip(put(adt,e8601da10.)) || "!n(" || strip(put(ady,best.)) || ")"; 
	space = '';
run;

proc sort data=final; 
	by trtn trt subjid avisitn diaday adt;  
run;

*===============================================================================
* 2. Produce Proc Report.
*===============================================================================; 
%calltf(byvar=trt,tagset=Y);   
 
%macro report;
%do i=1 %to 2;
 		
	%if &i=1 %then %do; ods rtf style=style1 file="&outdat\&pgm..rtf"; %let outdat=&outdat; %end;
	%if &i=2 %then %do; ods rtf style=style1 file="&outdat\open session\&pgm..rtf"; %let outdat=&outdat\open session; data final; set final; trtn=0; trt='Overall'; run; %end;

	options orientation=landscape nobyline;
	ods listing close; 
	ods tagsets.rtf style=styleL file="&outdat\&pgm..rtf" options(continue_tag="no"); 
   
	proc report data=final split='~' nowd missing spanrows spacing=1;    
		*style(report)=[rules=groups cellspacing=1 cellpadding=0.03in];   
  		by trtn trt; 
 		column subjid  avisitn periodc space diaday diadayc adt col3 accbmync EVENTNUM space DIATM  bsc SPACE;
			              
 		define subjid     / order order=internal style=[cellwidth=9%] "Subject ID" flow; 
  		define avisitn    / order order=internal noprint; 
  		define periodc    / order order=internal style=[cellwidth=8%] "Diary Visit Period" flow;                   
  		define diaday     / order order=internal noprint;  
        define diadayc    / order style=[cellwidth=6%]  "Diary~Day" flow;                  
  		define adt        / order order=internal noprint;  
  		define col3       / order style=[cellwidth=10%] "Date of~Diary~(Rel Day [1])" flow; 
  		define accbmync   / order style=[cellwidth=7%] "Any Bowel Movements" flow;      
  		         
  		define EVENTNUM    / style=[cellwidth=4% just=left]  "Movement~#"  f=2.; 
		define space      / style=[cellwidth=1%] " ";    
  		define diatm      / style=[cellwidth=5% just=left]  "Time" flow;     
  		define bsc    / style=[cellwidth=7% just=left]  "Bristol~Stool Chart" flow  f=2.;  
/*  		define sumleak    / style=[cellwidth=6% just=left]  "Total # of Bowel Movements" f=2.; */
	    define space      / style=[cellwidth=1%] " ";   
	run;	
    
	ods _all_ close;
	ods listing;

	*** paginate ***; 
	%mpgodsl;

%end;
%mend report;
%report
 
*===============================================================================
* 3. Create permanent data set for QC compare.
*===============================================================================; 
data qclis.&pgmqc;
  	retain trt subjid avisitn period  diadayc adt col3  accbmync  EVENTNUM    DIATM   bsc   ;     
  	set final; 
  	keep trt subjid avisitn period  diadayc adt col3  accbmync  EVENTNUM   DIATM   bsc  ;     
	%fmtqc;       
run; 
