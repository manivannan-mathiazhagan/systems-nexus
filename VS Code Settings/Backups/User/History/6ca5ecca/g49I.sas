***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    exp_adam_vlm_fmt.sas                                                             ***;
***                                                                                                 ***;
*** Purpose:       Generate ADaM Value-Level Metadata (VLM) and Formats Excel for define.xml.       ***;
***                Internally runs AMacVLM (derive VLM from BDS) and AMacFmt (derive formats        ***;
***                from SPECS/ADaM), and exports two sheets: ValueMetadata and Formats.             ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    08-Aug-2025                                                                      ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:   None                                                                              ***;
***                                                                                                 ***;
*** Requirements:                                                                                   ***;
*** - Libraries ADAM (BDS datasets) and SPECS (DOMAINS sheet) must be assigned                      ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
*** Excel File:      <ADAM Library Path>\Value_Level_Data.xlsx                                      ***;
*** Sheets:          ValueMetadata, Formats                                                         ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies:                                                                                   ***;
*** Data sets:       ADaM BDS datasets (with PARAMCD)                                               ***;
*** Libraries:       ADAM, SPECS                                                                    ***;
***-------------------------------------------------------------------------------------------------***;
*** Modification History                                                                            ***;
***-------------------------------------------------------------------------------------------------***;
*** Date       | Programmer               | Description                                             ***;
***------------|--------------------------|---------------------------------------------------------***;
*** 08Aug2025  | Manivannan Mathialagan   | Wrapped existing flow into %exp_adam_vlm_fmt() macro    ***;
***            |                          | and added robust length harmonization and export        ***;
***-------------------------------------------------------------------------------------------------***;

%macro exp_adam_vlm_fmt();

  /* === AMACVLM: Build VLM data from ADaM BDS === */
  %macro amacvlm();
    /* Step 1: Identify all BDS datasets in ADaM (those with PARAMCD and no underscore) */
    proc sql noprint;
      select distinct catx(".", libname, memname)
        into :allmem separated by " "
      from dictionary.columns
      where upcase(libname) = "ADAM"
        and upcase(name) = "PARAMCD"
        and index(memname, "_") = 0;

      /* Step 2: Max character lengths across the discovered BDS datasets */
      create table var_lengths as
      select upcase(name) as name,
             max(length) as maxlen
      from dictionary.columns
      where upcase(libname) = "ADAM"
        and upcase(memname) in (
          select distinct upcase(memname)
          from dictionary.columns
          where upcase(libname) = "ADAM"
            and upcase(name) = "PARAMCD"
            and index(memname, "_") = 0
        )
        and type = "char"
      group by name;
    quit;

    /* Step 3: Build LENGTH statement */
    data _null_;
      set var_lengths end=last;
      length lenstmt $10000;
      retain lenstmt "";
      lenstmt = catx(" ", lenstmt, catx(" ", name, "$", maxlen));
      if last then call symputx('lenstmt', lenstmt);
    run;

    /* Step 4: Create combined ADAMS safely (harmonized lengths) */
    data ADAMS;
      retain DATS PARAMCD PARAM PARCAT1 PARCAT2 AVALC1;
      length &lenstmt.;
      set &allmem. indsname=var1;

      if AVAL ne . then AVALC1 = strip(put(AVAL,best.));
      else AVALC1 = AVALC;

      DATS = scan(var1, 2, ".");

      array chk[2] $200 PARCAT1 PARCAT2;
      do j=1 to 2;
        chk[j] = coalescec(chk[j],"");
      end;
      drop j;
    run;

    /* Type sniff + width calc */
    proc sql noprint;
      create table VAL1 as 
      select DATS,PARCAT1,PARCAT2,PARAMCD,PARAM,AVALC1,
             case when AVALC1 ne "" and length(compress(AVALC1,'.-','kd')) = length(compress(AVALC1))
                  then input(AVALC1,?best.) else . end  as RESN,
             case when calculated RESN ne .
                       then strip(put(calculated RESN,best.))
                  when length(compress(AVALC1,'.-','kd')) ne length(compress(AVALC1)) and AVALC1 ne ""
                       then "CHKSYMBOL" 
                  else "" end as RESC,
             case when calculated RESN ne . then length(calculated RESC) 
                  when calculated RESC = "CHKSYMBOL" then 2000
                  else 0 end as LN_AV, 
             case when calculated RESN ne . and index(calculated RESC,".") > 0
                       then length(scan(calculated RESC,2,"."))
                  else 0 end as LN_TWO
      from ADAMS 
      where not missing(AVALC1);

      create table VAL2 as 
      select distinct DATS,PARCAT1,PARCAT2,PARAMCD,PARAM, 
             max(LN_AV)  as TOT_LEN,
             max(LN_TWO) as TWO_LEN,
             max(length(AVALC1)) as MAX_TOT
      from VAL1 
      group by DATS,PARCAT1,PARCAT2,PARAMCD,PARAM;

      create table VAL3 as 
      select DATS,PARCAT1,PARCAT2,PARAMCD,PARAM,MAX_TOT,
             case when TOT_LEN = 0 or TOT_LEN = 2000 then "text"
                  when TOT_LEN ne 0 and TWO_LEN = 0 then "integer"
                  when TOT_LEN ne 0 and TWO_LEN ne 0 then "float"
                  else "" end as TYPE1,
             case when calculated TYPE1 = 'float'
                       then cats(strip(put(TOT_LEN,best.)),".",strip(put(TWO_LEN,best.)))
                  else "" end as FRMT1 
      from VAL2
      order by DATS,PARCAT1,PARCAT2,PARAMCD,PARAM;

      /* Target OUTDSN structure */
      create table OUTDSN (
        dom     char(200) label="Dataset",
        tst     char(200) label="Grouping Variable",
        testcd  char(200) label="Group Value",
        test    char(200) label="Group Label",
        grp1    char(200) label="Grouping Variable 1",
        grp1val char(200) label="Group Value 1",
        grp2    char(200) label="Grouping Variable 2",
        grp2val char(200) label="Group Value 2",
        grp3    char(200) label="Grouping Variable 3",
        grp3val char(200) label="Group Value 3",
        grp4    char(200) label="Grouping Variable 4",
        grp4val char(200) label="Group Value 4",
        cla     char(2000) label="Where Clause",
        res     char(200) label="Result Variable",
        len     num(8)    label="Result Value Length",
        type    char(200) label="Result Value Type",
        fmt     char(200) label="Result Value Format",
        cntr    char(200) label="Control or Format",
        orig    char(200) label="Origin",
        resq    char(200) label="Role",
        cmnt    char(200) label="Comment"
      );
    quit;

    data VLM_DATA;
      retain dom tst testcd test grp1 grp1val grp2 grp2val grp3 grp3val grp4 grp4val cla res type len fmt cntr orig resq cmnt ;
      set OUTDSN VAL3;
      dom   = DATS;
      tst   = "PARAMCD";
      testcd= PARAMCD;
      test  = PARAM;
      len   = MAX_TOT;
      type  = TYPE1;
      res   = ifc(type="text","AVALC","AVAL");
      fmt   = FRMT1;
      cntr  = "";
      orig  = "";
      resq  = "Topic";
      cmnt  = "";

      if PARCAT1 ne "" then do; grp1="PARCAT1"; grp1val=PARCAT1; end; else do; grp1=""; grp1val=""; end;
      if PARCAT2 ne "" then do; grp2="PARCAT2"; grp2val=PARCAT2; end; else do; grp2=""; grp2val=""; end;
      grp3=""; grp3val=""; grp4=""; grp4val="";

      length TST_TXT GRP1_TXT GRP2_TXT $250;
      TST_TXT  = catx(" ", strip(tst), "EQ", strip(testcd)) || "(" || strip(test) || ")"; 
      GRP1_TXT = catx(" EQ ", GRP1, GRP1VAL);
      GRP2_TXT = catx(" EQ ", GRP2, GRP2VAL);
      cla      = catx(" and ", TST_TXT, GRP1_TXT, GRP2_TXT);

      keep dom tst testcd test grp1 grp1val grp2 grp2val grp3 grp3val grp4 grp4val cla res type len fmt cntr orig resq cmnt ;
    run;

    proc datasets lib=work nolist; delete adams val3 val2 val1 outdsn var_lengths; quit;
  %mend amacvlm;

  /* === AMACFMT: Derive formats from SPECS + ADaM === */
  %macro amacfmt();
    proc sql noprint;
      select cats("SPECS.", DATASET),
             trim(DATASET)
        into :LIST_SPEC separated by " ",
             :LIST_DS   separated by " "
      from SPECS.DOMAINS
      where upcase(INSTUDY_) = "Y";

      /* char lengths across SPECS selected datasets */
      create table var_lengths as
      select upcase(name) as name,
             max(length) as maxlen
      from dictionary.columns
      where upcase(libname) = "SPECS"
        and upcase(memname) in (
          select distinct DATASET from SPECS.DOMAINS where upcase(InStudy_) = "Y"
        )
        and type = "char"
      group by name;
    quit;

    data _null_;
      set var_lengths end=last;
      length lenstmt $10000; retain lenstmt "";
      lenstmt = catx(" ", lenstmt, catx(" ", name, "$", maxlen));
      if last then call symputx('lenstmt', lenstmt);
    run;

    /* Pull only rows that look like controlled lists / formats (skip date/time/Meddra/etc.) */
    data ADAM_FMT(rename = (CONTROL_OR_FORMAT = FORMAT));
      length &lenstmt.;
      set &LIST_SPEC.;

      if upcase(strip(CONTROL_OR_FORMAT)) not in ("", "ISO 8601", "ISO8601", "MEDDRA", "WHODRUG", "IS08601")
         and index(upcase(CONTROL_OR_FORMAT),"DATE") = 0
         and index(upcase(CONTROL_OR_FORMAT),"TIME") = 0
         and length(compress(CONTROL_OR_FORMAT, '0123456789.')) > 1
         and KEEP = 1;

      keep CONTROL_OR_FORMAT DATASET VARIABLE TYPE KEEP;
    run;

    /* Map VAR -> ORDER/CODE variables heuristically */
    data ADAM_FMT_IN;
      length ORD_VAR COD_VAR $32.;
      retain DATASET VARIABLE FORMAT TYPE ORD_VAR COD_VAR;
      set ADAM_FMT;

      /* order variable */
      if VARIABLE in ("SEX","RACE","ETHNIC","AVISIT",
                      "TRT01P","TRT01A","TRT02P","TRT02A",
                      "TRTP","TRTA","SHIFT1","PARCAT1","PARCAT2","AESEV","AEREL")
        then ORD_VAR = cats(VARIABLE,"N");
      else if VARIABLE = "VISIT"   then ORD_VAR = "VISITNUM";
      else if VARIABLE = "AVALCAT1" then ORD_VAR = "AVALCA1N";
      else if VARIABLE in ("PARAM","PARAMCD") then ORD_VAR = "PARAMN";
      else ORD_VAR = "";

      /* code variable */
      if VARIABLE in ("SEXN","RACEN","ETHNICN","AVISITN",
                      "TRT01PN","TRT01AN","TRT02PN","TRT02AN","TRTPN","TRTAN",
                      "SHIFT1N","PARCAT1N","PARCAT2N","AESEVN","AERELN")
        then COD_VAR = substr(VARIABLE, 1, length(VARIABLE)-1);
      else if VARIABLE = "VISITNUM"             then COD_VAR = "VISIT";
      else if VARIABLE = "AVALCA1N"             then COD_VAR = "AVALCAT1";
      else if VARIABLE in ("PARAMN","PARAMCD")  then COD_VAR = "PARAM";
      else if VARIABLE in ("ARMCD","ACTARMCD")  then COD_VAR = substr(VARIABLE,1,length(VARIABLE)-2);
      else COD_VAR = "";
    run;

    proc sql noprint;
      create table OUTDSN
      ( ORDER  num(8)   label="Order",
        FORMAT char(200) label="Format",
        CODE   char(200) label="Code",
        VALUE  char(200) label="Value"
      );
    quit;

    %macro get_fmt(dst, var, fmt, or_var=, co_var=);
      %local dsid rc varnum_var varnum_code varnum_order VAR_TYPE CO_VAR_TYPE keeplist selectlist orderbylist bylist;

      %let var    = %upcase(&var);
      %let co_var = %upcase(&co_var);
      %let or_var = %upcase(&or_var);

      %let dsid = %sysfunc(open(ADAM.&dst.));
      %if &dsid %then %do;
        %let varnum_var = %sysfunc(varnum(&dsid,&var));
        %if &varnum_var = 0 %then %do;
          %put ERROR: Variable &var not found in ADAM.&dst..;
          %let rc=%sysfunc(close(&dsid)); %return;
        %end;

        %if %length(&co_var) %then %do;
          %let varnum_code = %sysfunc(varnum(&dsid,&co_var));
          %if &varnum_code = 0 %then %do;
            %put ERROR: CODE variable &co_var not found in ADAM.&dst..;
            %let rc=%sysfunc(close(&dsid)); %return;
          %end;
        %end;
        %else %let varnum_code = &varnum_var;

        %if %length(&or_var) %then %do;
          %let varnum_order = %sysfunc(varnum(&dsid,&or_var));
          %if &varnum_order = 0 %then %do;
            %put WARNING: ORDER variable &or_var not found in ADAM.&dst.. Ignoring.;
            %let or_var=;
          %end;
        %end;
        %else %let varnum_order=0;

        %let VAR_TYPE    = %sysfunc(vartype(&dsid,&varnum_var));
        %let CO_VAR_TYPE = %sysfunc(vartype(&dsid,&varnum_code));
        %let rc=%sysfunc(close(&dsid));
      %end;
      %else %do; %put ERROR: Dataset ADAM.&dst. could not be opened.; %return; %end;

      %let keeplist    = &var;
      %let selectlist  = &var, "&fmt." as FMT;
      %let orderbylist = &var;
      %let bylist      = &var;

      %if %length(&co_var) %then %do;
        %let keeplist   = &keeplist &co_var;
        %let selectlist = &selectlist, &co_var;
      %end;

      %if %length(&or_var) %then %do;
        %let keeplist    = &keeplist &or_var;
        %let selectlist  = &or_var, &selectlist;
        %let orderbylist = &or_var, &orderbylist;
        %let bylist      = &or_var &bylist;
      %end;

      data FMT_1; set ADAM.&dst.; keep &keeplist; run;

      proc sql noprint;
        create table FMT_2 as
        select distinct &selectlist
        from FMT_1
        where not missing(&var)
          %if %length(&co_var) %then and not missing(&co_var)
          %if %length(&or_var) %then and not missing(&or_var)
        order by &orderbylist;
      quit;

      data FMT_3;
        length CODE VALUE FORMAT $200 ORDER 8;
        set FMT_2;
        by &bylist;
        ORDER  = _N_;
        FORMAT = "&fmt.";

        /* VALUE from co_var if present; else from var */
        %if %length(&co_var) %then %do;
          %if &CO_VAR_TYPE = C %then %do; VALUE = strip(&co_var); %end;
          %else %do; VALUE = strip(put(&co_var,best.)); %end;
        %end;
        %else %do;
          %if &VAR_TYPE = C %then %do; VALUE = strip(&var); %end;
          %else %do; VALUE = strip(put(&var,best.)); %end;
        %end;

        /* CODE from var always */
        %if &VAR_TYPE = C %then %do; CODE = strip(&var); %end;
        %else %do; CODE = strip(put(&var,best.)); %end;

        keep CODE VALUE FORMAT ORDER;
      run;

      proc append base=OUTDSN data=FMT_3 force; run;
      proc datasets lib=work nolist; delete FMT_:; quit;
    %mend get_fmt;

    /* Drive get_fmt from ADAM_FMT_IN */
    data _null_;
      set ADAM_FMT_IN;
      call execute(
        '%get_fmt('||
        'dst='    ||strip(DATASET)||
        ',var='   ||strip(VARIABLE)||
        ',fmt='   ||strip(FORMAT)||
        ',or_var='||strip(ORD_VAR)||
        ',co_var='||strip(COD_VAR)||
        ');'
      );
    run;

    proc sort data=OUTDSN out=FMT_SORTED nodupkey; by FORMAT CODE VALUE; run;
    proc sort data=FMT_SORTED; by FORMAT ORDER CODE VALUE; run;

    data FMT_DATA(rename=(ORD=ORDER));
      set FMT_SORTED;
      by FORMAT ORDER CODE VALUE;
      drop ORDER;
      if first.FORMAT then ORD=1; else ORD+1;
    run;

    proc datasets lib=work nolist; delete var_lengths ADAM_FMT ADAM_FMT_IN FMT_SORTED; quit;
  %mend amacfmt;

  /* === Run and export === */
  %amacvlm;
  %amacfmt;

  ods noresults;
  %let adam_path = %sysfunc(pathname(ADAM));
  ods excel file="&adam_path.\Value_Level_Data.xlsx" 
      options (autofilter='ALL' flow="DATA" frozen_headers="ON");

  ods excel options(sheet_name="ValueMetadata");
  proc print data=VLM_DATA noobs label; run;

  ods excel options(sheet_name="Formats");
  proc print data=FMT_DATA noobs label; run;

  ods excel close;
  ods results;

%mend exp_adam_vlm_fmt;
