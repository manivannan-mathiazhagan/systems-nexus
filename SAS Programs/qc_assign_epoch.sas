***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_assign_epoch.sas                                                              ***;
***                                                                                                 ***;
*** Purpose:       Create EPOCH based on SDTM.SE and Date variable                                  ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    08Mar2023                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name     | Description                                            | Default value   | Required  ***;
***          |                                                        |                 | Parameter ***;
*** ---------|--------------------------------------------------------|-----------------|-----------***;
*** DTC      | the DTC variable based on which EPOCH is assigned      | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** INDSET   | the name of INPUT dataset                              | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** OUTDSET  | the name of OUTPUT dataset                             | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          | No default      |   No      ***; 
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &dsn.                                                                       ***;
***                                                                                                 ***;
*** Variables:          EPOCH is added                                                              ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          SDTM.SE with USUBJID TAETORD SESTDTC SEENDTC EPOCH                          ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             qc_reduce_length                                                            ***;
***                                                                                                 ***;
*** Other:              None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%macro qc_assign_epoch(DTC,
                    INDSET,
                    OUTDSET,
                    DEBUG=N);

/*Taking SDTM SE dataset*/
proc sort data = SDTM.SE out=__EPC_SE;
    by USUBJID TAETORD ;
run;

/*Taking dates as Numeric*/
data __EPC_SE1(RENAME = (DT_1 = SESTDTC dt_2 =SEENDTC));
    set __EPC_SE;
    by USUBJID TAETORD;
    SEENDTN  = input(scan(SEENDTC,1,"T"),is8601da.);
    SEENDTN1 = SEENDTN+1;
    SESTDTN  = input(scan(SESTDTC,1,"T"),is8601da.);
    SESTDTN1 = SESTDTN+1;
    SESTTM   = scan(SESTDTC,2,"T");
    SEENTM   = scan(SEENDTC,2,"T");
    if length(compress(substr(SESTDTC,1,10),'-'))=8 then 
        do;
            if length(compress(SESTDTC))=10 then DT_1=compress(SESTDTC||'T00:00');
            else if length(compress(SESTDTC))=13 then DT_1=compress(SESTDTC||':00');
            else if length(compress(SESTDTC))=16 then DT_1=compress(SESTDTC);

            else if length(compress(SESTDTC))<10 then DT_1='';
               
        end;
    else dt_1='';

    if last.USUBJID  then 
        do;
            DT_2 = compress(strip(put(SEENDTN+1,is8601da.))||'T23:59');
        end;
    else 
        do;
            if length(compress(substr(SEENDTC,1,10),'-'))=8 then 
                do;
                    
                    if length(compress(SEENDTC))=10 then DT_2=compress(SEENDTC||'T23:59');
                    else if length(compress(SEENDTC))=13 then DT_2=compress(SEENDTC||':00');
                    else if length(compress(SEENDTC))=16 then DT_2=compress(SEENDTC);

                    else if length(compress(SEENDTC))<10 then DT_2='';
                    else put "&UWARN. - Diferent length of date " USUBJID SEENDTC;
                        
                end;
        end;
    keep USUBJID TAETORD EPOCH  DT_1 DT_2;
run;

/*Transposing Epoch*/
proc transpose data = __EPC_SE1 out=__EPC_SE_EPC(drop=_:) prefix=EPOC;
    by USUBJID;
    id TAETORD;
    var EPOCH;
run;

/*Transposing Start date*/
proc transpose data = __EPC_SE1 out=__EPC_SE_STD(drop=_:) prefix=STDT;
    by USUBJID;
    id TAETORD;
    var SESTDTC;
run;

/*Transposing End date*/
proc transpose data = __EPC_SE1 out=__EPC_SE_END(drop=_:) prefix=ENDT;
    by USUBJID;
    id TAETORD;
    var SEENDTC;
run;

/*merging based on usubjid*/
data __EPC_SE_ALL;
    merge __EPC_SE_EPC __EPC_SE_STD __EPC_SE_END;
    by USUBJID;
run;

/*Taking maximum value of TAETORD in data*/
proc sql noprint;
    select strip(put(max(TAETORD),best.)) into: TOT_EPC from __EPC_SE;
quit;

/*Taking input dataset*/
proc sort data = &INDSET. ;
    by USUBJID;
run;

/*generating output dataset*/
data &OUTDSET.;
    length EPOCH $200.;
    merge &INDSET.(in=a) __EPC_SE_ALL;
    by USUBJID;
    if a;
    
    /* Deriving Epoch based on dates*/
    array EPC[*] EPOC3 EPOC2 EPOC1 ;
    array SDT[*] STDT3 STDT2 STDT1 ;
    array EDT[*] ENDT3 ENDT2 ENDT1 ;
    
    EPOCH = "";

    do i = 1 to dim(EPC) until ( strip(SDT(i)) <=: strip(&DTC.) and strip(&DTC.) <: strip(EDT(i)) );

        if not missing(EPC(i)) then 
        do;

            if strip(SDT(i)) <=: strip(&DTC.) and strip(&DTC.) <: strip(EDT(i)) then EPOCH = EPC(i);
        
        end;
    
        else EPOCH = "";

    end;

    drop EPOC1-EPOC&TOT_EPC. STDT1-STDT&TOT_EPC. ENDT1-ENDT&TOT_EPC. i ;
run; 

%qc_reduce_length(&OUTDSET.);

/*Deleting Intermediate datasets created*/
%if "&DEBUG." ne "Y" %then
    %do;
        /*Deleting Intermediate datasets created*/
        proc datasets lib=work nolist;
            delete __EPC_:;
            quit;
        run;
    %end;

%mend qc_assign_epoch;

