************************************************************************************;
* PROGRAM:     P:\Rhythm\RM-493-026\Biostats\CSR\Create\SDTMpgms\chkheader.sas
* DATE:        09MAY2018
* PROGRAMMER:  N PATEL
*
* PURPOSE:     Check Program header to make sure correct path and program name were mentioned in each program.
*
************************************************************************************;
* MODIFICATIONS:  
*   PROGRAMMER:   
*   DATE:         
*   PURPOSE:
************************************************************************************;

proc datasets memtype=data kill nolist;
run;
OPTION MPRINT MLOGIC SYMBOLGEN;
filename lstpgms pipe "dir";
data _null_;
	length path $500;
	infile lstpgms dsd firstobs=4 obs=4;
	input path $;
	call symput("path",strip(substr(path,14))||'\');
	call symput("path1",compress(scan(path,-2,'\')));
	call symput("path2",compress(scan(path,-1,'\')));
run;

%put &path;
%put &path1;
%put &path2;

%global pgm dtl;

%macro outfile;

data _null_;

%if %upcase("&path1")="CREATE" and %upcase("&path2")="ADSPGMS" %then %do; %let pgm=d-header; %let dtl=d; %end;
%else %if %upcase("&path1")="CREATE" and %upcase("&path2")="SDTMPGMS" %then %do; %let pgm=s-header; %let dtl=s; %end;
%else %if %upcase("&path1")="CREATE" and %upcase("&path2")="RAWPGMS" %then %do; %let pgm=c-header; %let dtl=c; %end;
%else %if %upcase("&path1")="QC" and %upcase("&path2")="ADS" %then %do; %let pgm=qd-header; %let dtl=qd; %end;
%else %if %upcase("&path1")="QC" and %upcase("&path2")="SDTM" %then %do; %let pgm=qs-header; %let dtl=qs; %end;
%else %if %upcase("&path1")="QC" and %upcase("&path2")="RAW" %then %do; %let pgm=qc-header; %let dtl=qc; %end;
%else %if %upcase("&path1")="QC" and %upcase("&path2")="TABLES" %then %do; %let pgm=qt-header; %let dtl=qt; %end;
%else %if %upcase("&path1")="QC" and %upcase("&path2")="LISTINGS" %then %do; %let pgm=ql-header; %let dtl=ql; %end;
%else %if %upcase("&path1")="QC" and %upcase("&path2")="FIGURES" %then %do; %let pgm=qf-header; %let dtl=qf; %end;

%else %if %upcase("&path1")^="QC" and %upcase("&path2")="TABLES" %then %do; %let pgm=t-header; %let dtl=t; %end;
%else %if %upcase("&path1")^="QC" and %upcase("&path2")="LISTINGS" %then %do; %let pgm=l-header; %let dtl=l; %end;
%else %if %upcase("&path1")^="QC" and %upcase("&path2")="FIGURES" %then %do; %let pgm=f-header; %let dtl=f; %end;

run;

%mend outfile;

%outfile;
%put &path1, &path2, &pgm, &dtl;

options sysprintfont = 'Courier New' 8 leftmargin = '1in' rightmargin = '1in' topmargin = '1.5in' orientation = landscape;


filename emfs pipe "dir /B &dtl.*.sas | sort";

data files;
    infile emfs;
    input emfname :$200.;
run;

filename files "&path";

data t_null_ ;

    set files end = eof;

    length path path2 $ 1000;

    path = cats("&path", emfname);
    path2 = cats("&path", emfname);
    array text [15] $ 150 line1 - line15;
    start = 1;
    stop = length(emfname);

    retain re;

    if _n_ = 1 then do;
        re = prxparse('/\d{1,}/');
    end;

    array nums[*] n1 - n11;

     call prxnext(re, start, stop, emfname, position, length);
      do i = 1 to 11 while (position > 0);
         found = substr(emfname, position, length);
         put found= position= length=;
         nums[i] = input(found, 8.);

         call prxnext(re, start, stop, emfname, position, length);
      end;


    call missing(of Text[*]);

    infile myfile filevar = path   missover pad end = eof;

    *__emfname = "{{\field{\*\fldinst{HYPERLINK "||'"'||'file:./'||left(trim(emfname))||'"'||"}}{\fldrslt{\ul\cf2 "||left(trim(emfname))||"}}}";

    retain text;

    do i = 1 to 15;
        input  @1  line  $char1000. ;
        *text[i] = tranwrd(left(tranwrd(line, '\par', '')), '\_', '-');
		  text[i] = left(tranwrd(line, '\par', ''));*, '\_', '-');
    end;
    OUTPUT;
run;


data chk ;

    set files end = eof;
	if _n_=1;
    length path path2 $ 1000;

    path = cats("&path", emfname);
    path2 = cats("&path", emfname);

	infile myfile filevar = path ;*  missover pad end = eof;
	
    array text [*] $ 256 line1 - line100;
	
    call missing(of Text[*]);
    retain text;
	
    do i = 1 to 100;
        input  @1  line  $char1000. ;
        *text[i] = tranwrd(left(tranwrd(line, '\par', '')), '\_', '-');
		  text[i] = left(tranwrd(line, '\par', ''));*, '\_', '-');
    end;
    OUTPUT;
run;

proc sort data = t_null_ out = t_null_;
    by n1 - n10;
run;

data final(keep=emfname p names);
	set t_null_;
	array all[15] line1-line15;
	
	do p=1 to 15;
		names=all[p];
	output;
	end;
run;

data final;
	set final;
	if upcase(substr(names,1,11))='* PROGRAM: ';
	names=upcase(names);
	len=length(names);
	len2=length("*PROGRAM: ");
	pos=findw(upcase(names),"PROGRAM");
	posi=strip(substr(names,len2+2,len));	
	PPATH=strip("&path")||strip(emfname);
	
	IF UPCASE(PPATH)^=UPCASE(posi);***CHECK IF CORRECT DIRECTORY OR PROGRAM NAME;
run;

***CHECK IF FINAL DATASET IS EMPTY;
proc sql noprint;
		select count(*) into: numm
		from FINAL;
quit;


data sasname;
	length sasname $ 200;
	infile emfs;
	input sasname $ ;
	sasname = substr(sasname,1,length(sasname)-4);
run;

data _null_;
	set sasname end=eof;
	if eof then call symput('nsas',put(_n_,3.-l));
run;

%macro allchk;
	%do f = 1 %to &nsas;
		data _null_ ;
			set sasname;
			if _n_ = &f then call symput('sasnm',trim(left(sasname)));
		run;

		
		FILENAME SASINPUT "%lowcase(&sasnm).sas";

		DATA TEMP;
			LENGTH FILE $60 FINDTYPE $500;
			INFILE SASINPUT LENGTH=LENLINE END=EOF IGNOREDOSEOF;
			INPUT @1 LINE $VARYING300. LENLINE @;
			FILE = "&sasnm";
			linenm=_n_;
			if linenm > 10 then do;
				if index(upcase(line),'P:\')> 0 then do; _find=1; findtype="Use of P drive Physical Location"; end;
				if index(upcase(line),'LIBNAME')>0 then do; 
						_find=1; 
						if findtype^=' ' then findtype=strip(findtype)||', Use of Library Name';
						else findtype="Use of Library Name"; 
				end;
				/*if (index(upcase(line),'%INCLUDE')>0 and index(upcase(line),'M-SETUP')=0) then do;
						_find=1; 
						if findtype^=' ' then findtype=strip(findtype)||', Use of % include';
						else findtype='Use of % include'; 
				end;*/
			end;

			if (index(upcase(line),".XLS") > 0 and index(upcase(file),'TRIAL')=0) or index(upcase(line),".CSV") > 0 or index(upcase(line),".TXT") > 0 then do;
				_find=1; 
				if findtype^=' ' then findtype=strip(findtype)||', Conversion of non-SAS files';
				else findtype='Conversion of non-SAS files'; 
			end;

			if _find=1;
		RUN;
		
		proc append base=alltemp data=temp;
		run;

		DATA TEMP;
		  SET TEMP (OBS=0);
		RUN;
	%end;
%mend allchk;

%allchk;

proc sql noprint;
		select count(*) into: ntemp
		from ALLTEMP;
quit;

title;
footnote;
options nodate nonumber ;

%MACRO PRINTIT;
%if &NUMM^=0 %then %do;

title2 "HEADER CHECK LOCATION: &path.";
proc report data=final nowindows headskip headline missing split = '~' spacing=2;

  columns emfname names;

 define  emfname      /  order  width=30   'Program Name'         flow style(column)= [cellwidth = 20%];
 define  names        /         width=90   'Program Header Path'  flow style(column)= [cellwidth = 70%];


break after emfname /skip; 
run;
%end;

%else  %do;

title2 "HEADER CHECK LOCATION: &path.";
data empty;
		justline=1;
		site=' ';
		output;
		stop;
	run;

	proc report data=empty headskip nowindows missing;
		column  justline ;

		define justline /order noprint;
	   	*define site     /order  ' ' ;

	    compute after justline;
			line @1 "";
			line @1 "";
	    	line @1  "--------------------------------------------------------------";
			line @1  "    All programs headings have correct path    ";
			line @1  "--------------------------------------------------------------";
	    endcomp;
run;
%end;



%if &NTEMP^=0 %then %do;

title2 "PROGRAM CHECK LOCATION: &path.";
proc report data=alltemp nowindows headskip headline missing split = '~' spacing=2;

  columns file findtype line linenm;

 define  file      /  order  width=30   'Program Name'         flow style(column)= [cellwidth = 10%];
 define  findtype      /  order  width=30   'Finding'         flow style(column)= [cellwidth = 20%];
 define  line        /         width=90   'Line Description'  flow style(column)= [cellwidth = 60%];
 define  linenm        /         width=90   'Line Number'  style(column)= [cellwidth = 8%];


compute after file; 
        line '';
    endcomp;

run;
%end;

%else  %do;

title2 "PROGRAM CHECK LOCATION: &path.";
data empty;
		justline=1;
		site=' ';
		output;
		stop;
	run;

	proc report data=empty headskip nowindows missing;
		column  justline ;

		define justline /order noprint;
	   	*define site     /order  ' ' ;

	    compute after justline;
			line @1 "";
			line @1 "";
	    	line @1  "--------------------------------------------------------------";
			line @1  "                    All programs are GOOD                     ";
			line @1  "--------------------------------------------------------------";
	    endcomp;
run;
%end;





%mend;

ods pdf  file = "&path.&pgm..pdf";
%printit;

ods pdf close;


