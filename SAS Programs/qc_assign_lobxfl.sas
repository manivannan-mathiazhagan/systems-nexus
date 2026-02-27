***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_assign_lobxfl.sas                                                             ***;
***                                                                                                 ***;
*** Purpose:       Assign baseline flag based on date and RFSTDTC                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    08Mar2023                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** DMAIN    |  the main domain name - to create the --BLFL variable  | No default      |   Yes     ***;
***          |  the created variable would be named as &DMAIN.BLFL    |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** SORTVARS |  list of key variables used for sorting space          | No default      |   Yes     ***;
***          |  separated based on which --BLFL is assigned           |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** INDSET   |  the name of the INPUT dataset                         | No default      |   Yes     ***;
***----------|--------------------------------------------------------|-----------------------------***;
*** OUTDSET  |  the name of the OUTPUT dataset                        | No default      |   Yes     ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DATEVAR  | the respective date variable in character format       | No default      |   Yes     ***;
***          | which is compared with RFSTDTC to assign --LOBXFL      |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** COND     | any specific condition to subset the records           | No default      |   No      ***;
***          | like VSTESTCD ne 'VSALL'                               |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** LASTVAR  | the variable used to check the last record in sort     | No default      |   Yes     ***; 
***          |  variables - like xxTESTCD or xxTPT                    |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          | No default      |   No      ***; 
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &OUTDSET.                                                                   ***;
***                                                                                                 ***;
*** Variables:          new variable &DMAIN.BLFL is added                                           ***;
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
*** Other:              The variable RFSTDTC should be present in INPUT dataset                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%macro qc_assign_lobxfl(DMAIN=,
                   SORTVARS=,
                   INDSET=,
                   OUTDSET=,
                   DATEVAR=,
                   COND=,
                   LASTVAR=,
                   FLAGVAR=BLFL,
                   DEBUG=N);

%let sqlvars  = %sysfunc(tranwrd(&sortvars.,%str( ),%str(,)));

/*checking part*/
proc sql noprint;
    create table check as select distinct &sqlvars,count(*) as cnt from &INDSET. 
    
    /* any specific condition to subset the records */
    %if &COND. ne %then 
        %do; 
            where &COND. 
        %end; 
 
    group by &sqlvars. having calculated cnt gt 1 ;
quit;

/*checking duplicates based on given sorting order*/
%let check_cnt = &sysnobs.;

%if &check_cnt. gt 0 %then 
    %do; 
    
        %put %str(War)ning: Duplicates found with the key variables used for creating Baseline flag - Kindly check;

    %end;

/*Baseline Flag - Calculation part*/
data ___BLFL(compress=yes);
    set &INDSET. ;
    
    /*  Input Date*/
    if not missing(&DATEVAR.)  and length(&DATEVAR.) ge 10 then INDATE = input(scan(&DATEVAR.,1,"T"),??is8601da.);
    else INDATE = .;
    
    /*  Input Time*/
    if not missing(&DATEVAR.)  and length(&DATEVAR.) ge 10 then INTIME = input(scan(&DATEVAR.,2,"T"),??time5.);
    else INTIME = .;
    
    /*  Reference Date */
    if not missing(RFSTDTC) and length(RFSTDTC) ge 10 then RFDATE = input(scan(RFSTDTC,1,"T"),is8601da.);
    else RFDATE = .;
    
    /*  Reference Time */
    if not missing(RFSTDTC) and length(RFSTDTC) ge 10 then RFTIME = input(scan(RFSTDTC,2,"T"),tIME5.);
    else RFTIME = .;
    
    /*  Subsetting the records needed for Baseline calculation*/
     %if "&COND." ne "" %then 
    %do;
        if &DMAIN.ORRES ne '' and n(INDATE,RFDATE) eq 2 and 
       ( ( INDATE eq RFDATE and 
            ( 
                ( n(INTIME,RFTIME) eq 2  and INTIME le RFTIME ) 
                    OR 
                (INTIME eq .) 
             ) 
        ) or 
        
        ( indate lt rfdate) ) and &COND. ;
    %end;
  
  %else 
    %do;
       if &DMAIN.ORRES ne '' and n(INDATE,RFDATE) eq 2 and 
       ( ( INDATE eq RFDATE and 
            ( 
                ( n(INTIME,RFTIME) eq 2  and INTIME le RFTIME ) 
                    OR 
                (INTIME eq .) 
             ) 
        ) or 
        
        ( indate lt rfdate) );
    %end;
  
run;

/*Sorting based on Given order*/
proc sort data=___BLFL;
    by &SORTVARS.;
run;

/*Subsetting records on or before Reference date/Time*/
data ___BLFL2(keep=&SORTVARS.);
    set ___BLFL;
    by &SORTVARS.;
    if last.&LASTVAR.;
run;

proc sort data=&INDSET. out = ___BLFL3;
    by &SORTVARS.;
run;

/*Mapping Flag to the Baseline record*/
data &OUTDSET.(compress=yes);
    merge ___BLFL3 ___BLFL2(in=inbl);
    by &SORTVARS.;
    if inbl then &DMAIN.&FLAGVAR.='Y';
run;

/*Deleting Intermediate datasets created*/
%if "&DEBUG." ne "Y" %then
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete ___BLFL:;
            quit;
        run;
    %end;

%mend qc_assign_lobxfl;
