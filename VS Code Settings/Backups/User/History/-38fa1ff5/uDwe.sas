/*!
 *    Import an Excel (xlsx) file to SAS datasets
 *    @author K. McBride
 */

/**
 *    This macro will convert an Excel spreadsheet (in .xlsx format) to SAS datasets. It can do all sheets or one sheet, and you can specify the output SAS libname (default is WORK).
 *    <br><br>
 *    <b>Usage:</b><br><code>
 *      %imp_xlsx(fname=
 *    </code>
 *    <br><a href='https://instat.unfuddle.com/projects/1/messages'>Examples and details</a>
 **
 *    @param      ds         Input dataset
 *    @param
 *
 *  <h2>More Details</h2>
 *  <h4>block title</h4>
 *  <p>Details go here
 */
%macro imp_xlsx(fname=,sheet=ALL,outlib=WORK,sidtype=rID,hdrrow=1,datarow=2,);
    %***sidtype is depracated**;
    %***original author: K.McBride***;
    %***macro for importing an XLSX document into SAS datasets***;
    %***each sheet ends up as a dataset, using the name of the worksheet, in the outlib***;
    %***currently, all variables are long character to capture everything (future enhancement to have user specify types/input on variables (we will not try to guess)***;
    %statutil %util %local __drops _nobs _nvars;
    %global _vlist _vlistc _ncvars _max2txt _nfmtlist _fmtlist _ndtcnv _dtcnv;

    %let __drops=;
    %xinit(imp_xlsx) %if &_debug_=2 %then %xnoisy;
    %else %if &_debug_=1 %then %do;
        options notes;
        %let _notes_=1;
        options mprint;
    %end;
    %else %xquiet;
    options varlenchk=NOWARN;

    data _null_;
        call symput('usertemp',sysget('TEMP'));
    run;

    filename tmppipe pipe "mkdir ""&usertemp\&sysjobid\ddtemp""";

    data _wuz_result;
        infile tmppipe length=l;
        input line $varying500. l;
    run;
    %err_pipe(_wuz_result) filename tmppipe pipe
        "C:\Progra~1\7-Zip\7z x -y -o&usertemp\&sysjobid\ddtemp ""&fname"" ";

    data _wuz_result;
        infile tmppipe length=l;
        input line $varying500. l;
    run;
    %err_pipe(_wuz_result)
        %* get styles, to help not guess anymore at numeric/currency/text content *;
        filename styles "!TEMP\&sysjobid\ddtemp\xl\styles.xml";
    filename SXLEMAP "&glibroot\util\xlsx_styles.map";
    libname styles xml92 xmlmap=SXLEMAP access=READONLY;

    data _styles_xf1;
        set styles.xf1;
        idx=_n_-1;
    run;

    proc sql;
        create table _cellstyle as select xf1.idx, xf1.numFmtId, xf1.xfId,
            cellstyle.name1, cellstyle.builtinId, numFmt.formatCode from
            _styles_xf1 as xf1 left join styles.cellstyle on
            xf1.xfId=cellstyle.xfId left join styles.numFmt on
            xf1.numFmtId=numFmt.numFmtId order by xf1.idx ;
    quit;

    filename sharedSt "!TEMP\&sysjobid\ddtemp\xl\sharedStrings.xml";
        ** encoding="UTF-8";
    filename SXLEMAP "&glibroot\util\xlsx_sharedStrings.map";
    libname sharedSt xml92 xmlmap=SXLEMAP access=READONLY;

    /**data _null_;
    infile sharedSt dsd truncover lrecl=32767 encoding='utf-8'; input @;
    _infile_=prxchange('s/\xE2\x89\xA4/&le;/',-1,_infile_);
    file shareSt;
    put _infile_;
    run;**/
    data _sst;
        set sharedst.si;
        if tnum=. then tnum=_n_;
        tnum=tnum-1;
    run;

    ** need to do for space management **;
    proc sql noprint;
        select max(length(t)) into:_maxtxt from _sst;
        alter table _sst modify t length=&_maxtxt;
    quit;
    /*
    data _sst;
    length t $&_maxtxt;
    set _sst;
    run;
     */
    filename workbk "!TEMP\&sysjobid\ddtemp\xl\workbook.xml";
    filename SXLEMAP "&glibroot\util\xlsx_workbook.map";
    libname workbk xml92 xmlmap=SXLEMAP access=READONLY;

    ** using Relationships table is more reliable for sheet ID loading **;
    filename workbkr "!TEMP\&sysjobid\ddtemp\xl\_rels\workbook.xml.rels";
    filename SXLEMAP "&glibroot\util\xlsx_workbook_rels.map";
    libname workbkr xml92 xmlmap=SXLEMAP access=READONLY;

    proc sql noprint;
        create table _workbook as select s.*, r.Target, r.Type from workbk.sheet
            s left join workbkr.relationship r on s.r_Id=r.Id;
    quit;

    filename SXLEMAP "&glibroot\util\xlsx_worksheet.map";

    data _imp_logall;
        length strout $1000;
        strout='';
        output;
    run;

    data &outlib.._wkbk;
        set _workbook;
        %if &sheet^=ALL %then %do;
            where name="&sheet";
        %end;
        length strcode $1000;
        name=translate(strip(name),'_______________________________',' /.,?<>;:"[]\{}|`~!@#$%^&*()-=+');
        rId=substr(r_id,4)+0;
        sheetNum=scan(substr(target,17),1,'.')+0;
        *rId=sheetId;
        strcode="filename  sheet ""!TEMP\&sysjobid\ddtemp\xl\"||compress(target)||""";";
        call execute(strcode);
        strcode="libname   sheet xml xmlmap=SXLEMAP access=READONLY;";
        call execute(strcode);
        strcode="%nrstr(%%imp_xlsx_inc)("||compress(sheetId)||","||compress(name)||",hdrrow=&hdrrow,datarow=&datarow);";
        call execute(strcode);
        strcode="proc append base=_imp_logall data=_imp_log; run;";
        call execute(strcode);
        strcode="data &outlib.."||compress(name)||";";
        call execute(strcode);
        strcode="  set _sheet"||compress(sheetId)||"; **drop _label_; run;";
        call execute(strcode);
        option nosource;
    run;
    option source;
    %let __drops=&__drops _wkbk _workbook _wuz_result _sst _c0 _c _cval _cval1
        _tdata _imp_log _imp_logall _tdatac _tdatan _sheetc _sheetn _attrib
        _attrc _attrn _sheet:;

    %xnotes(1)

    data _null_;
        set _imp_logall end=last;
        put strout;
        if last then put;
    run;
    %xnotes(0) %exit: %if &_debug_=0 %then %do;

    %**clean up**;
    data _null_;
        command="rmdir /S /Q ""&usertemp\&sysjobid\ddtemp""";
        call system(command);
    run;
    libname styles clear;
    libname sharedst clear;
    libname workbk clear;
    libname workbkr clear;
    libname sheet clear;

    proc datasets lib=work nolist nodetails;
        delete &__drops _cellstyle _cval0 _styles_xf1;
    quit;
    options notes;
    %end;
    %xterm;
    options varlenchk=WARN;
%mend imp_xlsx;
