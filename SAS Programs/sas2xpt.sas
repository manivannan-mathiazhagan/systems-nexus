***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    sas2xpt.sas                                                                      ***;
***                                                                                                 ***;
*** Purpose:       Convert all SAS datasets available in a library to XPT and store it within a     ***;
***                new folder named as XPT in same path of the Library passed                       ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    11Mar2022                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** LIBNM    | the name of library in which the sas datasets are      | No default      |   Yes     ***;
***          | present - which is to be converted as XPT              |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          |     N           |   No      ***; 
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
*** Other:              The log file is stored in the same location where the individual logs are   ***;
***                     stored by using "&droot\&dbpath\logs\_runall_XPT.log"                       ***;
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
*** Other:              The Macro will create a Folder named xpt if it is not present within the    ***;
***                     passed library and stores the xpt files in that folder                      ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%macro sas2xpt(LIBNM,DEBUG=N);

/*Storing Log in Projects folder*/
proc printto new log="&droot\&dbpath\logs\_runall_XPT.log";
    run;

/*Getting the path of the library passed*/
%let LIBPATH=%sysfunc(pathname(&LIBNM.));
%put &LIBPATH.;

/*Making a folder named as XPT within the path of the library to store XPTs*/
x mkdir "&LIBPATH.\xpt";

/* Checks made */
proc sql noprint;

    /*Getting the  name of datasets available in the library - which cannot be converted or raises error in Log*/
    create table ___ERDATA1 as
    select distinct MEMNAME,MEMLABEL
    from SASHELP.VTABLE
    where upcase(strip(LIBNAME)) eq upcase("&LIBNM.") and
    ( length(MEMNAME) gt 8 or length(MEMLABEL) gt 40 );

    /*Getting the  name of variables with label more than 40 */
    create table ___ERDATA2 as
    select distinct MEMNAME,NAME,LABEL
    from SASHELP.VCOLUMN
    where upcase(strip(LIBNAME)) eq upcase("&LIBNM.") and length(LABEL) gt 40;

    /*Getting the  name of datasets available in the library - which needs to be converted */
    create table ___INDATA as
    select distinct MEMNAME
    from SASHELP.VCOLUMN
    where upcase(strip(LIBNAME)) eq upcase("&LIBNM.") and length(MEMNAME) le 8 and index(MEMNAME,"_") eq 0;

quit;

/* Getting the number of datasets needed to be converted in a macro variable */
%let tot_count =&SYSNOBS.;

%put &tot_count.;

/*storing the dataset names in a macro variable*/
proc sql noprint;
    select MEMNAME  into :DATS1-:DATS&tot_count  from ___INDATA;
quit;

/*Creating XPTs for all datasets and storing it in created folder*/
%do index = 1 %to &tot_count;

    libname xportout xport "&LIBPATH.\xpt\%lowcase(&&DATS&index..).xpt";

    proc copy in=&LIBNM. out=xportout memtype=data;
        select &&DATS&index..;
    run;

%end;

/* Raising needed warnings */
data _NULL_;
    set ___ERDATA1;
    if length(MEMNAME) gt 8 then
        do;
            putlog 'WAR' 'NING: Dataset name ' MEMNAME 'is exceeding the limit of 8 characters and is not converted' ;
        end;
    else if length(MEMLABEL) gt 40 then
        do;
            putlog 'WAR' 'NING: Dataset label for ' MEMNAME 'is exceeding the limit of 40 characters ' ;
        end;
run;

data _NULL_;
    set ___ERDATA2;
    putlog 'WAR' 'NING: Variable label for ' NAME 'in dataset ' MEMNAME 'is exceeding the limit of 40 characters' ;
run;

/*Deleting Intermediate datasets created*/
%if "&DEBUG." ne "Y" %then
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete ___INDATA ___ERDATA:;
            quit;
        run;
    %end;

/*Closing Log printing*/
proc printto;
    run;

%mend sas2xpt;

/* %sas2xpt(SDTM); */


/* %sas2xpt(ADAM); */


