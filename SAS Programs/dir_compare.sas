***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    dir_compare.sas                                                                  ***;
***                                                                                                 ***;
*** Purpose:       compare datasets in Comp directory with datasets in Base directory               ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    11Mar2022                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name        | Description                                         | Default value   | Required  ***;
***             |                                                     |                 | Parameter ***;
*** ------------|-----------------------------------------------------|-----------------|-----------***;
*** BASEFOLDER  | Base folder path                                    | No default      |   Yes     ***;
***             |                                                     |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** COMPFOLDER  | Comp folder path                                    | No default      |   Yes     ***;
***             |                                                     |                 |           ***;
*** ------------|-----------------------------------------------------|-----------------|-----------***;
*** BASEEXCL    | List of data to be EXCLUDED from Base folder        | No default      |   No      ***;
***             | for comparison                                      |                 |           ***;
*** ------------|-----------------------------------------------------|-----------------|-----------***;
*** COMPEXCL    | List of data to be EXCLUDED from Comp folder        | No default      |   No      ***;
***             | for comparison                                      |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** CRITLIST1   | List of data to be compared using                   | No default      |   No      ***;
***             | criterion=criterion1                                |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** CRITLIST1   | Criterion for data in critlist1                     | No default      |   No      ***;
***             |                                                     |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** CRITLIST2   | List of data to be compared using                   | No default      |   No      ***;
***             | criterion=criterion2                                |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** CRITLIST2   | Criterion for data in critlist2                     | No default      |   No      ***;
***             |                                                     |                 |           ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** SHOWTIME    | Show timestamp of BASE and COMP datasets when = Y   | No default      |   No      ***;
***             |                                                     |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Variables:          None                                                                        ***;
***                                                                                                 ***;
*** Other:              The Macro will create a File named Base_Compare_dataset_compare_timestamp   ***;
***                     within the compfolder as a PDF                                              ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             None                                                                        ***;
***                                                                                                 ***;
*** Other:              None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%macro dir_compare(basefolder=, compfolder=, 
                   baseexcl=, compexcl=,
                   critlist1=, criterion1=, 
                   critlist2=, criterion2=,
                   showtime=);
 
/* Assigning Libraries for both folders passed */
libname comp "&compfolder";
libname base "&basefolder";

/* Checking whether the directory Exists */
%macro chk_dir(dir) ; 
    %global direxist;
    %local rc fileref ; 
    
    %let rc = %sysfunc(filename(fileref,&dir)) ; 
    %if %sysfunc(fexist(&fileref)) %then 
        %do;
            %put NOTE: The directory exists: &dir  ; 
            %let direxist = Y;
        %end;
    %else 
        %do ;        
            %let direxist = N; 
            %put %sysfunc(sysmsg()) The directory does not exist: &dir. ; 
        %end ; 
        
   %let rc=%sysfunc(filename(fileref)) ; 
%mend chk_dir ;

    %chk_dir(&basefolder);

    %if &direxist = N %then %do; 
    	%goto exitpgm;
    %end;
    %chk_dir(&compfolder);
    %if &direxist = N %then %do; 
    	%goto exitpgm;
    %end;

/* Checking Dataset names in BASE */
proc sql ;
select distinct(memname) into: dslist 
from dictionary.tables
where libname='BASE'
;
quit;

%put &dslist;

%let TOT_DS =&SQLOBS.;

%if &sqlobs = 0 %then %do;
    %put ER-ROR: [DIR_COMPARE] There are datasets to compare in BASE directory: &basefolder.; 
    %goto exitpgm;
%end;

/* Checking Dataset names in COMP */
proc sql ;
select distinct(memname) into: dslist 
from dictionary.tables
where libname='COMP'
;
quit;

%put &dslist;

%if &sqlobs = 0 %then %do;
    %put ER-ROR: [DIR_COMPARE] There are datasets to compare in COMP directory: &compfolder.; 
    %goto exitpgm;
%end;


%let baseexcl=%sysfunc(upcase(&baseexcl));
%let compexcl=%sysfunc(upcase(&compexcl));
%let critlist1=%sysfunc(upcase(&critlist1));
%let critlist2=%sysfunc(upcase(&critlist2));
%put ****************: &critlist1 &critlist2 &baseexcl &compexcl;

proc contents data=base._all_ out=base(keep=memname) noprint;
run;

proc sort data=base nodupkey;
    by memname;
    where not (findw(symget('baseexcl'),strip(memname)) or findw(symget('compexcl'),strip(memname)));
run;

proc contents data=comp._all_ out=comp(keep=memname) noprint;
run;

proc sort data=comp nodupkey;
    by memname;
    where not (findw(symget('baseexcl'),strip(memname)) or findw(symget('compexcl'),strip(memname)));
run;

data notinab(keep=dataset sysinfo SYSINFO_CODES) inboth;
    merge base(in=a) comp(in=b);
    by memname;
    length ina inb $100 SYSINFO_CODES $200 dataset $50;
    if a and not b then ina='Data '||strip(memname)||' in BASE but not in COMP directory';
    else ina='';
    if b and not a then inb='Data '||strip(memname)||' in COMP but not in BASE directory';
    else inb='';
    if ina^=' ' or inb^=' ' then do;
        dataset=' ';
        sysinfo=.;
        SYSINFO_CODES=left(ina||inb);
        output notinab;
    end;
    else output inboth;
run;

data crit0 crit1 crit2;
    set inboth;
    if findw(symget('critlist1'),strip(memname)) then output crit1;
    else if findw(symget('critlist2'),strip(memname)) then output crit2;
    else output crit0;
run;

proc sql;
    create table syscodes
    (DATASET char(50), SYSINFO num, SYSINFO_CODES char(200), modate char(80), critn num);
quit;

%macro docrit(dset, critix);
proc sql ;
    select distinct(memname) into: dslist separated by ' ' 
    from &dset;
quit;

%put &dslist &critix;
%do i=1 %to &sqlobs;
    %let dsn=%scan(&dslist,&i,%str( ));

    proc compare base=base.&dsn comp=comp.&dsn noprint criterion=&critix;
    run;

    %let dsida=%sysfunc(open(base.&dsn));
    %let dsidb=%sysfunc(open(comp.&dsn));
     %let modtea=%sysfunc(attrn(&dsida,modte),datetime20.);
     %let modteb=%sysfunc(attrn(&dsidb,modte),datetime20.);

     %put &modtea &modteb;

    %if &modtea eq &modteb %then %do;
        %LET modate=;
    %end;
    %else %do;
        %if &showtime=Y %then %let modate=%str(Base=&modtea  Comp=&modteb);
        %else %let modate=Y;
    %end;

    %put &modate;

%let criterion=&critix;
%let sicode=&sysinfo;
%let dsname=&dsn;

data _null_;
    length decoded $ 600 text $200;
    array msg {17} $ 200 _temporary_ (
    " ",
    "Data set labels differ",
    "Data set types differ",
    "Variable has different informat",
    "Variable has different format",
    "Variable has different length",
    "Variable has different label",
    "BASE data set has observation not in COMP",
    "COMP data set has observation not in BASE",
    "BASE data set has BY group not in COMP",
    "COMP data set has BY group not in BASE",
    "BASE data set has variable not in COMP",
    "COMP data set has variable not in BASE",
    "A value comparison was unequal",
    "Conflicting variable types",
    "BY variables do not match",
    "Fatal er-ror: comparison not done"
    );
    testcode=&sicode;
    if testcode=0 then 
        decoded="NO DIFFERENCE BETWEEN BASE & COMP"; 
    else do;
    decoded=" "; 
        do k=1 to 16; 
        binval=2**(k-1); 
        match=band(binval, testcode); 
        key=sign(match)*k; 
        text=msg(key+1); 
        decoded=catx(" ^n - ",decoded,text); 
*        output;
        end;
    end;
        call symputx("message", decoded);
run;

proc sql;
    insert into syscodes values("&dsname.",&sicode.,"&message.", "&modate.", &criterion.);
quit;
%end;
/*    %let qida=%sysfunc(close(&dsida));*/
/*    %let qidb=%sysfunc(close(&dsidb));*/
%mend;

%if &critlist1 ne %then %do;
%docrit(crit1, &criterion1.);
%end;
%if &critlist2 ne %then %do;
%docrit(crit2, &criterion2.);
%end;
%docrit(crit0, 0);

data compare_report;
    set notinab syscodes;
    length critc $20 ;
    if critn in (., 1) then critc=' ';
    else critc=put(critn, best12.);
    seq=_n_;

    if sysinfo>0 then SYSINFO_CODES=' - '||SYSINFO_CODES;
run;

****Time Stamp Information ;
%global runtime rundate;
data _null_;
    length runtime $14;
    time = strip(put(time(),time5.));
    Timex = compress(time,':');
    runtime = strip(put(date(),date9.))||'T'||strip(put(timex,4.));
    rundate = put(date(),date9.);
    call symput('runtime',runtime);
    call symput ('rundate', rundate);
    call symput('time',time);
    run;
    %put &runtime &rundate &time;
 
goptions device=actximg;
options ls=135 ps=40;
ODS PDF FILE="&compfolder./Base_Comp_dataset_compare_&runtime..pdf";
ODS NOPROCTITLE;
ODS ESCAPECHAR='^';
options orientation=landscape;
options nonumber nodate;
*proc print data=compare_report noobs label;
*    var seq dataset critc MEANING_OF_SYSINFO_CODES modate ;

    proc report data=compare_report center headline missing nowindows split='@'
      style(report)={borderwidth=.5pt cellspacing=0pt cellpadding=0pt}
      style(header)={ protectspecialchars=off background=_undef_ };
      column seq dataset critc SYSINFO_CODES modate;

      define seq             / group "#" style(column)={cellwidth=10% just=c};
      define dataset         / display "Dataset" style(column)={cellwidth=10% just=l}; 
      define critc           / display "Criterion for Proc Compare" style(column)={cellwidth=10% just=l}; 
      define SYSINFO_CODES   / display "Comparison results for each dataset" style(column)={cellwidth=45% just=l}; 
      define modate          / display "Timestamp Mismatch" style(column)={cellwidth=20% just=l}; 

    title1 j=l "^S={font_size=8pt}Dataset(s) Comparisons Between BASE and COMP Directory" j=r 'Page ^{thispage} of ^{lastpage}';
    title2 j=l "^S={font_size=8pt}Base=&basefolder";
    title3 j=l "^S={font_size=8pt}Comp=&compfolder";

    %if &baseexcl eq and &compexcl eq %then %do;
        footnote1 j=l "^S={font_size=8pt}Output File=&compfolder.\Base_Comp_dataset_compare_&runtime..rtf";
    %end;
    %else %if &baseexcl eq and &compexcl ne %then %do; 
        footnote2 j=l "^S={font_size=8pt}Data excluded from Comp directory for comparison: &compexcl";
        footnote2 j=l "^S={font_size=8pt}Output File=&compfolder.\Base_Comp_dataset_compare_&runtime..rtf";
    %end;
    %else %if &baseexcl ne and &compexcl eq %then %do; 
        footnote1 j=l "^S={font_size=8pt}Data excluded from Base directory for comparison: &baseexcl";
        footnote2 j=l "^S={font_size=8pt}Output File=&compfolder.\Base_Comp_dataset_compare_&runtime..rtf";
    %end;
    %else %do;
        footnote1 j=l "^S={font_size=8pt}Data excluded from Base directory for comparison: &baseexcl";
        footnote2 j=l "^S={font_size=8pt}Data excluded from Comp directory for comparison: &compexcl";
        footnote3 j=l "^S={font_size=8pt}Output File=&compfolder.\Base_Comp_dataset_compare_&runtime..rtf";
    %end;
run;

%do i=1 %to &TOT_DS;
    %let dsn=%scan(&dslist,&i,%str( ));
title; footnote;
    proc compare base=base.&dsn comp=comp.&dsn novalues criterion=0;
    run;
%end;

ODS PDF CLOSE;

***Get rid of:;
*** ER-ROR: Unable to clear or re-assign the library COMP because it is still in use.;
*** ER-ROR: Er-ror in the LIBNAME statement.;
title;
footnote;
%macro close_all_dsid;
  %local i rc;
  %do i=1 %to 1000;
    %let rc=%sysfunc(close(&i));
  %end;
%mend;
%close_all_dsid;

libname base clear;
libname comp clear;

**exit the program;
%exitpgm: 
%put [logchk] Exiting logchk macro;


%mend dir_compare;

options mlogic mprint symbolgen;
%dir_compare(basefolder =P:\LegacyInstat_Projects\Paidion\Siolta STMC-103H-102\SASDATA\raw_v20251009\sdtm_v20251113\adam_v20251113, 
            compfolder =P:\LegacyInstat_Projects\Paidion\Siolta STMC-103H-102\SASDATA\raw_v20251215\sdtm_v20251215\adam_v20251215,
            baseexcl=%str(),     
            compexcl=%str(),     
            critlist1=%str(), 
            criterion1=,
            critlist2=%str(), 
            criterion2=,
            showtime=Y); 


