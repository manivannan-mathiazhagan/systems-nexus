options mautosource noxwait xsync;
data _null_;
    call symput('userhome',sysget('USERPROFILE'));
    call symput('username',sysget('USERNAME'));
run;

** CHANGED THIS TO POINT AT LOCAL DRIVE;
%let GLIBROOT =P:\BSP_LocalDev\&username\LocalDev\Instat\GLIB\macros;

** workaround for some macros that do not compile after setenv called even though they are in sasautos path **;
%include "&glibroot\util\exist.sas";
%include "&glibroot\clrenv.sas";
%include "&glibroot\setenv.sas";
%let Rterm = "C:\Program Files\R\R-4.4.2\bin\x64";
%let MQOSLib = &glibroot\WPS2R\EXE\mqoslib.exe;
%let SysProd = SAS;
%let _RDataDir = &userhome.\rdatadir;
%let env = USER;
%global fldrver;
