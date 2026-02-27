dm "log; clear; lst; clear;";
*************************************************************************************************************;
* VERISTAT INCORPORATED
*************************************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\QC\ADS\qd-addia.sas
* DATE:        02Jul2025
* PROGRAMMER:  Manivannan Mathialagan            
* PURPOSE:     QC ADDIARY.
* 
*************************************************************************************************************;
* MODIFICATIONS:
*   DATE:        
*   PROGRAMMER:  
*   PURPOSE:      
* 
*************************************************************************************************************;

%let pgm=qd-addiary;
%let pgmnum=0;
%let protdir=&difi2201dsmb;

%include "&protdir\macros\m-setup.sas";

proc datasets library=work memtype=data kill nolist; 
quit;

*===============================================================================
* 1. Bring in RAW.DIARY.  
*===============================================================================; 
data DIA1;
	length USUBJID AVISIT PARCAT1 PERIODC DIADAYC ACCBMYNC AMOUNTC SENSATC $200.; 
	set RAW.DIARY (encoding=any);
	where PAGENAME eq "14 Day Diary - Bowel Accidents" ;
	format _all_;  
	
	USUBJID 	=  'DIFI-22-01-' || strip(put(SITENUM,best.)) || '-' || strip(SUBNUM);
	AVISIT		=	strip(VISNAME);
	AVISITN		= 	VISITID;
	PARCAT1		=	PAGENAME;
	PERIOD		=	ACCPRD;
	PERIODC 	=   ACCPRD_DEC;
	DIADAY		=	ACCDDAY;
	DIADAYC		=	ACCDDAY_DEC;
	ADT			=	ACCDAT;	
	
	array TIME_VAR  [15] 	ACCTIM 		ACCTIM2 	ACCTIM3 	ACCTIM4 	ACCTIM5 
							ACCTIM6 	ACCTIM7 	ACCTIM8 	ACCTIM9 	ACCTIM10 
							ACCTIM11 	ACCTIM12 	ACCTIM13 	ACCTIM14  	ACCTIM15;

	array AMNT_N   [15]  	LEAKAM      LEAKAM2     LEAKAM3     LEAKAM4     LEAKAM5 
							LEAKAM6     LEAKAM7 	LEAKAM8 	LEAKAM9 	LEAKAM10 
							LEAKAM11 	LEAKAM12 	LEAKAM13 	LEAKAM14 	LEAKAM15;

	array AMNT_C   [15]  	LEAKAM_DEC 	LEAKAM2_DEC LEAKAM3_DEC LEAKAM4_DEC LEAKAM5_DEC 
							LEAKAM6_DEC LEAKAM7_DEC LEAKAM8_DEC LEAKAM9_DEC LEAKAM10_DEC 
							LEAKAM11_DEC LEAKAM12_DEC LEAKAM13_DEC LEAKAM14_DEC LEAKAM15_DEC; 

	array SENS_N   [15]  	LEAKS      	LEAKS2      LEAKS3      LEAKS4      LEAKS5      
							LEAKS6 		LEAKS7 		LEAKS8 		LEAKS9 		LEAKS10 
							LEAKS11 	LEAKS12 	LEAKS13 	LEAKS14 	LEAKS15;
	array SENS_C   [15]  	LEAKS_DEC  	LEAKS2_DEC  LEAKS3_DEC  LEAKS4_DEC  LEAKS5_DEC  
							LEAKS6_DEC 	LEAKS7_DEC 	LEAKS8_DEC 	LEAKS9_DEC 	LEAKS10_DEC 
							LEAKS11_DEC LEAKS12_DEC LEAKS13_DEC LEAKS14_DEC LEAKS15_DEC;

	if ACCYN eq 1 then 
		do;
			ACCBMYN		=	ACCYN;
			ACCBMYNC	=	ACCYN_DEC;
			do i = 1 to 15;
				EVENTNUM	=   i;
				DIATM		=	TIME_VAR[i];
				AMOUNT		=	AMNT_N[i];
				AMOUNTC		=	AMNT_C[i];
				SENSAT		=	SENS_N[i];
				SENSATC		=	SENS_C[i];
				if DIATM ne . then output;
			end;
		end;
	else if ACCYN eq 2 then 
		do;
			ACCBMYN		=	ACCYN;
			ACCBMYNC	=	ACCYN_DEC;
			call missing(DIATM,AMOUNT,AMOUNTC,SENSAT,SENSATC,EVENTNUM);
			output;
		end;
run;
	
data DIA2;
	length USUBJID AVISIT PARCAT1 PERIODC DIADAYC ACCBMYNC AMOUNTC SENSATC $200.; 
	set RAW.DIARY (encoding=any rename=(BSC= BSC_OLD));
	where PAGENAME eq "14 Day Diary - Bowel Movements" ;
	format _all_;  
	
	USUBJID 	=  'DIFI-22-01-' || strip(put(SITENUM,best.)) || '-' || strip(SUBNUM);
	AVISIT		=	strip(VISNAME);
	AVISITN		= 	VISITID;
	PARCAT1		=	PAGENAME;
	PERIOD		=	MOVPRD;
	PERIODC 	=   MOVPRD_DEC;
	DIADAY		=	MOVDDAY;
	DIADAYC		=	MOVDDAY_DEC;
	ADT			=	MOVDAT;	
	
	array TIME_VAR  [15] 	MOVTIM 		MOVTIM2 	MOVTIM3 	MOVTIM4 	MOVTIM5 
							MOVTIM6 	MOVTIM7 	MOVTIM8 	MOVTIM9 	MOVTIM10 
							MOVTIM11 	MOVTIM12 	MOVTIM13 	MOVTIM14  	MOVTIM15;

	array RES_N   [15]  	BSC_OLD     BSC2      	BSC3      	BSC4      	BSC5      
							BSC6 		BSC7 		BSC8 		BSC9 		BSC10 
							BSC11 		BSC12 		BSC13 		BSC14 		BSC15;

	if MOVYN eq 1 then 
		do;
			ACCBMYN		=	MOVYN;
			ACCBMYNC	=	MOVYN_DEC;
			do i = 1 to 15;
				EVENTNUM	=   i;
				DIATM		=	TIME_VAR[i];
				BSC			=	RES_N[i];
				if DIATM ne . then output;
			end;
		end;
	else if MOVYN eq 2 then 
		do;
			ACCBMYN		=	MOVYN;
			ACCBMYNC	=	MOVYN_DEC;
			call missing(DIATM,AMOUNT,AMOUNTC,SENSAT,SENSATC,EVENTNUM);
			output;
		end;
run;

data DIA3;
	set DIA1 DIA2;

proc sort;
	by USUBJID PARCAT1 AVISITN ADT diadayc;
run;
	
proc sql;
    create table DIA4 as
    select distinct USUBJID, PARCAT1, AVISITN, ADT,DIADAYC, count(*) as SUMEVENT
    from DIA3
    group by USUBJID, PARCAT1, AVISITN, ADT,DIADAYC;
quit;

data DIA5;
    merge DIA3(in=a) DIA4;
    by USUBJID PARCAT1 AVISITN ADT DIADAYC ;
run;
proc sort data=DIA5 OUT=DIA5_;
    by USUBJID PARCAT1 AVISITN ADT DIADAYC EVENTNUM;
	
run;	
   DATA dia5;SET DIA5_; by USUBJID PARCAT1 AVISITN ADT DIADAYC EVENTNUM;
if first.DIADAYC and ACCBMYN eq 1 then SUMEVENT = SUMEVENT;
	else if  ACCBMYN  eq 2 then SUMEVENT = 0;
	else SUMEVENT = .;
proc sort data=DIA5; 
  	by USUBJID; 
run; 

*===============================================================================
* 2. Merge together.    
*===============================================================================;
data DIA6;
	label 
		USUBJID='Unique Subject Identifier'                 
		TRTP='Planned Treatment'                        
		TRTPN='Planned Treatment (N)'                    
		TRTA='Actual Treatment'                          
		TRTAN='Actual Treatment (N)'                      
		PARCAT1='Category'                                  
		AVISITN='Visit (N)'                                 
		AVISIT='Visit'                                     
		PERIOD='Diary Period (N)'                          
		PERIODC='Diary Period'                              
		ACCBMYN='Did you have any bowel accidents today Y/N'                                                                                                               
		ACCBMYNC='Did you have any bowel accidents today'   
		ADT='Event Date'                                
		ADY='Event RelDay'                              
		DIADAY='Diary Day'                                 
		DIADAYC='Diary Day (display value)'                 
		EVENTNUM='Event Number'                             
		DIATM='Diary Time'                                
		AMOUNT='Amount (N)'                                
		AMOUNTC='Amount'                                   
		SENSAT='Sensation before Leakage (N) '             
		SENSATC='Sensation before Leakage'                  
		SUMEVENT='Sum of Event';
	format ADT  E8601DA. DIATM  TIME5. ;
	merge DIA5 (in=a) ads.adsl (in=b keep=&keyvars trt: cstper); 
	by USUBJID;
	if a and b;  
   
   	TRTP 	= TRT01P;
	TRTPN 	= TRT01PN; 
 	TRTA 	= TRT01A;  
	TRTAN 	= TRT01AN;
	 
    if n(ADT,BIODT)=2 then ADY=(ADT-BIODT)+(ADT>=BIODT);  	

	keep USUBJID SUBJID TRTP TRTA TRTPN TRTAN TRTSDT TRTSDTC 
		 ITTFL PARCAT1 AVISITN AVISIT PERIOD PERIODC ACCBMYN 
		 ACCBMYNC ADT ADY DIADAY DIADAYC DIATM EVENTNUM AMOUNT
		 AMOUNTC SENSAT SENSATC BSC SUMEVENT;
run;

proc sql noprint;
	alter table DIA6 
	modify 
		USUBJID char (35), 
		PARCAT1 char (100), 
		AVISIT char (50), 
		PERIODC char (19), 
		ACCBMYNC char (3),
		ADT nUM(8), 
		DIADAYC char(6),
		AMOUNTC char(19) , SENSATC char(14)
	;
quit;

proc sort; by USUBJID PARCAT1 AVISITN diaday eventnum PERIOD ADT;run;

proc sort data=ads.addiary out=diary; by USUBJID PARCAT1 AVISITN diaday eventnum PERIOD ADT;run;
*============================================================================================================;
* compare
*============================================================================================================;

ods listing;
proc compare base=diary  compare=dia6  listall;
run; 
	
