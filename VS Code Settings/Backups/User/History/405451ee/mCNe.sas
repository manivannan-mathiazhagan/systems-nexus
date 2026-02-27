dm "log;clear;lst;clear";
************************************************************************************;
* PROGRAM:     P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\qt-14-1-7-br.sas
* DATE:        1/21/2025 
* PROGRAMMER:  v emile
*
* PURPOSE:     tissue procurement
*              (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*  PROGRAMMER:  
*  DATE:       
*  PURPOSE:    
*************************************************************************************;
%let pgm=t-14-1-7-br;
%let pgmnum=14.1.7; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-'));
%let protdir=&difi2201dsmb;  

%include "&protdir\macros\m-setup.sas" ;

data ADSL_all;
    set ADS.ADSL;
    where ITTFL='Y'; 

	TRT=TRT01PN;
	output; 

	TRT = 3;
	output;  
run;

proc freq data=ADSL_ALL noprint;
    tables TRT/list out=BIGN(keep = TRT COUNT rename = (COUNT=TOTN));   
run;

/*Generating a BASE dataset for appending with same attributes*/
data TABDATA;
   length ROW 8. FORMAL $200 STAT $15 COL1 COL2 COL3  $20;
    ROW     	= .; 
    FORMAL      = "";
    STAT      	= "";
    COL1      	= "";
    COL2      	= ""; 
	COL3 		= "";
    stop;
run;

%macro FREQ_TAB(WHR_COND=, RW_NUM=, RW_TXT1=, RW_TXT2=%bquote(N(%)), DEN_VAR=TOTN, INDST=ADBR_NEW, PCT=Y);

proc freq data = &INDST. noprint;
    tables TRT/out=FR_&RW_NUM.;
    where &whr_cond. ;
quit;

data FR_&RW_NUM._PERC;
    merge BIGN_1(IN=B) FR_&RW_NUM.(IN=A) ;
    by TRT;
    if b;
    COUNT = coalesce(COUNT,0);

    %if "&PCT." eq "Y" %then 
		%do;
		    if COUNT ne 0 then 
		        do;
		            PERC   = (COUNT/&den_var.)*100;
		            TEXT   = strip(put(COUNT,best5.))||' ('||strip(put(PERC,5.1))||')'; 
		        end;
		    else
		        do; 
		            TEXT   = strip(put(COUNT,best5.)); 
		        end; 
		%end;
	%else 
		%do;
			TEXT   = strip(put(COUNT,best5.)); 
		%end;
run;

proc transpose data = FR_&RW_NUM._PERC out = FR_TR_&RW_NUM.(drop=_NAME_) prefix=COL;
    id  TRT;
    var TEXT;
run;

data FR_OUT_&RW_NUM.;
    length ROW 8. FORMAL $200 STAT $15 COL1 COL2 COL3  $20;
    set FR_TR_&RW_NUM.;
		                                              
	ROW     	= &RW_NUM.; 
    FORMAL      = "&RW_TXT1.";
    STAT      	= "&RW_TXT2.";
run;

/* Appending with base */
proc append base=TABDATA data=FR_OUT_&RW_NUM. force;
run;

proc datasets lib=work nolist noprint;
    delete FR_OUT_&RW_NUM. FR_&RW_NUM. FR_TR_&RW_NUM.;
    quit;
run;
    
%mend FREQ_TAB;

%macro head_row	(RW_NUM=, RW_TXT1=);

data FR_OUT_&RW_NUM.;
    length ROW 8. FORMAL STAT COL1 COL2 COL3  $200.;

	ROW     	= &RW_NUM.; 
    FORMAL      = "&RW_TXT1.";
    STAT      	= "";
run;

/* Appending with base */
proc append base=TABDATA data=FR_OUT_&RW_NUM. force;
run;

proc datasets lib=work nolist noprint;
    delete FR_OUT_&RW_NUM. ;
    quit;
run;
%mend head_row;

data ADBR_ALL;
    set ADS.ADBR;
    where ITTFL='Y' and TRTPN ne .; 

	TRT=TRTPN;
	output; 

	TRT = 3;
	output;  
run;

data ALL_1_0(where =( PARAMN ne 1)) ALL_1_N (where =( PARAMN eq 1));
	set ADBR_ALL;
run;

proc sql noprint;
	create table BIO_CNT as 
	select distinct STUDYID,USUBJID,TRT,PARAMN,PARAMCD,sum(AVAL) as AVAL 
	from ALL_1_N group by 
	STUDYID,USUBJID,TRT,PARAMN,PARAMCD;
quit;

data ADBR_NEW;
	set ALL_1_0 BIO_CNT;
run;

proc sort data=ADBR_NEW;
	by TRT USUBJID PARAMN;
run;

proc freq data=ADBR_NEW noprint; 
	by TRT;
	where paramn eq 2 and avalc ne "";
	tables STUDYID / out=MUSC missing;  
run;  

data BIGN_1;
	merge BIGN MUSC(KEEP = TRT COUNT RENAME = (COUNT = MUSC)) ;
	by TRT;
run;

proc sort data=ADBR_NEW out=BIOS nodupkey;
	where adt ne .;
	by TRT USUBJID ;
run;

%FREQ_TAB(WHR_COND=PARAMN EQ 1, RW_NUM=1, RW_TXT1=%STR(Number of subjects with any biopsy), RW_TXT2=%bquote(N(%)), DEN_VAR=TOTN, INDST=ADBR_NEW, PCT=Y);

%FREQ_TAB(WHR_COND=PARAMN EQ 1, RW_NUM=2, RW_TXT1=%STR(Total number of biopsies [1]), RW_TXT2=%bquote(N), DEN_VAR=TOTN, INDST=ALL_1_N, PCT=N);

%FREQ_TAB(WHR_COND=PARAMN EQ 1 AND AVAL EQ 1, RW_NUM=3, RW_TXT1=%STR(Number of subjects with 1 biopsy), RW_TXT2=%bquote(N(%)), DEN_VAR=TOTN, INDST=ADBR_NEW, PCT=Y);
%FREQ_TAB(WHR_COND=PARAMN EQ 1 AND AVAL GT 1, RW_NUM=4, RW_TXT1=%STR(Number of subjects with repeated biopsies), RW_TXT2=%bquote(N(%)), DEN_VAR=TOTN, INDST=ADBR_NEW, PCT=Y);
%FREQ_TAB(WHR_COND=PARAMN EQ 1 AND AVAL EQ 2, RW_NUM=5, RW_TXT1=%STR(Number of subjects with 2 biopsies), RW_TXT2=%bquote(N(%)), DEN_VAR=TOTN, INDST=ADBR_NEW, PCT=Y);
%FREQ_TAB(WHR_COND=PARAMN EQ 1 AND AVAL EQ 3, RW_NUM=6, RW_TXT1=%STR(Number of subjects with 3 biopsies), RW_TXT2=%bquote(N(%)), DEN_VAR=TOTN, INDST=ADBR_NEW, PCT=Y);
%FREQ_TAB(WHR_COND=PARAMN EQ 1 AND AVAL EQ 4, RW_NUM=7, RW_TXT1=%STR(Number of subjects with 4 biopsies), 
RW_TXT2=%bquote(N(%)), DEN_VAR=TOTN, INDST=ADBR_NEW, PCT=Y);
%head_row	(RW_NUM=8, RW_TXT1=%str(Location of Muscle Biopsy [2]));
%FREQ_TAB(WHR_COND=PARAMN EQ 2 AND AVAL EQ 1, RW_NUM=9, RW_TXT1=%STR(Left vastus lateralis), 
RW_TXT2=%bquote(N(%)), DEN_VAR=MUSC, INDST=ADBR_NEW, PCT=Y);
%FREQ_TAB(WHR_COND=PARAMN EQ 2 AND AVAL EQ 2, RW_NUM=10, RW_TXT1=%STR(Right vastus lateralis), 
RW_TXT2=%bquote(N(%)), DEN_VAR=MUSC, INDST=ADBR_NEW, PCT=Y);

%head_row	(RW_NUM=11, RW_TXT1=%str(Muscle biopsy wound closed by [2]));
%FREQ_TAB(WHR_COND=PARAMN EQ 4 AND AVAL EQ 1, RW_NUM=12, RW_TXT1=%STR(Adhesive strips), 
RW_TXT2=%bquote(N(%)), DEN_VAR=MUSC, INDST=ADBR_NEW, PCT=Y);
%FREQ_TAB(WHR_COND=PARAMN EQ 5 AND AVAL EQ 1, RW_NUM=13, RW_TXT1=%STR(Sutures), 
RW_TXT2=%bquote(N(%)), DEN_VAR=MUSC, INDST=ADBR_NEW, PCT=Y);
%FREQ_TAB(WHR_COND=PARAMN EQ 6 AND AVAL EQ 1, RW_NUM=14, RW_TXT1=%STR(Other), 
RW_TXT2=%bquote(N(%)), DEN_VAR=MUSC, INDST=ADBR_NEW, PCT=Y);


proc sort data=tabdata out=final; 
	by row;;
run;  
data qc ;
retain   FORMAL stat counter col1 col2 col3;
set final; 
by row;

array ch _character_;
do over ch;
ch=compress(ch);
ch=upcase(ch);
end;
keep  fORMAL  stat  col1 col2 col3;
run; 

*proc print;run;
*libname qctab "P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\QC";
*proc print data=qctab.&pgmqc;run;

proc compare base=qctab.&pgmqc  compare=qc listall;
*id  formal;
run;
