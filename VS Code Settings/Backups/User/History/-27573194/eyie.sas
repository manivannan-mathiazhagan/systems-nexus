***-------------------------------------------------------------------------------------------------***;
*** Study Name:         BSP Demo Project                                                            ***;
*** Program Name:       _runall_ADaM_define_v20250630.sas                                           ***;
***                                                                                                 ***;
*** Purpose:            Program to create the ADaM define.xml                                       ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         18Jun2025                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Modification History                                                                            ***;
***-------------------------------------------------------------------------------------------------***;
*** Date        | Modified By          | Description                                                ***;
***-------------|----------------------|------------------------------------------------------------***;
*** 18Jun2025   | Manivannan           | Initial version created                                    ***;
***-------------------------------------------------------------------------------------------------***;

/* Setenv call with respective folders and Parameters */
%let ad_path=raw_v20250618\sdtm_v20250630\adam_v20250630;

%setenv(sponsor =Instat,
        study   =BSP Demo Project,
        dbver2  =&ad_path.);       

/* New library for Storing define spec */
libname specs "&droot&dbpath\Specs\define";

/*Controlled Terminology data*/
libname glibstd "&droot&dbpath\Specs\cdisc";

%let cont_term_ver=20240329;

%imp_xlsx_json(filepath=&droot&dbpath\Specs\cdisc\ADaM_Terminology_&cont_term_ver..xlsx,sheet=ADaM_Terminology);

data ADaM_Terminology_&cont_term_ver.;
    set ADaM_Terminology;
run;

proc sql;
    create table glibstd.ctstandard_&cont_term_ver. as
        select  cl.cdisc_submission_value as control, 
                s.codelist_name as description, 
                s.codelist_code as ct_codelist, 
                s.code as ctcode, 
                s.cdisc_submission_value as code
        from ADaM_Terminology_&cont_term_ver. s, ADaM_Terminology_&cont_term_ver. cl
        where ^missing(s.codelist_code) and missing(cl.codelist_code)
        and s.codelist_code=cl.code
    ;
quit; 
 
/* Macro to check some needed variables are imported as Numeric */
%macro ensure_numeric(OUTLIB, SHEET, VAR);

	%local dsid varnum type rc;

	%let dsid = %sysfunc(open(&OUTLIB..&SHEET));
	%if &dsid %then 
		%do;
			%let varnum = %sysfunc(varnum(&dsid, &VAR));
			%if &varnum > 0 %then 
				%do;
					%let type = %sysfunc(vartype(&dsid, &varnum));
				%end;
			%else 
				%do;
					%let type = ;
				%end;
			%let rc = %sysfunc(close(&dsid));
		%end;
	%else 
		%do;
			%put ERROR: Unable to open dataset &OUTLIB..&SHEET;
			%let type = ;
		%end;

	%if %upcase(&type) = C %then 
		%do;
			data &sheet._c(drop = &VAR._); 
				set &OUTLIB..&SHEET(rename = (&VAR = &VAR._));
				&VAR = ifn(not missing(&VAR._), input(&VAR._, ?? best.), .);
			run;

			data &OUTLIB..&SHEET;
				set &sheet._c;
			run;

			%deltable(tables=&sheet._c);
		%end;
	%else %if "&type" = "" %then 
		%do;
			%put NOTE: Variable &VAR not found in &OUTLIB..&SHEET. Skipping conversion.;
		%end;

%mend;

/* Macro to import and ensure numeric fields are imported as proper way */
%macro adam_spec_import(SHTNM);
	%imp_sp_xlsx(Teams_channel=&SP_Channel_Name,filepath=BSP/ADaM_SPECS/&ADaM_SPECS_FILENAME..xlsx,outlib=SPECS,sheet=&SHTNM.);
    %ensure_numeric(SPECS,&SHTNM.,KEEP);
    %ensure_numeric(SPECS,&SHTNM.,ID_VAR);
	%ensure_numeric(SPECS,&SHTNM.,LEN);
%mend adam_spec_import;

/*Importing Sheets other than individual domains sheets*/
%adam_spec_import(Domains);
%adam_spec_import(Formats);
%adam_spec_import(Valuemetadata);

/*Importing individual Domains sheets*/
%adam_spec_import(ADSL);
%adam_spec_import(ADAE);
%adam_spec_import(ADVS);
%adam_spec_import(ADEG);
%adam_spec_import(ADLB);
%adam_spec_import(ADQS);
%adam_spec_import(ADCM);
%adam_spec_import(ADEC);
%adam_spec_import(ADMH);
%adam_spec_import(ADCE);
%adam_spec_import(ADFT);

/* Clearing the WORK library  */
proc datasets library=work memtype = data kill noprint;
quit;

/* Generating define.xml */
%create_define( sdtmadam=ADaM,
				sdtmadam_Ver=1.3,
                incl_acrf=0,
                incl_rg=1,
                specpath=&droot&dbpath\Specs\define,
                datapath=&droot&dbpath,
                xptpath=&droot&dbpath\XPT,
                ctpath=&droot&dbpath\Specs\cdisc,
                define_ver=2,
                odm_ver=1.3,
                xsl_ver=2-0-0,
                ig_ver=1.1,
                ct_version=20240329,
                meddra_version=27.0,
                whodrug_version=%bquote(WHODRUG GLOBAL B3 March 1, 2024),
                study_oid=BSP-DEMO-001,
                study_name=BSP-DEMO-001,
                study_desc=%nrstr(Demo Project for BSP Team),
                protocol=BSP-DEMO-001);
quit;

