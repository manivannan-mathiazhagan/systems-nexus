****************************************************************************
*  PROGRAM         : template.sas
*  SAS VS          : SAS 9.2 , 9.3, 9.4
*  WRITTEN BY      : Robert Diseker
*  PROTOCOL        : 
*  CREATE DATE     : 17MAY2017
*  COMMENTS        : template program for setting up rtf output for GRID
*				   : added to Programs/standard folder so SAS AUTOS will find it
*				   : called by titles.sas
*----------------------------------------------------------------------------
*  MODIFIED BY     :
*  MODIFIED DATE   :
*  MODIFIED COMMENT:
*****************************************************************************;
%macro template;
*ods path(prepend) work.templat(update);
ods path work.templat(update) sasuser.templat(update) sashelp.tmplmst(update);

PROC TEMPLATE;
  DEFINE STYLE styles.landscape8;
    PARENT=styles.rtf;
    REPLACE fonts  /
       'TitleFont2' = ("Courier New, courier",8pt)
       'TitleFont' = ("Courier New, courier",8pt)
       'StrongFont' = ("Courier New, courier",8pt)
       'EmphasisFont' = ("Courier New, courier",8pt)
       'FixedEmphasisFont' = ("Courier New, courier",8pt)
       'FixedStrongFont' = ("Courier New, courier",8pt)
       'FixedHeadingFont' = ("Courier New, courier",8pt)
       'BatchFixedFont' = ("Courier New, courier",8pt)
       'FixedFont' = ("Courier New, courier",8pt)
       'headingEmphasisFont' = ("Courier New, courier",8pt)
       'headingFont' = ("Courier New, courier",8pt)
       'docFont' = ("Courier New, courier",8pt);

    style table from table / background = _undef_ rules=groups cellspacing=0
    cellpadding=0pt bordertopwidth=7 bordertopcolor=white frame=above;

    style systemfooter from systemfooter /  protectspecialchars=off;

    style parskip / fontsize = 1pt; **JM: 23may2013;
      
    REPLACE headersAndFooters FROM CELL / background = _undef_
      font=fonts('HeadingFont')
      foreground=black
      background=white;

    REPLACE BODY from DOCUMENT /
      bottommargin=1in
      topmargin=1in
      rightmargin=1in
      leftmargin=1in;

    END;
RUN;

PROC TEMPLATE;
  DEFINE STYLE styles.patprof;
    PARENT=styles.rtf;
    REPLACE fonts  /
'TitleFont2' = ("Courier New",8pt)
'TitleFont' = ("Courier New",8pt)
'StrongFont' = ("Courier New",8pt,bold)
'EmphasisFont' = ("Courier New",8pt,italic)
'FixedEmphasisFont' = ("Courier New",8pt,italic)
'FixedStrongFont' = ("Courier New",8pt,bold)
'FixedHeadingFont' = ("Courier New",8pt,bold)
'BatchFixedFont' = ("Courier New",8pt)
'FixedFont' = ("Courier New",8pt)
'HeadingEmphasisFont' = ("Courier New",8pt,italic)
'HeadingFont' = ("Courier New",8pt,bold)
'DocFont' = ("Courier New",8pt);

    style table from table / background = _undef_ rules=groups cellspacing=0
    cellpadding=0pt bordertopwidth=7 bordertopcolor=white frame=above;

    style systemfooter from systemfooter /  protectspecialchars=off;
      
    REPLACE headersAndFooters FROM CELL / background = _undef_
      font=fonts('HeadingFont')
      foreground=black
      background=white;

    REPLACE BODY from DOCUMENT /
      bottommargin=1in
      topmargin=1in
      rightmargin=1in
      leftmargin=1in;
    END;
RUN;
%mend template;

