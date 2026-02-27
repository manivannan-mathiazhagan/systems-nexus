/*****************************************************************************
*Project Name/No.:		Global macro library 
*Purpose: 			      Sets environment variables based on &ENV (set in autoexec.sas)
*Original Author (Date) Kyle McBride (02DEC2003)
*Included Macros/Files:
*Input Data:			
*Output Reports/Data:	
*Program Instructions:	Sponsor=(root folder name for Sponsor)
                        Study=(root folder name for study) 
                        PGMLOC=U[default] for user folders, S for shared folders (optional)
                        DATALOC=U for user folders, S[default] for shared folders (optional)
                        OUTLOC=U for user folders, S[default] for shared folders (optional)
*****************************************************************************/
**%macro setenv(drug=,study=,_pgmloc=U,_dataloc=S,_outloc=S,dbver=current,subset=,clrenv=1);
%macro setenv(sponsor=,partner=,drug=,ind=,study=,_pgmloc=S,_dataloc=S,_outloc=S,dbver=,subset=,clrenv=1,sharedenv=USER,init_suffix=,
	            pgmtype=,dbver2=,deliver=,deliverdt=,unblinded=0)/ /*store*/;
%global PROOT DROOT UDROOT OROOT GDOCROOT SPROOT ENV GLIBROOT USERHOME USERNAME PGMSUFFIX VERSION;
%global ls ps title1 title2 skip leftmar rightmar bottom line119 line133 line159;
%global ntrtcols pgmloc outloc outdest db popsrc extpop dbsub dbpath totpage totpages tnumloc lnumloc tnumlocused lnumlocused
        allinone lastone bookmarks pdftoc cutdt tnumprefix tnumsuffix lnumprefix lnumsuffix tnum allout
        gfont gfontsize gpagesize gtitle_fontincr gleftmargin grightmargin gtopmargin gbottommargin gforce
        unfuddle unfuddle_projectid unfuddle_notebookid 
        googledoc googledoc_key hts cfns
        _lastrow _lastrow1 _lastrow2 _lastrow3 _lastrow4
        rptout rptlog runmode /* deprecated */
        outver listver tabver figver logver valver tdataver soutver pgmpath outpath soutpath savelog savetdata delivernm;
%if %length(&sponsor) & %length(&partner) %then %let sponsor=&partner\&sponsor; 
%else %if %length(&partner) %then %let sponsor=&partner;
%let PGMSUFFIX=&init_suffix;
%let delivernm=&deliver;
%if ^%index(%upcase(&deliver),%str(DEVELOPMENT)) & %index(%upcase(&pgmtype),%str(SHELLS)) %then %do;
	%put NOTE: SETENV parameter DELIVER must be Development TLFs when PGMTYPE contains SHELLS. DELIVER value will be set to Development TLFs.;
	%let deliver=Development TLFs;
%end;
%if %index(%upcase(&deliver),%str(DEVELOPMENT)) & %length(&deliverdt) %then %do;
	%put NOTE: SETENV parameter DELIVERDT specified but does not apply to Development. DELIVERDT value will not be used.;
	%let deliverdt=;
%end;

%let soutpath=;
%if &unblinded & %index(%upcase(&deliver),OUTPUT) %then %let outfolder=Unblinded;
%if &unblinded %then %let outfolder=Unblinded\Output;
%else %let outfolder=Output;

data _null_;
call symput('userhome',sysget('USERPROFILE'));
call symput('username',sysget('USERNAME'));
run;
*libname mystore "e:\users\&username\LocalDev\Instat\GLIB\macros";
*options MSTORED SASMSTORE=mystore;
/* options nomprint; */
%put Clearing out current session...;
%if &clrenv %then %do;
%clrenv;
%end;
%put Finished clearing session.;
%put;
%let ENV=&sharedenv;
%put Environment = &env;
%if %length(&drug) %then %let drug=\&drug;
%if %length(&ind) %then %let ind=\&ind;

%let USERROOTW=P:\BSP_LocalDev\&old_username.\LocalDev;
%let DEVROOTW=P:\LegacyInstat_Projects;
/**GDrive not supported yet, waiting on CloudMapper**
%if %sysfunc(fileexist("G:\My Drive\Projects\")) %then %let GDRIVEROOTW=g:\My Drive\Projects;
%else %if %sysfunc(fileexist("H:\My Drive\Projects\")) %then %let GDRIVEROOTW=h:\My Drive\Projects;
%else %if %sysfunc(fileexist("S:\My Drive\Projects\")) %then %let GDRIVEROOTW=s:\My Drive\Projects;
%else **/ 
%let GDRIVEROOTW=;
%let SHAREPTROOTW=f:\Projects;
/** drug and protocol should equal the same names used on directories in the CDS **
    env accepted values are DEV, PRD                                             **/
    %put -------------------------------------------------------------;
    %put Begin setting environment.;
	    %if &SYSSCP=WIN %then %do;
          %put WINDOWS platform detected.;
    	    %let ROOTWIN = &&&ENV.ROOTW.;
    	    %if &ENV=DEV | &ENV=USER %then %do;
    	    	%put Checking shared folder structure:  exist &DEVROOTW.\&sponsor\Projects&drug.&ind.\&study ? ...;
    	    	%if %sysfunc(fileexist("&DEVROOTW.\&sponsor\Projects&drug.&ind.\&study")) %then %do;
    	    	  %put ...yes, proceeding with old structure with extra \Projects in path.;
    	    		%let DLOC=\Projects;
    	    		%let OLOC=\Projects;
    	    	%end;
    	    	%else %do;
    	    	  %put ...no, proceeding with new structure without the extra \Projects in path.;
    	    		%let DLOC=;
    	    		%let OLOC=;
    	    	%end;
    	    	%if %sysfunc(fileexist("&USERROOTW.\&sponsor\Projects&drug.&ind.\&study")) %then %let PLOC=\Projects;
    	    	%else %let PLOC=;
      	    %if %sysfunc(fileexist("&ROOTWIN.\&sponsor.&ploc.&drug.&ind.\&study.\init.sas")) %then %let pgmfold=;
      	    %else %let pgmfold=\programs;
       	    %let PROOT = &ROOTWIN.\&sponsor.&ploc.&drug.&ind.\&study.&pgmfold.;
       	    %if &unblinded %then
       	    %let UDROOT = &DEVROOTW.\&sponsor.&dloc.&drug.&ind.\&study.\unblinded\sasdata;
       	    %else
       	    %let UDROOT = ;
       	    %let DROOT = &DEVROOTW.\&sponsor.&dloc.&drug.&ind.\&study.\sasdata;
       	    %let OROOT = &DEVROOTW.\&sponsor.&oloc.&drug.&ind.\&study.\&outfolder\&deliver;
       	    %if %length(&GDRIVEROOTW) %then %let GDOCROOT = &GDRIVEROOTW.\&sponsor.&dloc.&drug.&ind.\&study.\docs; %else %let GDOCROOT=;
            %let SPROOT = &SHAREPTROOTW.\&sponsor.&dloc.&drug.&ind.\&study.;
            %let GLIBROOT = &ROOTWIN.\instat\glib\macros;
    	    %end;
/*    	    %else %if &ENV=USER %then %do;
       	    %if %upcase(&_pgmloc)=U %then %let PLOC=\Projects;
       	    %else %let PLOC=\Projects;
       	    %if %upcase(&_dataloc)=U %then %let DLOC=\Projects;
       	    %else %let DLOC=\Projects;
       	    %if %upcase(&_outloc)=U %then %let OLOC=\Projects;
       	    %else %let OLOC=\Projects;
       	    %put NOTE: Checking for location of init.sas at &ROOTWIN.\&sponsor.&ploc.&drug.&ind.\&study.\init.sas;
      	    %if %sysfunc(fileexist("&ROOTWIN.\&sponsor.&ploc.&drug.&ind.\&study.\init.sas")) %then %let pgmfold=;
      	    %else %let pgmfold=\programs;
       	    %let PROOT = &ROOTWIN.\&sponsor.&ploc.&drug.&ind.\&study.&pgmfold.;
       	    %let DROOT = &DEVROOTW.\&sponsor.&dloc.&drug.&ind.\&study.\sasdata;
       	    %let OROOT = &DEVROOTW.\&sponsor.&oloc.&drug.&ind.\&study.\&outfolder;
            %let GLIBROOT = &USERROOTW.\instat\glib\macros;
    	    %end;
    	    %else %if &ENV=CLOUD %then %do;
       	    %if %upcase(&_pgmloc)=U %then %let PLOC=\Projects;
       	    %else %let PLOC=\Projects;
       	    %if %upcase(&_dataloc)=U %then %let DLOC=;
       	    %else %let DLOC=;
       	    %if %upcase(&_outloc)=U %then %let OLOC=;
       	    %else %let OLOC=;
      	    %if %sysfunc(fileexist("&ROOTWIN.\&sponsor.&ploc.&drug.&ind.\&study.\init.sas")) %then %let pgmfold=\programs;
      	    %else %let pgmfold=\programs;
       	    %let PROOT = &USERROOTW.\&sponsor.&ploc.&drug.&ind.\&study.&pgmfold.;
       	    %let DROOT = &ROOTWIN.\&sponsor.&dloc.&drug.&ind.\&study.\sasdata;
       	    %let OROOT = &ROOTWIN.\&sponsor.&oloc.&drug.&ind.\&study.\&outfolder;
            %let GLIBROOT = &USERROOTW.\instat\glib\macros;
    	    %end;
*/

    	      %if &SysProd=WPS %then %do;
      	    	options sasautos = ("&PROOT.\macros" "&GLIBROOT." "&GLIBROOT.\wps2r" 
      	    	"&GLIBROOT.\mproc"  "&GLIBROOT.\report"  "&GLIBROOT.\util" "&GLIBROOT.\cdisc" 
      	    	"&GLIBROOT.\stat"  "&GLIBROOT.\celgene" "!SASROOT\core\sasmacro" 
      	    	"!SASROOT\aacomp\sasmacro" "!SASROOT\accelmva\sasmacro" "!SASROOT\dmscore\sasmacro" 
      	    	"!SASROOT\graph\sasmacro" "!SASROOT\stat\sasmacro");
      	    %end;
      	    %else %do;
      	    	options sasautos = ("&PROOT.\macros","&GLIBROOT.","&GLIBROOT.\wps2r",
      	    	"&GLIBROOT.\mproc", "&GLIBROOT.\report", "&GLIBROOT.\util", "&GLIBROOT.\cdisc",
      	    	"&GLIBROOT.\stat", "&GLIBROOT.\celgene" "!SASROOT\core\sasmacro" "!SASROOT\aacomp\sasmacro" 
      	    	"!SASROOT\accelmva\sasmacro" "!SASROOT\dmscore\sasmacro" "!SASROOT\graph\sasmacro" "!SASROOT\stat\sasmacro");
      	    %end;
      	    %put SASAUTOS option set.;
      	    %put   &PROOT.\macros;
      	    %put   %str(&GLIBROOT.\*);
      %end;
    %if %length(&dbver2) | %length(&pgmtype) %then %do;
    	%if %length(&dbver2) %then %do;
	      %* new dbver2 uses standard folder naming, so we will parse out and build libnames;
	      %do __i=1 %to %eval(1+%sysfunc(countc(&dbver2, '\')));
	        %let __temp=%scan(&dbver2,&__i,%str(\));
	        %if %index(%lowcase(&__temp),%str(raw)) %then %let __tmp=raw;
	        %else %if %index(%lowcase(&__temp),%str(sdtm)) %then %let __tmp=sdtm;
	        %else %if %index(%lowcase(&__temp),%str(adam)) %then %let __tmp=adam;
	        %else %if %index(%lowcase(&__temp),%str(analysis)) %then %let __tmp=analysis;
	        %else %if %index(%lowcase(&__temp),%str(pp)) %then %let __tmp=pp;
	        %let dbpath=;
	        %do __j=1 %to &__i;
	          %let dbpath=%left(&dbpath.\%scan(&dbver2, &__j, %str(\)));
	        %end;
	        libname &__tmp "&droot.&dbpath";
       	    %if &unblinded %then %do;
       	    	libname u&__tmp "&udroot.&dbpath";
       	    %end;
	        %if &__tmp^=raw %then %do;
	        	%if %sysfunc(fileexist("&droot.&dbpath\&__tmp._specs")) %then %do;
	            libname &__tmp.spec "&droot.&dbpath\&__tmp._specs";
	          %end;
	        	%else %if %sysfunc(fileexist("&droot.&dbpath\specs")) %then %do;
	            libname &__tmp.spec "&droot.&dbpath\specs";
	          %end;
	          %else %do;
	          	%put Failed to set &__tmp SPEC folder, \&__tmp._specs or \specs subfolder is missing.;
	          %end;
	        %end;
	        %if &__i=%eval(1+%sysfunc(countc(&dbver2, '\'))) %then %let version=%lowcase(%scan(&__temp,2,%str(_\/)));
	        %if %substr(&version,1,1)^=v %then %let version=v&version;
	      %end;
  	    %let __version=_&version;
	      %if &deliverdt^= %then %do;
	 	      %if %lowcase(%substr(&deliverdt,1,1))^=d %then %let deliverdt=d&deliverdt;
	      	%let __temp=_&deliverdt;
	      %end;
	      %else %do;
	      	%let __temp=;
	      %end;
	    %end;
	    %else %do;
 	      	%let __version=_shells;
 	    %end;
 	    /** autoparse out the folder assignments, anticipated input values are:
 	          tables, figures, listings, tables_shells, tableshells, table_shells, etc **/
 	    %let _shells=0;
 	    %if %index(%upcase(&pgmtype),%str(SHELLS)) %then %do;
 	    	%* flag it is shells and remove shells from pgmtype;
 	    	%let _shells=1;
 	    	%let pgmtype=%sysfunc(prxchange(s/_SHELLS|_shells|SHELLS|shells//,-1,&pgmtype));
 	    %end;
 	    ** remap to new standard names **;
 	    %if %upcase(&pgmtype)=TABLE %then %let pgmtype=tables;
 	    %if %upcase(&pgmtype)=LISTING %then %let pgmtype=listings;
 	    %if %upcase(&pgmtype)=FIGURE %then %let pgmtype=figures;
 	    %if %upcase(&pgmtype)=RAND %then %let pgmtype=randomization;
 	    
 	    %let pgmloc=&pgmtype;
      %if %upcase(&pgmtype)=SDTM | %upcase(&pgmtype)=ADAM | %upcase(&pgmtype)=RANDOMIZATION %then %let outloc=;
 	    %else %let outloc=&pgmtype.&__version.&__temp;

				** the rest of these are deprecated (short life) but kept for existing programs using them **;
				%let listver=&outloc;
				%let tabver=&outloc;
				%let figver=&outloc;
			  ** end deprecated vars **;
			  ** set constants for standard folder names **;
				%let logver=logs; **&__version.&__temp;
				%let valver=validation_tables; **&__version.&__temp;
				%let tdataver=table_dataset; **&__version.&__temp;
				%let soutver=sas_output; **&__version.&__temp; 


 	    %if &_shells %then %do;
 	    	** backwards compatible: match folder name if for some reason folder was setup as ...\tables_shells or ...\table_shells (old practice) **;
 	    	%if %sysfunc(fileexist("&oroot\&pgmtype._shells")) %then %let outloc=&pgmtype._shells;
 	    	%else %if %sysfunc(fileexist("&oroot\%substr(&pgmtype,1,%eval(%length(&pgmtype)-1))_shells")) %then %let outloc=%substr(&pgmtype,1,%eval(%length(&pgmtype)-1))_shells;
 	    	/** this is the current method, and table2 will need to check if this is done here now and not append shells if it is **/
 	    	%else %if %sysfunc(fileexist("&oroot\&pgmtype\shells")) %then %let outloc=&pgmtype\shells;
 	    	%else %put %str(ERR)%str(OR:) OUTLOC not assigned. Shells subfolder does not exist at &oroot\&pgmtype;
 	    	%let outdest=WORD;
 	    %end;
 	    %else %do;
 	    	%let outdest=PDFTBL;
				%if %index(%upcase(&pgmtype),TABLE) %then %do;
				  %if %sysfunc(fileexist("&oroot\&outloc\&tdataver")) %then %do;
				    libname vtdata "&oroot\&outloc\&tdataver";
				  %end;
				  %else %put %str(ERR)%str(OR:) Could not assign VTDATA libref, folder does not exist (...&outloc\&tdataver);
				  %if %sysfunc(fileexist("&oroot\&outloc\&valver\val_dataset")) %then %do;
				    libname vtval "&oroot\&outloc\&valver\val_dataset";
				  %end;
				  %else %put %str(ERR)%str(OR:) Could not assign VTVAL libref, folder does not exist (...&outloc\&valver\val_dataset);
				%end;
        %if ^%sysfunc(fileexist("&oroot\&outloc")) %then %put %str(WARN)%str(ING:) OUTLOC folder not found, generated output will fail to save.;
      %end;

    %end; %else %do;
      %let db=&dbver;
      %let dbsub=&subset;
      %if %length(&subset) %then %let dbpath=&dbver.\&subset;
      %else %let dbpath=&dbver;
      %if %length(&pgmloc)=0 %then %let pgmloc=tables;
      %if %length(&outloc)=0 %then %let outloc=tables;
      %if %length(&outdest)=0 %then %let outdest=PDFTBL;
    %end;
    %if ^%exist(_debug_) %then %do;
      %global _debug_;
      %let _debug_=0;
    %end;
    %let allinone=0;
    %let lastone=1;
    %let bookmarks=1;
    %let pdftoc=0;
    %let unfuddle=0;
    %let googledoc=0;
    %let rptout=1;
    %let rptlog=0;
    %let runmode=DRAFT;
    %let savelog=0;
    %let savetdata=0;
    %let cutdt=; %let tnumprefix=1; %let tnumsuffix=; %let lnumprefix=0; %let lnumsuffix=; 
	 %let gfont=; %let gfontsize=; %let gpagesize=LETTER; %let gtitle_fontincr=1; 
	 %let gleftmargin=; %let grightmargin=; %let gtopmargin=; %let gbottommargin=; %let gforce=1;

    %if &_debug_>0 %then %do;
      options mprint;
    %end;
    /* x 'y:' nowait; */
    x "cd &proot" nowait;

    %put Environment variables PROOT, DROOT, OROOT, GDOCROOT and SPROOT are set for &ENV environment.;
    %put   PROOT = &PROOT;
    %put   DROOT = &DROOT;
    %put   OROOT = &OROOT;
    %put   GDOCROOT = &GDOCROOT;
    %put   SPROOT = &SPROOT;
    %put -------------------------------------------------------------;
		%if %length(&dbver2) %then %do;
  	  %let soutpath=&oroot\&outloc\&soutver;
	    %put *** DELIVER (deliverable name) is set to &deliver;
	    %put *** DELIVERDT (deliverable date) is set to &deliverdt;
	    %put *** VERSION (database version) is set to &version;
	    %*put *** TABVER (tables version) is set to &tabver;
	    %*put *** LISTVER (listings version) is set to &listver;
	    %*put *** FIGVER (figures version) is set to &figver;
	    %*put *** TDATAVER (tables dataset version) is set to &tdataver;
      %put *** SOUTPATH (SAS output destination) is set to &soutpath;
    libname meta "&proot\&pgmloc\metadata";
    %end;
    %put;
    %put *** PGMLOC (program location) is set to &pgmloc;
    %put *** OUTLOC (output location) is set to &outloc;
    %put *** OUTDEST (output destination/type) is set to &outdest;
    %put *** OUTPATH (table2 macro will assign this global var later) will be &oroot\&outloc;
    %put *** _debug_ is set to &_debug_;
    %put -------------------------------------------------------------;
    %put Finished setting environment.  Now loading study init.sas file.;
    %include "&proot\init&init_suffix..sas";

/* options mprint; */
%mend;
