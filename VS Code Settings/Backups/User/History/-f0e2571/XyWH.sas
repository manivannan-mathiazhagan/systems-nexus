
/****************************************************************************/
* STUDY         :  FERAHEME AS A MAGNETIC RESONANCE IMAGING (MRI) 
* PROTOCOL      :  FER-021-003
* PROGRAM       :  RS.SAS
* CREATED BY    :  Vamsi Areddula
* DATE CREATED  :  31May2024
* DESCRIPTION   :  PROGRAM FOR SDTM - RS DOMAIN
******************************************************************************;

***********DELETING THE DATASETS, LOGS AND OUTPUTS FROM WORK LIBRARY *********;

proc datasets memtype = data lib=work kill noprint; quit;
dm 'log;clear; output;clear;';

/**/
/*data RS ;*/
/*LENGTH STUDYID USUBJID RSTEST RSCAT RSORRES RSNAM RSEVAL RSEVALID $200. VISITNUM 8. VISIT $200. RSDTC $200. ;*/
/*infile "E:\Projects\Covis Pharma\Feraheme Imaging Primary\External Data\IE Technical Evaluation\v20230111_AP001\20230111_AP001_RS.CSV"*/
/*dlm="|" dsd FIRSTOBS=2  encoding="utf-8";*/
/**/
/*DOMAIN="RS";*/
/*USUBJID=SUBJID;*/
/*INPUT STUDYID $ SUBJID $ RSTEST $ RSCAT $ RSORRES $ RSNAM $ RSEVAL $ RSEVALID $ VISITNUM VISIT $ RSDTC $  ;*/
/**/
/*run;*/

data RS_0;
set raw.rs;
SUBJID=USUBJID;
rename
rsdtc=rst;
drop USUBJID STUDYID;
Run;

 

data RS_1;
LENGTH STUDYID $11. RSTESTCD $200. RSSCAT $200. RSTEST  $200. USUBJID $18.   ;
set RS_0;
Domain="RS";
STUDYID="FER-021-003";
USUBJID=catx('-',STUDYID,SUBJID);

if RSTEST ="Assessment Summary Comments" then do; RSTESTCD="SUMMARY"; RSSCAT="CQA"; RSTEST="Assessment Summary Comments"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Appearance of Normal Anatomy" then do; RSTESTCD="ANATOM"; RSSCAT="CQA"; RSTEST="Appearance of Normal Anatomy"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Border Delineation" then do; RSTESTCD="BORDEL"; RSSCAT="CQA"; RSTEST="Border Delineation"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Dural Thickening" then do; RSTESTCD="DUTHIC"; RSSCAT="CQA"; RSTEST="Dural Thickening"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Intensity of Enhancement" then do; RSTESTCD="INTENHAN"; RSSCAT="CQA"; RSTEST="Intensity of Enhancement"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Pattern of Enhancement" then do; RSTESTCD="PATTENH"; RSSCAT="CQA"; RSTEST="Pattern of Enhancement"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Presence of Artifacts" then do; RSTESTCD="PART"; RSSCAT="CQA"; RSTEST="Presence of Artifacts"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Rating of Overall Sameness" then do; RSTESTCD="RATE"; RSSCAT="CQA"; RSTEST="Rating of Overall Sameness"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Rim Enhancement" then do; RSTESTCD="RIMENH"; RSSCAT="CQA"; RSTEST="Rim Enhancement"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Size of Enhancing Lesions" then do; RSTESTCD="SIZELE"; RSSCAT="CQA"; RSTEST="Size of Enhancing Lesions"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Types of Artifacts" then do; RSTESTCD="TYPART"; RSSCAT="CQA"; RSTEST="Types of Artifacts"; end;
if RSTEST ="Combined Post-FMX/GBCA Qualitative Assessments - Which MRI is the FMX MRI?" then do; RSTESTCD="FMXMRI"; RSSCAT="CQA"; RSTEST="Which MRI is the FMX MRI?"; end;
if RSTEST ="Earliest Exam Date" then do; RSTESTCD="EXAMDT"; RSSCAT="CQA"; RSTEST="Earliest Exam Date"; end;
if RSTEST ="Image Quality - Comments on Image Quality" then do; RSTESTCD="IMQUALC"; RSSCAT="CQA"; RSTEST="Image Quality - Comments"; end;
if RSTEST ="Image Quality - Image Quality Evaluation" then do; RSTESTCD="IMQEVAL"; RSSCAT="CQA"; RSTEST="Image Quality - Image Quality Evaluation"; end;
if RSTEST ="Latest Exam Date" then do; RSTESTCD="LATDT"; RSSCAT="CQA"; RSTEST="Latest Exam Date"; end;
if RSTEST ="Lesion Count" then do; RSTESTCD="LESCNT"; RSSCAT="CQA"; RSTEST="Lesion Count"; end;
if RSTEST ="MRI SET 3-Lesion Count" then do; RSTESTCD="LESCNT"; RSSCAT="MS3 Technical Evaluation"; RSTEST="Lesion Count"; end;
if RSTEST ="MRI SET 3-Technical Evaluation - MRI SET 3-Effect of Presence of Artifacts on Evaluation" then do; RSTESTCD="PARTE"; RSSCAT="MS3 Technical Evaluation"; RSTEST="Effect Presence of Artifacts Evaluation"; end;
if RSTEST ="MRI SET 3-Technical Evaluation - MRI SET 3-Evaluability of Image Set" then do; RSTESTCD="EVALS"; RSSCAT="MS3 Technical Evaluation"; RSTEST="Evaluability of Image Set"; end;
if RSTEST ="MRI SET 3-Technical Evaluation - MRI SET 3-Presence of Artifacts" then do; RSTESTCD="PART"; RSSCAT="MS3 Technical Evaluation"; RSTEST="Presence of Artifacts"; end;
if RSTEST ="MRI SET 3-Technical Evaluation - MRI SET 3-Reason Evaluability of Image Set is Not evaluable" then do; RSTESTCD="EREAS"; RSSCAT="MS3 Technical Evaluation"; RSTEST="Reason Evaluability of Image Set is NE"; end;
if RSTEST ="MRI SET 4-Lesion Count" then do; RSTESTCD="LESCNT"; RSSCAT="MS4 Technical Evaluation"; RSTEST="Lesion Count"; end;
if RSTEST ="MRI SET 4-Technical Evaluation - MRI SET 4-Effect of Presence of Artifacts on Evaluation" then do; RSTESTCD="PARTE"; RSSCAT="MS4 Technical Evaluation"; RSTEST="Effect Presence of Artifacts Evaluation"; end;
if RSTEST ="MRI SET 4-Technical Evaluation - MRI SET 4-Evaluability of Image Set" then do; RSTESTCD="EVALS"; RSSCAT="MS4 Technical Evaluation"; RSTEST="Evaluability of Image Set"; end;
if RSTEST ="MRI SET 4-Technical Evaluation - MRI SET 4-Presence of Artifacts" then do; RSTESTCD="PART"; RSSCAT="MS4 Technical Evaluation"; RSTEST="Presence of Artifacts"; end;
if RSTEST ="MRI SET 4-Technical Evaluation - MRI SET 4-Reason Evaluability of Image Set is Not evaluable" then do; RSTESTCD="EREAS"; RSSCAT="MS4 Technical Evaluation"; RSTEST="Reason Evaluability of Image Set is NE"; end;
if RSTEST ="Technical Evaluation - Effect of Presence of Artifacts on Evaluation" then do; RSTESTCD="PARTE"; RSSCAT="Technical Evaluation"; RSTEST="Effect Presence of Artifacts Evaluation"; end;
if RSTEST ="Technical Evaluation - Evaluability of Image Set" then do; RSTESTCD="EVALS"; RSSCAT="Technical Evaluation"; RSTEST="Evaluability of Image Set"; end;
if RSTEST ="Technical Evaluation - Presence of Artifacts" then do; RSTESTCD="PART"; RSSCAT="Technical Evaluation"; RSTEST="Presence of Artifacts"; end;
if RSTEST ="Technical Evaluation - Reason Evaluability of Image Set is Not evaluable" then do; RSTESTCD="EREAS"; RSSCAT="Technical Evaluation"; RSTEST="Reason Evaluability of Image Set is NE"; end;

if rst ne . then rsdtc=put(rst,yymmdd10.) ;

drop SUBJID;
run;

proc sort data=RS_1 ;
by usubjid ;
run;

data RS_2 ;
length studyid domain $200.;
merge sdtm.dm(in=a) RS_1(in=b) ;
by usubjid ;
if a ;

rsstresc = strip(rsorres);
run;


proc sort data=RS_2 out=RS_2_1;
by usubjid visitnum rsevalid rstestcd rsdtc;
Run;

*-------------------------------------creating baseline falgs------------------------------*;

data rs_flag;
 set RS_2_1;  
  if rsdtc ne "" and rfstdtc ne "" and rsstresc ne ""  and rsdtc le rfstdtc ;
run;

proc sort data=rs_flag;
by usubjid visitnum rsevalid rstestcd rsdtc;
run;

data rs_flag2;
 set rs_flag;
/*by studyid usubjid rscat rsscat rstestcd rstest rst rsevalid visitnum;*/
 	by usubjid visitnum rsevalid rstestcd rsdtc;
  rslobxfl = "Y";
  if last.rstestcd;
  if rslobxfl ne "" then rsblfl = strip(rslobxfl);
run;


proc sort data=rs_flag2 nodupkey;
by usubjid visitnum rsevalid rstestcd rsdtc;
run;

data RS_2_2;
 merge RS_2_1(in=a) rs_flag2(drop=rfstdtc);
by usubjid visitnum rsevalid rstestcd rsdtc;
if a;

	epoch   = "TREATMENT";

run;


data RS_2_3;
	set RS_2_2;

*RSDY;

     if rsdtc ne "" then rsdtcn = input(substr(rsdtc,1,10),is8601da.);
     if rfstdtc ne "" then rfstdn = input(substr(rfstdtc,1,10),??is8601da.);

     if rsdtcn ne . and rfstdn ne . then do;
     	if rsdtcn>=rfstdn then rsdy = (rsdtcn-rfstdn)+1;
      		else if rsdtcn<rfstdn then rsdy = (rsdtcn-rfstdn);
   	 end;

run;

proc sort data=RS_2_3;by studyid usubjid rscat rsscat rstestcd rstest rst rsevalid visitnum;run;

data RS_3;
set RS_2_3 ;
by studyid usubjid rscat rsscat rstestcd rstest rst rsevalid visitnum;
if first.usubjid then RSSEQ=1 ;
else RSSEQ +1 ;
run;


data rs;
retain STUDYID DOMAIN USUBJID RSSEQ RSTESTCD RSTEST RSCAT RSSCAT RSORRES RSNAM RSEVAL RSEVALID VISITNUM VISIT RSDTC;
set RS_3;
drop rst ;
Run;

dm log 'LOG; FILE "&DROOT&DBPATH\LOGS\RS.LOG" REPLACE' log;

*-------------------------------------END OF PROGRAM-------------------------*; 
