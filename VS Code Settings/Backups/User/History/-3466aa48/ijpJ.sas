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

/*OHSU File*/
%imp_xlsx(  fname=E:\Projects\Covis Pharma\Feraheme Imaging Supplemental\External Data\OHSU Data\Supportive study - patient characteristics and AE events.xlsx,
            sheet=ALL,
            outlib=RAW,
            datarow=2);

/*RS File*/
proc import file="E:\Projects\Covis Pharma\Feraheme Imaging Supplemental\External Data\IE Technical Evaluation\v20240508_AP002\20240508_AP002_RS.csv"
        out=RAW.RS
        dbms=dlm replace;
        delimiter="|";
        getnames=yes;
        GUESSINGROWS = MAX;
run;

/*TR File*/
proc import file="E:\Projects\Covis Pharma\Feraheme Imaging Supplemental\External Data\IE Technical Evaluation\v20240508_AP002\20240508_AP002_TR.csv"
        out=RAW.TR
        dbms=dlm replace;
        delimiter="|";
        getnames=yes;
        GUESSINGROWS = MAX;
run;

/*TU File*/
proc import file="E:\Projects\Covis Pharma\Feraheme Imaging Supplemental\External Data\IE Technical Evaluation\v20240508_AP002\20240508_AP002_TU.csv"
        out=RAW.TU
        dbms=dlm replace;
        delimiter="|";
        getnames=yes;
        GUESSINGROWS = MAX;
run;
