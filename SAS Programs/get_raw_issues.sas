%macro get_raw_issues();

title;

data NODATA;
    Message="Issue resolved";
    output;
run;

%let RAWPATH=%sysfunc(pathname(RAW));

%put &RAWPATH.; 

%macro totobs(mydata);
    %let mydataID=%sysfunc(OPEN(&mydata.,IN));
    %let NOBS=%sysfunc(ATTRN(&mydataID,NOBS));
    %let RC=%sysfunc(CLOSE(&mydataID));
    &NOBS
%mend;

%macro OUT_XCL(DSNM,COND,TTL,NUM,WRK_RAW);
    
%if "&WRK_RAW." eq "N" %then 
    %do; 
        data ISSUE_&NUM.;
            set RAW.&DSNM.;
            where &COND. ;
        run;

        %let REC_N=%cmpres(%totobs(ISSUE_&NUM.));
        %if "&REC_N." ne "0" %then 
            %do;
                ods excel options(sheet_name="Issue &NUM.");
                title3 "&TTL. in RAW.&DSNM." ;
                
                proc print data=ISSUE_&NUM. noobs ;
                run;                 
            %end;
        %else  
            %do;
                ods excel options(sheet_name="Issue &NUM.");        
                title3 "&TTL. in RAW.&DSNM." ;
        
                proc print data=NODATA noobs ;
                run;
            %end;
    %end;
%else 
    %do;
        %let REC_N1=%cmpres(%totobs(ISSUE_&NUM.));
        %if "&REC_N1." ne "0" %then 
            %do;           
                ods excel options(sheet_name="Issue &NUM.");
                title3 "&TTL." ;
                
                proc print data=&DSNM. noobs ;
                run;
            %end;
        %else  
            %do;
                ods excel options(sheet_name="Issue &NUM.");        
                title3 "&TTL." ;
        
                proc print data=NODATA noobs ;
                run;
            %end;
    %end;

%mend OUT_XCL;

/*generating the Report file*/
ods excel file="&RAWPATH.\Raw_Data_Issues.xlsx" 
    options ( embedded_titles="YES" title_footnote_width='13' row_heights='0,0,0,14' );
    
    title1 "&RAWPATH." ;

    /* Calling the derived macro as per need */
    data _null_;
        set LIST;
        call execute('%OUT_XCL(DSNM='||strip(DSET)||',COND=%str('||strip(CONDITION)||'),TTL=%str('||strip(TITLE)||'),NUM='||strip(put(ISSUENO,best.))||',WRK_RAW='||strip(WORK)||');');
    run;

ods excel close;

title;

%mend get_raw_issues;

/*%get_raw_issues;*/

