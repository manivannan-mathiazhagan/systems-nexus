***************************************************************************;
*       PROGRAM         : pagebrk.sas
*       SAS VS          : SAS 9.1.3
*       WRITTEN BY      : utility from internet.. 
                          http://www.lexjansen.com/pharmasug/2003/technicaltechniques/tt094.pdf
*       PROTOCOL        : General Use
*       CREATE DATE     : 16apr2007
*       COMMENTS        : To determine page breaks
*--------------------------------------------------------------------------
*       MODIFIED BY     : Lisa Stetler
*       MODIFIED DATE   : 18apr2007
*       MODIFIED COMMENT: Increased functionality. Added QC check, added SKIPVAR parameter, 
*                         removed KEEPID parameter, gave default values, fixed so that lines skipped can
*                         come before any var (*** lines skipped are thought of as compute before)
*                         Returns a macro variable _maxpg for use in (Page X of Y)
*   KNOWN INEFFECIENCIES: Does not have "compute after" functionality
*                         If a "wrapping" variable is also a "grouping" code still would count all wraps (may
*                         be able to "trick" it using skiplines or xtrfirst
***************************************************************************;
*       MODIFIED BY     : Manivannan
*       MODIFIED DATE   : 26Jun2018
*       MODIFIED COMMENT: Bug Fix: if KEEPONPG var not in same case as UNIQUE macro did not run correctly
***************************************************************************;
* indata   = input dataset,
* outdata  = output dataset (default=OUTDATA),
* unique   = identifies unique observations (must be a true unique sort),
* wrapvars = variables that can potentially have wrapped text (can be left blank),
* idwrap   = identifier for text going to next line (default=@),
* keeponpg = var that IDs what is trying to be kept together on 1 page (if left blank will be the value of 
*            the last variable in "unique". If present must be in "unique"),
* xtrfirst = # of line skips needed for first obs for KEEPONPG var (default=0),
* skipline = # of line skips between unique obs (default=0),
* skipvar  = the variable to skip lines before (may be left blank, but if intended for use, must be in "unique")
* linesavl = # of lines available per page excl header and footer,
* forcebrk = var that needs to be forced to break on a new page (may be left blank)
* replace  = if Y then replaces skipchar with /line for wrapvars
***************************************************************************;
%macro pagebrk(indata=,outdata=OUTDATA,unique=,wrapvars=,idwrap=@,keeponpg=,xtrfirst=0,skipline=0,skipvar=,linesavl=,forcebrk=,replace=,replaceval=^{newline 1});

   %** sort the incoming data set **;
   proc sort data=&indata out=mdata1;
      by &unique;
   run;

   %** get last variable of unique sort **;
   data a;
      length keeponpg unique lastunq keepid $200.; 
      unique=upcase("&unique");
      keeponpg=upcase("&keeponpg");
      x=index(reverse(trim(left(unique))), ' ');
      if x=0 then lastunq=upcase("&unique");
      else lastunq=compress(reverse(substr(reverse(trim(left(unique))), 1, x)));
      call symput("lastunq", lastunq);
      %if &keeponpg = %then %do;
         call symput("keeponpg", lastunq);
         keeponpg=lastunq;
      %end;
      y=index(reverse(trim(left(unique))), reverse(trim(left(keeponpg))));
      keepid=trim(left(reverse(substr(reverse(trim(left(unique))), y))));
      call symput("keepid", keepid);
   run;

   %** check to make sure unique sorting **;
   data mdatack;
       set mdata1;
       by &unique;
       if first.&lastunq ne last.&lastunq;
   run;

   proc contents data = mdatack out=mdatack1 noprint;
   run;

   data _null_;
     set mdatack1 end=eof;
     if eof and nobs ne 0 then put "WAR" "NING: NOT A UNIQUE SORT";
   run;
   %** end of check to make sure unique sorting **;
  
   %** count the maximum number of lines per observation **;
   data mdata2;
      set mdata1;
      by &unique;
      %** count the number of wraps per line **;
      %if &wrapvars ne %then %do;
         array wrap{*} &wrapvars;
         maxlines=0;
         do i=1 to dim(wrap);
            maxlines=max(maxlines,
            length(compress(wrap{i}))-length(compress(wrap{i}," &idwrap"))+1);
         end;
         drop i;
      %end;
      %else %do;
         maxlines=1;
      %end;
      %** add the line skips and the additional lines for the first keeponpg variable **;
      %if &skipvar ne   %then %do;
         if first.&skipvar and first.&keeponpg then maxlines=maxlines+&skipline+&xtrfirst;
         else if first.&skipvar then maxlines=maxlines+&skipline;
         else if first.&keeponpg then maxlines=maxlines+&xtrfirst;
         else maxlines=maxlines;
      %end;
      %else %do;
         if first.&keeponpg then maxlines=maxlines+&xtrfirst;
         else maxlines=maxlines;
      %end;
   run;
   %** count the number of lines needed for each keeponpg variable **;
   data mdata3 (keep=&keepid keepline);
      set mdata2;
      by &unique;
      retain keepline 0;
      if first.&keeponpg then keepline=maxlines;
      else keepline=keepline+maxlines;
      if last.&keeponpg;
   run;

   %** merge the maximum number of lines per keeponpg variable onto rest of data **;
   data mdata4 ;***(drop=lineonpg checkfit keepline maxlines pageneed);
      merge mdata2 mdata3;
      by &keepid;
   run;

   data &outdata (drop=lineonpg checkfit keepline maxlines pageneed);
      set mdata4;
      by &unique;
      pageneed=ceil(keepline/&linesavl);
      %** identify the page breaks **;
      retain _page 1 lineonpg 0 checkfit;
      %if &forcebrk ne %then %do;
         ** if it is a forced break (and not the first one), then go to next page **;
         if first.&forcebrk and _n_ ne 1 then do;
            _page=_page+1;
            lineonpg=0;
            %if &skipvar ne  %then %do;
               if ^(first.&skipvar) then maxlines=maxlines+&skipline;
            %end;
         end;
      %end;
      %** deal with keeponpg variable that only need one page **;
      if pageneed=1 then do;
         %** check to see if keeponpg variable will fit on the page **;
         if first.&keeponpg then checkfit=lineonpg+keepline;
         %** yes - whole keeponpg variable fits **;
         if checkfit<=&linesavl then lineonpg=lineonpg+maxlines;
         %** no - keeponpg variable will not fit **;
         if checkfit>&linesavl then do;
            _page=_page+1;
            %if &skipvar ne  %then %do;
               if ^(first.&skipvar) then maxlines=maxlines+&skipline;
            %end;
            lineonpg=maxlines;
            checkfit=keepline;
         end;
      end;
      %** deal with keeponpg variable that need more than one page **;
      if pageneed>1 then do;
         %** check to see if unique variable will fit on the page **;
         checkfit=lineonpg+maxlines;
         %** yes - unique variable fits **;
         if checkfit<=&linesavl then lineonpg=lineonpg+maxlines;
         %** no - unique variable does not fit **;
         if checkfit>&linesavl then do;
            _page=_page+1;
            lineonpg=&xtrfirst+maxlines;
            checkfit=&xtrfirst+maxlines;
         end;
      end;
   run;
 
  data &outdata;
      set &outdata;
      _page2 = _page;
  run;          

   %global _maxpg;
   data _null_; 
     set &outdata end=eof;
     if eof then call symput('_maxpg', compress(put(_page, 9.)));
   run;
   
   %if &replace=Y %then %do;
      data &outdata;
         set &outdata;
        %if &wrapvars ne %then %do;
            array wrap{*} &wrapvars;
              do i=1 to dim(wrap);
                 wrap{i}= tranwrd(wrap{i}, "&idwrap", "&replaceval");
              end;
              drop i;
        %end;
       run;
   %end;
    
%mend pagebrk;
