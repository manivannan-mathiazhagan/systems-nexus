/*!
* Enhanced version of the table generating macro, used to create table layout templates. 
* Options for titles, footnotes, column headers and dummy ("shell") text that also can receive statistical results as input to populate the table with results.
* @author K. McBride
*/

/**
* The <code>%table2</code> is an enhanced version of the original table generator that has significant improvements including native Word and PDF table output options. 
* This macro can be used to generate ad-hoc summary tables but is typically used as "table shells" created in stand-alone programs that later can be reused to receive statistical results as input to replace the shell text with the results.
* The macro supports flex-input parameters for titles, footnotes, spanning headers, column headers and dummy ("shell") text, and a panels parameter to control breaks and groupings across pages for very wide tables.
* <br><br>
* <b>Usage:</b><br><code>
* %table2(titles=%bquote(1;C;Title of Table;2;C;Subtitle of Table;),
*         footnotes=%bquote(1;L;Notes: this is a footnote.;),
*         columns=%bquote(1;1;L;L;.;.;GROW;.;Column1;
*                         1;2;C;C;.;.;GROW;.;Column2;),
*         rows=%bquote(1;1;Row 1 column 1; Row 1 column 2;)
*         )
* </code>
* <br><a href='https://instat.unfuddle.com/a#/projects/1/search?query=table2%2Bexample&filter=messages' target=_blank>Search Unfuddle Messages (examples, etc)</a>
* <br><a href='https://instat.unfuddle.com/a#/projects/1/repositories/3/history?path=%2Ftrunk%2Fmacros%2Fstat%2Ftable2.sas' target=_blank>History of Changes</a>
*
* @param	attribs		________________________
* @param	titles		________________________
* @param	footnotes	________________________
* @param	columns		________________________
* @param	spanhdrs	________________________
* @param	spanhdr2	________________________
* @param	spanhdr3	________________________
* @param	rows		________________________
* @param	indata		________________________
* @param	sortvars	________________________
* @param	panels		________________________
* @param	output		________________________
* @param	pgmloc		________________________
*
*/
%macro table3(attribs=,
	           titles=,footnotes=,columns=,spanhdrs=,spanhdr2=,spanhdr3=,rows=,
             indata=,sortvars=,panels=,
             output=&outdest,pgmloc_=tables)/ /*store*/;
   %put NOTE: Initializing the TABLE macro (log notes suppressed unless the _debug_ macro var is set to 1).;
   %global listnum lpageno outpath;
   %local _tproctime_ _xproctime_;
   %let _xproctime_=0;
   %let _tproctime_=0;

   %statutil
   %i_common2
   %xinit(table);
   %if %length(&indata)=0 & %length(&data) %then %let indata=&data;
   %if &indata ^=  %then %let _dodata=1; %else %let _dodata=0;
   %xbug(TABLE: ,data indata _dodata)

   %* if running adhoc, not in context of Specs/setenv/table_runs etc then we need to set these default values;
   %if ^%exist(rptout) %then %let rptout=1;
   %if ^%exist(allinone) %then %let allinone=0;
   %if ^%exist(lastone) %then %let lastone=1;
   %if ^%exist(bookmarks) %then %let bookmarks=1;


   %if &_debug_=2 %then %xnoisy;
   %else %if &_debug_=1 %then %do;
      %xnotes(1);
   %end;
   %else %xquiet;
%*   options nomprint;
   %* set constants;
   %let __npar_t=3;
   %let __npar_f=3;
   %let __npar_c=9;
   %let __npar_sh=3;
   %let __npar_sh2=3;
   %let __npar_sh3=3;
   %let __npar_p=3;

   %* initialize vars,options and set defaults;
   %let __ps= ;
   %let __ls= ;
   %let __rowshell=1;
   %let __shellstats=1;
   %let __topmargin=0.7799;
   %let __bottommargin=0.3799;
   %let __leftmargin=0.7799;
   %let __rightmargin=0.7799;
   %let __tmargin= ;
   %let __bmargin= ;
   %let __lmargin= ;
   %let __rmargin= ;
   %let __topline=1;
   %let __headline=1;
   %let __bottomline=1;
   %let __portrait=0;
   %let __intext=0;
   %let __twidth=1;
   %let __talign=C;
   %let __theight= ;
   %let __pgbk_inlevel=0;
   %let __indent=2;
   %let __relrows=1;
   %let __relcolumns=1;
   %let __pageorder=OVERTHENDOWN;
   %let __flowtype=SHIFTROWS;
   %let __globalflow=1;
   %let __flowchar=;
   %let __idcols=0;
   %let __PGBK_NEWVALINCOL=0;
   %let __pgbk_repeat_label=1;
   %let __pgbk_repeat_label_upto_inlvl=0;
   %let __pgbk_reducer=0;
   %let __dpalign=1;
   %let __pageno=1;
	%let __font=Arial;
	%let __fontsize=9;
	%let __pagesize=LETTER;
	%let __title_fontincr=1;

   %let __ntitl=0;
   %let __rtitles=0;
   %let __rtitles_wraps=0;
   %let __nfn=0;
   %let __rfootnotes=0;
   %let __rfootnotes_wraps=0;
   %let __ncol=0;
   %let __nrow=0;
   %let __nsphdr=0;
   %let __nsphdr2=0;
   %let __nsphdr3=0;
   %let __npanels=0;
   %let __cntwraps=0;
   %let __cntflows=0;
   %let __dowrap=1;
   %let __wrap=wrap;
   %if %upcase(&output)=WORD | %upcase(&output)=PDFTBL | %upcase(&output)=WORDPDF | %upcase(&output)=ODT | %upcase(&output)=ALL | %upcase(&output)=BMSRTF %then %do; %let __dowrap=0; %let __wrap=; %end;
   %if ^%length(&pgmloc) %then %let pgmloc=&pmgloc_;

   %* get number of table elements*;
   %let __ntitl=%eval(%npars(&titles,%str(;)) / &__npar_t);
   %let __nfn=%eval(%npars(&footnotes,%str(;)) / &__npar_f);
   %let __ncol=%eval(%npars(&columns,%str(;)) / &__npar_c);
   %let __nsphdr=%eval(%npars(&spanhdrs,%str(;)) / &__npar_sh);
   %let __nsphdr2=%eval(%npars(&spanhdr2,%str(;)) / &__npar_sh2);
   %let __nsphdr3=%eval(%npars(&spanhdr3,%str(;)) / &__npar_sh3);
   %let __npanels=%eval(%npars(&panels,%str(;)) / &__npar_p);
   %let __npar_r=%eval(&__ncol + 2);
   %let __nrow=%eval(%npars(&rows,%str(;)) / &__npar_r);
   %if &__npanels=0 %then %do;
    %*put *** NCOL IS: &__ncol;
    %let panels=%str(1;1-&__ncol;.;);
    %let __npanels=1;
   %end;

  data _attribs;
    set sashelp.vmacro;
    where substr(name,1,2)='__';
    keep name value;
  run;

   %xbug(TABLE: number of table objects,__ncol __nsphdr __nsphdr2 __ntitl __nfn __nrow __npanels)
   %if %exist(_sttime_) %then %do;
	   %let _sptime_ = %sysfunc(time());
	   %let _xproctime_ = %sysfunc(round(&_sptime_ - &_sttime_ - &_tproctime_,.02));
	   %let _tproctime_ = %sysfunc(round(&_sptime_ - &_sttime_,.02));
	   %put NOTE: **Macro Proctime** &_main_ macro - Macro initialization - used &_xproctime_ seconds, total so far is &_tproctime_ seconds.;
   %end;
 
  %if %exist(__tnum) %then %do;
	  %if %length(&__tnum)=0 %then %getrefnums;
	  %xbug(TABLE: reference lookup,__tnum __tsrc __lnum __lsrc __lref)
	%end;
  
   %* grab attributes and put parameters into arrays **;
   %getattribs(%str(&attribs));

   %let __pageorder=%upcase(&__pageorder);
   %let __flowcharmap=%flowcharmap;

   %if %index(&__twidth,%str(%%)) %then %let __twidth=%sysevalf(%substr(&__twidth,1,%index(&__twidth,%str(%%))-1) / 100);
   %xbug(TABLE:,__twidth)

   %* set defaults for courier new 8pt **;
   %if &__portrait %then %do;
      %if &SysProd=WPS %then %do;
      options ls=122 ps=89;
      %end;
      %else %do;
      options orientation=portrait;
      %end;
      %xchkint(__ps,89,,)
      %xchkint(__ls,122,,)
   %end;
   %else %do;
      %if &SysProd=WPS %then %do;
      options ls=158 ps=65;
      %end;
      %else %do;
      options orientation=landscape;
      %end;
      %xchkint(__ps,64,,)
      %xchkint(__ls,158,,)
   %end;
   %xchkint(__tmargin,6,,)
   %xchkint(__bmargin,1,,)
   %xchkint(__lmargin,13,,)
   %xchkint(__rmargin,11,,)
   %xchkint(__indent,3,,)

   %** check for specified page/font attribs and assign global values if non specified **;
  %if %exist(gforce) %then %do;
		%macro gchk(nm);
			%if %length(&&g&nm) %then %let __&&nm=&&g&nm;
		%mend;
		%if &gforce %then %do;
			%gchk(topmargin);
			%gchk(bottommargin);
			%gchk(rightmargin);
			%gchk(leftmargin);
			%gchk(pagesize);
			%gchk(font);
			%gchk(fontsize);
			%gchk(title_fontincr);
		%end;
  %end;
  /** new defaults **
   %let __topmargin=0.7799;
   %let __bottommargin=0.3799;
   %let __leftmargin=0.7799;
   %let __rightmargin=0.7799;
   **/
   %if &__topmargin ^=  %then %do;
      %let __topmargin=%xrepstr(%upcase(&__topmargin),IN,%str( ));
      %if &__topmargin=1 %then %let __tmargin=6;
      %else %if %sysevalf(&__topmargin=1.5) %then %let __tmargin=10;
      %else %if %sysevalf(&__topmargin=1.35) %then %let __tmargin=8;
      %else %if %sysevalf(&__topmargin=.98) %then %let __tmargin=6;
      %else %if %sysevalf(&__topmargin=.7799) %then %let __tmargin=5;
      %else %do;
        %put WARNING: Invalid value for attribute TOPMARGIN, .7799in, 1in, .98in, 1.35in and 1.5in are only accepted. Default of .7799in will be used.;
        %let __topmargin=.7799; %let __tmargin=5;
      %end;
   %end;
   %if &__bottommargin ^=  %then %do;
      %let __bottommargin=%xrepstr(%upcase(&__bottommargin),IN,%str( ));
      %if &__bottommargin=1 %then %let __bmargin=4;
      %else %if %sysevalf(&__bottommargin=.5) %then %let __bmargin=6;
      %else %if %sysevalf(&__bottommargin=.98) %then %let __bmargin=8;
      %else %if %sysevalf(&__bottommargin=.3799) %then %let __bmargin=4;
      %else %do;
        %put WARNING: Invalid value for attribute BOTTOMMARGIN, .3799in, 1in, .98in, and .5in are only accepted. Default of .3799in will be used.;
        %let __bottommargin=.3799; %let __bmargin=4;
      %end;
   %end;
   %if &SysProd=WPS %then %let __bmargin=%eval(&__bmargin - 1);
   %if &__leftmargin ^=  %then %do;
      %let __leftmargin=%xrepstr(%upcase(&__leftmargin),IN,%str( ));
      %if &__leftmargin=1 %then %let __lmargin=12;
      %else %if %sysevalf(&__leftmargin=.75) %then %let __lmargin=9;
      %else %if %sysevalf(&__leftmargin=.5) %then %let __lmargin=5;
      %else %if %sysevalf(&__leftmargin=1.25) %then %let __lmargin=16;
      %else %if %sysevalf(&__leftmargin=.98) %then %let __lmargin=12;
      %else %if %sysevalf(&__leftmargin=.7799) %then %let __lmargin=10;
      %else %do;
        %put WARNING: Invalid value for attribute LEFTMARGIN, .7799in, 1in, .98in, 1.25in, .75in and .5in are only accepted. Default of .7799in will be used.;
        %let __leftmargin=.7799; %let __lmargin=10;
      %end;
   %end;
   %if &__rightmargin ^=  %then %do;
      %let __rightmargin=%xrepstr(%upcase(&__rightmargin),IN,%str( ));
      %if &__rightmargin=1 %then %let __rmargin=11;
      %else %if %sysevalf(&__rightmargin=.75) %then %let __rmargin=8;
      %else %if %sysevalf(&__rightmargin=.5) %then %let __rmargin=4;
      %else %if %sysevalf(&__rightmargin=1.25) %then %let __rmargin=15;
      %else %if %sysevalf(&__rightmargin=.98) %then %let __rmargin=11;
      %else %if %sysevalf(&__rightmargin=.7799) %then %let __rmargin=10;
      %else %do;
        %put WARNING: Invalid value for attribute RIGHTMARGIN, .7799in, 1in, .98in, 1.25in, .75in and .5in are only accepted. Default of 1in will be used.;
        %let __rightmargin=.7799; %let __rmargin=10;
      %end;
   %end;
   %if &__portrait %then %let __rmargin=%eval(&__rmargin + 1);
   %if &__intext %then %do;
      %put INTEXT option specified, LS and PS will be modified and margins set to zero.;
      %let __ls = %eval(&__ls - &__lmargin - &__rmargin);
      %let __lmargin=0;
      %let __rmargin=0;
      %let __ps = %eval(&__ps - &__tmargin - &__bmargin);
      %let __tmargin=0;
      %let __bmargin=1;  %* rtf needs the extra line;
      %let _framewidth=%eval(&__ls-&__lmargin-&__rmargin);
      %let _width=%sysevalf((&__ls)*&__twidth);
      %put LS=&__ls  PS=&__ps;
   %end;
   %else %do;
    %let _framewidth=%eval(&__ls-&__lmargin-&__rmargin);
    %let _width=%sysfunc(ceil((&__ls-&__lmargin-&__rmargin)*&__twidth));
   %end;

   %xbug(TABLE: page setup,__tmargin __bmargin __lmargin __rmargin _width _framewidth)

   %let pgmpath=%str(&proot\&pgmloc\);
   %let outpath=%str(&oroot\&outloc\);
   /** deprecated experimental RUNMODE, will try to keep around to be backwards compatable, no guarantees **/
 	 %if %exist(runmode) %then %do; 
 	 	 %if %upcase(&runmode)^=DRAFT %then %let outpath=%str(&oroot\&outloc\&runmode\); 
 	 %end;

   %if %index(%upcase(&outloc),TABLES) & %length(&indata)=0 & ^%index(%upcase(&outloc),SHELL) %then %let outpath=&outpath%str(shells\);
   %if %index(%upcase(&pgmloc),TABLES) & %length(&indata)=0 & ^%index(%upcase(&pgmloc),SHELL) %then %let pgmpath=&pgmpath%str(shells\);

   %*if &__intext %then %do;
      %*let pgmpath=&pgmpath%str(intext\);
      %*let outpath=&outpath%str(intext\);
   %*end;

   %xbug(TABLE: parameters, titles footnotes columns spanhdrs spanhdr2 spanhdr3 rows)

   %*getrefnums;
   %if &__ntitl %then %do;
      %getparams2(titles,&__npar_t,&__npar_t);
   %end;
   %if &__nfn %then %do;
      %getparams2(footnotes,&__npar_f,&__npar_f);
   %end;
   %getparams2(columns,&__npar_c,&__npar_c,_relcolumns=&__relcolumns);
   %getparams2(spanhdrs,&__npar_sh,&__npar_sh);
   %getparams2(spanhdr2,&__npar_sh2,&__npar_sh2);
   %getparams2(spanhdr3,&__npar_sh3,&__npar_sh3);
   %getparams2(panels,&__npar_p,&__npar_p);
  %if &__nrow %then %do;
   %getparams2(rows,&__npar_r,3,_relrows=&__relrows);
  %end;

  data _columns;
    set _columns;
    col=input(arg1,2.);
    colgrp=input(arg2,2.);
  run;

   %if &_dodata %then %do;
      %xchkend(&indata);
   %end;
   %if &_xrc_^=OK %then %goto exit;

  proc sql noprint;
    select count(*) into:_err from _columns where upcase(arg7)='FLOW' and arg5='';
  quit;
  %if &_err %then %do;
    %xerrset(FLOW option requested for column &__i but column width is not specified. FLOW requires a column width.);
    %goto exit;
  %end;

   %if %exist(_sttime) %then %do;
	   %let _sptime_ = %sysfunc(time());
	   %let _xproctime_ = %sysfunc(round(&_sptime_ - &_sttime_ - &_tproctime_,.02));
	   %let _tproctime_ = %sysfunc(round(&_sptime_ - &_sttime_,.02));
	   %put NOTE: **Macro Proctime** &_main_ macro - Defaults and parameters - used &_xproctime_ seconds, total so far is &_tproctime_ seconds.;
   %end;

  %* if we have panels, assign cols on each panel *;
  proc sql noprint;
    select max(0,input(scan(arg2,1,'-'),2.)-1) into:__pan_repcol_end from _panels where arg1='1';
  quit;
  %xbug(TABLE:,__pan_repcol_end)
  data _panels;
    set _panels;
    ncol=0;
    length cols $100;
    cols='';
    do j=1 to &__pan_repcol_end;
      ncol=ncol+1;
      cols=trim(cols)||' '||left(j);
    end;
    do j=scan(arg2,1,'-') to scan(arg2,2,'-');
      ncol=ncol+1;
      cols=trim(cols)||' '||left(j);
    end;
    cols=left(cols);
    drop j;
  run;

  %macro titlfn2(tf);
    %if %dsobs(_&tf.) %then %do;
    proc sql noprint;
      create table _&tf.2 as
      select *, (countc(arg1,'L')>0) as ord1, input(translate(arg1,'','L'),2.) as ord2
      from _&tf.
      ;
    quit;
    proc sort data=_&tf.2;
      by ord1 ord2;
    run;
    data _&tf.2;
      set _&tf.2 end=last;
      retain _lastnum totestwraps 0;
      if ^index(arg1,'L') then do;
        _lastnum=input(arg1,2.);
        row=_lastnum;
      end;
      else do;
        row=_lastnum+input(substr(arg1,2),2.);
      end;
      twidth=&_width*(1 - .3*(&_width=&_framewidth));
      flow=1;
      rename arg2=titlalign arg3=text;
      drop _lastnum param arg1 wordwraps;
      ** approximate Word wraps **;
      wordwraps=ceil(length(arg3)/166)-1;
      totestwraps=totestwraps+wordwraps;
      if last then do;
      	call symput("__r&tf",row);
      	call symput("__r&tf._wraps",totestwraps);
      end;
    run;
    %if &__dowrap %then %do;
    %tblwrap(_&tf.2,twidth)
    data _&tf.2;
      set _&tf.2wrap end=last;
      if last then do;
      	call symput("__r&tf",row);
      	call symput("__r&tf._wraps",_totwraps);
      end;
    run;
    %end; 
    %end; %else %do;
    data _&tf.2;
      _tf=.;
    run;
    %end;
  %mend titlfn2;
  %titlfn2(titles)
  %titlfn2(footnotes)
   %xbug(TABLE: parameters read(counts),__rtitles __rfootnotes __rtitles_wraps __rfootnotes_wraps __ncol)
   %xchkint(__rtitles,,,)
   %xchkint(__rfootnotes,,,)
   %xchkint(__ncol,,1,)
  %if ^&__rowshell | &__nrow=0 %then %do;
   %xchkint(__nrow,,0,)
  %end;
  %else %do;
   %xchkint(__nrow,,1,)
  %end;

   %* calculate pageftr start row *;
   %let __ftrstrow = %eval(&__ps - &__rfootnotes - &__bmargin - &__tmargin - &__rfootnotes_wraps);
   %if &__bottomline %then %let __ftrstrow=%eval(&__ftrstrow - 1);
   %xbug(TABLE:,__ftrstrow __ps __rfootnotes __bmargin __tmargin __rfootnotes_wraps)

  proc sql noprint;
    create table _pcolumns as
    select c.*, panel, pancols
    from _columns c left join (select c.arg1, input(_panels.arg1,2.) as panel, _panels.cols as pancols from _columns c, _panels where indexw(_panels.cols,c.arg1)) t
    on c.arg1=t.arg1
    ;
  quit;
  data _pcolumns;
    set _pcolumns;
    if panel=. then do i=1 to &__npanels;
      panel=i;
      output;
    end;
    else output;
    drop i;
  run;

   proc sort data=_columns out=_coltmp(keep=col arg8 arg9 rename=(arg9=text));
      by param;
   run;
  %if &__nrow | &_dodata %then %do;
    %if &__nrow %then %do;
     data _rows2;
        set _rows;
        length row col 8 text $2000 inlvl 8 src 8;
        src=1;
        row=arg1;
        inlvl=arg2;
        %do __i=1 %to &__ncol;
           %let __tmp=%eval(&__i + 2);
           col=&__i;
           text=arg&__tmp;
           output;
        %end;
        keep col row text inlvl src;
     run;

     %** get max text length for each column - to be used by GROW option **;
     data _grow;
        set _rows2(where=(upcase(substr(text,1,8)) ne '#NOGROW#'
        and upcase(substr(text,1,5)) ne '#SPAN'
        and upcase(substr(text,1,6)) ne '#INLVL'
        and upcase(text) ne '#LINE#'
        and upcase(scan(text,1)) ne 'NOTE:' and upcase(scan(text,2)) ne 'NOTE:' ))
     %if &_dodata %then %do;
           &indata(where=(substr(text,1,8) ne '#NOGROW#'
           and upcase(substr(text,1,5)) ne '#SPAN' ))
     %end;
        _coltmp(drop=arg8)
     ;
    %end;
    %else %if &_dodata %then %do;
     data _grow;
        set &indata(where=(substr(text,1,8) ne '#NOGROW#'
            and upcase(substr(text,1,5)) ne '#SPAN' ))
           _coltmp(drop=arg8)
        ;
    %end;
        %* for grow calcs assume global skip char;
        length newtext $2000;
        do while(index(text,'~'));
          newtext=scan(text,1,'~');
          output;
          text=substr(text,index(text,'~')+1);
        end;
        if newtext='' then newtext=text;
        output;
     run;
     data _grow;
        set _grow(drop=text rename=(newtext=text));
        if substr(text,1,1)='#' and index(substr(text,2),'#') then
           text=substr(text,index(substr(text,2),'#')+2);
        if index(text,'#DSVAR=') then text='';
        _tlength=length(text);
        keep col _tlength text;
     run;
       proc sort data=_grow;
        by col;
     run;
     data _grow;
        merge _grow _coltmp(drop=text);
        by col;
  %end;
  %else %do;
   data _grow;
      set _coltmp;
        %* for grow calcs assume global skip char;
        length newtext $2000;
        do while(index(text,'~'));
          newtext=scan(text,1,'~');
          output;
          text=substr(text,index(text,'~')+1);
        end;
        if newtext='' then newtext=text;
        output;
     run;
     data _grow;
        set _grow;
        if substr(text,1,1)='#' and index(substr(text,2),'#') then
           text=substr(text,index(substr(text,2),'#')+2);
        if index(text,'#DSVAR=') then text='';
        _tlength=length(text);
  %end;
      if inlvl>0 and arg8='CELLINDENT' then _tlength=_tlength+inlvl*&__indent;
   run;
   proc summary data=_grow;
      var _tlength;
      by col;
      output out=_growmax(drop=_TYPE_ _FREQ_) max=_cmaxlen;
   run;
  data _columns;
    merge _columns _growmax;
    by col;
    if _cmaxlen=. or arg7^='GROW' then _cmaxlen=0;
    _cmaxlen=max(arg5,_cmaxlen);
  run;
   %if &syserr>4 %then %do;
      %xerrset(Processing max text length for each column failed.);
      %goto exit;
   %end;

  proc sql noprint;
    create table _cgrpmax as
    select colgrp, max(_cmaxlen) as _cgmw from _columns as _cgmw
    group by colgrp;
  quit;
  proc sort data=_columns;
    by colgrp;
  run;
  data _columns;
    merge _columns _cgrpmax;
    by colgrp;
    cwid=_cgmw;
    cspc=input(arg6,best2.);
  run;
  proc sort data=_columns;
    by col;
  run;
  proc sort data=_pcolumns;
    by col;
  run;
  data _columns2;
    merge _pcolumns _columns;
    by col;
  run;
  proc sort data=_columns2;
    by panel col;
  run;
  data _columns2;
    retain row col;
    set _columns2;
    by panel;
    if upcase(arg7)='FLOW' then flow=1; else flow=0;
    if upcase(arg8)='CELLINDENT' then cellindent=1; else cellindent=0;

    retain row 1 pcol .;
    if first.panel then pcol=1;
    else pcol=pcol+1;
    rename arg3=chalign arg4=cdalign arg9=colhdr;
    drop param arg1 arg2 arg5-arg8;
  run;
  proc sql noprint;
    create table _pcolsumm as
    select panel, sum(cwid) as _sumcolw, sum(max(0,cspc)) as _sumcols, max(countc(colhdr,'~')+1) as _chdrrowsmax, sum(case when missing(cspc) then 1 else 0 end) as ncols_without_spacing,
                  &_width - sum(cwid) - sum(max(0,cspc)) as _spleft, max(pcol) as maxpcol
    from _columns2
    group by panel;
    select min(_spleft) into:__spleft from _pcolsumm;
    select max(_chdrrowsmax) into:__chdrrows from _pcolsumm;
  quit;
   %if &__spleft<0 & &__dowrap %then %do;
      %xerrset(%str(Table width exceeds line size, table macro will abort))
      %put ERROR: You may need to adjust column widths or spacings, or turn off GROW option on some columns.;
      %xbugds(_pcolsumm,panel _spleft _sumcolw _sumcols)
      %xbugds(_columns2,panel col cwid cspc)
      %put;
      %goto exit;
   %end;

  %* assign column positions *;
  %* distribute unused spacing evenly across columns with no spacing defined **;
  data _columns2;
    merge _columns2 _pcolsumm(keep=panel ncols_without_spacing _spleft maxpcol) ;
    retain _spget _spgetmore _newpos .;
    by panel;
    if first.panel then do;
      if "&__talign"="C" then _newpos=int( (&_width/&__twidth - &_width) / 2);
      else _newpos=1;
      if _spleft>0 then do;
        _spget=ceil(_spleft / ncols_without_spacing);
        _spgetmore=_spleft - _spget*ncols_without_spacing;
      end;
      else do;
        _spget=0;
        _spgetmore=0;
      end;
    end;
    cpos=_newpos;
    if cspc=. then do;
      cspc=_spget + (_spgetmore>0);
      if _spgetmore>0 then _spgetmore=_spgetmore-1;
    end;
    output;
    _newpos=_newpos + cwid + cspc;
  run;
  %** end of setting column positions, width and spacing **;

  %* set sphdr widths and find number of rows needed for spanning headers *;
  %let __sphdrrows=0;
  %let __sphdr2rows=0;
  %let __sphdr3rows=0;
  %if &__nsphdr > 0 %then %do;
    data _spanhdrs;
      set _spanhdrs;
      stcol=scan(arg1,1,'-')+0;
      endcol=scan(arg1,2,'-')+0;
      _sphdrrows=countc(arg3,'~')+1;
    run;
    proc sql noprint;
      create table _spanhdrs_1 as
      select s.*, pc1.pancols as pancols1, pc1.pcol as pcol1, pc2.pancols as pancols2, pc2.pcol as pcol2
      from _spanhdrs s, _columns2 pc1, _columns2 pc2
      where s.stcol=pc1.col and s.endcol=pc2.col;
    quit;
    data _spanhdrs_1;
      set _spanhdrs_1;
      if endcol>scan(pancols1,-1) then do;
        newcol=endcol;
        endcol=scan(pancols1,-1);
        output;
        stcol=endcol+1; endcol=newcol;
        output;
      end;
      else output;
      drop newcol pancols1 pcol1 pancols2 pcol2;
    run;

    proc sql noprint;
      create table _spanhdrs_2 as
      select pc1.panel, pc2.panel as panel2, s.*,
        pc1.cpos as cpos1, pc1.cwid as cwid1, pc1.cspc as cspc1, pc2.cpos as cpos2, pc2.cwid as cwid2, pc2.cspc as cspc2,
        pc1.cpos as _sphdrp, pc2.cpos - pc1.cpos + pc2.cwid as _sphdrw, pc1.pancols, pc1.pcol
      from _spanhdrs_1 s, _columns2 pc1, _columns2 pc2
      where s.stcol=pc1.col and s.endcol=pc2.col;
      select max(_sphdrrows) into:__sphdrrows from _spanhdrs_2;
    quit;
    %if &__sphdrrows=  %then %let __sphdrrows=0;
  %end;
  %if &__nsphdr2 > 0 %then %do;
    data _spanhdr2;
      set _spanhdr2;
      stcol=scan(arg1,1,'-')+0;
      endcol=scan(arg1,2,'-')+0;
      _sphdr2rows=countc(arg3,'~')+1;
    run;
    proc sql noprint;
      create table _spanhdr2_1 as
      select distinct pc1.panel, s.*, pc1.pancols/**, pc1.col**/
      from _spanhdr2 s, _columns2 pc1
      where s.stcol=pc1.col or s.endcol=pc1.col or 
       (s.endcol>
         select distinct input(scan(pancols,-1),best.) as lstpancols from _columns2 having col=max(col)
       );
    quit;
    data _spanhdr2_1;
      set _spanhdr2_1;
      retain newend .;
      if newend ne . then do; stcol=newend+1; newend=.; end;
      if endcol>scan(pancols,-1) then do; endcol=scan(pancols,-1); newend=endcol; end;
      drop newend;
    run;
    proc sql noprint;
      create table _spanhdr2_2 as
      select s.*,
        pc1.cpos as cpos1, pc1.cwid as cwid1, pc1.cspc as cspc1, pc2.cpos as cpos2, pc2.cwid as cwid2, pc2.cspc as cspc2,
        pc1.cpos as _sphdrp, pc2.cpos - pc1.cpos + pc2.cwid as _sphdrw, pc1.pcol
      from _spanhdr2_1 s, _columns2 pc1, _columns2 pc2
      where s.stcol=pc1.col and s.endcol=pc2.col;
      select max(_sphdr2rows) into:__sphdr2rows from _spanhdr2_2;
    quit;
    data _spanhdr2_2;
      set _spanhdr2_2;
      if endcol>scan(pancols,-1) then endcol=scan(pancols,-1);
    run;
    %if &__sphdr2rows=  %then %let __sphdr2rows=0;
  %end;
  %if &__nsphdr3 > 0 %then %do;
    data _spanhdr3;
      set _spanhdr3;
      stcol=scan(arg1,1,'-')+0;
      endcol=scan(arg1,2,'-')+0;
      _sphdr3rows=countc(arg3,'~')+1;
    run;
    proc sql noprint;
      create table _spanhdr3_1 as
      select distinct pc1.panel, s.*, pc1.pancols
      from _spanhdr3 s, _columns2 pc1
      where s.stcol=pc1.col or s.endcol=pc1.col or 
       (s.endcol>
         select distinct input(scan(pancols,-1),best.) as lstpancols from _columns2 having col=max(col)
       );
    quit;
    data _spanhdr3_1;
      set _spanhdr3_1;
      retain newend .;
      if newend ne . then do; stcol=newend+1; newend=.; end;
      if endcol>scan(pancols,-1) then do; endcol=scan(pancols,-1); newend=endcol; end;
      drop newend;
    run;
    proc sql noprint;
      create table _spanhdr3_2 as
      select s.*,
        pc1.cpos as cpos1, pc1.cwid as cwid1, pc1.cspc as cspc1, pc2.cpos as cpos2, pc2.cwid as cwid2, pc2.cspc as cspc2,
        pc1.cpos as _sphdrp, pc2.cpos - pc1.cpos + pc2.cwid as _sphdrw, pc1.pcol
      from _spanhdr3_1 s, _columns2 pc1, _columns2 pc2
      where s.stcol=pc1.col and s.endcol=pc2.col;
      select max(_sphdr3rows) into:__sphdr3rows from _spanhdr3_2;
    quit;
    data _spanhdr3_2;
      set _spanhdr3_2;
      if endcol>scan(pancols,-1) then endcol=scan(pancols,-1);
    run;
    %if &__sphdr3rows=  %then %let __sphdr3rows=0;
  %end;

   %* prepare data null sections **;
  %if &__nrow | &_dodata %then %do;
    %if &__nrow & &_dodata %then %do;
      proc sort data=&indata out=_rows30;
        by row col;
      run;
      proc sort data=_rows2;
        by row col;
      run;
      data _rows30;
        merge _rows30(in=a) _rows2(keep=row col inlvl rename=(inlvl=rinlvl));
        by row col;
        if a;
        if inlvl=. then inlvl=rinlvl;  %* make sure data provided inlvls override shell rows inlvl;
      run;
    %end;
    %else %do;
      data _rows30;
        set &indata;
      run;
    %end;
  data _rows3a;
     set
     %if (&__rowshell | ^&_dodata) & &__nrow %then %do;
        _rows2
        %if ^&__shellstats %then %do;
        (where=(upcase(text) ^contains 'XX' and upcase(text) ^contains 'X.X'))
        %end;
     %end;
     %if &_dodata %then %do;
        _rows30;
        if upcase(scan(text,1)) ne 'NOTE:' and upcase(scan(text,2)) ne 'NOTE:'
     %end;
     ;
     if src=. then src=0;
     if src=1 and text in ('','.') then delete;
  run;
  %end;
  %else %do;
  data _rows3a;
    length row col 8 text $2000 src 8;
    row=1;
    src=1;
    %do __i=1 %to &__ncol;
      col=&__i;
      text="Col.&__i";
      output;
    %end;
  run;
  %end;

proc sql noprint;
  create table _rows31 as
  select _rows3a.*, panel, pancols
  from _rows3a left join _pcolumns p
  on _rows3a.col = p.col;
quit;
Proc sort data=_rows31;
   by &sortvars panel col row src;
run;

data _rows3b;
   set _rows31;
   by &sortvars panel col row;
   if first.row;
run;
data _rows3c;
  set _rows3b;
   %** assign col2 (ending column) value if span option in cell **;
   %** note: spanned cell value inherits align from starting column cdalign value **;
   col2=col;
   if index(upcase(text),'#SPAN') then do;
      _tmp0=index(upcase(text),'#SPAN'); %*starting position;
      _tmp1=index(substr(text,_tmp0+1),'#')-6; %*length of span number;
      _tmp2=substr(text,_tmp0+6,_tmp1);
      if _tmp2>0 then do;
         %*assign ending col2 value;
         %*span support for panels added: now we are getting the panel n-th column number;
         col2=scan(pancols,col+_tmp2-1);
         if col2=. then col2=scan(pancols,-1);  ** if span is longer than this panel columns, we take the last column;
      end;
      else put 'WARNING: SPAN cell option requires a value greater than 1.';
      if _tmp0>1 then text=substr(text,1,_tmp0-1)||substr(text,_tmp0+7+_tmp1);
      else text=substr(text,8+_tmp1);
   end;
   drop _tmp0 _tmp1 _tmp2;
run;


%* apply FLOW;
proc sort data=_columns2;
  by &sortvars panel col;
proc sort data=_rows3c;
  by &sortvars panel col;
data _rows3d;
   merge _rows3c(in=a) _columns2(drop=row colhdr);
   by &sortvars panel col; if a;
run;

proc sort data=_rows3d;
   by &sortvars panel col2;
run;
data _rows3e;
   merge _rows3d(in=a) _columns2(keep=panel col cwid cpos rename=(col=col2 cwid=c2wid cpos=c2pos));
   by &sortvars panel col2; if a;
   %* adjust col width for spanned columns if span cell option used;
   if col2 > col then do;
      cwid=c2pos+c2wid-cpos;
   end;
run;

proc sort data=_rows3e;
   by &sortvars row col;
run;

**apply within text INLVL override**;
data _rows3f;
   set _rows3e;
   by &sortvars row col;
   if inlvl=. then inlvl=0;
   if substr(text,1,6)='#INLVL' then do;
      _tmp1=index(substr(text,2),'#')-7; %*length of span number;
      _tmp2=substr(text,8,_tmp1)-1;
      if _tmp2>=0 then do;
         %*override inlvl value;
         inlvl=_tmp2;
      end;
      else put 'WARNING: INLVL cell option requires a value greater than or equal to 0.';
      text=substr(text,9+_tmp1);
   end;
run;
%if %eval(&__dowrap) %then %do;
  %tblwrap(_rows3f,cwid)
%end;
  proc sort data=_rows3f&__wrap out=_rows4;
     by &sortvars panel col row;
  run;

   data pos;
      set _rows4;
      by &sortvars panel col row;
      retain decpos parpos declen parlen 0;
      if substr(text,1,8) in ('#NOGROW#','#NOFLOW#') then text=substr(text,9);
      if first.col then do;
         decpos=.; declen=.;
         parpos=.; parlen=.;
      end;
      if row>0 then do;
         if index(text,'.') > decpos and (index(text,'.') < index(text,'(') or ^index(text,'('))
            and ^index(text,',')
            and text=translate(text,'','ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz')
            then do;
            decpos=index(text,'.');
            declen=index(text,'.');
         end;
         if index(text,')') > parpos
            and text=translate(text,'','ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz')
            then do;
            parpos=index(text,')');
            *parlen=length(text);
            parlen=index(text,')');
         end;
      end;
      if last.col then output;
      keep &sortvars panel col decpos parpos declen parlen;
   run;
   data _rows4;
      merge _rows4(in=a) pos;
      by &sortvars panel col; if a;
      %if ^%eval(&__dowrap) %then %do; flowrow=0; %end;
   run;
   proc sort data=_rows4;
      by &sortvars panel row col;
   run;
   %if &syserr>4 %then %do;
      %xerrset(Processing position guides failed.);
      %goto exit;
   %end;

   %if %exist(_sttime) %then %do;
	   %let _sptime_ = %sysfunc(time());
	   %let _xproctime_ = %sysfunc(round(&_sptime_ - &_sttime_ - &_tproctime_,.02));
	   %let _tproctime_ = %sysfunc(round(&_sptime_ - &_sttime_,.02));
	   %put NOTE: **Macro Proctime** &_main_ macro - Layout - used &_xproctime_ seconds, total so far is &_tproctime_ seconds.;
	 %end;

 %***This section is for data null style output: we manually find page breaks, repeat elements on pages, etc***;
   %*if ^&__rowshell %then %do;
      %* detect singlespace;
      data _null_;
        set _rows4 end=last;
        where flowrow ne 1;
        retain lastrow snglsp 0;
        if row>0 and lastrow=. then lastrow=row;
        else if row>1 then do;
          if row-lastrow=1 then snglsp=1;
        end;
        lastrow=row;
        if last then call symput('__snglsp',snglsp);
      run;
      %*if ^%length(&__pgbk_newvalincol) %then %let __pgbk_newvalincol=&__ncol;
      %xbug(TABLE: pagebreaks, __pgbk_inlevel __pgbk_newvalincol __snglsp)
      %xbug(TABLE: lastbdr, __ftrstrow __tmargin __rtitles __chdrrows __headline __topline __sphdrrows __sphdr2rows __sphdr3rows)

      data _pages _bks _allpgs(drop=rowgrp pgnum rowsgrp newrow lastrow lastskip pgbkrow lastbdr pgbk);
       ** create subvar variable in case it does not exist **;
       length subvar 8;
       set _rows4(where=(panel=1)) end=eof;
       by &sortvars panel row col;
       %if %upcase(&output)=BMSRTF %then %do;
       	retain lastbdr %eval(38-&__rtitles+3-&__rfootnotes-&__chdrrows-&__sphdrrows-&__sphdr2rows-&__sphdr3rows-&__pgbk_reducer);;
      %end; %else %do;
       retain lastbdr
       %eval(&__ftrstrow - &__tmargin - &__rtitles - &__rtitles_wraps - &__chdrrows - &__headline - &__topline - &__sphdrrows - &__sphdr2rows - &__sphdr3rows - &__pgbk_reducer - 1);;
     %end;
       length pgbk_label0 %do __zz=1 %to &__pgbk_repeat_label_upto_inlvl; pgbk_label&__zz %end; $200;
       retain rowgrp pgnum rowsgrp newrow lastrow lastskip lastnonsub pgbkrow . pgbk_label0 %do __zz=1 %to &__pgbk_repeat_label_upto_inlvl; pgbk_label&__zz %end;;
       if row<0 then do;
          *pgnum=0;
          output _allpgs;
       end;
       if pgnum=. and row>0 then do;
      	pgnum=1;
      	lastskip=row;
      	pgbkrow=row;
      	lastnonsub=row;
      	pgbk=1;
      	%do __zz=0 %to &__pgbk_repeat_label_upto_inlvl;
      		if col=1 and inlvl=&__zz then pgbk_label&__zz=prxchange('s/#NEWPAGE#//', -1, text);
      	%end;
       end;
       if first.row then do;
        if (row ne lastrow+1 & &__snglsp) /*or inlvl le &__pgbk_inlevel*/
          or (col le &__pgbk_newvalincol and flowrow=0)
          or (&__pgbk_newvalincol=0 and ^&__snglsp and col=1) then do;
		      	lastskip=row;
		      	rowsgrp=1;
        end;
        else rowsgrp+1;
	       %do __zz=0 %to &__pgbk_repeat_label_upto_inlvl;
	      	 if col=1 and inlvl=&__zz then do;
	      	 	pgbk_label&__zz=prxchange('s/#NEWPAGE#//', -1, text);
	      	 	%do __yy=%eval(&__zz+1) %to &__pgbk_repeat_label_upto_inlvl;
	      	 		pgbk_label&__yy='';
	      	 	%end;
	      	 end;
	       %end;
       end;
       newrow=row-pgbkrow+1;

       if newrow > lastbdr or (substr(text,1,9)='#NEWPAGE#' and ^(row=pgbkrow)) then do;
      	pgbk=1;
      	if substr(text,1,9)='#NEWPAGE#' then do;
      		pgbkrow=row;
		       %do __zz=0 %to &__pgbk_repeat_label_upto_inlvl;
		      	 if col=1 and inlvl=&__zz then do;
		      	 	pgbk_label&__zz=prxchange('s/#NEWPAGE#//', -1, text);
		      	 	%do __yy=%eval(&__zz+1) %to &__pgbk_repeat_label_upto_inlvl;
		      	 		pgbk_label&__yy='';
		      	 	%end;
		      	 end;
		       %end;
      	end;
      	else if (row-lastskip > 10 & &__snglsp) then pgbkrow=min(row-1, lastnonsub);
      	else pgbkrow=lastskip;
      	pgnum+1;
      	output _bks;
       end;
       else do;
        pgbk=0;
        if substr(text,1,9)='#NEWPAGE#' then text=substr(text,10);  ** ignore newpage if not used (improper usage)**;
       end;
       if first.row and ^subvar then lastnonsub=row;
       if row > 0 then output _pages;
       lastrow=row;
       if eof then call symput('npgs',pgnum);
      run;
      %if &syserr>4 %then %do;
         %xerrset(Processing page breaks for NOROWSHELL condition failed.);
         %goto exit;
      %end;

   %*end;

   proc sort data=_bks;
     by row;
   run;
   proc sort data=_rows4;
     by row;
   run;
   data _pages2;
     merge _rows4(where=(row>0)) _bks(keep=pgbkrow pgnum pgbk_label0-pgbk_label&__pgbk_repeat_label_upto_inlvl rename=(pgnum=pgnum_ pgbkrow=row));
    by row;
    retain pgnum .;
    if _n_=1 then pgnum=1;
    if pgnum_ ne . and pgnum ne pgnum_ then pgnum=pgnum_;
    drop pgnum_;
   run;

   proc sort data=_pages2;
      by pgnum row;
   data _bks2;
      set _pages2;
      by pgnum row;
      if first.pgnum;
      if pgnum=1 then row=1;
   run;

   data _allpgs;
    set _allpgs;
    do pgnum=1 to &npgs;
    output;
    end;
   run;

   data _pages3;
    set _pages2 _allpgs;
   run;

   proc sort data=_pages3;
      by pgnum;

   data _pages3;
      merge _pages3 _bks2(keep=pgnum row rename=(row=pgbk));
      by pgnum;
   run;

   proc sort in=_pages3 out=_rows5;
    by &sortvars pgnum row col;
   run;
   %if &syserr>4 %then %do;
      %xerrset(Processing page breaks failed.);
      %goto exit;
   %end;
%*end;
  proc sort data=_rows5;
    by panel row col;
  run;
  data _rows5p1(keep=row col keepnext newpage);
    merge _rows5(in=a) _pages(keep=panel row col newrow lastskip rowsgrp lastrow);
    by panel row col; if a;
    retain keepcnt keepnext .;
    if first.row then do;
      if row=lastskip then keepcnt=1;
      else keepcnt=keepcnt+1;
      if keepcnt<11 or inlvl ne lag(inlvl) then keepnext=1; else keepnext=0;
    end;
    if substr(text,1,9)='#NEWPAGE#' then do;
      text=substr(text,10);
      newpage=1;
    end;
    if first.row and row=pgbk and pgnum>1 then newpage=1;
    if panel=1 then output;
  run;
  proc sort data=_rows5;
    by row col;
  run;
  data _rows5;
    merge _rows5 _rows5p1;
    by row col;
    if substr(text,1,9)='#NEWPAGE#' then text=substr(text,10);
  run;
  %if &__pgbk_repeat_label %then %do;
  proc sort data=_rows5;
  	by panel pgnum row col;
  run;
  data _rows5;
    set _rows5;
    by panel pgnum;
    array pgbklbls{%eval(&__pgbk_repeat_label_upto_inlvl+1)} pgbk_label0-pgbk_label&__pgbk_repeat_label_upto_inlvl;
    if first.pgnum and pgbk_label0 ne '' and col=1 and inlvl ne 0 then newpage=.;
    output;
    originlvl=inlvl;
    if first.pgnum and pgbk_label0 ne '' and col=1 and originlvl ne 0 then do _inlvl=&__pgbk_repeat_label_upto_inlvl to 0 by -1;
    	if originlvl > _inlvl then do;
	      row=row-.1;
	      text=pgbklbls{_inlvl+1};
	      inlvl=_inlvl;
	      if inlvl=0 then newpage=1;
	      output;
	    end;
    end;
  run;
  %end;

  proc sort data=_rows5 out=_rowsout;
   %if %xeq(&__pageorder,OVERTHENDOWN) %then %do;
    by &sortvars pgnum panel row col;
  %end; %else %do;
    by &sortvars panel pgnum row col;
  %end;
  run;
 
  **repeat titles/footnotes for all pages/panels**;
  proc sql noprint;
    create table _titlesout as
    select t2.pgnum, t2.panel, t1.*
    from _titles2 t1, (select unique pgnum, panel from _rowsout) t2;
  quit;
  proc sql noprint;
    create table _footnotesout as
    select t2.pgnum, t2.panel, t1.*
    from _footnotes2 t1, (select unique pgnum, panel from _rowsout) t2;
  quit;

  %if &__nsphdr > 0 %then %do;
  data _spanhdrs_2;
    set _spanhdrs_2;
    rename arg2=sphalign arg3=text;
    row=1;
  run;
  %if &__dowrap %then %do;
  %tblwrap(_spanhdrs_2,_sphdrw)
  %end;
  **repeat for each page**;
  proc sql noprint;
    create table _spanhdrsout as
    select t2.pgnum, t1.*
    from _spanhdrs_2&__wrap t1, (select unique pgnum, panel from _rowsout) t2
    where t1.panel=t2.panel;
  quit;
  %end;
  %if &__nsphdr2 > 0 %then %do;
  data _spanhdr2_2;
    set _spanhdr2_2;
    rename arg2=sphalign arg3=text;
    row=1;
  run;
  %if &__dowrap %then %do;
  %tblwrap(_spanhdr2_2,_sphdrw)
  %end;
  **repeat for each page**;
  proc sql noprint;
    create table _spanhdr2out as
    select t2.pgnum, t1.*
    from _spanhdr2_2&__wrap t1, (select unique pgnum, panel from _rowsout) t2
    where t1.panel=t2.panel;
  quit;
  %end;
  %if &__nsphdr3 > 0 %then %do;
  data _spanhdr3_2;
    set _spanhdr3_2;
    rename arg2=sphalign arg3=text;
    row=1;
  run;
  %if &__dowrap %then %do;
  %tblwrap(_spanhdr3_2,_sphdrw)
  %end;
  **repeat for each page**;
  proc sql noprint;
    create table _spanhdr3out as
    select t2.pgnum, t1.*
    from _spanhdr3_2&__wrap t1, (select unique pgnum, panel from _rowsout) t2
    where t1.panel=t2.panel;
  quit;
  %end;
  
  **repeat column headers on each page;
  proc sql noprint;
    create table _columnsout as
    select t2.pgnum, t1.*, &_width as twid, &_framewidth as fwid 
    from _columns2 t1, (select unique panel, pgnum from _rowsout) t2
    where t1.panel=t2.panel;
    select max(panel)*max(pgnum) into:totpg from _rowsout;
  quit;

  data _tabline;
    length row 8 text $2000;
    row=1; text='#LINEFULL#'; twidth=&_width*(1 - .3*(&_width=&_framewidth)); 
    output;
  run;
  proc sql noprint;
    create table _tablineout as
    select t2.pgnum, t2.panel, t1.*
    from _tabline t1, (select unique pgnum, panel from _rowsout) t2;
  quit;
  
  %let _dskwrd=0;
  data _out0;
    set 
    %if &__ntitl>0 %then %do; _titlesout(in=int) %end;
    %if &__nsphdr3>0 %then %do; _spanhdr3out(in=ins3) %end;
    %if &__nsphdr2>0 %then %do; _spanhdr2out(in=ins2) %end;
    %if &__nsphdr>0 %then %do; _spanhdrsout(in=ins) %end;
    _columnsout(in=inc rename=(colhdr=text))
    _rowsout(in=inr)
    %if &__nfn>0   %then %do; _footnotesout(in=inf) %end;
    %if &__topline %then %do; _tablineout(in=intop) %end;
    %if &__headline %then %do; _tablineout(in=inhdl) %end;
    %if &__bottomline %then %do; _tablineout(in=inbot) %end;
    ;
    retain col1pos .;
    if int then do;
      rptsect=1;
      pos=1;
      wid=&_framewidth;
      algn=titlalign;
      indt=0;
    end;
    
    %if &__nsphdr3>0 %then %do; 
    else if ins3 then do;
      rptsect=2;
      pos=_sphdrp;
      wid=_sphdrw;
      algn=sphalign;
      col=stcol;
      col2=endcol;
      indt=0;
    end;
    %end;
    %if &__nsphdr2>0 %then %do; 
    else if ins2 then do;
      rptsect=2.5;
      pos=_sphdrp;
      wid=_sphdrw;
      algn=sphalign;
      col=stcol;
      col2=endcol;
      indt=0;
    end;
    %end;
    %if &__nsphdr>0 %then %do; 
    else if ins then do;
      rptsect=3;
      pos=_sphdrp;
      wid=_sphdrw;
      algn=sphalign;
      col=stcol;
      col2=endcol;
      indt=0;
    end;
    %end;
    else if inc then do;
      rptsect=4;
      pos=cpos;
      wid=cwid;
      algn=chalign;
      indt=0;
      if col=1 then col1pos=cpos;
    end;
    else if inr then do;
      rptsect=5;
      pos=cpos;
      wid=cwid;
      algn=cdalign;
      indt=inlvl;
      roworig=row;
      if row>0 then row=row-pgbk+1;
    end;
    %if &__nfn>0   %then %do; 
    else if inf then do;
      rptsect=6; 
      pos=col1pos;
      wid=twidth;
      algn=titlalign;
      indt=flowrow*2;
    end;
    %end;
    %if &__topline %then %do;
    else if intop then do;
      rptsect=1.5;
      pos=col1pos;
      wid=twidth;
      algn='L';
      indt=0;
    end;
    %end;
    %if &__headline %then %do;
    else if inhdl then do;
      rptsect=4.5;
      pos=col1pos;
      wid=twidth;
      algn='L';
      indt=0;
    end;
    %end;
    %if &__bottomline %then %do;
    else if inbot then do;
      rptsect=5.5;
      pos=col1pos;
      wid=twidth;
      algn='L';
      indt=0;
    end;
    %end;
    if rptsect in (1,2,2.5,3,6) and text='.' then delete; 
    if rptsect in (1,1.5,2,2.5,3,4,4.5) then rptgroup=1;
    else if rptsect=5 then rptgroup=2;
    else if rptsect=6 then rptgroup=3;
    length _dsvar $20 _dskwrd $50 textorig $200;
    if index(text,'#DSVAR') then do;
      _dsvar=scan(substr(text,index(text,'#DSVAR=')+7),1,'#');
      _dskwrd=scan(substr(text,index(text,'#DSVAR=')),1,'#');
      call symput('_dskwrd',1);
    end;
    textorig=text;
  run;

  %** handle keyword replacements here **;
  %let pgmname=%lowcase(&pgnm..sas);
  %let date9=&sysdate9;
  %let listnum=&__lnum;
  %let datasource=&__tsrc;
  %let ldatasource=&__lsrc;
  %let listrefnum=&__lref;
  %if %exist(db) %then %do; %let dbver=&db; %end;
  %if %exist(cutdt) %then %do; %let cutoff=&cutdt; %end;
  %let extractdate=%extractlkup(%scan(%str(&__tsrc),1));
  %let PGMFULLNAME=%lowcase(&pgmpath&pgnm..sas);
  %let PGMRELNAME=%lowcase(...\Programs\&pgmloc\&pgnm..sas);
  %let PGMRELPATH=%lowcase(...\Programs\&pgmloc);

  proc sort data=_out0;
  %if %xeq(&__pageorder,OVERTHENDOWN) %then %do;
    by &sortvars pgnum panel descending rptsect descending row col;
  %end; %else %do;
    by &sortvars panel pgnum descending rptsect descending row col;
  %end;
  %macro repldsvar(var);
    %if %eval(%dsvarnum(_out0,&var)>0) %then %do;
    data _out0;
      set _out0(rename=(&var=_&var));
      length &var %dsvarlike(_out0,&var);
      retain &var; drop _&var;
      if _&var ne '' then &var=_&var;
        if index(text,"#DSVAR=&var#") then text=prxchange("s/#DSVAR=&var#/"||trim(left(&var))||"/", -1, text);
    %end; %else %do;
    data _out0;
      set _out0;
        if index(text,"#DSVAR=&var#") then text=prxchange("s/#DSVAR=&var#/<&var>/", -1, text);
    %end;
    run;
  %mend;

  %if &_dskwrd %then %do;
  proc sort data=_out0 out=_dskwlst(keep=_dsvar) nodupkey;
    where _dsvar ne '';
    by _dskwrd;
  run;  
  data _null_;
  set _dskwlst;
    call execute('%repldsvar('||compress(_dsvar)||')');
  run;
  %end;

  data _out1;
  set _out0;
    match1=prxparse("S/##+ of ##+/"||compress((pgnum-1)*&__npanels+panel)||" of "||compress("&totpg")||"/");
    if _n_=1 then do;
      ** match1b and match4b fix a bug in resolve() where the / * string causes all text after it to truncate **;
      match1b=prxparse("S/\/\*/^^^^^^/");
      match2=prxparse("S/#(LINE|LINEFULL)#/!$1!/");
      match3=prxparse("S/#(\D+\d*)#/&$1/");
      match4=prxparse("S/!(LINE|LINEFULL)!/#$1#/");
      match4b=prxparse("S/\^\^\^\^\^\^/\/*/");
    end;
    retain match1b match2-match4 match4b;
    length _dsvar $20;
    call prxchange(match1,1,text);
    if text ^in ('#LINE#','#LINEFULL#') then do;
      call prxchange(match1b,-1,text,text);
      call prxchange(match2,-1,text,text);
      call prxchange(match3,-1,text,text);
      call prxchange(match4,-1,text,text);
      text=resolve(text);
      call prxchange(match4b,-1,text,text);
    end;
  run;

  proc sort data=_out1 out=_out;
  %if %xeq(&__pageorder,OVERTHENDOWN) & %upcase(&output)^=WORD & %upcase(&output)^=PDFTBL & %upcase(&output)^=WORDPDF & %upcase(&output)^=ODT & %upcase(&output)^=ALL & %upcase(&output)^=BMSRTF %then %do;
    by &sortvars pgnum panel rptgroup rptsect row col;
  %end; %else %do;
    by &sortvars panel pgnum rptgroup rptsect row col;
  %end;
  run;

  %if %exist(_sttime) %then %do;
	  %let _sptime_ = %sysfunc(time());
	   %let _xproctime_ = %sysfunc(round(&_sptime_ - &_sttime_ - &_tproctime_,.02));
	   %let _tproctime_ = %sysfunc(round(&_sptime_ - &_sttime_,.02));
	   %put NOTE: **Macro Proctime** &_main_ macro - Page breaks and data prep - used &_xproctime_ seconds, total so far is &_tproctime_ seconds.;
  %end;
 %***End of Section to prepare data null style dataset***;


%if %upcase(&output)=WORD | %upcase(&output)=PDFTBL | %upcase(&output)=WORDPDF | %upcase(&output)^=ODT | %upcase(&output)^=ALL | %upcase(&output)=BMSRTF %then %do;
  %xnotes(1);
  %let odtfile=&outpath.&filenm;
  %put Output file: &odtfile;
  %if &_debug_=0 %then %do;
    %xnotes(0);
  %end;
 
  proc sort data=_out;
  	by panel rptgroup rptsect row col;
  run;

  data _out(drop=zzz yyy);
    merge _out(drop=maxpcol pancols) _pcolsumm(keep=panel maxpcol) _columns2(where=(zzz=1 and yyy=1) keep=panel col row pancols rename=(col=zzz row=yyy));
    by panel;
    if col2=. then col2=col;
%if %upcase(&output)^=BMSRTF %then %do;
    text=prxchange('s/</&lt;/', -1, prxchange('s/>/&gt;/', -1,prxchange('s/&/&amp;/', -1, text)));
    if col>1 and index(text,'( ') then
      text=prxchange('s/(\()\s+(\d)/$1$2/',-1,text);
    drop pgnum;
%end;
%if %upcase(&output)=BMSRTF %then %do;
	  text=prxchange('s/N=&N\d/N=xx/',-1,text);
    if rptsect=1 and (index(text,'Subgroup:') or index(text,'#byval')) then do;
    	row=row+1;
    	text=prxchange('s/Subgroup://', -1, text);
    end;
%end;
    if rptsect=5 then row=roworig;
    *rename lastrow=pgbk_lastrow;
    if pgnum=1 and rptsect in (1,1.5,2,2.5,3,4,4.5,6) or rptsect=5;
  run;
  proc sort data=_out;
  	by panel rptgroup rptsect row col;
  run;
  
  %if %eval(&rptout) %then %do;
    %let __twidthpct=%sysevalf(&__twidth*100);
    %if %upcase(&output)=BMSRTF %then %do;
    	/* %include "&glibroot\report\bms\*.sas"; */
    	%makebmsrtf(&odtfile, tw=&__twidthpct, lrmargin=&__leftmargin);
    %end;
    %else %do;
	    %if %upcase(&output)=ODT | &env=CLIENT %then %do;
	      %let __word=0; %let __pdf=0; %let __odt=1;
	    %end; %else %if %upcase(&output)=WORDPDF %then %do; 
	      %let __word=1; %let __pdf=1; %let __odt=0;
	    %end; %else %if %upcase(&output)=PDFTBL %then %do;
	      %let __word=0; %let __pdf=1; %let __odt=0;
	    %end; %else %if %upcase(&output)=WORD %then %do;
	      %let __word=1; %let __pdf=0; %let __odt=0; 
	    %end; %else %if %upcase(&output)=BMSRTF %then %do;
	      %let __word=0; %let __pdf=0; %let __odt=0; 
	    %end; %else %if %upcase(&output)=ALL %then %do;
	      %let __word=1; %let __pdf=1; %let __odt=1;
	    %end; %else %do;
	      %let __word=1; %let __pdf=0; %let __odt=0;
	    %end;
	    %makeodt(&odtfile,twidpct=&__twidthpct,word=&__word,pdf=&__pdf,odt=&__odt,
	      portrait=&__portrait, pagesize=&__pagesize, font=&__font, fontsize=&__fontsize, title_fontincr=&__title_fontincr, 
      leftmargin=&__leftmargin, rightmargin=&__rightmargin, topmargin=&__topmargin, bottommargin=&__bottommargin);
		%end;
  %end;
   %if %exist(_sttime) %then %do;
	   %let _sptime_ = %sysfunc(time());
	   %let _xproctime_ = %sysfunc(round(&_sptime_ - &_sttime_ - &_tproctime_,.02));
	   %let _tproctime_ = %sysfunc(round(&_sptime_ - &_sttime_,.02));
	   %put NOTE: **Macro Proctime** &_main_ macro - Execute ODT Generator - used &_xproctime_ seconds, total so far is &_tproctime_ seconds.;
   %end;
   
   %if &allinone & &lastone %then %do;
   ** setup a subdirectory holding copies of everything just generated in this runall session;
   ** temp filenames should be timestamped in name, so order is chronological, ready for merge;
   ** pdftk merge the directory *.pdf;
   ** move file to folder and rename file;
   %end;
%end;

%if %exist(savetdata) %then %do;
	%if &savetdata %then %do;
	  data _rptlog1 _rptlog2;
	    length filename $50 user $20 pgnm $30 pgext $30 tnum $20 runtime 8 panel rptgroup rptsect row col 8 text $2000 /*algn $2*/ indt 8
	           StudyGroupID TrtGroupID PopID ParamID PhaseID SubID SubSEQ 8;
	    set _out(keep=rptgroup rptsect panel /*algn*/ indt row col text);
	    where rptsect in (2,3,4,5);
	    retain runtime .;
	    user="&username"; pgnm="&pgnm"; pgext="%trim(&pgext)"; if _n_=1 then runtime=datetime();
	    filename="&filenm"; tnum="&__tnum";
	    StudyGroupID=&extStudyGroupID; TrtGroupID=&extTrtGroupID; PopID=&extPopID; ParamID=&extParamID; PhaseID=&extPhaseID; SubID=&extSubID; SubSEQ=&extSubSEQ;
	    format runtime datetime28.3;
	    if rptgroup=1 then output _rptlog1; else output _rptlog2;
	  run;
	  proc sort data=_rptlog1 nodupkey;
	    by rptgroup descending rptsect descending row col;
	  run;
	  data _rptlog1;
	  	set _rptlog1;
	  	by rptgroup descending rptsect descending row;
	  	retain trow 0;
	  	if first.row then trow=trow-1;
	  run;
	  proc sort data=_rptlog1;
	    by rptgroup rptsect trow col;
	  run;
	  proc sort data=_rptlog2 nodupkey;
	    by rptgroup rptsect row col;
	  run;
	  data _rptlog2;
	  	set _rptlog2;
	  	by rptgroup rptsect row;
	  	retain trow 0;
	  	if first.row then trow+1;
	  run;
	  data _rptlog(drop=row);
	  	set _rptlog1 _rptlog2;
	    by rptgroup rptsect trow col;
	  run;	  
	  proc transpose data=_rptlog out=_trptlog(rename=(trow=row));
	    by rptsect trow user runtime;
	  	id col;
	  	var text;
	  run;
	  proc sql noprint;
	  	select max(col) into:__maxtcol from _rptlog;
	  quit;
	  %xnotes(1)
	  %put;
	  data vtdata.&tdatanm;
	    retain row _1-_%left(&__maxtcol) user runtime;
	    set _trptlog;
	    array allvars _character_;
	    do over allvars;
	    	allvars=prxchange('s/~#LINE#//', -1, allvars);
	    end;
	    drop rptsect _name_;
	  run;  
	  %if &_debug_=0 %then %do;
	    %xnotes(0);
	  %end;
	%end;
%end;

%if &_debug_ = 0 %then %do;
   proc datasets lib=work nolist nodetails;
      delete in in0 in2 pos _allpgs _bks _bks2 _pages _pages2 _pages3 _grow _growmax stats
      _attribs _rows: _columns: _titles: _footnotes: _spanhdr: _panels: _out: __out2a _pcolsumm _coltmp _pcolumns _table _tabline: _cgrpmax _fill0
      %if &savetdata %then %do; _rptlog: _trptlog %end;;
   quit;
%end;
%exit:
%let pgext=;
%let data=;
%let tabnum=;
%let listnum=;
%let __tnum=;
%xnotes(1)
%xterm;
%mend table3;
