%macro makebmsrtf(outfile, tw=100, lrmargin=.75) / minoperator;
  proc sql noprint;
    select case when index(HFLeft,'Protocol:') then scan(HFLeft,2,':') else HFLeft end, HFCenter into :__hfleft, :__hfcenter from meta.headersfooters where pagelocation='Header' and HFRow=1;
  quit;
  ods escapechar="^";
    %loadrtf(protocol=&__hfleft, display=&__hfcenter, lrmargin=&lrmargin)
  %let twidth=%sysevalf(11-2*&lrmargin);

  ** need to put out titles and footnotes **;
    data _null_;
      set _out(where=((rptsect=6 or (rptsect=1 and row>1)) and panel=1)) end=last;
        by rptsect row;
        retain fr . cnt 0 outtext;
        if _n_=1 then fr=row;
        length type $10 outtext $1000;
        if rptsect=1 then type='title'; else type='footnote';
        if rptsect=1 then row=row-fr+1;
        if first.row then outtext=catx(' ',cats(type,put(row,2.)),cats('j=',left(titlalign)),'"'||trim(text)||'"');
        else outtext=catx(' ',outtext,cats('j=',left(titlalign)),'"'||trim(text)||'"');
        if last.row then do;
            cnt+1;
            call symput('tf'||left(cnt), outtext);
            outtext='';
        end;
        if last then call symput('ntf',cnt);
    run;
    
    ** get columns **;
    proc sql noprint;
        select max(inlvl) into :_nlvls from _out;
    quit;
    %let _col1pre=;
    %if &_nlvls>0 %then %do i=1 %to &_nlvls;
        %let _col1pre=&_col1pre.\tx%sysevalf(182*&i);
    %end;
    
    proc sql noprint;
      select count(distinct col) into :_ncol
        from _out
        where rptsect=4;
      select distinct col, chalign, case when cdalign='L' and col=1 then 'L '||"pretext=""^R%str(%')&_col1pre.%str(%') """ when cdalign='L' then 'L' when cdalign='C' then 'L' else '' end as cdalign, &twidth*round((cwid+cspc-2)/twid,.01) as cwid, 
             case when flow=1 then 'flow' else '' end, text
        into :_col separated by '|', :_chalign separated by '|', :_cdalign separated by '|', :_cwid separated by '|', :_flow separated by '|', :_coltext separated by '|'
        from _out
        where rptsect=4;
      select max(length(text)) into: __maxtext TRIMMED from _out;
    quit;

/**
� = n pct (dec 400)
� = sumstats, p-value (dec 612)
� = text, ranges, etc (center)
**/
  
  /* Characters per inch for Courier New */
%let _cpi = %sysevalf(120/8);

/* Column width (col1) in inches */
%let _col1w = %scan(&_cwid,1,|);

/* %let _col1w =5.569718; */

/* Tab width in characters */
%let _tabchars = %sysevalf((182/1440)*&_cpi);

/* Layout overhead loss observed in BMS RTF tables */
%let _layoutloss = 20;

/* Available characters before indentation */
%let _avail0 = %sysfunc(floor(%sysevalf((&_col1w*&_cpi)-&_layoutloss)));

/* Available characters after 1 or 2 indent levels */
%let _avail1 = %sysfunc(floor(%sysevalf((&_avail0)-&_tabchars)));
%let _avail2 = %sysfunc(floor(%sysevalf((&_avail0)-2*&_tabchars)));

%put &_avail0. &_avail1. &_avail2.;

	 data _outrtf0;
  	length text wr_ch $2000. ind_add $200.;
    set _out(where=(rptsect=5));
	%wrap(oldvar=text, newvar=wr_ch, rowsize=&_avail1., use=1);
	if inlvl gt 2 then ind_add = strip(repeat("^{unicode '0009'x} ", inlvl-2));
	else if inlvl EQ 2 then ind_add = "^{unicode '0009'x} ";
	else ind_add="";
	if col = 1 then text = strip(tranwrd(wr_ch,'@',cat(" ^{newline} ^{unicode '0009'x} ",strip(ind_add)," ")));
	else text = text;

    if inlvl and col=1 then text=catx(' ',repeat("^{unicode '0009'x} ", inlvl-1),text);
    if colgrp>=10 then do;
/**        if ^(index(text,',') or countc(text,'.')>1) then text=text=catx(' ',"^R'\tqdec\tx"||compress(put(scan("&_cwid",col,"|")*.4*1440,4.))||"'",text);
        else text=catx(' ',"^R'\tqc\tx"||compress(put(scan("&_cwid",col,"|")*.5*1440,4.))||"\tab'",text); **/

        if index(text,'^n') or index(text,'[') or index(text,'{') or index(text,':') or index(text,',') or index(text,'=') then text='�'||text;
      else if ^(countc(text,'.')>1 or index(text,'(') or statmac in ('freqdist','aelist','freqlist')) then text='�'||text;
      else if countc(text,'.')>1 or index(text,'(') or statmac in ('freqdist','aelist','freqlist') then text='�'||text;
      end;
  run;
  ** check if subgroup var is present **;
  proc sql noprint;
    select count(*) into :__hassub from dictionary.columns where libname='WORK' and memname='_OUTRTF0' and upcase(name)='SUBGROUP';
  quit;
  %if &__hassub %then %do; %let temp_subvars=subgroupn subgroup; %let temp_subvars2=subgroupn, subgroup; %end; %else %do; %let temp_subvars=; %let temp_subvars2=; %end;
  ** check if >1 panels present **;
  proc sql noprint;
  	select max(panel) into :__npanels from _pcolumns;
  quit;
  %let __panelpg=;
  %if &__npanels>1 %then %do;
  	** find ID columns for proc report, and drop the dup records before transposing **;
  	proc sort data=_pcolumns out=_idcols;
  		by col panel;
  	run;
  	data _idcols;
  		set _idcols;
  		by col panel;
  		idcol=1;
  		if ^first.col and last.col then output;
  		keep col idcol;
  	run;
  	proc sql noprint;
  		create table _outrtf1 as
  		select o.*, i.idcol
  		from _outrtf0 o left join _idcols i on o.col=i.col
  		where i.idcol ne 1 or (i.idcol=1 and panel=1)
  		order by &temp_subvars2 pgnum, row, col, panel;
  	quit;
  	** get macro vars to use in proc report code **;
  	proc sql noprint;
  		select input(scan(pancols,-1),best.)+1 into :__panelpg separated by ' '
  		from (select distinct pancols from _pcolumns where panel<&__npanels);
  		select col into :__idcols separated by ' '
  		from _idcols;
  	quit;
  %end;
  %else %do;
  	data _outrtf1; set _outrtf0; run;
  %end;
  proc transpose data=_outrtf1 out=_outrtf prefix=col;
    by &temp_subvars pgnum row;
    id col;
    var text;
  run;
  data _outrtf;
    length pgnum grp row 8 col1-col%left(&_ncol) $2000;
    set _outrtf;
    retain grp 0 lastrow 0;
    if _n_=1 then grp=1;
    if int(row) ne row or round(row) > lastrow+1 then grp+1;
    **if int(row)=row then output;
    lastrow=round(row);
  run;
  ** fix unwanted page breaks by tagsets.rtf !!! **;
  data _outrtf;
    set _outrtf;
    by grp;
    array cols col:;
    output;
    if last.grp then do;
        do over cols; cols=' '; end;
        output;
    end;
  run;

  %let _collst=;
    %do i=1 %to &_ncol; 
        %let _collst=&_collst col&i; 
    %end;
  ** spanning columns **;
  proc sql noprint;
    select count(*) into :_nsphdr
    from _out where rptsect=3;
  quit;
  %if &_nsphdr>0 %then %do;
  data collst;
    set _out(where=(rptsect=3)) end=last;
    length strout $2000;
    retain strout '' lastcol 0 ncols &_ncol;
    do i=lastcol+1 to stcol-1;
        strout=catx(' ',strout,'col'||left(i));
    end;
    strout=catx(' ',strout,cats("('^S={borderbottomwidth=1}",prxchange('s/~#LINE#//',-1,text),"'"));
    do i=stcol to endcol;
        strout=catx(' ',strout,'col'||left(i));
    end;
    strout=cats(strout,')');
    if last then call symput('_collst',strout);
    lastcol=endcol;
  run;
    %end;
  data _null_;
    call symput('usertemp',sysget('TEMP'));
  run;
  filename bmsrtf "&usertemp\rtftemp.rtf";
    options number nobyline orientation=landscape leftmargin=&lrmargin.in rightmargin=&lrmargin.in topmargin=1in bottommargin=0.97in nodate;
  ods listing close;
    ods tagsets.bmsrtf file=bmsrtf style=Styles.Prismrtf uniform  options(vspace='No' continue_tag='No');
    %do i=1 %to &ntf;
        &&tf&i;
    %end;
    
  ** INSERT PROC REPORT CODE HERE **;
  proc sort data=_outrtf;
    by pgnum grp row;
  run;
**  ods tagsets.show_class file="&oroot\show_class.txt";
  proc report data=_outrtf nowd  split = "~" style(report)=[width=100% cellspacing=0 padding=1pt] style(column)={fontsize=8pt}; 
    column &temp_subvars pgnum grp &_collst;

    %if &__hassub %then %do;
        define subgroupn / order noprint;
        define subgroup / noprint;
        by subgroup;
    %end;
    define pgnum / order noprint page;
    define grp / order order=data noprint;
    /*define row / order=internal order noprint;*/

      %do i = 1 %to &_ncol;
        define col&i / %if &i=1 %then %do;  %end; %if %qscan(&_coltext,&i,|)=%quote(.) %then %do; "" %end; %else %do; "%scan(&_coltext,&i,|)" %end; style(column) = [asis=on cellwidth=%scan(&_cwid,&i,|)in just=%scan(&_cdalign,&i,|) ] style(header)=[just=%scan(&_chalign,&i,|)] %scan(&_flow,&i,|) %if &__npanels>1 %then %do; %if &i in (&__idcols) %then %do; ID %end; %if &i in (&__panelpg) %then %do; PAGE %end; %end; ;
      %end;
    
    **break after grp / skip summarize suppress;

       compute before pgnum /  style={font_size = 8pt};
            line "  ";
       endcomp;
        break after pgnum / page;
    run;
**    ods tagsets.show_class close;
    ods listing;
    ods tagsets.bmsrtf close;

    /** manipulate the RTF and replace placeholders with tabs - doing here post processing since PROC REPORT will count RTF pretext in table layout calculations, and will wrap within cells with RTF code in there causing page breaks to be broken **
            � = n pct (dec 400)
            � = sumstats, p-value (dec 612)
            � = text, ranges, etc (center)

        min columm 1270
        above that, split in half and add to dec stop**/

    data _outrtfcols0;
        infile bmsrtf truncover;
        input _line_ $char1500.;
        retain hdrrow frstbdyrow blankrow frstrow colnum 0;
        if index(_line_,'\trowd\trkeep\trhdr\trqc\trgaph0') then do; hdrrow+1; colnum=0; end;
        else if index(_line_,'\trowd\trkeep\trqc\trgaph0') and hdrrow>0 then do; frstbdyrow=1; hdrrow=0; colnum=0; end;
      if index(_line_,'\pard\plain\intbl\sb1\sa1\sl-181\fs16\cf1\qc\f1{\cell}') and frstbdyrow then do; blankrow=1; end;
      
      
        if hdrrow and index(_line_,'\cellx') then do;
            colnum+1; colwid=substr(_line_,index(_line_,'\cellx')+6);
            output;
        end;
        if _line_='{\row}' then do; 
            if blankrow then frstrow=1; else frstrow=0;
            frstbdyrow=0; blankrow=0;
        end;
    run;
    proc sql noprint;
        select max(hdrrow) into:_maxhdr from _outrtfcols0;
    quit;
    data _outrtfcols;
        set _outrtfcols0(where=(hdrrow=&_maxhdr));
        retain lastval .;
        if colwid > lastval then do;
            if colnum=1 then colwid2=colwid+0;
            else colwid2=colwid-lastval;
            f_tabstop=400+ceil((colwid2-1270)/2); s_tabstop=612+ceil((colwid2-1270)/2); output; 
        lastval=colwid;
     end;
    run;
    proc sql noprint;
        select count(colnum), colnum, lastval, f_tabstop, s_tabstop 
          into :_nrtfcols TRIMMED, :_rtfcolnum separated by '|', :_rtflastval separated by '|', :_rtfftab separated by '|', :_rtfstab separated by '|'
        from _outrtfcols
        where lastval ne .;
    quit;
    data _null_;
        infile bmsrtf truncover;
        file "&outfile..rtf" lrecl=32767;
        input _line_ $char1500.;
        length newline $1500;
        retain thiscol .;
      if thiscol ne . then do;
        **newline=prxchange('s/\\f1{�([^}]*)}/\\f1\\tqdec\\tabs'||scan("&_rtfftab",thiscol,"|")||'{\1}/', -1, _line_);
        if index(_line_,'�') then newline=prxchange('s/�/\\tqdec\\tx'||scan("&_rtfftab",thiscol,"|")||' /', -1, _line_);
        else if index(_line_,'�') then newline=prxchange('s/�/\\tqdec\\tx'||scan("&_rtfstab",thiscol,"|")||' /', -1, _line_);
        else if index(_line_,'�') then newline=prxchange('s/\\ql\\f1{�/\\qc\\f1{/', -1, _line_);
        else newline=_line_;
        put newline;
      end;
      else put _line_;
        %do i = 1 %to &_nrtfcols;
            %if &i>1 %then %do; else %end; if scan(_line_,-1,"\")="cellx%scan(&_rtflastval,&i,|)" then thiscol=&i;
        %end;
          else thiscol=.;
    run;
%mend makebmsrtf;

