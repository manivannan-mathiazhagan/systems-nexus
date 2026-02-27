%macro
    makeodt(outfile,twidpct=100,talign=C,titl_in_pagehdr=1,word=1,pdf=0,odt=0,portrait=0,
    pagesize=,font=,fontsize=,title_fontincr=,leftmargin=,rightmargin=,topmargin=,bottommargin=);
    %*put ** Starting TABLE_MAKEODT Macro .... **;
    %* called from table2 and uses temp datasets from there, mainly _columnsout and _out **;
    %local __pagewidthin __pageheightin __leftmarginin __rightmarginin
        __topmarginin __bottommarginin __framewidthin __twidthin __fromleft
        __template;

    %if &portrait=1 %then %do;
        %if &pagesize=A4 %then %do;
            %let __pageheightin=11.6902;
            %let __pagewidthin=8.2701;
        %end;
        %else %do;
            %let __pageheightin=11;
            %let __pagewidthin=8.5;
        %end;
        %let __template=portrait;
        %let titl_in_pagehdr=0;
        %let talign=L;
    %end;
    %else %do;
        %if &pagesize=A4 %then %do;
            %let __pageheightin=8.2701;
            %let __pagewidthin=11.6902;
        %end;
        %else %do;
            %let __pageheightin=8.5;
            %let __pagewidthin=11;
        %end;
        %let __template=landscape;
    %end;
    %let __leftmarginin=&leftmargin;
    %let __rightmarginin=&rightmargin;
    %let __topmarginin=&topmargin;
    %let __bottommarginin=&bottommargin;

    %let __framewidthin=%sysevalf(&__pagewidthin - &__leftmarginin -
        &__rightmarginin);
    %let __twidthin=%sysfunc(round(%sysevalf(&__framewidthin *
        &twidpct/100),.001));
    %xbug(TABLE_MAKEODT: ,__pagewidthin __leftmarginin __rightmarginin
        __framewidthin __twidthin) %if &talign=C %then %let
        __fromleft=%sysfunc(round((%sysevalf(&__framewidthin -
        &__twidthin))/2,.001));
    %else %let __fromleft=0;

    data _null_;
        call symput('usertemp',sysget('TEMP'));
    run;
    %if %upcase(&pagesize)=A4 %then %let __odt_templ=odt_templa4;
    %else %let __odt_templ=odt_templ0; ** default page size is US Letter **;
    **filename wzpipe pipe """""c:\program files (x86)\winzip\wzunzip"" -d -o -x*.zip ""&glibroot\report\xml_parts\odt_template\&__odt_templ..zip"" ""&usertemp\&sysjobid\odttemp"" 2>$1""";
    filename wzpipe pipe
        """C:\Progra~1\7-Zip\7z x -bd -aoa -x!*.zip ""&glibroot\report\xml_parts\odt_template\&__odt_templ..zip"" -o""&usertemp\&sysjobid\odttemp"" -r 2>$1""";

    data _wz_results1;
        infile wzpipe length=l;
        input line $varying500. l;
    run;

    filename odtcont "&usertemp\&sysjobid\odttemp\content.xml";
    filename odtsty "&usertemp\&sysjobid\odttemp\styles.xml";

    %macro addstr;
        strout=catx(cr,trim(strout),trim(thisstr));
    %mend addstr;

    %macro prt;
        put strout;
        strout='';
    %mend prt;

    %macro strtitles(alignvar,psty);
        select (&alignvar);
        when('L') if missing(text_l) then text_l=text;
        when('C') if missing(text_c) then text_c=text;
        when('R') if missing(text_r) then text_r=text;
        otherwise if missing(text_l) then text_l=text;
        end;
        if last.row then do;
            /** Landscape Ranges:
            0-132 -> Full
            133-215 -> 1in
            216-260 -> Full
            261-320 -> 1in
            >320 -> Full
             **/
            if missing(text_l) & missing(text_r) then
                pstyle=trim(pstyle)||'_Center';
            if (template='landscape' and (133 le length(textorig) le 215) or
                (261 le length(textorig) le 320) ) or (template='portrait' and
                ^index(pstyle,'Sub') and length(textorig)>80 ) or
                (template='portrait' and index(pstyle,'Sub') and
                length(textorig)>75 ) then pstyle=trim(pstyle)||'Long';
            if scan(text_l,1)='Page' and scan(text_l,3)='of' and
                countw(text_l)=4 then
                text_l="Page <text:page-number text:select-page=""current"">1</text:page-number> of <text:page-count style:num-format=""1"">1</text:page-count>";
            if scan(text_r,1)='Page' and scan(text_r,3)='of' and
                countw(text_r)=4 then
                text_r="Page <text:page-number text:select-page=""current"">1</text:page-number> of <text:page-count style:num-format=""1"">1</text:page-count>";
            if scan(text_c,1)='Page' and scan(text_c,3)='of' and
                countw(text_c)=4 then
                text_c="Page <text:page-number text:select-page=""current"">1</text:page-number> of <text:page-count style:num-format=""1"">1</text:page-count>";
            if text_c ne '' and (text_l^='' or text_r^='') then
                text_c=cats("<text:tab/>",text_c);
            if text_r ne '' then text_r=cats("<text:tab/>",text_r);
            if text_c='' and text_r ne '' then
                text_r=cats("<text:tab/>",text_r);
            thisstr=cats("<text:p text:style-name=""",&psty,""">",text_l,text_c,text_r,"</text:p>");
            text_l='';
            text_c='';
            text_r='';
            %addstr;
        end;
    %mend strtitles;

    %* this finishes out styles.xml *;
    data _odtstyles;
        set _out(where=(panel=1 and rptsect in (1,6))) end=last;
        by panel rptgroup rptsect row col;
        file odtsty mod lrecl=32767 encoding='utf-8';
        length pstyle $30 tnum_fnd lastrow 8 fontsize fontsize1 twidin twidpct
            fromleft frtab fctab trtab tctab 8 cr $4 endsty $14 frame_tabsty
            table_tabsty $400 text_l text_c text_r $2000 thisstr $5000 strout
            $32767;
        retain strout tnum_fnd tsub_fnd lastrow pstyle text_l text_c text_r;
        retain template lmrg rmrg tmrg bmrg pgw pgh fontsize fontsize1 twidin
            twidpct fromleft frtab fctab trtab tctab cr endsty frame_tabsty
            table_tabsty;
        if _n_=1 then do;
            ** need to calculate column width in percent and inches **;
            template="&__template";
            fontsize=&fontsize;
            fontsize1=fontsize+&title_fontincr;
            twidin=&__twidthin;
            twidpct=&twidpct;
            fromleft=&__fromleft;
            frtab=&__framewidthin; ** - 0.0148;
            fctab=round(frtab/2,.0001);
            trtab=twidin; ** - 0.0148;
            tctab=round(trtab/2,.0001);
            lmrg=&__leftmarginin;
            rmrg=&__rightmarginin;
            tmrg=&__topmarginin;
            bmrg=&__bottommarginin;
            pgw=&__pagewidthin;
            pgh=&__pageheightin;
            cr='0A'x;
            endsty='</style:style>';
            frame_tabsty=cat("<style:paragraph-properties text:number-lines=""false"" text:line-number=""0""><style:tab-stops><style:tab-stop style:position=""",fctab,"in"" style:type=""center""/><style:tab-stop style:position=""",
                frtab,"in"" style:type=""right""/></style:tab-stops></style:paragraph-properties>");
            table_tabsty=cat("<style:paragraph-properties text:number-lines=""false"" text:line-number=""0""><style:tab-stops><style:tab-stop style:position=""",tctab,"in"" style:type=""center""/><style:tab-stop style:position=""",
                trtab,"in"" style:type=""right""/></style:tab-stops></style:paragraph-properties>");
        end;

        if _n_=1 then do;
            strout='<!-- Styles specific to this report -->';
            thisstr=cat("<style:default-style style:family=""paragraph""><style:paragraph-properties fo:hyphenation-ladder-count=""no-limit"" style:text-autospace=""ideograph-alpha"" style:punctuation-wrap=""hanging"" ",
                "style:line-break=""strict"" style:tab-stop-distance=""0.4925in"" style:writing-mode=""lr-tb""/>");
            %addstr;
            thisstr=cat("<style:text-properties style:use-window-font-color=""true"" style:font-name=""&font"" fo:font-size=""",fontsize,"pt"" fo:language=""en"" fo:country=""US"" style:font-name-asian=""&font"" ",
                "style:font-size-asian=""",fontsize,"pt"" style:language-asian=""zxx"" style:country-asian=""none"" style:font-name-complex=""&font"" style:font-size-complex=""",fontsize,"pt"" ",
                "style:language-complex=""zxx"" style:country-complex=""none"" fo:hyphenate=""false"" fo:hyphenation-remain-char-count=""2"" fo:hyphenation-push-char-count=""2""/></style:default-style>");
            %addstr;
            %prt
                thisstr=cat("<style:style style:name=""Standard"" style:family=""paragraph"" style:class=""text""><style:paragraph-properties fo:orphans=""0"" ",
                "fo:widows=""0"" fo:hyphenation-ladder-count=""no-limit"" style:text-autospace=""ideograph-alpha"" style:punctuation-wrap=""hanging"" style:line-break=""strict"" style:writing-mode=""lr-tb""/> ",
                "<style:text-properties style:use-window-font-color=""true"" style:font-name=""&font"" fo:font-size=""",fontsize,"pt"" fo:language=""en"" fo:country=""US"" style:letter-kerning=""true"" style:font-name-asian=""&font"" ",
                "style:font-size-asian=""",fontsize,"pt"" style:language-asian=""zxx"" style:country-asian=""none"" style:font-name-complex=""Tahoma2"" style:font-size-complex=""12pt"" style:language-complex=""zxx"" ",
                "style:country-complex=""none"" fo:hyphenate=""false"" fo:hyphenation-remain-char-count=""2"" fo:hyphenation-push-char-count=""2""/>",
                "</style:style>");
            %addstr;
            %prt thisstr="<!-- margin-left should match from left of table -->";
            %addstr;
            %prt
                thisstr=cat("<style:style style:name=""Table_Footer"" style:display-name=""Table Footer"" style:family=""paragraph"" style:parent-style-name=""Caption"">",
                "<style:paragraph-properties fo:margin-left=""1.1272in"" fo:margin-right=""1.1866in"" fo:text-indent=""0in"" style:auto-text-indent=""false""/>",
                "<style:text-properties fo:font-size=""",fontsize,"pt"" style:font-size-asian=""",fontsize,"pt"" style:font-size-complex=""",fontsize,"pt""/>",
                "</style:style>");
            %addstr;
            %prt
                thisstr=cat("<style:style style:name=""Table_Contents_BlockLabel"" style:display-name=""Table Contents Block Label"" style:family=""paragraph"" style:parent-style-name=""Table_Contents_Text"">",
                "<style:text-properties fo:font-size=""",fontsize1,"pt"" style:font-size-asian=""",fontsize1,"pt"" style:font-size-complex=""",fontsize1,"pt"" fo:font-weight=""bold"" style:font-weight-asian=""bold"" style:font-weight-complex=""bold""/>",
                "</style:style>");
            %addstr;
            %prt
                thisstr=cat("<style:style style:name=""PageHeader"" style:family=""paragraph"" style:parent-style-name=""Standard"" style:class=""extra"">",frame_tabsty,"<style:text-properties fo:font-size=""",fontsize1,"pt"" style:font-size-asian=""",
                fontsize1,"pt"" style:font-size-complex=""",fontsize1,"pt""/>",endsty);
            %addstr;
            thisstr=cat("<style:style style:name=""PageHeader_Center"" style:display-name=""PageHeader Center"" style:family=""paragraph"" style:parent-style-name=""Standard"" style:class=""extra"">",frame_tabsty,
                "<style:paragraph-properties fo:margin-left=""0.2in"" fo:margin-right=""0.2in"" fo:text-align=""center"" style:justify-single-word=""false"" fo:text-indent=""0in"" style:auto-text-indent=""false""/>",
                "<style:text-properties fo:font-size=""",fontsize1,"pt"" style:font-size-asian=""",fontsize1,"pt"" style:font-size-complex=""",fontsize1,"pt""/>",endsty);
            %addstr;
            thisstr=cat("<style:style style:name=""PageFooter"" style:family=""paragraph"" style:parent-style-name=""Standard"" style:class=""extra"">",frame_tabsty,"",endsty);
            %addstr;
            %prt
                thisstr=cat("<style:style style:name=""Titles"" style:family=""paragraph"" style:parent-style-name=""PageHeader"" style:class=""extra""><style:paragraph-properties fo:margin-top=""0.0201in"" fo:margin-bottom=""0in"" ",
                "style:justify-single-word=""false""/><style:text-properties fo:font-style=""normal"" style:font-style-asian=""normal"" style:font-style-complex=""normal"" fo:font-size=""",fontsize1,"pt"" style:font-size-asian=""",fontsize1,
                "pt"" style:font-size-complex=""",fontsize1,"pt""/></style:style>",
                "<style:style style:name=""Table_Number"" style:display-name=""Table Number"" style:family=""paragraph"" style:parent-style-name=""Titles""><style:text-properties ",
                "fo:font-style=""normal"" fo:font-weight=""bold"" style:font-style-asian=""normal"" style:font-weight-asian=""bold"" style:font-style-complex=""normal"" style:font-weight-complex=""bold""/></style:style>",
                "<style:style style:name=""Table_Number_Center"" style:display-name=""Table Number Center"" style:family=""paragraph"" style:parent-style-name=""Titles"">",
                "<style:paragraph-properties fo:margin-left=""0.2in"" fo:margin-right=""0.2in"" fo:text-align=""center"" style:justify-single-word=""false"" fo:text-indent=""0in"" style:auto-text-indent=""false""/>",
                "<style:text-properties fo:font-style=""normal"" fo:font-weight=""bold"" style:font-style-asian=""normal"" style:font-weight-asian=""bold"" style:font-style-complex=""normal"" style:font-weight-complex=""bold""/>",
                "</style:style>");
            %addstr;
            %prt
                thisstr=cat("<style:style style:name=""Table_Title"" style:display-name=""Table Title"" style:family=""paragraph"" style:parent-style-name=""Titles""/>",
                "<style:style style:name=""Table_Title_Center"" style:display-name=""Table Title Center"" style:family=""paragraph"" style:parent-style-name=""Titles""><style:paragraph-properties fo:margin-left=""0.2in"" fo:margin-right=""0.2in"" ",
                "fo:text-align=""center"" /></style:style>",
                "<style:style style:name=""Table_Title_CenterLong"" style:display-name=""Table Title CenterLong"" style:family=""paragraph"" style:parent-style-name=""Titles""><style:paragraph-properties fo:margin-left=""1in"" fo:margin-right=""1in"" ",
                "fo:text-align=""center"" /></style:style>");
            %addstr;
            %prt thisstr=cat(
                "<style:style style:name=""Table_Subtitle"" style:display-name=""Table Subtitle"" style:family=""paragraph"" style:parent-style-name=""Titles"" style:master-page-name=""""><style:paragraph-properties ",
                "fo:margin-top=""0.1in"" fo:margin-bottom=""0in""/></style:style>",
                "<style:style style:name=""Table_Subtitle2"" style:display-name=""Table Subtitle2"" style:family=""paragraph"" style:parent-style-name=""Table_Subtitle""><style:paragraph-properties ",
                "fo:margin-top=""0.0402in"" fo:margin-bottom=""0in""/></style:style>",
                "<style:style style:name=""Table_Subtitle_Center"" style:display-name=""Table Subtitle Center"" style:family=""paragraph"" style:parent-style-name=""Titles"" style:master-page-name="""">",
                "<style:paragraph-properties fo:margin-top=""0.1in"" fo:margin-bottom=""0in"" fo:text-align=""center""/></style:style>");
            %addstr;
            %prt thisstr=cat(
                "<style:style style:name=""Table_Subtitle2_Center"" style:display-name=""Table Subtitle2 Center"" style:family=""paragraph"" style:parent-style-name=""Table_Subtitle"">",
                "<style:paragraph-properties fo:margin-top=""0.0402in"" fo:margin-bottom=""0in"" fo:text-align=""center""/></style:style>",
                "<style:style style:name=""Table_Subtitle_CenterLong"" style:display-name=""Table Subtitle CenterLong"" style:family=""paragraph"" style:parent-style-name=""Titles"" style:master-page-name="""">",
                "<style:paragraph-properties fo:margin-top=""0.1in"" fo:margin-bottom=""0in"" fo:margin-left=""1in"" fo:margin-right=""1in"" fo:text-align=""center""/></style:style>",
                "<style:style style:name=""Table_Subtitle2_CenterLong"" style:display-name=""Table Subtitle2 CenterLong"" style:family=""paragraph"" style:parent-style-name=""Table_Subtitle"">",
                "<style:paragraph-properties fo:margin-top=""0.0402in"" fo:margin-bottom=""0in"" fo:margin-left=""1in"" fo:margin-right=""1in"" fo:text-align=""center""/></style:style>");
            %addstr;
            thisstr="</office:styles><office:automatic-styles>";

            %addstr;
            %prt;
            strout=cat("<style:page-layout style:name=""Mpm1""><style:page-layout-properties fo:page-width=""",pgw,"in"" fo:page-height=""",pgh,"in"" style:num-format=""1"" style:print-orientation=""",template,""" fo:margin-top=""",tmrg,"in"" ",
                "fo:margin-bottom=""",bmrg,"in"" fo:margin-left=""",lmrg,"in"" fo:margin-right=""",rmrg,"in"" fo:background-color=""#ffffff"" style:writing-mode=""lr-tb"" style:layout-grid-color=""#c0c0c0"" style:layout-grid-lines=""29"" ",
                "style:layout-grid-base-height=""0.25in"" style:layout-grid-ruby-height=""0in"" style:layout-grid-mode=""none"" style:layout-grid-ruby-below=""false"" style:layout-grid-print=""false"" style:layout-grid-display=""false"" ",
                "style:layout-grid-base-width=""0.1665in"" style:layout-grid-snap-to-characters=""true"" style:footnote-max-height=""0in""><style:background-image/><style:footnote-sep style:width=""0.0071in"" ",
                "style:distance-before-sep=""0.0398in"" style:distance-after-sep=""0.0398in"" style:adjustment=""left"" style:rel-width=""25%"" style:color=""#000000""/></style:page-layout-properties><style:header-style><style:header-footer-properties ",
                "fo:min-height=""0in"" fo:margin-bottom=""0.1965in""/></style:header-style><style:footer-style><style:header-footer-properties fo:min-height=""0in"" fo:margin-top=""0.1965in""/></style:footer-style></style:page-layout>",
                "<style:page-layout style:name=""Mpm2""><style:page-layout-properties fo:page-width=""",pgw,"in"" fo:page-height=""",pgh,"in"" style:num-format=""1"" style:print-orientation=""",template,""" fo:margin-top=""",tmrg,"in"" fo:margin-bottom=""",
                bmrg,"in"" ",
                "fo:margin-left=""",lmrg,"in"" fo:margin-right=""",rmrg,"in"" fo:background-color=""#ffffff"" style:writing-mode=""lr-tb"" style:layout-grid-color=""#c0c0c0"" style:layout-grid-lines=""29"" style:layout-grid-base-height=""0.25in"" ",
                "style:layout-grid-ruby-height=""0in"" style:layout-grid-mode=""none"" style:layout-grid-ruby-below=""false"" style:layout-grid-print=""false"" style:layout-grid-display=""false"" style:layout-grid-base-width=""0.1665in"" ",
                "style:layout-grid-snap-to-characters=""true"" style:footnote-max-height=""0in""><style:background-image/><style:footnote-sep style:width=""0.0071in"" style:distance-before-sep=""0.0398in"" style:distance-after-sep=""0.0398in"" ",
                "style:adjustment=""left"" style:rel-width=""25%"" style:color=""#000000""/></style:page-layout-properties><style:header-style><style:header-footer-properties fo:min-height=""0in"" fo:margin-bottom=""0.1965in""/>",
                "</style:header-style><style:footer-style><style:header-footer-properties fo:min-height=""0in"" fo:margin-top=""0.1965in""/></style:footer-style></style:page-layout></office:automatic-styles><office:master-styles>",
                "<style:master-page style:name=""Standard"" style:page-layout-name=""Mpm1"">");
            put strout;
            strout='';
        end;

        if rptsect=1 and first.rptsect then strout='<style:header>';
        if rptsect=6 and first.rptsect then strout='<style:footer>';

        if rptsect=1 then do;
            if first.row then do;
                pstyle='';
                if textorig='Table #tabnum#' or
                    index(upcase(textorig),'APPENDIX') then do;
                    pstyle='Table_Number';
                    tnum_fnd=1;
                end;
                else do;
                    if tnum_fnd=. then pstyle='PageHeader';
                    else if row gt lastrow+1 then do;
                        if tsub_fnd then pstyle='Table_Subtitle2';
                        else pstyle='Table_Subtitle';
                        tsub_fnd=1;
                    end;
                    else if tnum_fnd then pstyle='Table_Title';
                    else pstyle='PageHeader';
                end;
                if pstyle='' then pstyle='PageHeader';
            end;
        end;
        else if rptsect=6 then pstyle='PageFooter';
        %strtitles(titlalign,pstyle);

        if last.rptsect then do;
            if rptsect=1 then
                thisstr="<text:p text:style-name=""Table_Row_Separator""/></style:header>";
            else if rptsect=6 then thisstr='</style:footer>';
            %addstr;
            %prt;
        end;
        if last then do;
            %prt;
            thisstr=cat("</style:master-page><style:master-page style:name=""First_20_Page"" style:display-name=""First Page"" style:page-layout-name=""Mpm2"" style:next-style-name=""Standard""><style:header>",
                "<text:p text:style-name=""Header""/></style:header><style:footer><text:p text:style-name=""Footer""/></style:footer></style:master-page></office:master-styles></office:document-styles>");
            put thisstr;
        end;
        lastrow=row;
    run;

    %* this finishes out the styles section of content.xml *;
    data _null_;
        set _columnsout(where=(pgnum=1)) end=last;
        by panel;
        file odtcont mod lrecl=32767 encoding='utf-8';
        length frame_tabsty table_tabsty $400 thisstr $2000 strout $32767;
        retain strout;
        ** need to calculate column width in percent and inches **;
        fontsize=&fontsize;
        fontsize1=fontsize+&title_fontincr;
        if cwid<5 and cspc<3 then cwid=cwid+1;
        cwidpct=round((cwid+cspc)/twid*100,.001)*1000;
        cwidin=round(&__twidthin * cwidpct/100000,.001);
        twidin=&__twidthin;
        twidpct=&twidpct;
        fromleft=&__fromleft;
        frtab=&__framewidthin - 0.0148;
        fctab=round(frtab/2,.0001);
        trtab=twidin - 0.0148;
        tctab=round(trtab/2,.0001);
        cr='0A'x;
        endsty='</style:style>';
        frame_tabsty=cat("<style:paragraph-properties text:number-lines=""false"" text:line-number=""0""><style:tab-stops><style:tab-stop style:position=""",fctab,"in"" style:type=""center""/><style:tab-stop style:position=""",
            frtab,"in"" style:type=""right""/></style:tab-stops></style:paragraph-properties>");
        table_tabsty=cat("<style:paragraph-properties text:number-lines=""false"" text:line-number=""0""><style:tab-stops><style:tab-stop style:position=""",tctab,"in"" style:type=""center""/><style:tab-stop style:position=""",
            trtab,"in"" style:type=""right""/></style:tab-stops></style:paragraph-properties>");

        if _n_=1 then do;
            strout='<!-- Styles specific to this report -->';
            thisstr=cat("<style:style style:name=""PageHeader"" style:family=""paragraph"" style:parent-style-name=""Standard"" style:class=""extra"">",frame_tabsty,"<style:text-properties fo:font-size=""",fontsize1,"pt"" ",
                "style:font-size-asian=""",fontsize1,"pt"" style:font-size-complex=""",fontsize1,"pt""/>",endsty);
            %addstr;
            thisstr=cat("<style:style style:name=""PageFooter"" style:family=""paragraph"" style:parent-style-name=""Standard"" style:class=""extra"">",table_tabsty,"",endsty);
            %addstr;
            thisstr=cat("<style:style style:name=""Titles"" style:family=""paragraph"" style:parent-style-name=""PageHeader"" style:class=""extra""><style:paragraph-properties fo:margin-top=""0.0201in"" fo:margin-bottom=""0in"" ",
                "style:justify-single-word=""false""/><style:text-properties fo:font-style=""normal"" style:font-style-asian=""normal"" style:font-style-complex=""normal"" fo:font-size=""",fontsize1,"pt"" style:font-size-asian=""",fontsize1,"pt"" ",
                "style:font-size-complex=""",fontsize1,"pt""/></style:style><style:style style:name=""Table_Number"" style:display-name=""Table Number"" style:family=""paragraph"" style:parent-style-name=""Titles""><style:text-properties ",
                "fo:font-style=""normal"" fo:font-weight=""bold"" style:font-style-asian=""normal"" style:font-weight-asian=""bold"" style:font-style-complex=""normal"" style:font-weight-complex=""bold""/></style:style><style:style ",
                "style:name=""Table_Title"" style:display-name=""Table Title"" style:family=""paragraph"" style:parent-style-name=""Titles""/><style:style style:name=""Table_Subtitle"" style:display-name=""Table Subtitle"" style:family=""paragraph"" ",
                "style:parent-style-name=""Titles"" style:master-page-name=""""><style:paragraph-properties fo:margin-top=""0.1in"" fo:margin-bottom=""0in"" style:page-number=""auto""/></style:style><style:style style:name=""Table_Subtitle2"" ",
                "style:display-name=""Table Subtitle2"" style:family=""paragraph"" style:parent-style-name=""Table_Subtitle""><style:paragraph-properties fo:margin-top=""0.0402in"" fo:margin-bottom=""0in""/></style:style>");
            %prt;
        end;
        if first.panel then do;
            thisstr=cat("<style:style style:name=""TableMain",panel,""" style:family=""table"">");
            %addstr;
            thisstr=cat("<style:table-properties style:width=""",twidin,"in"" style:rel-width=""",twidpct,"%"" fo:margin-left=""",fromleft,"in"" table:align=""left"" style:shadow=""none"" fo:keep-with-next=""auto"" ",
                "style:writing-mode=""lr-tb""/>",cr,endsty);
            %addstr;
        end;

        thisstr=cat("<style:style style:name=""TableMain",panel,".Col",pcol,""" style:family=""table-column"">");
        %addstr;
        thisstr=cat("<style:table-column-properties style:column-width=""",cwidin,"in"" style:rel-column-width=""",cwidpct,"*""/>",cr,endsty);
        %addstr;

        if last then do;
            strout=catx(cr,strout,"</office:automatic-styles>");
            put strout;
        end;
    run;

    %macro pout(psty,var);
        thisstr=cat("<text:p text:style-name=""&psty"">",&var,"</text:p>");
        %addstr;
    %mend pout;

    %macro rowskip;
        thisstr=cat("<table:table-row table:style-name=""TableRow.Separator"">");
        %addstr;
        do j=1 to maxpcol;
            thisstr=cat("<table:table-cell table:style-name=""TableCell.Body"" office:value-type=""string""><text:p text:style-name=""Table_Row_Separator""/></table:table-cell>");
            %addstr;
        end;
        thisstr="</table:table-row>";
        %addstr;
        %prt;
    %mend rowskip;

    data _outodt;
        set _out(where=(1<rptsect<6)) end=last;
        by panel rptgroup rptsect row col;
        file odtcont mod lrecl=32767 encoding='utf-8';
        length colcntr 8 colexpect pcolexpect $2 rowsty cellsty psty $50 thisstr
            $2000 strout $32767;
        retain strout rowsty cellsty psty lastrow colcntr colexpect pcolexpect
            col1indt;

        if _n_=1 then do;
            ** need to calculate column width in percent and inches **;
            fwidin=&__framewidthin;
            twidin=&__twidthin;
            twidpct=&twidpct;
            fromleft=&__fromleft;
            cr='0A'x;

            thisstr=cat("<office:body><office:text><office:forms form:automatic-focus=""false"" form:apply-design-mode=""false""/><text:sequence-decls><text:sequence-decl text:display-outline-level=""0"" text:name=""Illustration""/>",
                "<text:sequence-decl text:display-outline-level=""0"" text:name=""Table""/><text:sequence-decl text:display-outline-level=""0"" text:name=""Text""/><text:sequence-decl text:display-outline-level=""0"" text:name=""Drawing""/>",
                "</text:sequence-decls>");
            %addstr;
            %prt;
        end;

        if first.panel then do; **start new table**;
            if panel>1 then do;
                thisstr="<text:p text:style-name=""Table_Page_Separator""/>";
                %addstr;
            end;
            /*else thisstr="<text:p text:style-name=""Table_Row_Separator""/>";*/
            thisstr=cats("<!-- Begin Table --><table:table table:name=""TableMain",panel,""" table:style-name=""TableMain",panel,""">");
            %addstr;
            do i=1 to maxpcol;
                thisstr=cats("<table:table-column table:style-name=""TableMain",panel,".Col",i,"""/>");
                %addstr;
            end;
            %prt;
            thisstr="<table:table-header-rows>";
            %addstr;
        end;
        if first.rptsect then lastrow=0;
        /*else if row=pgbk then lastrow=lastrow+1;*/
        **TEMP FIX FOR ROW NUM FORCED PAGEBREAKS, NOT SUPPORTED SO WE BRING THEM UP UNDER PREVIOUS ROWS**;
        ** conditions for row separator style;
        if rptsect in (1.5,4.5) then rowsty="TableRow.Separator";
        else rowsty="TableRow.KeepTogether";

        ** set cell style;
        if first.row then col1indt=indt;
        if rptsect in (2,2.5,3,4) then cellsty="TableCell.Header";
        else if rptsect=5 and col1indt<1 then cellsty="TableCell.Body";
        else if rptsect=5 then cellsty="TableCell.BodyTight";
        if scan(text,-1,'~')="#LINE#" then
            cellsty=cats(cellsty,".BottomBorder");
        else if index(text,'#LINE#') then
            _errtxt=cat('Warning: #LINE# specified on panel ',trim(panel),' row ',trim(row),' within text - only valid location is at the end of the text.');
        text=prxchange('s/(~)?#LINE#//', -1, text);

        ** set paragraph style;
        if rptsect in (2,2.5,3,4,5) then do;
            select (algn);
                when('L') psty='Table_Contents_Text';
                when('C') psty='Table_Contents_CenterAlign';
                when('R') psty='Table_Contents_RightAlign';
                otherwise psty='Table_Contents';
            end;
        end;
        else psty="Table_Contents";
        if newpage then psty=cats(psty,".NewPage");
        else do;
            if indt>0 and cellindent then
                psty='Table_Contents_Text'||left(indt);
            if keepnext then psty=cats(psty,".KeepNext");
        end;
        ** row skipped;
        if first.row and lastrow ^in (.,0) and row-lastrow>1 then do i=1 to
            (round(row)-lastrow-1);
            %rowskip;
        end;

        if first.row then do;
            thisstr=cats("<table:table-row table:style-name=""",rowsty,""">");
            %addstr;
            colcntr=1;
        end;
        if first.col then do;
            colexpect=scan(pancols,colcntr);
            pcolexpect=colcntr;
        end;

        ** topline/headline;
        if rptsect=1.5 then do;
            do i=1 to maxpcol;
                thisstr=cats("<table:table-cell table:style-name=""TableCell.Header.TopBorder"" office:value-type=""string""><text:p text:style-name=""Table_Row_Separator""/></table:table-cell>");
                %addstr;
            end;
        end;
        else if rptsect=4.5 then do;
            do i=1 to maxpcol;
                thisstr=cats("<table:table-cell table:style-name=""TableCell.Headline"" office:value-type=""string""><text:p text:style-name=""Table_Row_Separator""/></table:table-cell>");
                %addstr;
            end;
        end;
        else do;
            nspancols=0;
            j=0;
            **fill in skipped columns;
            if pcol ne pcolexpect then do i=pcolexpect to pcol-1;
                j=j+1;
                if rptsect ^in (2,2.5,3) then do;
                    thisstr=cat("<table:table-cell table:style-name=""",trim(cellsty),""" office:value-type=""string""><text:p text:style-name=""",trim(psty),"""/></table:table-cell>");
                    %addstr;
                end;
                else do;
                    thisstr=cat("<table:table-cell table:style-name=""TableCell.BodyTight"" office:value-type=""string""><text:p text:style-name=""",trim(psty),"""/></table:table-cell>");
                    %addstr;
                end;
            end;
            colcntr=colcntr+j;
            **detect spanned columns and handle;
            if col ne col2 then do;
                nspancols=col2 - (col-pcol) - pcol + 1;
                spancell=cat("table:number-columns-spanned=""",nspancols,"""");
            end;
            else spancell='';
            ***This puts out the current cell***;
            thisstr=cat("<table:table-cell table:style-name=""",trim(cellsty),""" ",trim(spancell)," office:value-type=""string"">");
            %addstr;
            ***Splits wrapping, convert "  " to tabs***;
            do i=1 to countw(text,'~');
                thisstr=trim(scan(text,i,'~'));
                _nspcr=0;
                do while (length(thisstr)>2 & substr(thisstr,1,2)='  ');
                    _nspcr=_nspcr+1;
                    thisstr=substr(thisstr,3);
                end;
                if _nspcr>0 then
                    thisstr=repeat('<text:tab/>',_nspcr-1)||thisstr;
                thisstr=cats("<text:p text:style-name=""",psty,""">",thisstr,"</text:p>");
                %addstr;
            end;
            thisstr="</table:table-cell>";
            %addstr;
            **fill in for spanned columns;
            do i=1 to nspancols-1;
                thisstr="<table:covered-table-cell/>";
                %addstr;
                colcntr=colcntr+1;
            end;
            %prt;
        end;

        if last.row then do;
            if colcntr<maxpcol and pcol ne . then do i=colcntr+1 to maxpcol;
                thisstr=cat("<table:table-cell table:style-name=""TableCell.BodyTight"" office:value-type=""string""><text:p text:style-name=""Table_Contents""/></table:table-cell>");
                %addstr;
            end;
            /*      if last.rptgroup and rptgroup=1 and &__headline then strout=prxchange('s/TableCell.Header/TableCell.Header.BottomBorder/', -1, strout);  */
            thisstr="</table:table-row>";
            %addstr;
            %prt;
        end;
        if last.rptgroup and rptgroup=1 then do;
            /*      %rowskip; */
            thisstr="</table:table-header-rows>";
            %addstr;
            %prt;
        end;
        if last.panel then do;
            **closing spacer row with bottomborder;
            thisstr=cat("<table:table-row table:style-name=""TableRow.KeepTogether"">");
            %addstr;
            do i=1 to maxpcol;
                thisstr=cat("<table:table-cell table:style-name=""TableCell.Body.BottomBorder"" office:value-type=""string""><text:p text:style-name=""Table_Row_Separator""/></table:table-cell>");
                %addstr;
            end;
            thisstr="</table:table-row>";
            %addstr;
            %prt;
            thisstr="</table:table>";
            %addstr;
            %prt;
        end;

        if last then do;
            %prt;
            thisstr="<text:p text:style-name=""Last_Paragraph""/></office:text></office:body></office:document-content>";
            %addstr;
            %prt;
        end;
        output;
        if last.row then lastrow=row;
        if last.col then colcntr=colcntr+1;
    run;

    **filename wzpipe pipe """""c:\program files (x86)\winzip\wzzip"" -e0 -p &usertemp\&sysjobid\odttemp.odt ""&usertemp\&sysjobid\odttemp\mimetype"" 2>&1""";
    filename wzpipe pipe
        """c:\bsp_apps\7za\7za a -mx0 &usertemp\&sysjobid\odttemp.odt ""&usertemp\&sysjobid\odttemp\mimetype"" 2>&1""";

    data _pipe_wz_results1;
        infile wzpipe length=l;
        input line $varying500. l;
    run;
    **filename wzpipe pipe """""c:\program files (x86)\winzip\wzzip"" -r -p -x""&usertemp\&sysjobid\odttemp\mimetype"" &usertemp\&sysjobid\odttemp.odt ""&usertemp\&sysjobid\odttemp"" 2>&1""";
    filename wzpipe pipe
        """c:\bsp_apps\7za\7za a &usertemp\&sysjobid\odttemp.odt ""&usertemp\&sysjobid\odttemp\*"" -xr!""&usertemp\&sysjobid\odttemp\mimetype"" 2>&1""";

    data _pipe_wz_results2;
        infile wzpipe length=l;
        input line $varying500. l;
    run;
    %xnotes(1) %put NOTE: Master OpenOffice ODT output file generated, now
        converting to Word.;
    %if &_debug_=0 %then %do;
        %xnotes(0);
    %end;
    ** with NEWPAGE, all output has to go through Word format first (only one that honors pagebreak within a table) **;
    filename wzpipe pipe
        """""c:\Program Files\libreoffice\program\python"" &GLIBROOT\report\api\unoconv.py -f docx7 ""&usertemp\&sysjobid\odttemp.odt"" """;

    data _pipe_py_results_word;
        infile wzpipe length=l;
        input line $varying500. l;
    run;

    %if %sysfunc(fileexist(&usertemp\&sysjobid\odttemp.docx)) %then %do;
        %if &word %then %do;
            %xnotes(1) %put NOTE: Copying Word table to output file with .docx
                extension;
            %if &_debug_=0 %then %do;
                %xnotes(0);
            %end;
            filename wzpipe pipe
                "copy ""&usertemp\&sysjobid\odttemp.docx"" ""&outfile..docx"" ";

            data _pipe_wz_move_results_word;
                infile wzpipe length=l;
                input line $varying500. l;
            run;
        %end;
        %if &pdf %then %do;
            %xnotes(1) %put NOTE: Converting Word table to PDF and adding
                bookmarks if requested.;
            %if &_debug_=0 %then %do;
                %xnotes(0);
            %end;
            filename wzpipe pipe
                "c:\bsp_apps\oo\OfficeToPDF.exe /print ""&usertemp\&sysjobid\odttemp.docx"" ""&usertemp\&sysjobid\odttemp.pdf"" ";

            **  filename wzpipe pipe "python c:\bsp_apps\oo\unoconv.py -f pdf -p 8100 ""&usertemp\&sysjobid\odttemp.odt"" ";
            data _pipe_py_results_pdf;
                infile wzpipe length=l;
                input line $varying500. l;
            run;
            %if &bookmarks %then %do;
                data _null_;
                    file "&usertemp\&sysjobid\odttemp.txt" lrecl=2000;
                    set _odtstyles(where=(rptsect=1 and tnum_fnd and
                        (index(pstyle,'Table_Number') or
                        index(pstyle,'Table_Title') or
                        index(pstyle,'Table_Subtitle')))) end=last;
                    length _strout $2000;
                    retain tcnt 0 _strout;
                    if index(pstyle,'Table_Number') then
                        _strout=trim(left(text));
                    else do;
                        tcnt=tcnt+1;
                        if tcnt=1 and text ne '' then
                            _strout=trim(_strout)||": "||left(trim(text));
                        if tcnt=2 and text ne '' then
                            _strout=trim(_strout)||" - "||left(trim(text));
                        if tcnt=3 and text ne '' then
                            _strout=trim(_strout)||" ("||left(trim(text))||")";
                        if tcnt=4 and text ne '' then
                            _strout=trim(_strout)||" ["||left(trim(text))||"]";
                    end;
                    if last then do;
                        put "BookmarkBegin";
                        put "BookmarkTitle: " _strout;
                        put "BookmarkLevel: 1";
                        put "BookmarkPageNumber: 1";
                    end;
                run;
                filename wzpipe pipe
                    "pdftk ""&usertemp\&sysjobid\odttemp.pdf"" update_info ""&usertemp\&sysjobid\odttemp.txt"" output ""&usertemp\&sysjobid\odttemp_bm.pdf"" ";

                data _pipe_pdfbm_results;
                    infile wzpipe length=l;
                    input line $varying500. l;
                run;
                filename wzpipe pipe
                    "c:\bsp_apps\BeCyPDFMetaEdit\BeCyPDFMetaEdit ""&usertemp\&sysjobid\odttemp_bm.pdf"" -PM 2 -r";

                data _pipe_pdfpm_results;
                    infile wzpipe length=l;
                    input line $varying500. l;
                run;
                filename wzpipe pipe
                    "c:\bsp_apps\qpdf-6.0.0\bin\qpdf -linearize ""&usertemp\&sysjobid\odttemp_bm.pdf"" ""&outfile..pdf"" ";

                data _pipe_pdflin_results;
                    infile wzpipe length=l;
                    input line $varying500. l;
                run;
            %end;
            %else %do;
                filename wzpipe pipe
                    "c:\bsp_apps\qpdf-6.0.0\bin\qpdf -linearize ""&usertemp\&sysjobid\odttemp.pdf"" ""&outfile..pdf"" ";

                data _pipe_pdflin_results;
                    infile wzpipe length=l;
                    input line $varying500. l;
                run;
            %end;
            %xnotes(1) %put NOTE: Copying PDF table to output file with .pdf
                extension;
            %if &_debug_=0 %then %do;
                %xnotes(0);
            %end;
        %end;
    %end;
    %else %do;
        %xnotes(1) %put ERROR: Conversion to Word failed, if PDF was requested
            then it was skipped.;
        %if &_debug_=0 %then %do;
            %xnotes(0);
        %end;
    %end;
    %if &odt %then %do;
        %xnotes(1) %put NOTE: Copying ODT table to output file with .odt
            extension;
        %if &_debug_=0 %then %do;
            %xnotes(0);
        %end;
        filename wzpipe pipe
            "move ""&usertemp\&sysjobid\odttemp.odt"" ""&outfile..odt"" ";

        data _pipe_move_results_odt;
            infile wzpipe length=l;
            input line $varying500. l;
        run;
    %end;
    %if ^&_debug_ %then %do;
        filename clnpipe pipe "del ""&usertemp\&sysjobid\odttemp*.*""";

        data _pipe_cln_results;
            infile clnpipe length=l;
            input line $varying500. l;
        run;
        filename clnpipe pipe "rmdir /S /Q ""&usertemp\&sysjobid\odttemp""";

        data _pipe_cln_results;
            infile clnpipe length=l;
            input line $varying500. l;
        run;

        proc datasets lib=work nodetails nolist;
            delete _pipe: _outodt _odtstyles;
        quit;
    %end;
    %xnotes(1) %put NOTE: MAKEODT macro completed.;
    %if &_debug_=0 %then %do;
        %xnotes(0);
    %end;
%mend makeodt;
