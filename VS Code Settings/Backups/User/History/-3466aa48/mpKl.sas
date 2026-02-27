***-------------------------------------------------------------------------------------------------***;
*** Study Name:         FER-021-003                                                                 ***;
*** Program Name:       _import_raw_20250729.sas                                                    ***;
***                                                                                                 ***;
*** Purpose:            Program to Generate RAW Dataset from excel and CSV files.                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         24Aug2024                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%setenv(sponsor =Covis Pharma,
        study   =Feraheme Imaging Supplemental,
        dbver2  =raw_v20250729\sdtm_v20250829);

%let rootpath = %substr(&droot., 1, %eval(%length(&droot.) - %length(%scan(&droot., -1, '\')) - 1));

/*OHSU File*/
%imp_xlsx(  fname=&rootpath.\External Data\OHSU Data\Supportive study - patient characteristics and AE events.xlsx,
            sheet=ALL,
            outlib=RAW,
            datarow=2);

/*RS File*/ 
proc import file="&rootpath.\External Data\IE Technical Evaluation\v20250729_AP003\20250729_AP003_EFF_RS.csv"
        out=RAW.RS
        dbms=dlm replace;
        delimiter="|";
        getnames=yes;
        GUESSINGROWS = MAX;
run;

/*TR File*/
proc import file="&rootpath.\External Data\IE Technical Evaluation\v20250729_AP003\20250729_AP003_EFF_TR.csv"
        out=RAW.TR
        dbms=dlm replace;
        delimiter="|";
        getnames=yes;
        GUESSINGROWS = MAX;
run;

/*TU File*/
proc import file="&rootpath.\External Data\IE Technical Evaluation\v20250729_AP003\20250729_AP003_EFF_TU.csv"
        out=RAW.TU
        dbms=dlm replace;
        delimiter="|";
        getnames=yes;
        GUESSINGROWS = MAX;
run;
