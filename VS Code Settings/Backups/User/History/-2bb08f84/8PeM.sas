/******************************* EPOCH DERIVATION ***************************/
%MACRO DERIVE_EPOCH(IN,DTC,DTN,OUT);

    DATA EPC;
        SET &IN;

        IF LENGTH(COMPRESS(&DTC))=10 THEN DTE=COMPRESS(&DTC||'T23:59:00');
        ELSE IF LENGTH(COMPRESS(&DTC))=13 THEN DTE=COMPRESS(&DTC||':00:00');
        ELSE IF LENGTH(COMPRESS(&DTC))=16 THEN DTE=COMPRESS(&DTC||':00');
        ELSE IF LENGTH(COMPRESS(&DTC))=19 THEN DTE=COMPRESS(&DTC);
        ELSE IF LENGTH(COMPRESS(&DTC))<10 THEN DTE='';
        IF DTE NE '' THEN &DTN=INPUT(DTE,IS8601DT19.);
        FORMAT &DTN DATETIME20. ;
    RUN;

    PROC SORT DATA=SDTM.SE OUT=SE(KEEP=USUBJID SESTDTC SEENDTC EPOCH);
        BY USUBJID SESTDTC ;
    RUN;

    DATA SE;

        SET SE ;
        BY USUBJID SESTDTC;

        IF LENGTH(COMPRESS(SESTDTC))=10 THEN DTS=COMPRESS(SESTDTC||'T00:00:00');
        ELSE IF LENGTH(COMPRESS(SESTDTC))=13 THEN
            DTS=COMPRESS(SESTDTC||':00:00');
        ELSE IF LENGTH(COMPRESS(SESTDTC))=16 THEN DTS=COMPRESS(SESTDTC||':00');
        ELSE IF LENGTH(COMPRESS(SESTDTC))=19 THEN DTS=COMPRESS(SESTDTC);
        ELSE IF LENGTH(COMPRESS(SESTDTC))<10 THEN DTS='';
        SESTDTN=INPUT(DTS,IS8601DT19.);
        IF LENGTH(COMPRESS(SEENDTC))=10 THEN DTL=COMPRESS(SEENDTC||'T00:00:00');
        ELSE IF LENGTH(COMPRESS(SEENDTC))=13 THEN
            DTL=COMPRESS(SEENDTC||':00:00');
        ELSE IF LENGTH(COMPRESS(SEENDTC))=16 THEN DTL=COMPRESS(SEENDTC||':00');
        ELSE IF LENGTH(COMPRESS(SEENDTC))=19 THEN DTL=COMPRESS(SEENDTC);
        ELSE IF LENGTH(COMPRESS(SEENDTC))<10 THEN DTL='';
        SEENDTN=INPUT(DTL,IS8601DT19.);

        IF SESTDTN=SEENDTN THEN SEENDTN+5;

        IF LAST.USUBJID THEN SEENDTN=DATETIME();

        KEEP USUBJID SESTDTC SEENDTC SESTDTN SEENDTN EPOCH ;
        FORMAT SESTDTN SEENDTN DATETIME20. ;
    RUN;

    PROC SQL;

        CREATE TABLE &OUT AS SELECT A.*,B.SESTDTN,B.SEENDTN,B.EPOCH FROM EPC AS
            A LEFT JOIN SE AS B ON A.USUBJID=B.USUBJID AND &DTN >= SESTDTN AND
            &DTN< SEENDTN;

    QUIT;

%MEND;

/******************************** CHECK FOR THE EXISTENCE OF A SPECIFIED VARIABLE ****************************/
%MACRO VAREXIST(DS,VAR);

    %LOCAL DSID RC ;

    %LET DSID=%SYSFUNC(OPEN(&DS));

    %IF (&DSID) %THEN %DO;
        %IF %SYSFUNC(VARNUM(&DSID,&VAR)) %THEN 1;
        %ELSE 0 ;
        %LET RC=%SYSFUNC(CLOSE(&DSID));
    %END;
    %ELSE 0;

%MEND VAREXIST;

/*************************************** STUDY DAY DERIVATION **************************************/
%MACRO DERIVE_DY(IN,OUT,DOM);

    DATA DM ;
        SET SDTM.DM;
        IF LENGTH(RFSTDTC)=>10 THEN
            RFSTDTN=INPUT(SUBSTR(RFSTDTC,1,10),IS8601DA.);
        ELSE RFSTDTN=.;
        KEEP USUBJID RFSTDTC RFSTDTN;
    RUN;

    PROC SORT;
        BY USUBJID ;
    RUN;

    DATA &OUT;

        MERGE &IN(IN=A) DM;
        BY USUBJID;
        IF A;

        %IF %varexist(&IN,&DOM.DTC) EQ 1 %THEN %DO ;

            IF LENGTH(&DOM.DTC)=> 10 THEN &DOM.DTN1=
                INPUT(SUBSTR(&DOM.DTC,1,10),YYMMDD10.);
            ELSE &DOM.DTN1=.;

            IF NMISS(&DOM.DTN1,RFSTDTN)=0 THEN DO;
                IF &DOM.DTN1 >= RFSTDTN THEN &DOM.DY=&DOM.DTN1-RFSTDTN+1;
                ELSE &DOM.DY=&DOM.DTN1-RFSTDTN;
            END;

        %END;

        %IF %varexist(&IN,&DOM.STDTC) EQ 1 %THEN %DO ;

            IF LENGTH(&DOM.STDTC)=> 10 THEN &DOM.STDTN1=
                INPUT(SUBSTR(&DOM.STDTC,1,10),YYMMDD10.);
            ELSE &DOM.STDTN1=.;

            IF NMISS(&DOM.STDTN1,RFSTDTN)=0 THEN DO;
                IF &DOM.STDTN1 >= RFSTDTN THEN &DOM.STDY=&DOM.STDTN1-RFSTDTN+1;
                ELSE &DOM.STDY=&DOM.STDTN1-RFSTDTN;
            END;

        %END;

        %IF %varexist(&IN,&DOM.ENDTC) EQ 1 %THEN %DO ;

            IF LENGTH(&DOM.ENDTC)=> 10 THEN &DOM.ENDTN1=
                INPUT(SUBSTR(&DOM.ENDTC,1,10),YYMMDD10.);
            ELSE &DOM.ENDTN1=.;

            IF NMISS(&DOM.ENDTN1,RFSTDTN)=0 THEN DO;
                IF &DOM.ENDTN1 >= RFSTDTN THEN &DOM.ENDY=&DOM.ENDTN1-RFSTDTN+1;
                ELSE &DOM.ENDY=&DOM.ENDTN1-RFSTDTN;
            END;

        %END;

    RUN;
%MEND DERIVE_DY;

****** GET UNSCH VISITNUM;

/*NOTE: VISITNUM  SHOULD BE IN  THE  NAME OF  VISN_ IN THE &IN DATASET */
%MACRO GET_UNSCHVN(IN=,OUT=,DTC=);
    DATA SCH UNSCH;

        SET &IN ;

        IF INDEX(UPCASE(VISIT),"UNSCH") >0 THEN OUTPUT UNSCH;
        ELSE OUTPUT SCH;
    RUN;

    DATA UNSCH2;
        SET UNSCH;

        IF &DTC NE " " AND LENGTH(&DTC)>10 THEN &DTC.T=STRIP(SCAN(&DTC,1,"T"));
        ELSE IF &DTC NE " " AND LENGTH(&DTC)=10 THEN &DTC.T=&DTC;

        DROP VISIT VISN_;

    RUN;

    DATA SV_UNSCH SV_SCH;
        SET SDTM.SV;

        IF INDEX(UPCASE(VISIT),"UNSCH") >0 THEN OUTPUT SV_UNSCH;
        ELSE OUTPUT SV_SCH;
    RUN;

    PROC SQL;

        CREATE TABLE UNVIS AS SELECT A.*,B.SVSTDTC,B.VISIT,B.VISITNUM FROM
            UNSCH2 AS A LEFT JOIN SV_UNSCH AS B ON A.USUBJID=B.USUBJID AND
            A.&DTC.T=B.SVSTDTC ORDER BY STUDYID,USUBJID,VISITNUM;

    QUIT;

    PROC SORT DATA=SCH (RENAME=(VISN_=VISITNUM));
        BY STUDYID USUBJID VISITNUM ;
    RUN;

    *** TOTAL SET  ;
    DATA &OUT ;
        LENGTH VISIT $200.;
        SET SCH UNVIS ;
        BY USUBJID VISITNUM ;
    RUN;

%MEND ;

/******************************** SUPP MACRO ***********************/
%MACRO SUPP(DM,OUT,VAR,QNAM,QLABEL,QVAL,QORIG);
    DATA &OUT ;
        LENGTH QVAL QORIG $200. QLABEL $40. QNAM $8. ;
        SET &DM._F(RENAME=(DOMAIN=RDOMAIN));
        WHERE &VAR NE "";

        IDVAR="&DM.SEQ";
        IDVARVAL=STRIP(PUT(&DM.SEQ,BEST.));
        QNAM="&QNAM" ;
        QLABEL=&QLABEL ;
        QVAL=STRIP(&QVAL);
        QORIG="&QORIG";
        QEVAL="";

        KEEP STUDYID RDOMAIN USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL QORIG
            QEVAL;
    RUN;

%MEND ;

******* To Get Missing dates;
/*First Check whether the missing date is  present in raw.dov or not*/

/*The output date varible --- VISDAT*/
%MACRO GET_DTMISS(IN,DAT,OUT);
    DATA DATE_Y DATE_N;

        SET &IN;

        IF &DAT EQ . THEN OUTPUT DATE_N;
        IF &DAT NE . THEN OUTPUT DATE_Y;
    RUN;

    PROC SORT DATA=DATE_Y ;
        BY SUBJECTID VISIT &DAT;
    RUN;

    PROC SQL;
        CREATE TABLE XNYZ AS SELECT A.*,B.VISDAT FROM DATE_N AS A LEFT JOIN
            RAW.DOV AS B ON A.SUBJECTID=B.SUBJECTID AND A.VISIT=B.VISIT ORDER BY
            SUBJECTID,VISIT,VISDAT;
    QUIT;

    DATA &OUT;
        SET DATE_Y(RENAME=(&DAT=VISDAT)) XNYZ;
        BY SUBJECTID VISIT VISDAT;
    RUN;

%MEND;

************* MACRO FOR SEQ ;
%MACRO GET_SEQ(IN,VAR,DM);
    PROC SORT DATA=&IN OUT=LKG;
        BY &VAR;
    RUN;

    DATA &DM._F;
        SET LKG ;
        BY &VAR;
        IF FIRST.USUBJID THEN &DM.SEQ=1 ;
        ELSE &DM.SEQ +1 ;
    RUN;
%MEND ;

************* MACRO FOR LOBXFL ;
%MACRO DERIVE_LOBXFL(IN,VAR,OUT,DM);

    PROC SORT DATA=&IN OUT=BLF ;
        BY &VAR ;
    RUN;

    DATA BL1;

        SET BLF;

        IF CMISS(&DM.DTC,RFSTDTC)=0 AND &DM.DTC<=RFSTDTC AND &DM.STRESC NE ""
            /* AND SCAN(UPCASE(VISIT),1,"") NE "UNSCHEDULED" */;

    RUN;

    PROC SORT ;
        BY &VAR ;
    RUN;

    DATA BFLAG;

        SET BL1;
        BY &VAR ;

        IF LAST.&DM.TESTCD;
        &DM.LOBXFL="Y";

        KEEP &VAR &DM.LOBXFL;
    RUN;

    DATA &OUT;

        MERGE BLF BFLAG;
        BY &VAR ;

    RUN;

%MEND;

/************************************ SAS TO XPT ********************************/
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
        create table ___ERDATA1 as select distinct MEMNAME,MEMLABEL from
            SASHELP.VTABLE where upcase(strip(LIBNAME)) eq upcase("&LIBNM.") and
            ( length(MEMNAME) gt 8 or length(MEMLABEL) gt 40 );

        /*Getting the  name of variables with label more than 40 */
        create table ___ERDATA2 as select distinct MEMNAME,NAME,LABEL from
            SASHELP.VCOLUMN where upcase(strip(LIBNAME)) eq upcase("&LIBNM.")
            and length(LABEL) gt 40;

        /*Getting the  name of datasets available in the library - which needs to be converted */
        create table ___INDATA as select distinct MEMNAME from SASHELP.VCOLUMN
            where upcase(strip(LIBNAME)) eq upcase("&LIBNM.") and
            length(MEMNAME) le 8;

    quit;

    /* Getting the number of datasets needed to be converted in a macro variable */
    %let tot_count=&SYSNOBS.;

    %put &tot_count.;

    /*storing the dataset names in a macro variable*/
    proc sql noprint;
        select MEMNAME into :DATS1-:DATS&tot_count from ___INDATA;
    quit;

    /*Creating XPTs for all datasets and storing it in created folder*/
    %do index=1 %to &tot_count;

        libname xportout xport "&LIBPATH.\xpt\%lowcase(&&DATS&index..).xpt";

        proc copy in=&LIBNM. out=xportout memtype=data;
            select &&DATS&index..;
        run;

    %end;

    /* Raising needed warnings */
    data _NULL_;
        set ___ERDATA1;
        if length(MEMNAME) gt 8 then do;
            putlog 'WAR' 'NING: Dataset name ' MEMNAME
                'is exceeding the limit of 8 characters and is not converted' ;
        end;
        else if length(MEMLABEL) gt 40 then do;
            putlog 'WAR' 'NING: Dataset label for ' MEMNAME
                'is exceeding the limit of 40 characters ' ;
        end;
    run;

    data _NULL_;
        set ___ERDATA2;
        putlog 'WAR' 'NING: Variable label for ' NAME 'in dataset ' MEMNAME
            'is exceeding the limit of 40 characters' ;
    run;

    /*Deleting Intermediate datasets created*/
    %if "&DEBUG." ne "Y" %then %do;
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
%macro shortlen(dsn,desc);

    data _null_ ;
        length retain $32767 ;
        retain retain 'retain' ;
        dsid=open( "&DSN", 'I' ) ;
        /* open dataset for read access only */
        do _i_=1 to attrn( dsid, 'nvars' ) ;
            retain=trim( retain ) || ' ' || varname( dsid, _i_ ) ;
        end ;
        call symput( 'RETAIN', retain ) ;
    run ;

    data _null_;
        set &dsn;
        array qqq(*) _character_;
        call symput('siz',put(dim(qqq),5.-L));
        stop;
    run;

    data _null_;
        set &dsn end=done;
        array qqq(&siz) _character_;
        array www(&siz.);
        if _n_=1 then do i=1 to dim(www);
            www(i)=0;
        end;
        do i=1 to &siz.;
            www(i)=max(www(i),length(qqq(i)));
        end;
        retain _all_;
        if done then do;
            do i=1 to &siz.;
                length vvv $50;
                vvv=catx(' ','length',vname(qqq(i)),'$',www(i),';');
                fff=catx(' ','format ',vname(qqq(i))||' '||
                    compress('$'||put(www(i),3.)||'.;'),' ');
                call symput('lll'||put(i,3.-L),vvv) ;
                call symput('fff'||put(i,3.-L),fff) ;
            end;
        end;
    run;

    data &dsn ;
        %do i=1 %to &siz.;
        &&lll&i &&fff&i %end;
        set &dsn;
    run;

    data &dsn (label=&desc);
        &RETAIN;
        set &dsn;
        informat _all_;
        format _all_;
    run;

%mend shortlen;

%macro lastword(_arg,delim=%str( ));
    %local __word;
    %if %index(&_arg,&delim) %then %let
        __word=%reverse(%unquote(%qscan(%reverse(&_arg),1,&delim)));
    %else %let __word=&_arg;
    &__word %mend lastword;

    %macro reverse(_arg);
        %local i __strout;
        %let __strout=;
        %do i=%length(&_arg) %to 1 %by -1;
            %let __strout=&__strout%unquote(%qsubstr(&_arg,&i,1));
        %end;
        &__strout %mend reverse;

        %macro SDTM_TRIAL_attrib(SDTM_DS=, IN_DATA=, OUTSET=, DEBUG=N);
            libname P21_SPEC
                "P:\LegacyInstat_Projects\Instat\CDISC\Pinnacle Specification";
            %let SDT_NME=33;

            options validvarname=V7;

            %if "&OUTSET." eq "" %then %do;
                %let OUTSET=SDTM.&SDTM_DS.;
            %end;

            %if %index(&SDTM_DS.,SUPP) eq 0 %then %do;
                /* Subsetting the Specs for respective Parent domain*/
                data ___SPEC_&SDTM_DS.;
                    set P21_SPEC.SD&SDT_NME._VARIABLES;
                    where DATASET eq upcase("&SDTM_DS.");
                run;

                data _NULL_;
                    set P21_SPEC.SD&SDT_NME._DATASETS;
                    where DATASET eq upcase("&SDTM_DS.");

                    call symput("DSETLAB", trim(compbl(LABEL)));
                run;
            %end;
            %else %do;
                /* Subsetting the Specs for SUPPQUAL domain*/
                data ___SPEC_&SDTM_DS.;
                    set P21_SPEC.SD&SDT_NME._VARIABLES;
                    where DATASET eq "SUPPQUAL";
                run;

                %let PAR_DS=%substr(&SDTM_DS.,5,2);

                data _NULL_;
                    length LABEL $200.;
                    LABEL="Supplemental Qualifiers for &PAR_DS.";
                    call symput("DSETLAB", trim(compbl(LABEL)));
                run;
            %end;

            /*Finding the list of matching variables kept in Input dataset and Specs*/
            proc sql noprint;
                create table ___SPEC_INPUT_VAR as select NAME,1 as KEEP from
                    SASHELP.VCOLUMN where LIBNAME eq "WORK" and MEMNAME eq
                    upcase("&IN_DATA.");

                create table ___SPEC_MATCH as select a.*, b.keep from
                    ___SPEC_&SDTM_DS. a left join ___SPEC_INPUT_VAR b on
                    a.VARIABLE eq b.NAME;
            quit;

            *************************;
            *** Subset for domain ***;

            *************************;
            data ___SPEC_TAB1 (keep=LABEL VARIABLE ORDER DATA_TYPE rename=(
                VARIABLE=NAME DATA_TYPE=TYPE));
                set ___SPEC_MATCH;
                where KEEP eq 1 ;
            run;

            proc sort data=___SPEC_TAB1 out=___SPEC_TAB2;
                by ORDER;
            run;

            /*Checking if Required (Mandatory) Variables are not present*/
            data ___SPEC_MAND (keep=LABEL VARIABLE ORDER DATA_TYPE rename=(
                VARIABLE=NAME DATA_TYPE=TYPE));
                set ___SPEC_MATCH;
                where KEEP eq . and upcase(strip(MANDATORY)) eq "YES" ;
                put "WARN" "ING: Mandatory variable of Domain " Dataset "- "
                    Variable " is not present in &IN_DATA." ;
            run;

            *** Define variable attributes (name, label, type, length) ***;
            data ___SPEC_ATTRIB;
                length STRING_ VARS_ $1000;
                retain VARS_;
                set ___SPEC_TAB2 end=eof;

                if upcase(TYPE) in("CHAR", "TEXT" "DATETIME" "DATE") then do;
                    STRING_="attrib " || trim(left(NAME)) || " label='" ||
                        trim(left(LABEL)) || "' length=$200";
                end;
                else if upcase(TYPE) in("NUM", "INTEGER", "FLOAT") then do;
                    STRING_="attrib " || trim(left(NAME)) || " label='" ||
                        trim(left(LABEL)) || "' length=8";
                end;

                call symput("ATT_" || compress(put(_N_, best.)), STRING_);

                *call symput("ATT_" || compress(put(order, best.)), string_);
                if _N_=1 then VARS_=compress(NAME);
                else VARS_=trim(left(VARS_)) || " " || compress(NAME);

                if EOF then do;
                    call symput("COUNTTO", put(_N_, best.));
                    call symput("KEEPVAR", VARS_);
                end;
            run;

            %qc_reduce_length(&IN_DATA.);

            *** Assign attributes ***;
            data &OUTSET. (keep=&KEEPVAR. label="&DSETLAB." );
                retain &KEEPVAR. ;
                %do ii=1 %to &COUNTTO.;
                    &&ATT_&ii..;
                %end;

                set &IN_DATA.;
                informat _all_;
                format _all_;
            run;

            %qc_reduce_length(&OUTSET.);

            data &OUTSET.(label="&DSETLAB." );
                set &OUTSET.;
            run;

            /*Deleting Intermediate datasets created*/
            %if "&DEBUG." ne "Y" %then %do;
                /*Deleting Intermediate datasets created*/
                proc datasets lib=work nolist;
                    delete ___SPEC_: ;
                quit;
                run;
            %end;

        %mend SDTM_TRIAL_attrib;
