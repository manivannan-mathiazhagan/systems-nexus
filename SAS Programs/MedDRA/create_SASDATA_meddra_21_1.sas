/*********************************************************************************
*  Program:     MEDDRASTANDARDNAMES.SAS                                          *
*  Author:      Greg Wagner                                                      *
*  Date:        05/06/06                                                         *
*                                                                                *
*  Description: Creates MEDDRA dictionary tables for use with ClinPlus coding    *
*               version 2.00bV8a utilizing MedDRA default naming conventions.    *
*                                                                                *
*               This program is based on the orignal MEDDRA.SAS program          *
*               supplied with ClinPlus coding.  It differs in that the           *
*               standard variable naming for the columns used follows the        *
*               documentation supplied by the MSSO. The only difference being    *
*               that the underscores have been dropped out of the variable       *
*               names so that all field names are 8 characters or less.          *
*               An additional column llttext duplicates the lltname.             *
*                                                                                *
*  Parameters:                                                                   *
*                                                                                *
*    RAWPATH:          Defines path to raw ascii files location.                 *
*    CPPATH:           Path to the ClinPlus coding system directory.             *
*    REMOVENONCURRENT: Specifies if non-current terms should be retained.        *
*    OUTPATH:          Path to final dictionary location.                        *
*    COMPRESS:         Specifies if the output table should be compressed.       *
*    VERSION:          Specifies the text to be written to the version column.   *
*                                                                                *
*                                                                                *
*  Output Structure:                                                             *
*                                                                                *
*    compress:        Compressed version of term.                                *
*    llttext:         Duplicate of lltname, used to return proper information.   *
*    lltname:         Low Level Term text.                                       *
*    lltcode:         Low Level Term Code.                                       *
*    ptname:          Preferred/Reported Term text.                              *
*    ptcode           Preferred/Reported Term code.                              *
*    hltname:         High Level Term text.                                      *
*    hltcode:         High Level Term code.                                      *
*    hlgtname:        High Level Group Term text.                                *
*    hlgtcode:        High Level Group Term code.                                *
*    soccode:         Combined System Organ Class code and text.                 *
*    pt_soc:          Primary SOC code value.                                    *
*    primesoc:        Primary SOC Flag.                                          *
*    version:         Dictionary Version Text.                                   *
*                                                                                *
**********************************************************************************/

*******************;
*** Parameters  ***;
*******************;

*** Set RAWPATH to the directory the raw ascii text files are located ***;
%LET RAWPATH=F:\Dept\Biostats\MedDRA Dictionary\Version 21.1\MedAscii;

***  Set flag to remove non-current terms.  The Default is Y - remove   ***;
***  Possible values are Y and N                                        ***;
%LET REMOVENONCURRENT=N;

*** Set CPPATH to the directory the ClinPlus(R) Coding system is located ***;
/*%LET CPPATH=L:\software\SUPPORT\cpcode\coding200;*/

*** Set OUTPATH to the directory you want the ClinPlus(R) for of the directory to reside ***;
%LET OUTPATH=F:\Dept\Biostats\MedDRA Dictionary\Version 21.1\SASDATA;

*** Set flag to compress the output data set. Values are Y and N, the Default is Y ***;
%LET COMPRESS = Y;

*** Specify dictionary version text ***;
%LET VERSION=MedDRA 21.1;



/*-----------------------------------------------------------------------------------------*/
/*  !!! DO NOT EDIT BELOW THIS LINE !!!                                                    */
/*-----------------------------------------------------------------------------------------*/

/*  Assign libref for output location  */
libname dict "&outpath";

/* Assign libref to the ClinPlus coding catalog */
/*libname s "&cppath";*/

/* Create System Organ Class (SOC) data set. */
data dict.soc (keep=soc soctext);
    length soc $8;
    infile "&rawpath.\soc.asc" dlm='$' dsd;
    input socnum soctext : $200. f3 $ f4 f5 f6 $ f7 f8 f9;
    soctext=upcase(soctext);
    soc=putn(socnum,'z8.');
run;

/* Create SOC to High Level Group Term (HLGT) data set. */
data soc_hlgt (keep=soc hlgtcode);
    length soc hlgtcode $8;
    infile "&rawpath.\soc_hlgt.asc" dlm='$' dsd;
    input socnum hlgtnum;
    soc=putn(socnum,'z8.');
    hlgtcode=putn(hlgtnum,'z8.');
run;

/* Create High Level Group Term (HLGT) data set. */
data dict.hlgt (keep=hlgtcode hlgtname);
    length hlgtcode $8;
    infile "&rawpath.\hlgt.asc" dlm='$' dsd;
    input hlgtnum hlgtname : $200. f3 f4 f5 $ f6 f7 f8;
    hlgtname=upcase(hlgtname);
    hlgtcode=putn(hlgtnum,'z8.');
run;

/* Create High Level Group Term (HLGT) to High Level Term (HLT) data set. */
data hlgt_hlt (keep=hlgtcode hltcode);
    length hltcode hlgtcode $8;
    infile "&rawpath.\hlgt_hlt.asc" dlm='$' dsd;
    input hlgtnum hltnum;
    hltcode=putn(hltnum,'z8.');
    hlgtcode=putn(hlgtnum,'z8.');
run;

/* Create High Level Term (HLT) data set. */
data dict.hlt (keep=hltcode hltname);
    length hltcode $8;
    infile "&rawpath.\hlt.asc" dlm='$' dsd;
    input hltnum hltname : $200. f3 f4 f5 $ f6 f7 f8;
    hltcode=putn(hltnum,'z8.');
    hltname=upcase(hltname);
run;

/* Create High Level Term (HLT) to Preferrd Term (PT) data set. */
data hlt_pt (keep=hltcode ptcode);
    length hltcode ptcode $8;
    infile "&rawpath.\hlt_pt.asc" dlm='$' dsd;
    input hltnum mednum;
    hltcode=putn(hltnum,'z8.');
    ptcode=putn(mednum,'z8.');
run;

/* Create Preferred Term (PT) data set. */
data dict.pt (keep=ptcode ptname pt_soc WHOcode icd9 icd9a);
    length pt_soc ptcode $8;
    infile "&rawpath.\pt.asc" dlm='$' dsd;
    input mednum ptname : $200. f3 socnum WHOcode $ f6 f7 $ icd9 $ icd9a $ f10 f11;
    ptname=upcase(ptname);
    pt_soc=putn(socnum,'z8.');
    ptcode=putn(mednum,'z8.');
run;

/* Create Low Level Term  (LLT) data set. */
data llt dict.llt (keep=lltcode lltname ptcode WHOcode icd9 icd9a);
    length lltcode ptcode $8;
    infile "&rawpath.\llt.asc" dlm='$' dsd;
    input verbnum lltname : $200. mednum WHOcode $ f5 f6 $ icd9 $ icd9a $ f9 f10 $ f11;
    lltname=upcase(lltname);
    ptcode=putn(mednum,'z8.');
    lltcode=putn(verbnum,'z8.');
	if "&removeNonCurrent"='Y' then if f10='N' then delete;
run;


/* Start to merge data sets together to create the MEDDRA data set. */
proc sql;
     create table meddra as                   /* Merge SOC and High Level Group Term */
     select a.*, b.hlgtcode
     from dict.soc a,
          soc_hlgt b
          where a.soc=b.soc;
     create table meddra as                   /* Merge in High Level Term Code */
     select a.*, b.hltcode
     from meddra a,
          hlgt_hlt b
          where a.hlgtcode=b.hlgtcode;
     create table meddra as                   /* Merge in Preferred Term Code */
     select a.*, b.ptcode
     from meddra a,
          hlt_pt b
          where a.hltcode=b.hltcode;
     create table meddra as                   /* Merge in Preferred Term and other info. */
     select a.*, b.ptname, b.pt_soc, b.WHOCode, b.ICD9, b.icd9a
     from meddra a,
          dict.pt b
          where a.ptcode=b.ptcode;
     create table meddra as                   /* Merge in Low Level Term and other info. */
     select a.*, b.lltcode, b.lltname, b.ICD9, b.icd9a
     from meddra a,
          llt b
          where a.ptcode=b.ptcode;
     create table meddra as                   /* Merge in HLGT text.*/
     select a.*, b.hlgtname
     from meddra a,
          dict.hlgt b
          where a.hlgtcode=b.hlgtcode;
     create table meddra as                   /* Merge in HLT text.*/
     select a.*, b.hltname
     from meddra a,
          dict.hlt b
          where a.hltcode=b.hltcode;
      quit;
run;

***************************************************************************************;
* Create combined SOCCODE field, LLTTEXT and VERSION fields and set primesoc flag     *;
***************************************************************************************;
data meddra/*(drop=soc soctext)*/;     
    length compress $200 primesoc 8 llttext $200 version $40;
    set meddra;
    if lltname='' then delete;
    if pt_soc = soc then primesoc=0; /* to sort by primary system */
    else primesoc=1;
    soccode=trim(left(soc))||' - '||soctext;
    llttext=lltname;								
    version="&version";						   
run;


***************************************************************************************;
** Re-order table columns and keep only what is needed and write to output directory **;
***************************************************************************************;
proc sql;
     create table dict.meddra as
     select a.compress, llttext,
     			a.lltname, a.lltcode, 
     			a.ptname, a.ptcode, 
     			a.hltname, a.hltcode, 
     			a.hlgtname, a.hlgtcode,
     			a.soctext, a.soc, a.soccode, 
     			a.primesoc, a.version
     	from meddra a;
quit;

***************************************************************************************;
** Set macro parameters for compress algorithm                                       **;
***************************************************************************************;
%let dsname=meddra;      /* Dictionary data set name */
%let subject=lltname;    /* Name of field to be compressed */
%let compfld=compress;   /* Name of field to contain compressed value */

** Call compress entry **;
/*dm 'af c=s.cpcode.compdict.scl';*/

***************************************************************************************;
* Create listing of duplicate compress Terms                                          *;
***************************************************************************************;
proc sort data=dict.meddra out=dupchk;by compress soccode;
data dupchk;set dupchk;by compress soccode;
     if first.soccode & last.soccode then delete;

proc print;
title1 'Listing of duplicate compress terms';
run;


***************************************************************************************;
* Clear duplicate compress values from final meddra data set                          *;
***************************************************************************************;
proc sort data=dict.meddra;
by compress soccode;
run;

%macro runit;
	data dict.meddra
		%if &compress = Y %then %do;
			(compress=yes)
		%end;
		;
	
	set dict.meddra;
	by compress soccode;
	if ^(first.soccode and  last.soccode) then compress='';
%mend runit;
%runit;

***************************************************************************************;
*  Re-sort final table                                                                *;
***************************************************************************************;
proc sort data=dict.meddra noduplicates; by compress ptcode primesoc soccode;		


***************************************************************************************;
*  Add index on lltname and compress term.                                            *;
***************************************************************************************;
proc datasets library=dict;modify meddra;index create lltname compress;quit;

***************************************************************************************;
*  Create contents listing in output directory.                                       *;
***************************************************************************************;
ods rtf body="&outpath\MedDRAContents.rtf" style=rtf;
proc contents data=dict.meddra position; run;
ods rtf close;

run;
