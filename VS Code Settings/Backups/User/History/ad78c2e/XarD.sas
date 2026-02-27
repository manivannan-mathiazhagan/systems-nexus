************************************************************************************;
* VERISTAT INCORPORATED
************************************************************************************;
* PROGRAM:    P:\Aerin Medical\CTP1450\Biostats\CSR\Macros\m-tf-create.sas
* DATE:       21MAY2024
* PROGRAMMER: Gabe Trout
*
* PURPOSE:    macro to create Titlefooters dataset
*
************************************************************************************;
* MODIFICATIONS:
*   PROGRAMMER:
*   DATE:
*   PURPOSE:
************************************************************************************;

**************************************************
CHANGE THE PROTDIR FOR EACH STUDY
**************************************************;

%let protdir=P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB;
%let dir = &protdir\Docs\Analysis Plan\TitlesFootnotes;
%let file = titlesfooters.xlsx;

%include "&protdir\macros\m-tf-readex.sas";

libname titles "&protdir\Docs\Analysis Plan\TitlesFootnotes";

******************************************************************************************************
GET THE TITLES AND FOOTNOTES EXCEL(titlesfooters) USING READEX MACRO
******************************************************************************************************;

%readex(
        filen   = &dir\&file,
        rst     = 4,
        rsp     = 500,
        sheet   = Tables,
        ncol    = 16,
        outd    = tab
    );


%readex(
        filen   = &dir\&file,
        rst     = 4,
        rsp     = 200,
        sheet   = Figures,
        ncol    = 16,
        outd    = fig
    );


%readex(
        filen   = &dir\&file,
        rst     = 4,
        rsp     = 100,
        sheet   = Listings,
        ncol    = 16,
        outd    = list
    );

*******************************************************************************************************
END OF EXCEL EXCUTION
*******************************************************************************************************;

data table;
set
   list (in=c)
    tab (in=a)
   fig (in=b)
;
where compress(col2) ne '';
run;

proc sort data = table;
by col2;
run;


%macro chk();

    %if %sysfunc(fileexist(&protdir\Macros\titlesfootersX.sas7bdat)) %then %do;
        %put File exists and will be compared;

        data orig;
        set titles.titlesfootersX;
        run;

        data titles.titlesfootersX;
        set table;
        run;

        proc compare base = orig comp=table OUTNOEQUAL out=diffs noprint;
        id col2;
        run;

        data diffs1(where=(diff=1));
        set diffs;
            array vars col1-col16;
            do i = 1 to 16;
                if index(vars[i],'X') > 0 then do;
                    diff = 1;
                    i = 99;
                end;
            end;
        run;

        %let numobs = 0;
        data _null_;
        set diffs1 nobs=nn;
            call symput('numobs',compress(put(nn,best.)));
        run;
        title;
        footnote;
        %if &numobs > 0 %then %do;
            proc print data = diffs1;
                title1 'LIST OF OUTPUTS THAT NEED TO BE RE-RUN';
                var col2;
            run;
        %end;
        %else %do;
            %put No titles or footnotes changed;
        %end;

    %end;
    %else %do;
        %put First time titles are being created;

        data titles.titlesfooters;
        set table;
        run;
    %end;
%mend;
%chk;

