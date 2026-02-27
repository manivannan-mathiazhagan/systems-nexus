/****************************************************************************/
* STUDY			:  FERAHEME AS A MAGNETIC RESONANCE IMAGING (MRI) 
* PROTOCOL		:  FER-021-003
* PROGRAM		:  AE.SAS
* CREATED BY	:  Delli karthikeyan
* DATE CREATED	:  31May2022
* DESCRIPTION	:  PROGRAM FOR SDTM - AE DOMAIN
******************************************************************************;

***********DELETING THE DATASETS, LOGS AND OUTPUTS FROM WORK LIBRARY *********;
proc datasets memtype=data lib=work kill noprint;
quit;

dm 'log;clear; output;clear;';
options validvarname=upcase;

proc format;
    value gr 1="MILD" 2="MODERATE" 3="SEVERE" 4="SEVERE" 5="SEVERE" ;
run;

proc format;
    value $tgr "1"="UNRELATED" "2"="UNLIKELY" "3"="POSSIBLY" "4"="PROBABLY"
        "5"="DEFINITELY" other="*" ;
run;

data ae_1;
    set raw.Pt_characteristics_and_ae_data;
    studyid="FER-021-003";
    subjid=substr(study_id,7,12);
    domain="AE";
    usubjid=catx('-',studyid,subjid);
    usubjid=strip(studyid)||"-"||strip(subjid);
    aeterm=upcase(strip(toxicity_event));
    aecat=upcase(strip(category_of_toxicity)); /*Category of Toxicity*/
    aellt="";
    aelltcd=.;
    aedecod="";
    aeptcd=.;
    aeacn="";
    aeser="";
    aehlt="";
    aehltcd=.;
    aehlgt="";
    aehlgtcd=.;
    aebodsys="";
    aebdsycd=.;
    aesoc="";
    aesoccd=.;
    aeendtc="";
    aeendy=.;

    if grade_of_toxicity ne . then
        aesev=strip(put(grade_of_toxicity,gr.));/*Grade of Toxicity*/
    if grade_of_toxicity=4 then aeslife="Y";
    if grade_of_toxicity=5 then aesdth="Y";

    if date_of_toxicity ne . then
        aestdtc=strip(put(date_of_toxicity,yymmdd10.)); /*Date of Toxicity*/
    aerel=strip(put(attribute_of_toxicity,tgr.));

    if aestdtc ne "" then aestn=input(aestdtc,yymmdd10.) ;

    ndfeiae1=strip(put(number_of_days_after_fe_injectio,best.)) ;
    /*NDPE=NUMBER_DAYS_POST_FE;*/
    /*CTCAE=CTCAE_VERSION;*/
    /*AEENDTC=strip(aestdtc); */
    if upcase(aeterm)="NONE" then delete ;
    drop number_of_days_after_fe_injectio;
    rename ndfeiae1=ndfeiae ;
run;

proc sort data=ae_1;
    by usubjid aestn aeterm;
run;

proc sort data=sdtm.dm out=dm(keep=usubjid rfstdtc);
    by usubjid;
run;

data ae1;
    merge ae_1(in=a) dm;
    by usubjid;

    if a;

    epoch="TREATMENT";

    /*Study day calculation*/
    if rfstdtc ne ' ' then rfstdtn=input(rfstdtc,yymmdd10.);

    if length(aestdtc)=10 then sdt=input(aestdtc,yymmdd10.);
    else if length(aestdtc)> 10 then sdt=input(scan(aestdtc,1,'T'),yymmdd10.);

    if nmiss(sdt,rfstdtn)=0 then do;
        if sdt >= rfstdtn then aestdy=sdt-rfstdtn+1;
        else aestdy=sdt-rfstdtn;
    end;

    /*Sequence derivation*/
    if first.usubjid then aeseq=1;
    else aeseq+1;

run;

/*data ae2;*/
/*	set ae1;*/
/*keep studyid subjid domain usubjid aeterm aecat aesev aeser aestdtc aerel aeseq aeslife aesdth NDPE CTCAE AEENDTC;*/
/*run;*/
/**/
/*%derive_dy(ae2,aeday,ae);*/
/**/
/*%get_seq(aeday,usubjid AESTN aeterm,ae);*/
dm log 'LOG; FILE "&DROOT&DBPATH\LOGS\AE.LOG" REPLACE' log;

************************************END OF PROGRAM****************************;
