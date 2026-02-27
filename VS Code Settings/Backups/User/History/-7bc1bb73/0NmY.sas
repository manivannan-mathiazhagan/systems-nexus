/*****************************************************************************************************
 *Program Name:           _runall-TrialDS.sas
 *Project Name/No.:       FER-021-003
 *Purpose:                Program to create the Trial design datasets from GDOC Trial data.
 *Original Author (Date): Manivannan (24Jun2024)
 *
 *   Note : If this program needs to be used by other projects,
 *          1. Update the dbver parameter value in SETENV macro call statement to point to SDTM folder.
 *          2. Updtae the GDOC key value in the imp_gdoc macro call statements.
 *          3. Copy the SDTM_ATTRIB and reduce_len macros
 *******************************************************************************************************/
;

/*** Macro to create Trial design datasets from Trial design data ***/
%macro trialds(ds);

    ** Load Trial design GDOC data into datasets in Specs Library**;
    %imp_gdocjson(sheet=_&ds,gdoc_key=&sdtm_specs_gdoc_key,
        outlib=WORK,force=1,add_rownums=1);

    %if "&ds." eq "TS" %then %do;
        data _null_;
            set _&DS;
            type_ver=vtype(TSVCDVER);
            call symput("TYPE",TYPE_VER);
        run;
        %if "&TYPE." eq "N" %then %do;
            data DS1;
                set _&DS(rename=(TSVCDVER=TSVCDVRN));
                DY=TODAY();
                if TSVCDVRN ne . and TSVCDVRN le DY then TSVCDVER=
                    strip(put(TSVCDVRN,is8601da.));
                else if TSVCDVRN ne . and TSVCDVRN gt DY then TSVCDVER=
                    strip(put(TSVCDVRN-21916,is8601da.));
            run;
        %end;
        %else %do;
            data DS1;
                set _&DS;
            run;
        %end;
    %end;
    %else %if "&ds." eq "TI" %then %do;
        data _null_;
            set _&DS;
            type_ver=vtype(TIVERS);
            call symput("TYPE",TYPE_VER);
        run;
        %if "&TYPE." eq "N" %then %do;
            data DS1;
                set _&DS(rename=(TIVERS=TIVERSN));
                TIVERS=strip(put(TIVERSN,8.1));
            run;
        %end;
        %else %do;
            data DS1;
                set _&DS;
            run;
        %end;
    %end;
    %else %do;
        data DS1;
            set _&DS;
        run;
    %end;

    /*Assigning attributes from Spec Gdoc*/
    %sdtm_trial_attrib(SDTM_DS=&DS,IN_DATA=DS1);

    proc datasets library=WORK memtype=data kill noprint;
    quit;

%mend trialds;

/*Storing Log in Projects folder*/
proc printto new log="&droot\&dbpath\Logs\Trial_Domains.log";
run;

%trialds(TA);

%trialds(TE);

%trialds(TI);

%trialds(TS);

%trialds(TV);

/*Closing Log printing*/
proc printto;
run;
