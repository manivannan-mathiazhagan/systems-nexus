***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    MedDRA_coding.sas                                                                ***;
***                                                                                                 ***;
*** Purpose:       Program to merge Coded terms or Low Level terms as per needed dictionary         ***;
***                and generate all needed coded variables                                          ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    11Jul2022                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** AEDSET   | the dataset name of the AE - with needed variables     | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** AEVAR    | the variable name in which Low level term or Term is   | No default      |   Yes     ***;
***          | stored - based on which Coding has to be done          |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** MEDPATH  |  the path where MedDRA datasets are stored             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** OUTDSET  | the name of OUTPUT dataset                             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DOMAIN   | the name of Domain in which coding has to be done      | AE              |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          | N               |   No      ***;
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &OUTDSET.                                                                   ***;
***                                                                                                 ***;
*** Variables:          Below mentioned variables are added                                         ***;
***                                                                                                 ***;
***                     &DOMAIN.LLT         -   Lowest Level Term                                   ***;
***                     &DOMAIN.LLTCD       -   Lowest Level Term Code                              ***;
***                     &DOMAIN.DECOD       -   Dictionary-Derived Term                             ***;
***                     &DOMAIN.PTCD        -   Preferred Term Code                                 ***;
***                     &DOMAIN.HLT         -   High Level Term                                     ***;
***                     &DOMAIN.HLTCD       -   High Level Term Code                                ***;
***                     &DOMAIN.HLGT        -   High Level Group Term                               ***;
***                     &DOMAIN.HLGTCD      -   High Level Group Term Code                          ***;
***                     &DOMAIN.BODSYS      -   Body System or Organ Class                          ***;
***                     &DOMAIN.BDSYCD      -   Body System or Organ Class Code                     ***;
***                     &DOMAIN.SOC         -   Primary System Organ Class                          ***;
***                     &DOMAIN.SOCCD       -   Primary System Organ Class Code                     ***;
***                     VERSION             -   The MedDRA version as mentioned in MedDRA dataset   ***;
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
*** Other:              1. &DOMAIN.SOC and &DOMAIN.BODSYS are same                                  ***;
***                     2. &DOMAIN.SOCCD and  &DOMAIN.BDSYCD are same                               ***;
***                     3. All CD( Codes) variables(LLTCD, PTCD , ... etc) are in numeric           ***;
***                     4. Remove or rename variables if the output variables as mentioned above    ***;
***                        are already present in &INDSET.                                          ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%macro MedDRA_coding(INDSET=,TERMVAR=,MEDPATH=,OUTDSET=,DOMAIN=AE,DEBUG=N);

libname MEDDRA "&MEDPATH." ;

/* Taking One HLT per LLT as there may be multiple HLT within same LLT */
proc sort data = MEDDRA.MEDDRA out= LLT_HLT(keep = LLTNAME HLTNAME) nodupkey;
    by LLTNAME HLTNAME;
run;

data LLT_HLT_1;
    set LLT_HLT;
    by LLTNAME HLTNAME;
    if first.LLTNAME;
run;

/* Taking One HLGT per LLT as there may be multiple HLGT within same LLT */
proc sort data = MEDDRA.MEDDRA out= LLT_HLGT(keep = LLTNAME HLGTNAME) nodupkey;
    by LLTNAME HLGTNAME;
run;

data LLT_HLGT_1;
    set LLT_HLGT;
    by LLTNAME HLGTNAME;
    if first.LLTNAME;
run;

proc sort data = MEDDRA.MEDDRA out= VERSION(keep = VERSION) nodupkey;
    by VERSION;
run;

data _null_;
   set VERSION;
   call symput('VERSION',strip(VERSION));
run;

/* Merging coded datasets with input dataset */
proc sql noprint;

    create table CODED_UNQ as
    select
    a.TEMP_TERM as __CD_TEMP_TERM,
    b.LLTNAME   as __CD_LLTNAME,   b.LLTCODE   as __CD_LLTCODE,
    c.PTNAME    as __CD_PTNAME,    b.PTCODE    as __CD_PTCODE,
    d.SOCTEXT   as __CD_SOCTEXT,   c.PT_SOC    as __CD_SOCCODE,
    e.HLTNAME   as __CD_HLTNAME,   f.HLTCODE   as __CD_HLTCODE,
    g.HLGTNAME  as __CD_HLGTNAME,  h.HLGTCODE  as __CD_HLGTCODE
    from

    ( select distinct &TERMVAR. as TEMP_TERM from &INDSET. where &TERMVAR. ne "" ) a

    left join
    MEDDRA.LLT b
    on upcase(strip(a.TEMP_TERM)) eq upcase(strip(b.LLTNAME))

    left join
    MEDDRA.PT c
    on b.PTCODE eq c.PTCODE

    left join
    MEDDRA.SOC d
    on c.PT_SOC eq d.SOC

    left join
    LLT_HLT_1 e
    on b.LLTNAME eq e.LLTNAME

    left join
    MEDDRA.HLT f
    on e.HLTNAME eq f.HLTNAME

    left join
    LLT_HLGT_1 g
    on b.LLTNAME eq g.LLTNAME

    left join
    MEDDRA.HLGT h
    on g.HLGTNAME eq h.HLGTNAME

    ;

    create table &INDSET._CD_ALL as
        select a.*,b.*
        from
            &INDSET. a
            left join CODED_UNQ b
            on a.&TERMVAR. eq b.__CD_TEMP_TERM ;
quit;

/* Creating needed variables */
data &OUTDSET.;
    length VERSION $200.;
    set &INDSET._CD_ALL;
    
    array  chars[6]    $200.   &DOMAIN.LLT   &DOMAIN.DECOD  &DOMAIN.HLT   &DOMAIN.HLGT    &DOMAIN.BODSYS  &DOMAIN.SOC ;
    array  chars_in[6] $200.   __CD_LLTNAME  __CD_PTNAME    __CD_HLTNAME  __CD_HLGTNAME   __CD_SOCTEXT    __CD_SOCTEXT ;
    array  numbs[6]    8.      &DOMAIN.LLTCD &DOMAIN.PTCD   &DOMAIN.HLTCD &DOMAIN.HLGTCD  &DOMAIN.BDSYCD  &DOMAIN.SOCCD ;
    array  numbs_in[6] $200.   __CD_LLTCODE  __CD_PTCODE    __CD_HLTCODE  __CD_HLgTCODE   __CD_SOCCODE   __CD_SOCCODE ;

    do i = 1 to 6;
        CHARS[i] = CHARS_IN[i];
        if NUMBS_IN[i] ne "" then NUMBS[i] = input(NUMBS_IN[i],best.);
    end;
    
    if cmiss(&DOMAIN.LLT,&DOMAIN.DECOD,&DOMAIN.HLT,&DOMAIN.HLGT,&DOMAIN.BODSYS,&DOMAIN.SOC) ne 6 then VERSION = "&VERSION.";
    else VERSION = "";
    
    drop __CD_: i;
run;


%if "&DEBUG." ne "Y" %then
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete &INDSET._CD_ALL CODED_UNQ LLT_HLT_1 LLT_HLGT_1 LLT_HLT LLT_HLGT;
            quit;
        run;
    %end;

%mend MedDRA_coding;

 %MedDRA_coding(INDSET=chk1, 
                TERMVAR=verbterm, 
                MEDPATH=E:\Projects\Instat\MedDRA\Version 23\SASDATA, 
                 OUTDSET=AE1); 
