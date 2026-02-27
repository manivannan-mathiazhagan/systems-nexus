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

%let company=xxxxx;
%let protocol=xxxxxxxxxxx;
%let draft=%str(Confidential);   

proc datasets memtype=data kill nolist;
run;

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
    

   %* only one layout is specified ;
   %let maxls=135 ;
   %if %substr(&pgm,%length(&pgm))=L %then %do;
      %let ps=48;
      %let ls=135;
   %end;
   %else %do ;
      %let ps=48;
      %let ls=135;
   %end;
%mend;
%outdat;

    libname raw  "&protdir\rawdata";
    libname sdtm  "&protdir\SDTMdata";
    libname ads "&protdir\adsdata";
    libname qclis "&protdir\Listings\QC";
    libname qctab "&protdir\Tables\QC";
    libname qcfig "&protdir\Figures\QC";
    libname stemp "P:\Projects\Rhythm\SDTM Standards\SASData\CDISC Specs";
    
   libname library "&protdir\formats";

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

options sasautos=(sasautos, "&protdir\macros")
        fmtsearch=(work raw.formats formats.formats)
        validvarname=upcase
        ls=&ls ps=&ps nodate nonumber 
        mprint mlogic mtrace symbolgen missing=' ' formchar="|_ _ ||||||" noxwait noxsync NOQUOTELENMAX;      

ods escapechar = "!";

*=================================================================================== 
* 4a.  Titles and Footnotes:  SET-UP
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

*===================================================================================
*  b.  Titles and Footnotes:  DAT (DOC) for Standard Report
*===================================================================================;
%global tl1 tl2 tl3 ft99;

data _null_;
     space = floor(&ls/2 - length("&draft")/2);  
     space2 = space - length("&company");    
     call symput("tl1",trim("&company") || repeat(' ',space2) || trim("&draft") || repeat(' ',&ls));
     call symput("tl2","&protocol" || repeat(' ',&ls));      

          if substr("%upcase(&pgm)",1,1) = "T" then call symput("tl3","Table &pgmnum"); 
     else if substr("%upcase(&pgm)",1,1) = "L" then call symput("tl3","Listing &pgmnum"); 
     else if substr("%upcase(&pgm)",1,1) = "F" then call symput("tl3","Figure &pgmnum");  
     else call symput("tl3"," ");

     space = 120 - length("&file") - length("&dtstamp") - 1;					 
     call symput("ft99",trim("&file") || repeat(' ',space) || trim("&dtstamp")); 
run; 

*===================================================================================
*  c.  Titles and Footnotes:  RTF for Clinical Review
*===================================================================================;
ods path(prepend) work.template(update);

%let _ol = \pard\brdrt\brdrs\brdrw10\brsp\par; 
 
proc template;
   define style styles.style1;
   parent=styles.rtf;
   replace fonts/'TitleFont'           = ("Courier New, Courier", 9pt)
                 'TitleFont2'          = ("Courier New, Courier", 9pt)
                 'StrongFont'          = ("Courier New, Courier", 9pt, Bold)
                 'EmphasisFont'        = ("Courier New, Courier", 9pt, Italic)
                 'FixedEmphasisFont'   = ("Courier New, Courier", 9pt, Italic)
                 'FixedStrongFont'     = ("Courier New, Courier", 9pt, Bold)
                 'BatchFixedFont'      = ("SAS Monospace, Courier New, Courier", 9pt)
                 'FixedFont'           = ("Courier New, Courier", 9pt)
                 'headingEmphasisFont' = ("Courier New, Courier", 9pt)
                 'headingFont'         = ("Courier New, Courier", 9pt)
                 'docFont'             = ("Courier New, Courier", 9pt)
                 'FootnoteFont9'       = ("Courier New, Courier", 9pt)
                 'FootnoteFont'        = ("Courier New, Courier", 9pt);
   replace color_list / 'LINK'= blue
                        'BGH' = white
                        'FG'  = black
                        'BG'  = white;
   replace body from document / bottommargin = 1.00in
                                topmargin    = 1.00in
                                rightmargin  = 1.00in
                                leftmargin   = 1.00in;
   replace table from output / frame       = void
                               rules       = group
                               cellpadding = 0pt
                               cellspacing = 0pt
                               borderwidth = 1.0pt;
   
        style header from header / asis=on just=center background=white frame=below frameborder=on;
        style data from cell / asis=on just=left protectspecialchars=off; 
		style SystemFooter / asis=on just=left;

   replace SystemTitle from TitlesAndFooters /
        font = Fonts('TitleFont');
   end;
quit;
 
data _null_;
     call symput('deg','B0'x);    ** Degree symbol ;
     call symput('s1','B9'x);     ** superscript 1 ;
     call symput('s2','B2'x);     ** superscript 2 ;
     call symput('s3','B3'x);     ** superscript 3 ;
     call symput('s4','A7'x);     ** superscript MARK ;
     call symput('tm','AE'x);     ** trademark ;
     call symput('bl','A0'x);     ** blank ;
     call symput('f0','F0'x);     
run;
*=================================================================================== 
*  5.  Specific Table Name  
*===================================================================================;
%global ctl5 ctl6 ctl7 ctl8 ctl9 ctl10 ;

data _null_ ;
     infile "&outdat\&pgm..sas" missover pad ;
     retain chk 0 cnt 4;

     input @1 wrd $&ls.. ;

     if chk=0 and index(upcase(wrd),'PURPOSE:') then chk=1 ;
     if chk=1 then do ;
        cnt+1 ;
        call symput('ctl' || put(cnt,1.), strip(substr(wrd,16)));
     end ;
     if chk=1 and wrd='*' then stop ;
run;


