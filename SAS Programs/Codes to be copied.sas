/* 1) init.sas */
%include "&proot\study_formats.sas";

*** assign logchk flag variables ***;
%global uerr uwarn unote;
%let uerr  = %quote(USER_ERR:) ;
%let uwarn = %quote(USER_WARN:) ;
%let unote = %quote(USER_NOTE:) ;

/*Assigning Gdoc Key for SDTM Specs and ADaM specs as a macro variable for using it in all programs*/
%let sdtm_specs_gdoc_key=1ZfCOFaXYfR5mHRRiClr5lywsBcijl7cFo3mBnO-4QuE;

%let adam_specs_gdoc_key=1vj-hvmHfwSxS5cZJalYL-YUNrageA5rQQOO6tdEUsM4;

%global random rawlib sdtmlib adamlib logroot ;  

%if &unblinded %then 
    %do;
        %let random  = UNBLIND;
        %let rawlib  = URAW;
        %let sdtmlib = USDTM;
        %let adamlib = UADAM;
        %let logroot = &udroot.;
     %end;
%else
    %do;
        %let random  = BLIND;
        %let rawlib  = RAW;
        %let sdtmlib = SDTM;
        %let adamlib = ADAM;
        %let logroot = &droot.;
     %end;


%put &RANDOM. &RAWLIB. &SDTMLIB. &ADAMLIB. &LOGROOT.; 
 
 
/* 2) Study Formats.sas */

/* Importing the QC_FORMATS sheet where formats values are added */
%macro Create_format(dev,gkey,DEVQC);
    
%imp_gdoc(gdoc_key=&gkey., outlib=work,sheet=&DEVQC._FORMATS); 

/* Generating formats from GDOC inputs */
proc sort data = &DEVQC._FORMATS OUT=&DEVQC._&dev._FMT(keep = FMTNAME START LABEL TYPE)  nodupkey; 
     by FMTNAME TYPE START LABEL; 
run; 

proc format cntlin= &DEVQC._&dev._FMT library=WORK;  
run;  
quit;

%mend;
 
/*Validation formats*/ 
%Create_format(SDTM,&sdtm_specs_gdoc_key,QC);
%Create_format(ADAM,&adam_specs_gdoc_key,QC);

/* 3) SDTM Validation Runall */
%global SDTM_VERSN DROOT_PROJ;
%let SDTM_VERSN=%str(3.3);

%let DROOT_PROJ=%qsubstr(&droot,1,%eval(%length(&droot) - %length(%qscan(&droot,-1,\)) -1));