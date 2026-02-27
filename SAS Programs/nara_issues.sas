/* Program to call  get_raw_issues */

proc datasets library=WORK memtype = data kill noprint;
quit;

%imp_xlsx(fname=Y:\mmathialagan\My SAS Files\MyCode\raw_issue_2_dm\get_raw_issues_nara.xlsx,Sheet=List);
/*SUBJECTID, VISIT combination is not available in datasets*/

proc sql noprint;

    create table SV as 
    select distinct SUBJECTID,VISIT,VISDAT,"Y" as SVFL 
    from RAW.SV 
    order by SUBJECTID,VISIT;
    
    create table VS as 
    select distinct SUBJECTID,VISIT,"VS" as VSFL 
    from RAW.VS 
    order by SUBJECTID,VISIT;
    
    create table FEEDHX as 
    select distinct SUBJECTID,VISIT,"FEEDHX" as FEEDFL 
    from RAW.FEEDHX 
    order by SUBJECTID,VISIT;
    
    create table INFANTCHAR as 
    select distinct SUBJECTID,VISIT,"INFANTCHAR" as INFCHARFL 
    from RAW.INFANTCHAR 
    order by SUBJECTID,VISIT;
    
    create table INCLEXCL as 
    select distinct SUBJECTID,VISIT,"INCLEXCL" as INCEXCFL 
    from RAW.INCLEXCL 
    order by SUBJECTID,VISIT;
    
    create table PFQ as 
    select distinct SUBJECTID,VISIT,"PFQ" as PFQFL 
    from RAW.PFQ 
    order by SUBJECTID,VISIT;
    
    create table DA as 
    select distinct SUBJECTID,VISIT,"DA" as DAFL 
    from RAW.DA 
    order by SUBJECTID,VISIT;
    
    create table PFQSP as 
    select distinct SUBJECTID,VISIT,"PFQSP" as PFQSP 
    from RAW.PFQSP 
    order by SUBJECTID,VISIT;

    create table INFQ as 
    select distinct SUBJECTID,VISIT,QINFDTM 
    from RAW.INF_Q 
    order by SUBJECTID,VISIT;
    
quit;

data ISS_CHK_1;
    merge SV VS FEEDHX INFANTCHAR INCLEXCL PFQ pfQSP ;
    by SUBJECTID VISIT;
    if SVFL eq "" and index(visit,"Unscheduled") eq 0;
    DATASET = catx(", ", VSFL,FEEDFL,INFCHARFL,INCEXCFL,PFQFL,PFQSP);
run;

/*Feeding date is before Birth date in RAW.INTAKE*/
proc sort data = RAW.DM out=DM(keep = SUBJECTID BRTHDAT ); 
    by SUBJECTID ;
run;      

proc sort data = RAW.INTAKE out=INTAKE; 
    by SUBJECTID ;
run;

data ISS_CHK_2;
    merge INTAKE DM;
    by SUBJECTID;
    if FEEDDT ne . and BRTHDAT ne . and FEEDDT lt BRTHDAT;
run;

/*IE - Not met to include in Study - But Formula intake data is available*/
data IE_1;
    set RAW.INCLEXCL(rename = (VISIT = VISITS));

    DOMAIN      = "&DOMAIN.";
    SUBJID      = SUBJECTID;
    VISIT       = strip(put(VISITS,$rawvis2sdtm.)); 
    VISITNUM    = input(strip(put(VISIT,$visitnf.)),best.);

    /* Outputting needed records */
    array INC_VARS[13] INC01 - INC13;
    array EXC_VARS[6] EXC01 - EXC06;
   
    if index(catx(":",of INC_VARS[*]),"No") gt 0 or index(catx(":",of EXC_VARS[*]),"Yes") gt 0;
   keep SUBJECTID INC: EXC: ;
run;

proc sort data = IE_1; 
    by SUBJECTID ;
run;

data ISS_CHK_3;
    merge IE_1(in=a) INTAKE(in=b) ;
    by SUBJECTID;
    if a and b;
run;

/*End of Study status is not Screen Failure for a subject who has failed in Criterion*/
proc sort data = RAW.DS out=DS_SCFL; 
    by SUBJECTID ;
    where DS_SFAIL ne "Yes";
run;

data ISS_CHK_4;
    merge IE_1(in=a) DS_SCFL(in=b) ;
    by SUBJECTID;
    if a and b;
run;

proc sort data = RAW.FCOMPL out= FCOMPL;
    by SUBJECTID OTHDT_1;
    where index(visit,"Unscheduled") gt 0 and OTHDT_1 ne .;
run;

proc sql noprint;
    /*  Unscheduled Visit from RAW.FCOMPL dataset - which is occuring on same date as Scheduled visit */
    create table ISS_CHK_5 as
    select a.*, b.VISIT,b.VISDAT from 
    ( select distinct SUBJECTID, OTHDT_1,VISIT as FCOMPL_VISIT  from RAW.FCOMPL where index(visit,"Unscheduled") gt 0 and OTHDT_1 ne .) a
    left join
    ( select distinct SUBJECTID, VISIT,VISDAT  from RAW.SV where index(VISIT,"Unscheduled") eq 0 and VISDAT ne .) b
    on a.SUBJECTID eq b.SUBJECTID and a.OTHDT_1 eq b.VISDAT;

    /*Formula intake date is before the Informed consent date*/
    create table ISS_CHK_6 as
    select a.SUBJECTID,a.ICDAT, b.FEEDDT,b.VISIT from 
    ( select distinct SUBJECTID, ICDAT  from RAW.DM where ICDAT ne .) a
    left join
    ( select distinct SUBJECTID, VISIT,FEEDDT from RAW.INTAKE where FEEDDT ne .) b
    on a.SUBJECTID eq b.SUBJECTID and b.FEEDDT lt a.ICDAT having cmiss(FEEDDT,ICDAT) eq 0;
    
    /*Same SUBJECTID, QINFDTM has multiple records in INF_Q dataset*/
    create table ISS_CHK_7 as
    select *, count(*) as count from 
    ( select * from RAW.INF_Q outer union corr select * from RAW.INF_Qsp) group by SUBJECTID,QINFDTM having calculated count gt 1;
    
    /*Same SUBJECTID, HCDAT has multiple records in HC dataset*/
    create table ISS_CHK_8 as
    select *, count(*) as count from RAW.HC where HCDAT ne . group by SUBJECTID,HCDAT having calculated count gt 1;

    /*Same SUBJECTID, LNGDAT has multiple records in LH dataset*/
    create table ISS_CHK_9 as
    select *, count(*) as count from RAW.LH where LNGDAT ne . group by SUBJECTID,LNGDAT having calculated count gt 1;

    /*Same SUBJECTID, WTDAT has multiple records in WT dataset*/
    create table ISS_CHK_10 as
    select *, count(*) as count from RAW.WT where WTDAT ne . group by SUBJECTID,WTDAT having calculated count gt 1;

    /*    RFSTDTC(SV.FRMSTDTM) is after RFENDTC(DS.DS_FORMDT)*/
    create table ISS_CHK_11 as
    select A.*,B.ds_formdt  from 
    (select subjectid,frmstdtm from RAW.sv where frmstdtm ne . ) a
    left join 
    (select subjectid,ds_formdt from RAW.ds where ds_formdt ne . ) b on a.subjectid eq b.subjectid
    having ds_formdt ne . and frmstdtm gt ds_formdt;
    ;

    
quit;

data DV_1;
    length subjectid cat  $200.; 
    set RAW.DV_BM;
    if upcase(strip(DATE_OF_DEVIA_TION)) not in ("" "N/A" ) then deviation_dt = input(DATE_OF_DEVIA_TION,anydtDTe.);
    if upcase(strip(DATE_IDENTIFI_ED)) not in ("" "N/A" ) then identified_dt = input(DATE_IDENTIFI_ED,anydTDTe.);   
    subjectid = compress(subject_id);
    CAT = "B&M";
    keep SUBJECTID deviation_dt identified_dt CAT ;
    format deviation_dt identified_dt  date9.;

run;

data DV_2;
    length subjectid cat  $200.; 
    set RAW.DV_BostroM;
    if upcase(strip(DATE_OF_DEVIATION)) not in ("" "N/A" ) then deviation_dt = input(DATE_OF_DEVIATION,anydtDTe.);
    if DATE_IDENTIFIED ne . then identified_dt = DATE_IDENTIFIED;
    subjectid = compress(subjec_tid);
    CAT = "BostroM";
    keep SUBJECTID deviation_dt identified_dt CAT ;
    format deviation_dt identified_dt  date9.;
run;

data DV_3;
    lENGTH subjectid cat  $200.; 
    set RAW.DV_petty;
    if upcase(strip(DATEOFDEVIATION)) not in ("" "N/A" ) then deviation_dt = input(DATEOFDEVIATION,anydtDTe.);
    if DATEIDENTIFIED ne . then identified_dt = DATEIDENTIFIED;   
    SUBJECTID = compress(subject_id);
    CAT = "Petty";
    keep SUBJECTID deviation_dt identified_dt CAT ;
    format deviation_dt identified_dt  date9.;

run;

data DV_ALL;
    set DV_1-DV_3;
run;

data ISS_CHK_12;
    set DV_ALL ;
    if identified_dt ne . and identified_dt lt deviation_dt and deviation_dt ne .  ;
run;

proc sort data = DV_ALL;
    by SUBJECTID;
run;

data ICD;
    FORMAT ICDAT date9.;
set raw.dm;
    keep subjectid icdat;
run;

proc sort data = ICD;
    by SUBJECTID;
run;

data ISS_CHK_13;
    merge DV_ALL(IN=A) ICD;
    by SUBJECTID;
    if a ;
    if ( ICDAT ne . and deviation_dt lt ICDAT and deviation_dt ne . ) or ( ICDAT ne . and identified_dt lt ICDAT and identified_dt ne . ) ;
run;

data ISS_CHK_14;
    merge SV INFQ;
    by SUBJECTID VISIT;
    if cmiss(QINFDTM,VISDAT) eq 0;
    if QINFDTM ne . and ABS(VISDAT-QINFDTM) gt 120 and VISDAT ne .  ;
    drop SVFL;
run;
    
%get_raw_issues;
