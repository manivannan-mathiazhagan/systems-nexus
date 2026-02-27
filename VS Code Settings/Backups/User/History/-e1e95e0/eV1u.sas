/****************************************************************************/
* STUDY        :  FERAHEME AS A MAGNETIC RESONANCE IMAGING (MRI) 
* PROTOCOL     :  FER-021-003
* PROGRAM      :  SE.SAS
* CREATED BY   :  Vamsi Yadav
* DATE CREATED :  24Jun2024
* DESCRIPTION  :  PROGRAM FOR SDTM -SE DOMAIN
******************************************************************************;

***********DELETING THE DATASETS, LOGS AND OUTPUTS FROM WORK LIBRARY *********;
proc datasets memtype=data lib=work kill noprint;
quit;
dm 'log;clear; output;clear;';
options validvarname=upcase;

proc sort data=sdtm.dm out=dm1(where=(rfstdtc ne ""));
    by usubjid;
run;

data se1;
    set dm1;

    domain="SE";
    epoch="TREATMENT";
    taetord=1;

    if rfstdtc ne "" then sestdtc=strip(rfstdtc);
    else sestdtc="";
    if rfpendtc ne "" then seendtc=strip(rfpendtc);
    else seendtc="";

    if armcd ne "" then etcd=strip(armcd);
    else etcd="";
    if arm ne "" then element=strip(arm);
    else element="";

    keep studyid usubjid domain rfstdtc epoch taetord sestdtc seendtc etcd
        element;
run;

*********Study day*********;
data se2(drop=rfstdtc rfsdtn sestdn seendn);
    set se1;

    if rfstdtc ne "" then rfsdtn=input(substr(rfstdtc,1,10),is8601da.);
    if sestdtc ne "" then sestdn=input(substr(sestdtc,1,10),is8601da.);
    if seendtc ne "" then seendn=input(substr(seendtc,1,10),is8601da.);

    *sestdy*;
    if sestdn >= rfsdtn then sestdy=(sestdn-rfsdtn)+1;
    else if sestdn < rfsdtn then sestdy=(sestdn-rfsdtn);
    *seendy*;
    if seendn >= rfsdtn then seendy=(seendn-rfsdtn)+1;
    else if seendn < rfsdtn then seendy=(seendn-rfsdtn);
run;

*********Seq*********;
proc sort data=se2;
    by usubjid;
run;

data se3;
    set se2;
    by usubjid;

    if first.usubjid then seseq=1;
    else seseq+1;

run;

dm log 'LOG; FILE "&DROOT&DBPATH\LOGS\SE.LOG" REPLACE' log;
