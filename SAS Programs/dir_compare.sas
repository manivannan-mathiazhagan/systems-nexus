***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    dir_compare.sas                                                                  ***;
***                                                                                                 ***;
*** Purpose:       compare datasets in Comp directory with datasets in Base directory               ***;
***                 - HTML output only                                                              ***;
***                 - Exclude variables across all datasets                                         ***;
***                 - Highlight summary rows                                                        ***;
***-------------------------------------------------------------------------------------------------***;

%macro dir_compare(basefolder=, compfolder=, 
                   baseexcl=, compexcl=,
                   exclvars=,
                   critlist1=, criterion1=, 
                   critlist2=, criterion2=,
                   showtime=Y);
 
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
            %put NOTE: The directory exists: &dir ; 
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
%if &direxist = N %then %goto exitpgm;

%chk_dir(&compfolder);
%if &direxist = N %then %goto exitpgm;

/* Checking Dataset names in BASE */
proc sql noprint;
    select distinct(memname) into: dslist separated by ' '
    from dictionary.tables
    where libname='BASE';
quit;

%let TOT_DS =&SQLOBS.;

%if &sqlobs = 0 %then %do;
    %put ER-ROR: [DIR_COMPARE] There are no datasets to compare in BASE directory: &basefolder.; 
    %goto exitpgm;
%end;

/* Checking Dataset names in COMP */
proc sql noprint;
    select distinct(memname) into: dslist separated by ' '
    from dictionary.tables
    where libname='COMP';
quit;

%if &sqlobs = 0 %then %do;
    %put ER-ROR: [DIR_COMPARE] There are no datasets to compare in COMP directory: &compfolder.; 
    %goto exitpgm;
%end;

%let baseexcl=%sysfunc(upcase(%superq(baseexcl)));
%let compexcl=%sysfunc(upcase(%superq(compexcl)));
%let exclvars=%sysfunc(upcase(%superq(exclvars)));
%let critlist1=%sysfunc(upcase(%superq(critlist1)));
%let critlist2=%sysfunc(upcase(%superq(critlist2)));

%put ****************: &critlist1 &critlist2 &baseexcl &compexcl &exclvars;

proc contents data=base._all_ out=_base_mem(keep=memname) noprint;
run;

proc sort data=_base_mem nodupkey;
    by memname;
    where not (findw(symget('baseexcl'),strip(memname)) or findw(symget('compexcl'),strip(memname)));
run;

proc contents data=comp._all_ out=_comp_mem(keep=memname) noprint;
run;

proc sort data=_comp_mem nodupkey;
    by memname;
    where not (findw(symget('baseexcl'),strip(memname)) or findw(symget('compexcl'),strip(memname)));
run;

data notinab(keep=dataset sysinfo sysinfo_codes modate critn status) inboth;
    merge _base_mem(in=a) _comp_mem(in=b);
    by memname;
    length ina inb $100 sysinfo_codes $300 dataset $50 status $20 modate $80;
    if a and not b then ina='Data '||strip(memname)||' in BASE but not in COMP directory';
    else ina='';
    if b and not a then inb='Data '||strip(memname)||' in COMP but not in BASE directory';
    else inb='';
    if ina^=' ' or inb^=' ' then do;
        dataset=strip(memname);
        sysinfo=.;
        sysinfo_codes=left(catx(' ',ina,inb));
        critn=.;
        modate='';
        if a and not b then status='MISSING IN COMP';
        else if b and not a then status='MISSING IN BASE';
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
    (dataset char(50), status char(20), sysinfo num, sysinfo_codes char(600), modate char(80), critn num);
quit;

%macro docrit(dset, critix);
proc sql noprint;
    select distinct(memname) into: dslist separated by ' ' 
    from &dset;
quit;

%do i=1 %to &sqlobs;
    %let dsn=%scan(&dslist,&i,%str( ));

    %if %length(%superq(exclvars)) > 0 %then %do;
        proc compare base=base.&dsn(drop=&exclvars) comp=comp.&dsn(drop=&exclvars) noprint criterion=&critix;
        run;
    %end;
    %else %do;
        proc compare base=base.&dsn comp=comp.&dsn noprint criterion=&critix;
        run;
    %end;

    %let dsida=%sysfunc(open(base.&dsn));
    %let dsidb=%sysfunc(open(comp.&dsn));

    %if &dsida > 0 %then %let modtea=%sysfunc(attrn(&dsida,modte),datetime20.);
    %else %let modtea=;

    %if &dsidb > 0 %then %let modteb=%sysfunc(attrn(&dsidb,modte),datetime20.);
    %else %let modteb=;

    %if &dsida > 0 %then %let rc=%sysfunc(close(&dsida));
    %if &dsidb > 0 %then %let rc=%sysfunc(close(&dsidb));

    %if &modtea eq &modteb %then %do;
        %let modate=;
    %end;
    %else %do;
        %if %upcase(&showtime)=Y %then %let modate=%str(Base=&modtea  Comp=&modteb);
        %else %let modate=Y;
    %end;

    %let sicode=&sysinfo;
    %let dsname=&dsn;

    data _null_;
        length decoded $600 text $200 cmpstatus $20;
        array msg {17} $200 _temporary_ (
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
        if testcode=0 then do;
            decoded="NO DIFFERENCE BETWEEN BASE & COMP";
            cmpstatus='MATCH';
        end;
        else do;
            decoded=" "; 
            do k=1 to 16; 
                binval=2**(k-1); 
                match=band(binval, testcode); 
                key=sign(match)*k; 
                text=msg(key+1); 
                decoded=catx(" | ",decoded,text); 
            end;
            cmpstatus='DIFFERENCES';
        end;
        call symputx("message", decoded);
        call symputx("cmpstatus", cmpstatus);
    run;

    proc sql;
        insert into syscodes values("&dsname.","&cmpstatus",&sicode,"&message.","&modate.",&critix.);
    quit;
%end;
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
    length critc $20 rowstyle $50;
    if critn in (., 1) then critc=' ';
    else critc=put(critn, best12.);
    seq=_n_;

    if strip(upcase(sysinfo_codes)) = 'NO DIFFERENCE BETWEEN BASE & COMP' then
        rowstyle='style={background=#E8F5E9}';
    else if index(upcase(sysinfo_codes),'IN BASE BUT NOT IN COMP DIRECTORY') 
         or index(upcase(sysinfo_codes),'IN COMP BUT NOT IN BASE DIRECTORY') then
        rowstyle='style={background=#FFF8DC}';
    else
        rowstyle='style={background=#FDECEC}';
run;

****Time Stamp Information ;
%global runtime rundate;
data _null_;
    length runtime $14;
    time = strip(put(time(),time5.));
    timex = compress(time,':');
    runtime = strip(put(date(),date9.))||'T'||strip(put(timex,4.));
    rundate = put(date(),date9.);
    call symput('runtime',runtime);
    call symput('rundate', rundate);
    call symput('time',time);
run;

options ls=max ps=max nonumber nodate;
ods noproctitle;
ods escapechar='^';

ods html5 path="&compfolder"
         file="Base_Comp_dataset_compare_&runtime..html"
         style=htmlblue;

/* Main summary table only */
title;
title1 j=c "Base=&basefolder";
title3 j=c "Comp=&compfolder";

title5 j=c "Comparison Summary";

proc report data=compare_report nowindows missing split='@'
    style(report)={borderwidth=.5pt cellspacing=0 cellpadding=4}
    style(header)={background=cxD9EAF7 font_weight=bold}
    style(column)={just=l vjust=top};
    column rowstyle seq dataset critc sysinfo_codes modate;

    define rowstyle      / noprint;
    define seq           / group "#" style(column)={cellwidth=5% just=c};
    define dataset       / display "Dataset" style(column)={cellwidth=12%};
    define critc         / display "Criterion for Proc Compare" style(column)={cellwidth=10%};
    define sysinfo_codes / display "Comparison results for each dataset" style(column)={cellwidth=53%};
    define modate        / display "Timestamp Mismatch" style(column)={cellwidth=20%};

    compute before;
        call define(_row_,'style','style={background=white}');
    endcomp;

    compute rowstyle;
        call define(_row_,'style',rowstyle);
    endcomp;
run;

/* Individual comparisons */
%do i=1 %to &tot_ds;
    %let dsn=%scan(&dslist,&i,%str( )); 
	title;
    title1 j=c "Comparison results for each dataset";
    title2 ;
    title3 j=c "Detailed Comparison: &dsn";
    title4 ;

    %if %length(%superq(exclvars)) > 0 %then %do;
        proc compare base=base.&dsn(drop=&exclvars) comp=comp.&dsn(drop=&exclvars) listall criterion=0;
        run;
    %end;
    %else %do;
        proc compare base=base.&dsn comp=comp.&dsn listall criterion=0;
        run;
    %end;
%end;

ods html close;

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

%exitpgm: 
%put [dir_compare] Exiting dir_compare macro;

%mend dir_compare;