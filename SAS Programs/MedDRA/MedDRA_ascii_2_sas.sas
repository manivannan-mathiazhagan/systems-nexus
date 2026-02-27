***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    MedDRA_ascii_2_sas.sas                                                           ***;
***                                                                                                 ***;
*** Purpose:       Program to create the MedDRA SAS datasets from raw ASCII files downloaded        ***;
***                from  meddra.org                                                                 ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    08Jul2022                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name                | Description                                 | Default value   | Required  ***;
***                     |                                             |                 | Parameter ***;
***---------------------+---------------------------------------------+-----------------+-----------***;
*** RAWPATH             | the path to raw ascii files location        | No default      |   Yes     ***;
***                     |                                             |                 |           ***;
***---------------------+---------------------------------------------+-----------------+-----------***;
*** REMOVENONCURRENT    | Specifies if non-current terms should be    | No default      |   Yes     ***;
***                     | retained                                    |                 |           ***;
***                     |                                             |                 |           ***;
***---------------------+---------------------------------------------+-----------------+-----------***;
*** OUTPATH             | the path to final dictionary location       | No default      |   Yes     ***;
***                     |                                             |                 |           ***;
***---------------------+---------------------------------------------+-----------------+-----------***;
*** COMPRESS            | Specifies if the output table should be     | No default      |   Yes     ***;
***                     | compressed                                  |                 |           ***;
***                     |                                             |                 |           ***;
***---------------------+---------------------------------------------+-----------------+-----------***;
*** VERSION             | Specifies the text to be written to the     | No default      |   Yes     ***;
***                     | version column                              |                 |           ***;
***                     |                                             |                 |           ***;   
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &OUTDSET.                                                                   ***;
***                                                                                                 ***;
*** Variables:          As below                                                                    ***;
***                                                                                                 ***;
***                   compress:        Compressed version of term.                                  ***;
***                   llttext:         Duplicate of lltname, used to return proper information.     ***;
***                   lltname:         Low Level Term text.                                         ***;                                                    *
***                   lltcode:         Low Level Term Code.                                         ***;
***                   ptname:          Preferred/Reported Term text.                                ***;
***                   ptcode           Preferred/Reported Term code.                                ***;
***                   hltname:         High Level Term text.                                        ***;
***                   hltcode:         High Level Term code.                                        ***;
***                   hlgtname:        High Level Group Term text.                                  ***;
***                   hlgtcode:        High Level Group Term code.                                  ***;
***                   soccode:         Combined System Organ Class code and text.                   ***;
***                   pt_soc:          Primary SOC code value.                                      ***;
***                   primesoc:        Primary SOC Flag.                                            ***;
***                   version:         Dictionary Version Text.                                     ***;
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

%macro MedDRA_ascii_2_sas(RAWPATH,REMOVENONCURRENT=Y,OUTPATH,COMPRESS=Y,VERSION);
 
/*-----------------------------------------------------------------------------------------*/
/*  !!! DO NOT EDIT BELOW THIS LINE !!!                                                    */
/*-----------------------------------------------------------------------------------------*/

/*  Assign libref for output location  */
libname DICT "&outpath";

/* Create System Organ Class (SOC) data set. */
data DICT.SOC (keep=SOC SOCTEXT);
    length SOC $8;
    infile "&rawpath.\soc.asc" dlm='$' dsd;
    input SOCNUM SOCTEXT : $200. F3 $ F4 F5 F6 $ F7 F8 F9;
    
    SOCTEXT     =   upcase(SOCTEXT);
    SOC         =   putn(SOCNUM,'z8.');
run;

/* Create SOC to High Level Group Term (HLGT) data set. */
data SOC_HLGT (keep=SOC HLGTCODE);
    length SOC HLGTCODE $8;
    infile "&rawpath.\soc_hlgt.asc" dlm='$' dsd;
    input SOCNUM HLGTNUM;
    SOC         =   putn(SOCNUM,'z8.');
    HLGTCODE    =   putn(HLGTNUM,'z8.');
run;

/* Create High Level Group Term (HLGT) data set. */
data DICT.HLGT (keep=HLGTCODE HLGTNAME);
    length HLGTCODE $8;
    infile "&rawpath.\hlgt.asc" dlm='$' dsd;
    input HLGTNUM HLGTNAME : $200. F3 F4 F5 $ F6 F7 F8;
    
    HLGTNAME    =   upcase(HLGTNAME);
    HLGTCODE    =   putn(HLGTNUM,'z8.');
run;

/* Create High Level Group Term (HLGT) to High Level Term (HLT) data set. */
data HLGT_HLT (keep=hlgtcode hltcode);
    length HLTCODE hlgtcode $8;
    infile "&rawpath.\hlgt_hlt.asc" dlm='$' dsd;
    input HLGTNUM HLTNUM;
    
    HLTCODE     =   putn(HLTNUM,'z8.');
    HLGTCODE    =   putn(HLGTNUM,'z8.');
run;

/* Create High Level Term (HLT) data set. */
data DICT.HLT (keep=hltcode hltname);
    length HLTCODE $8;
    infile "&rawpath.\hlt.asc" dlm='$' dsd;
    input HLTNUM HLTNAME : $200. F3 F4 F5 $ F6 F7 F8;
    
    HLTCODE     =   putn(HLTNUM,'z8.');
    HLTNAME     =   upcase(HLTNAME);
run;

/* Create High Level Term (HLT) to Preferrd Term (PT) data set. */
data HLT_PT (keep=HLTCODE PTCODE);
    length HLTCODE PTCODE $8;
    infile "&rawpath.\hlt_pt.asc" dlm='$' dsd;
    input HLTNUM MEDNUM;
    
    HLTCODE     =   putn(HLTNUM,'z8.');
    PTCODE      =   putn(MEDNUM,'z8.');
run;

/* Create Preferred Term (PT) data set. */
data DICT.PT (keep=PTCODE PTNAME PT_SOC WHOCODE ICD9 ICD9A);
    length PT_SOC PTCODE $8;
    infile "&rawpath.\pt.asc" dlm='$' dsd;
    input MEDNUM PTNAME : $200. F3 SOCNUM WHOCODE $ F6 F7 $ ICD9 $ ICD9A $ F10 F11; 
    
    PTNAME      =   upcase(PTNAME);
    PT_SOC      =   putn(SOCNUM,'z8.');
    PTCODE      =   putn(MEDNUM,'z8.');
run;

/* Create Low Level Term  (LLT) data set. */
data LLT DICT.LLT (keep=LLTCODE LLTNAME PTCODE whoCODE ICD9 ICD9A);
    length LLTCODE PTCODE $8;
    infile "&rawpath.\llt.asc" dlm='$' dsd;
    INPUT VERBNUM LLTNAME : $200. MEDNUM WHOCODE $ F5 F6 $ ICD9 $ ICD9A $ F9 F10 $ F11;
    
    LLTNAME     =   upcase(LLTNAME);
    PTCODE      =   putn(MEDNUM,'z8.');
    LLTCODE     =   putn(VERBNUM,'z8.');
    
    if "&removeNonCurrent"='Y' then if f10='N' then delete;
run;


/* Start to merge data sets together to create the MEDDRA data set. */
proc sql;
     create table MEDDRA as                   /* Merge SOC and High Level Group Term */
     select a.*, b.HLGTCODE
     from DICT.soc a,
          SOC_HLGT b
          where a.SOC=b.SOC;
     create table MEDDRA as                   /* Merge in High Level Term Code */
     select a.*, b.HLTCODE
     from MEDDRA a,
          HLGT_HLT b
          where a.HLGTCODE=b.HLGTCODE;
     create table MEDDRA as                   /* Merge in Preferred Term Code */
     select a.*, b.PTCODE
     from MEDDRA a,
          HLT_PT b
          where a.HLTCODE=b.HLTCODE;
     create table MEDDRA as                   /* Merge in Preferred Term and other info. */
     select a.*, b.PTNAME, b.PT_SOC, b.WHOCODE, b.ICD9, b.ICD9A
     from MEDDRA a,
          DICT.PT b
          where a.PTCODE=b.PTCODE;
     create table MEDDRA as                   /* Merge in Low Level Term and other info. */
     select a.*, b.LLTCODE, b.LLTNAME, b.ICD9, b.ICD9A
     from MEDDRA a,
          LLT b
          where a.PTCODE=b.PTCODE;
     create table MEDDRA as                   /* Merge in HLGT text.*/
     select a.*, b.HLGTNAME
     from MEDDRA a,
          DICT.HLGT b
          where a.HLGTCODE=B.HLGTCODE;
     create table MEDDRA as                   /* Merge in HLT text.*/
     select a.*, b.HLTNAME
     from MEDDRA a,
          DICT.HLT b
          where a.HLTCODE=b.HLTCODE;
      quit;
run;

***************************************************************************************;
* Create combined SOCCODE field, LLTTEXT and VERSION fields and set primesoc flag     *;
***************************************************************************************;
data MEDDRA/*(drop=soc soctext)*/;     
    length COMPRESS $200 PRIMESOC 8 LLTTEXT $200 VERSION $40;
    set MEDDRA;
    if LLTNAME  =   '' then delete;
    
    if PT_SOC = SOC then PRIMESOC=0; /* to sort by primary system */
    else PRIMESOC=1;  
    
    SOCCODE     =   trim(left(SOC))||' - '||SOCTEXT;
    LLTTEXT     =   LLTNAME;                                
    VERSION     =   "&VERSION";                        
run;

***************************************************************************************;
** Re-order table columns and keep only what is needed and write to output directory **;
***************************************************************************************;
proc sql;
     create table DICT.MEDDRA as
         select a.COMPRESS, LLTTEXT,
                a.LLTNAME, a.LLTCODE, 
                a.PTNAME, a.PTCODE, 
                a.HLTNAME, a.HLTCODE, 
                a.HLGTNAME, a.HLGTCODE,
                a.SOCTEXT, a.SOC, a.SOCCODE, 
                a.PRIMESOC, a.VERSION
        from MEDDRA a;
quit;

***************************************************************************************;
** Set macro parameters for compress algorithm                                       **;
***************************************************************************************;
%let DSNAME=MEDDRA;      /* Dictionary data set name */
%let SUBJECT=LLTNAME;    /* Name of field to be compressed */
%let COMPFLD=COMPRESS;   /* Name of field to contain compressed value */

** Call compress entry **;
/*dm 'af c=s.cpcode.compdict.scl';*/

***************************************************************************************;
* Create listing of duplicate compress Terms                                          *;
***************************************************************************************;
proc sort data=DICT.MEDDRA out=DUPCHK;
    by COMPRESS SOCCODE; 
run;

data DUPCHK;
    set DUPCHK;
    by COMPRESS SOCCODE;  
    
    if first.SOCCODE & last.SOCCODE then delete;

proc print;
title1 'Listing of duplicate compress terms';
run;

***************************************************************************************;
* Clear duplicate compress values from final meddra data set                          *;
***************************************************************************************;
proc sort data=DICT.MEDDRA;
    by COMPRESS SOCCODE;
run;

%macro runit; 
    
    data DICT.MEDDRA
        %if &compress = Y %then %do;
            (compress=yes)
        %end;
        ;
    
        set DICT.MEDDRA;
        by COMPRESS SOCCODE;
        if ^(first.SOCCODE and  last.SOCCODE) then compress='';
    run;

%mend runit;
%runit;

***************************************************************************************;
*  Re-sort final table                                                                *;
***************************************************************************************;
proc sort data=DICT.MEDDRA NODUPLICATES; 
    by COMPRESS PTCODE PRIMESOC SOCCODE;   
run;    

***************************************************************************************;
*  Add index on lltname and compress term.                                            *;
***************************************************************************************;
proc datasets library=DICT;
    modify MEDDRA;
    index CREATE LLTNAME COMPRESS;
quit;

***************************************************************************************;
*  Create contents listing in output directory.                                       *;
***************************************************************************************;
ods rtf body="&outpath\MedDRAContents.rtf" style=rtf;
proc contents data=DICT.MEDDRA POSITION; run;
ods rtf close;

run;

%mend MedDRA_ascii_2_sas
   
/* %MedDRA_ascii_2_sas(RAWPATH=F:\Dept\Biostats\MedDRA Dictionary\Version 21.1\MedAscii, */
                    /* OUTPATH=F:\Dept\Biostats\MedDRA Dictionary\Version 21.1\SASDATA, */
                    /* VERSION=MedDRA 21.1); */
