************************************************************************************
* VERISTAT INCORPORATED                                                     
************************************************************************************
* PROGRAM:    m_setup.sas  
* DATE:       23JUL2009
* PROGRAMMER: Laurie Drinkwater
*
* PURPOSE:    General SETUP Information 
*
************************************************************************************;
  
*===================================================================================
* 1.  Project Set-Up
*===================================================================================; 
%global company protocol draft; 

%let company=Cook MyoSite, Inc.;
%let protocol=DIFI 22-01;
%let draft=%str(Confidential);  
%let datacut=07JUL2025; 

proc datasets memtype=data kill nolist;
run;

%let keyvars=%str(studyid usubjid subjid siteid trtsdt trtsdtm trtedt trtedtm biodt icsfl ittfl saffl ppsfl); 
 
*===================================================================================
* 2.  Libname Information 
*===================================================================================;
%global raw in out library outdat pgmlis pgmwrk pgmlog pgmdat pgmstt pgmtxt mcat;  
 
%let mcat=*;

%macro outdat;

		 %if %substr(%upcase(&pgm),1,1)=T %then %let outdat=&protdir\Tables;
   %else %if %substr(%upcase(&pgm),1,1)=L %then %let outdat=&protdir\Listings;
   %else %if %substr(%upcase(&pgm),1,1)=F %then %let outdat=&protdir\Figures;
   %else %if %substr(%upcase(&pgm),1,1)=D %then %let outdat=&protdir\Create\ADSpgms;
   %else %if %substr(%upcase(&pgm),1,1)=C %then %let outdat=&protdir\create\RAWpgms;
   %else %if %substr(%upcase(&pgm),1,1)=S %then %let outdat=&protdir\create\SDTMpgms;
   %else %if %substr(%upcase(&pgm),1,2)=QT %then %let outdat=&protdir\QC\Tables;
   %else %if %substr(%upcase(&pgm),1,2)=QL %then %let outdat=&protdir\QC\Listings;
   %else %if %substr(%upcase(&pgm),1,2)=QF %then %let outdat=&protdir\QC\Figures;
   %else %if %substr(%upcase(&pgm),1,2)=QD  %then %let outdat=&protdir\QC\ADS;
   %else %if %substr(%upcase(&pgm),1,2)=QS  %then %let outdat=&protdir\QC\SDTM;
   %else %let outdat=&protdir\adhoc;   
%mend;
%outdat;

libname raw  "&protdir\rawdata"; * ACCESS=READONLY;
libname sdtm  "&protdir\SDTMdata";
libname ads "&protdir\adsdata";
libname qclis "&protdir\Listings\QC";
libname qctab "&protdir\Tables\QC";
libname qcfig "&protdir\Figures\QC";
libname adfxml "&protdir\Create\Definexml\ADaM\Datasets";
libname titles "&protdir\Docs\Analysis Plan\TitlesFootnotes";
libname library "&protdir\formats";   
libname atemp   "P:\Projects\Cook MyoSite\DIFI - 22-01\ADS Template"; 
libname openses "P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\_Restricted\Tables\Open Session\qcdatset";
libname random "&protdir\Random";
libname stds   "P:\Biostatistics\Standard Datasets" access=readonly;

filename pgmlis "&outdat\&pgm..lis";
filename pgmwrk "&outdat\&pgm..wrk";
filename pgmlog "&outdat\&pgm..log";
filename pgmdat "&outdat\&pgm..dat";
filename pgmstt "&outdat\&pgm..stt";

*===================================================================================
* 3.  Standards Options 
*===================================================================================;
%global ls ps;
%let ls=135;
%let ps=48;

options sasautos=(sasautos, "&protdir\macros", "&protdir\tables\macros","&protdir\figures\macros", "&protdir\listings\macros")
        fmtsearch=(work raw.formats formats.formats)
        validvarname=upcase
        ls=&ls ps=&ps  nodate nonumber
        mprint mlogic mtrace symbolgen missing=' ' formchar="|_ _ ||||||" noxwait noxsync noquotelenmax;
 
ods escapechar = "!";

*=================================================================================== 
* 4.  Titles and Footnotes:  SET-UP
*===================================================================================; 
data _null_;
	 call symput('line',"!R/RTF'\brdrb\brdrs\brdrw11'");
     call symput("file","PROGRAM NAME: &outdat\&pgm");
     call symput("dtstamp","DATE: " || put(date(),date9.) ||' '|| put(time(),time5.));	

     call symput('deg','B0'x);    ** Degree symbol ;
     call symput('s1','B9'x);     ** superscript 1 ;
     call symput('s2','B2'x);     ** superscript 2 ;
     call symput('s3','B3'x);     ** superscript 3 ;
     call symput('s4','A7'x);     ** superscript MARK ;
     call symput('tm','AE'x);     ** trademark ;
     call symput('bl','A0'x);     ** blank ;
     call symput('f0','F0'x);  
run;
  
%global space;

ods path(prepend) work.template(update);
ods escapechar = "!";

%let bborder=%str(!S={borderbottomwidth=1});
%let line=!S={bordertopwidth=1};
%let space=�;  /* ALT+255 hidden character */

proc template;
     define style style1;
     parent = styles.rtf;
     replace fonts/
       'TitleFont2'         = ("Courier New",9.0pt)
       'TitleFont'          = ("Courier New",9.0pt)
       'StrongFont'         = ("Courier New",9.0pt)
       'EmphasisFont'       = ("Courier New",9.0pt)
       'FixedEmphasisFont'  = ("Courier New",9.0pt)
       'FixedStrongFont'    = ("Courier New",9.0pt)
       'FixedHeadingFont'   = ("Courier New",9.0pt)
       'BatchFixedFont'     = ("Courier New",9.0pt)
       'headingEmphasisFont'= ("Courier New",9.0pt)
       'headingFont'        = ("Courier New",9.0pt)
       'FixedFont'          = ("Courier New",9.0pt)
       'docFont'            = ("Courier New",9.0pt);
     style body from document /
       topmargin=1in
       bottommargin=1in
       leftmargin=1in
       rightmargin=1in;
     style table from output /
       asis=on
       protectspecialchars=off
       rules=groups
       frame=above
       cellspacing=0
       cellpadding=0
       outputwidth=100%;
     style data from cell /
       just=center
       asis=on
       protectspecialchars=off;
     style header from header /
       just=center
       asis=on
       background=white
       frame=below;
     style systemfooter from titlesandfooters /
       rules=groups
       asis=on
       just=left;
    end;
run;

proc template;
  define style styleL;
  parent = style1;
    style data from cell /
      just=left
      asis=on
      protectspecialchars=off;
    style header from header /
      just=left
      asis=on
      background=white
      frame=below;
   end;
run;

*===================================================================================
*  5.  Formatting macros for RTF
*===================================================================================;
%macro fmtqc;
  array ch _character_;
  do over ch;
    ch=tranwrd(ch,"!n","");
    ch=compress(ch,"�");
    ch=compress(ch);
    ch=upcase(ch);
  end;
%mend fmtqc;

*===================================================================================
*  6.  Macro calls
*===================================================================================; 
%include "&protdir\macros\m-tf-call.sas"; 
%include "&protdir\macros\m-tf-readex.sas"; 
