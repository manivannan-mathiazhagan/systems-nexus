***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    logchk.sas                                                                       ***;
***                                                                                                 ***;
*** Purpose:       Create a summary of log issues for entire directory or one log file at a time    ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    12May2023                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** logsite  |  the individual log file name or Location where all    | No default      |   Yes     ***;
***          |  the Log files are stored                              |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** bysev    |  Sort the report by Severity                           |      N          |   Yes     ***;
***          |  It can have values as Y/N - if it is given as Y, the  |                 |           ***;
***          |  report will  be sorted based on Severity of Issue,    |                 |           ***;
***          |  If N, the report will  be sorted based on Line number |                 |           ***;
***          |  of Issue                                              |                 |           ***;
***-------------------------------------------------------------------|-----------------|-----------***;
*** debug    | Used for debugging - if it is given as Y, the          |      N          |   No      ***; 
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Variables:          None                                                                        ***;
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
 
%macro logchk(logsite,
              bysev=N,
              debug=N);

options validvarname= v7;

%put NOTE: [logchk] macro starting execution: &logsite.;

%local infile logpath filexst index slash;
title;footnote;
           
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

%macro logkeys;
%put Note: [logkeys] started Executing;
 
if index(upcase(rec),"CONVERTED TO") > 0 then 
    do;
        record = "Conversion Issue";
        severity =        1;
    end;
else if index(upcase(rec),"ENDSAS") > 0 then 
    do;
        record = "ENDSAS found";
        severity =        1;
    end;
else if index(upcase(rec),"ARRAY SUBSCRIPT OUT OF RANGE") > 0 then 
    do;
        record = "Error: Array Definition";
        severity =        1;
    end;
else if index(upcase(rec),"ERROR: MIXING OF IMPLICIT AND EXPLICIT ARRAY SUBSCRIPTING IS NOT ALLOWED") > 0 then 
    do;
        record = "Error: Array Definition";
        severity =        1;
    end;
else if index(upcase(rec),"WAS NOT FOUND OR COULD NOT BE LOADED") > 0 then 
    do;
        record = "Error: Format not found";
        severity =        1;
    end;
else if index(upcase(rec),"INVALID ARGUMENT TO FUNCTION") > 0 then 
    do;
        record = "Error: Function";
        severity =        1;
    end;
else if index(upcase(rec),"INPUT STATEMENT REACHED PAST THE END OF A LINE") > 0 then 
    do;
        record = "Error: Input Statement";
        severity =        1;
    end;
else if index(upcase(rec),"INVALID") > 0 then 
    do;
        record = "Error: Invalid infile data";
        severity =        1;
    end;
else if index(upcase(rec),"NOTE: LIBRARY") > 0 and index(upcase(rec),"DOES NOT EXIST") > 0 then 
    do;
        record = "Error: Libref does not exist";
        severity =        1;
    end;
else if index(upcase(rec),"ERROR: A LOCK IS NOT AVAILABLE") > 0 then 
    do;
        record = "Error: Locked dataset";
        severity =        1;
    end;
else if index(upcase(rec),"ERROR: MACRO KEYWORD") > 0 then 
    do;
        record = "Error: Macro code";
        severity =        1;
    end;
else if index(upcase(rec),"ERROR: OPEN CODE STATEMENT RECURSION") > 0 then 
    do;
        record = "Error: Macro code";
        severity =        1;
    end;
else if index(upcase(rec),"WARNING: APPARENT INVOCATION OF MACRO") > 0 or index(upcase(rec),"WARNING: APPARENT SYMBOLIC REFERENCE") > 0 then 
    do;
        record = "Error: Macro code";
        severity =        1;
    end;
else if index(upcase(rec),"STOPPED DUE TO LOOPING") > 0 then 
    do;
        record = "Error: Stopped due to looping";
        severity =        1;
    end;
else if index(upcase(rec),"FUNCTION HAS NO EXPRESSION TO EVALUATE") > 0 then 
    do;
        record = "Error: system macro";
        severity =        1;
    end;
else if index(upcase(rec),"MACRO FUNCTION IS NOT A NUMBER") > 0 then 
    do;
        record = "Error: system macro";
        severity =        1;
    end;
else if index(upcase(rec),"ERROR: INVALID ARGUMENTS DETECTED IN") > 0 then 
    do;
        record = "Error: system macro";
        severity =        1;
    end;
else if index(upcase(rec),"COULD NOT BE PERFORMED") > 0 then 
    do;
        record = "Missing Values";
        severity =        1;
    end;
else if index(upcase(rec),"MISSING VALUES WERE GENERATED AS A RESULT OF PERFORMING") > 0 then 
    do;
        record = "Missing Values";
        severity =        1;
    end;
else if index(upcase(rec),"OVERWRITTEN") > 0 then 
    do;
        record = "Overwritten variables";
        severity =        1;
    end;
else if index(upcase(rec),"QC_ERR") > 0 then 
    do;
        record = "QC Error";
        severity =        1;
    end;
else if index(upcase(rec),"REPEATS OF BY VALUES") > 0 then 
    do;
        record = "Repeats of BY values";
        severity =        1;
    end;
else if index(upcase(rec),"ASSUMING THE SYMBOL") > 0 then   
    do;
        record = "SAS keyword misspelled";
        severity =        1;
    end;
else if index(upcase(rec),"NOTE: AT LEAST ONE W.D FORMAT") > 0 then 
    do;
        record = "Truncation";
        severity =        1;
    end;
else if index(upcase(rec),"UNINITIAL") > 0 then 
    do;
        record = "Uninitialized Variable";
        severity =        1;
    end;
else if index(upcase(rec),"EXTRANEOUS INFORMATION") > 0 then 
    do;
        record = "Warning: Macro code";
        severity =        1;
    end;
else if index(upcase(rec),"ALREADY EXISTS ON FILE") > 0 then 
    do;
        record = "Warning: Overwritten variables";
        severity =        1;
    end;
else if index(upcase(rec),"THE MEANING OF AN IDENTIFIER AFTER A QUOTED STRING MIGHT CHANGE") > 0 then 
    do;
        record = "Note: Quote issue";
        severity =        3;
    end;
else if index(upcase(rec),"QC_MESSAGE") > 0 then 
    do;
        record = "QC Message";
        severity =        3;
    end;
else if index(upcase(rec),"UNABLE TO COPY SASUSER REGISTRY") > 0 then 
    do;
        record = "Unable to copy SASUSER registry";
        severity =        3;
    end;
else if index(upcase(rec),"CARTESIAN PRODUCT") > 0 then 
    do;
        record = "Cartesian Product";
        severity =        2;
    end;
else if index(upcase(rec),"OBSERVATION(S) OUTSIDE THE AXIS RANGE") > 0 then 
    do;
        record = "Figure axis range";
        severity =        2;
    end;
else if index(upcase(rec),"QC_WARN") > 0 then 
    do;
        record = "QC Warning";
        severity =        2;
    end;
else if index(upcase(rec),"NOTE: THE LOGLOG TRANSFORM") > 0 and index(upcase(rec),"TO SUPPRESS") > 0 then 
    do;
        record = "Statistical Issue";
        severity =        2;
    end;
else if index(upcase(rec),"OPTION HAS NO EFFECT") > 0 then 
    do;
        record = "Statistical Issue";
        severity =        2;
    end;
else if index(upcase(rec),"DIVISION BY ZERO") > 0 then 
    do;
        record = "Warning: Division by 0";
        severity =        2;
    end;
else if index(upcase(rec),"HAS BECOME MORE THAN 262 CHARACTERS LONG") > 0 then 
    do;
        record = "Warning: Quote issue";
        severity =        2;
    end;
else if index(upcase(rec),"STOPPED BECAUSE OF INFINITE LIKELIHOOD") > 0 then 
    do;
        record = "Warning: Statistical";
        severity =        2;
    end;
else if index(upcase(rec),"THE OLD SYNTAX MIGHT NOT WORK IN THE NEXT RELEASE") > 0 then 
    do;
        record = "Warning: Statistical";
        severity =        2;
    end;
else if index(upcase(rec),"VALIDITY OF THE MODEL FIT IS QUESTIONABLE") > 0 then 
    do;
        record = "Warning: Statistical";
        severity =        2;
    end;
else if index(upcase(rec),"THE MAXIMUM LIKELIHOOD ESTIMATE MAY NOT EXIST") > 0 then 
    do;
        record = "Warning: Statistical";
        severity =        2;
    end;
else if index(upcase(rec),"WARNING: LENGTH OF CHARACTER VARIABLE HAS ALREADY BEEN SET") > 0 then 
    do;
        record = "Warning: Variable attributes";
        severity =        2;
    end;
else if index(upcase(rec),"REMERGING SUMMARY STATISTICS") > 0 then 
    do;
        record = "Warning: Remerging Summary Stats";
        severity =        2;
    end;
else if index(upcase(rec),"PRODUCT WITH WHICH") > 0 or index(upcase(rec),"YOUR SYSTEM IS SCHEDULED TO EXPIRE") > 0 then 
    do;
        delete;
    end;
else if index(upcase(rec),"SYNTAX ERROR, EXPECTING ONE OF THE FOLLOWING:") > 0 then 
    do;
        record = "Error: Syntax error";
        severity =        1;
    end;
else if index(upcase(rec),"NOTE: THE SAS SYSTEM STOPPED PROCESSING THIS STEP BECAUSE OF ERRORS") > 0 then 
    do;
        record = "Error: SAS System stopped";
        severity =        1;
    end;
else if index(upcase(rec),"USER_ERR") > 0 then 
    do;
        record = "User Error";
        severity =        1;
    end;
else if index(upcase(rec),"USER_WARN") > 0 then 
    do;
        record = "User Warning";
        severity =        2;
    end;
else if index(upcase(rec),"USER_NOTE") > 0 then 
    do;
        record = "User Note";
        severity =        3;
    end;
else if index(upcase(rec),"EXPORT CANCELLED") > 0 then 
    do;
        record = "Export Cancelled";
        severity =        1;
    end;
else if index(upcase(rec),"WARNING:") > 0 then 
    do;
        record = "WARNING:";
        severity =        2;
    end;
else if index(upcase(rec),"ERROR:") > 0 then 
    do;
        record = "ERROR:";
        severity =        1;
    end;
 
%mend logkeys;

%if  %upcase(&sysscp.) = LIN X64 %then %let slash = /;
%else %if %upcase(&sysscp.) = WIN %then %let slash = \;
%if  %index(&logsite., .log)> 0 %then %let infile = %scan(&logsite,1,"&slash.",b);

%if %sysfunc(fileexist(&logsite.)) & &infile ne %then 
    %do; 
        %let filexst = Y;
    %end;
%else %if &infile ne %then 
    %do;
        %put %sysfunc(sysmsg()) The file does not exist. ; 
        %goto exitpgm;
    %end;
%else 
    %do;
        %chk_dir (&logsite.);
        %if &direxist = N %then %goto exitpgm;
        %else %symdel direxist;
    %end;

%**logpath = directory where log sits;
%**lspath = directory path for windows set for html;
data _null_;
   length rpath logpath lspath $500 ;
    if index("&logsite", ".log")> 0 then 
        do;
            %**when given a directory/file only;
            rpath = reverse( "&logsite." );
            logpath = reverse(substr( trim(left(rpath)), index(rpath, "&slash.")+1)) ;
            lspath = logpath ;              
        end;
   else 
        do;
            %**when given a directory only;
            logpath = "&logsite.";
            lspath = logpath ;  
        end;
   call symputx('logpath',logpath);
   call symputx('lspath',lspath);
run;

%put infile = &infile;
%put logpath = &logpath;
%put lspath = &lspath;

%macro get_filenames(location);

filename _dir_ "%bquote(&location.)";

data filenames(keep=memname);
    length memname $2000;
    handle=dopen( '_dir_' );
    if handle > 0 then 
        do;
            count=dnum(handle);
            do i=1 to count;
                memname=dread(handle,i);
                output filenames;
            end;
        end;
    rc=dclose(handle);
run;

filename _dir_ clear;
%mend;

%get_filenames(&logpath.);  

proc sort data =  filenames (where= ( index(upcase(memname),".LOG")>0 or index(upcase(memname),".TXT")>0  )) 
    out =  dirlist (rename=(memname = file_n));
    by memname;
run;

*---------------------------------;
*  Are any logs in the directory? ;
*---------------------------------;
proc sql noprint;
    select count(*) into: max
    from dirlist;
    quit;

%put max=&max;

%if &max = 0 %then %do;
    %put ERROR: [logchk] There are no log files in directory: &logsite.; 
    %goto exitpgm;
%end;

*----------------------------------------;
** Macro technique to get Modified Date**;
*----------------------------------------;
%macro FileAttribs(path, _file);                                                                                                           
   %local rc fid fidc;                                                                                                                   
   %local   ModifyDT;                                                                                                       
   %let rc=%sysfunc(filename(onefile,&path.&slash.&_file.));                                                                                       
   %let fid=%sysfunc(fopen(&onefile));                                                                                                 
   %let ModifyDT=%qsysfunc(finfo(&fid,Last Modified));                                                                                   
   %let fidc=%sysfunc(fclose(&fid));                                                                                                    
   %let rc=%sysfunc(filename(onefile));                                                                                                 
   %put NOTE- &_file Last modified &ModifyDT;  
   
data dirlist;
    length moddate $20;
    set dirlist;
    if file_n = "&_file" then moddate = "&ModifyDT.";
run; 

%mend FileAttribs; 
                                                                                            
%** Just pass in the path and file name **;

%if &infile ne %then 
    %do;
        %FileAttribs(&logpath., &infile.);
    %end;
%else 
    %do;
        data _null_;
            set dirlist;
            length dir_file $200;
            dir_file ="&logpath.";
            call execute('%fileAttribs('||dir_file||','||file_n||');');
        run;
    %end;

*-------------------------------------------------------------------------------------------------------;
*  Assign a name to each log, so the identification of SAS log file becomes possible. ;
*-------------------------------------------------------------------------------------------------------;
 data dirlist;
      set dirlist;
      logn=trim(left(scan(file_n,-2,'.')));
      logname=trim(left(scan(logn,-1,"slash.")));
      drop logn;
      if _n_=1 then merge1=1;else
      if _n_^=1 then merge1+1;
 run;
*-------------------------------------------------------------------------------------------------------;
*  Does the file exist if a single file is called? ;
*-------------------------------------------------------------------------------------------------------;

%if &infile NE %then 
    %do;
        %***check for a single file call;
        %***test for file exist;
        data _null_;
            set dirlist;
            if upcase(file_n)= %upcase("&infile.") then 
                do;
                    %*call symput ('filexst', 'Y');
                    call symput ('index',put(merge1,8.));
                end;
        run;
        %***put filexst = &filexst;
        %**if &filexst ne Y %then %goto exitpgm;
    %end;
 
data _null_;
    set dirlist;
    call symput ("logn"||strip(put(merge1,8.)), logname);
    call symput ("logf"||strip(put(merge1,8.)), file_n);
    call symput ("logmod"||strip(put(merge1,8.)), moddate);
run;

*************************************************************;
*** Bring in each file and review log issues, assign severity;
*************************************************************;

%do i=1 %to &max;

    %if &infile NE & &filexst = Y %then 
        %do;
            %if &i NE &index %then 
                %do;
                    %goto exit;
                %end;
        %end;

    %let inf&i = %trim(&logpath.&slash.&&logf&i.);

    %if  %upcase(&sysscp.) = LIN X64 %then %let IGNOREDOSEOF = ;
    %else %if %upcase(&sysscp.) = WIN %then %let IGNOREDOSEOF = IGNOREDOSEOF;

    DATA __TMP&&logn&i ;
        INFILE "&&inf&i" TRUNCOVER &IGNOREDOSEOF;
        length rec $500;
        INPUT 
          rec 1-500;
    run;

    /*%local compfl&i;*/
    data test&i ;
        length file_n $250 logname $2000 moddate $25 record $100 Severity 8;
        set __TMP&&logn&i end= eof ;
      
        if _n_=1 then line=1;
        else if _n_^=1 then line+1;
      
        file_n="&&logf&i";
        moddate="&&logmod&i";
        logname="<h3 align=left> <a href='file:///"||"&lspath."||"/"||strip(file_n)||"'"||">"||strip(file_n)||'</a></h3>';

        if index(REC,'/*') =0 then 
            do;  
                /*Call logkey macro made from prelogchk;*/
                %logkeys;
            end;
    
            if record ^=' ';
             
    run;

    proc sql noprint;
            select count(file_n) into: tcnt&i
            from test&i.;
    quit;

    %if &&tcnt&i = 0 %then 
        %do;
            data clean ;     
                length file_n $250 logname $2000 moddate $25 record $100 Severity 8 rec $500;
                file_n="&&logf&i";
                moddate="&&logmod&i";
                logname="<h3 align=left> <a href='file:///"||"&lspath."||"/"||strip(file_n)||"'"||">"||strip(file_n)||'</a></h3>';
                record = 'Clean Log';
                severity = .;
                rec = 'No log issues found';
                output;
            run;

            data test&i;
                set test&i clean;
            run;
        %end;

    proc sort data = test&i;
        %if "&bysev." = "Y" %then 
        %do;
            by severity record;
        %end;
        %else
        %do;
            by line severity ;
        %end;
    run;

    /*Summarize findings;*/
    data test&i.b;
        length linesum $200;
        retain cntrec 0 linesum '';
        set test&i;
        %if "&bysev." = "Y" %then 
        %do;
            by severity record;
            if first.record then 
            do;
                cntrec =1;
                linesum = strip(put(line,8.));
            end;
        else 
            do;
                cntrec +1;
                linesum = strip(linesum)||', '||strip(put(line,8.));
            end;
            if last.record;
        %end;
        %else
        %do;
            by line severity ;
            cntrec =1;
            linesum = strip(put(line,8.));
        %end;        
    run;

    Data AllDetails;
         set
         %if &i = 1 | &infile NE %then 
            %do;
                test&i.;
            %end;
        %else 
            %do;
                AllDetails test&i.;
             %end;
        ;
    run;

    %exit: ;%**end of loop for i;
%end; %***end of do 1 to max;


************************************;
***Time to print based on macro call;  
************************************;
proc format ;
    value level
    1 = 'High'
    2 = 'Medium'
    3 = 'Low';
    value LEVCOLOR
    1 = 'RED'
    2 = 'ORANGE'
    3 = 'GREEN';
    value levels
    0 = 'Total'
    0.5 = 'Clean'
    1 = 'High severity issues'
    2 = 'Medium severity issues'
    3 = 'Low severity issues';
run;

%let index = &index;
%let infileb = %scan(&infile,1,.);
%put infileb=&infileb;

/*Time;*/
%let __ST = %sysfunc(datetime());
data _null_;
    start = put(&__st, tod.);
    call symputx('__stime',start);
run;

/*Print Detailed report;*/


        title "Log check was run: &sysdate. &__stime."; 
        title2 "&logsite."; 

        %if &infile NE & &filexst = Y %then 
            %do;

                proc report data=test&index. nowd headline headskip split='$';

            %end;
        %else 
            %do; 
                /* All Log details ; */
                ods html path ="&logpath." file="Log_Check_Report.html" ; 
                proc report data=Alldetails nowd headline headskip split='$';
            %end;
    
        column logname moddate line record rec severity;
        
        define logname      / 'Log file name'               width=50    left order order=data flow ;
        define moddate      / 'Last Modified Date & Time'   width=30    left  order order=data flow;
        define line         / 'Log line'                    width=10    left style(column)={ font_weight=bold } flow;
        define record       / 'Log Issue'                   width=30    left style(column)={ font_weight=bold } flow;
        define rec          / 'Log Issue Details'           width=40    left style(column)={ font_weight=bold} flow;
        define severity     / 'Severity'                    width=8     left format =level. style(column)={ font_weight=bold  foreground=levcolor.  } flow;
        run;

    ods html close;
    ods listing;

/*If not Debug: Clean up files*/
%if &debug = N %then 
    %do;
        proc datasets nolist;
            delete dirlist filenames test: alldetails __TMP: clean;
        ;
        quit;
    %end;

%**end; %*from exitpgm;
%exitpgm: %**exit the program;
title;footnote;
%put [logchk] Exiting logchk macro;

%mend logchk;
