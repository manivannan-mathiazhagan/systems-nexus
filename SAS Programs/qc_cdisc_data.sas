***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_cdisc_data.sas                                                                ***;
***                                                                                                 ***;
*** Purpose:       Macro to call each validation program passed in dsn by space separated           ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
*** Created On:    23Mar2023                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters  | Description                                         | Default value   | Required  ***;
***             |                                                     |                 | Parameter ***;
*** ------------|-----------------------------------------------------|-----------------|-----------***;
*** cdisc_type  |  Type of CDISC - SDTM/ADaM                          |   No default    |   Yes     ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** dsets       |  List of datasets to be validated                   |   No default    |   Yes     ***;
***-------------|-----------------------------------------------------|-----------------|-----------***;
*** ref_spec    |  Refresh the Specs datasets ?                       |     N           |           ***;
***             |   If Y - then specs datasets will be refreshed      |                 |           ***; 
***             |   If N - then specs datasets will not be refreshed  |                 |           ***;    
***-------------------------------------------------------------------------------------------------***;

%macro qc_cdisc_data(cdisc_type=,dsets=,ref_spec=N);

%let SDT_VER=%sysfunc(compress(%sysfunc(tranwrd(&SDTM_VERSN.,.,_))));
%let SDT_NME=%sysfunc(compress(%sysfunc(tranwrd(&SDTM_VERSN.,., ))));

%put &SDT_VER.;
%put &SDT_NME.;

/*options nomprint nomlogic nosymbolgen nosource nonotes;*/

%if "%upcase(&cdisc_type.)" eq "SDTM" %then 
    %do;
        
        /*Importing Spec details from Pinnacle 21 Specification */
        libname P21_SPEC "E:\Projects\Instat\CDISC\Pinnacle Specification";
                
         %if "&ref_spec." eq "Y"  %then 
            %do;
                %imp_xlsx(  fname=E:\Projects\Instat\CDISC\Pinnacle Specification\SDTM_IG_&SDT_VER..xlsx,
                            sheet=Datasets,
                            outlib=WORK);
                            
                data P21_SPEC.SD&SDT_NME._DATASETS;
                    set WORK.DATASETS;
                run;

                %imp_xlsx(  fname=E:\Projects\Instat\CDISC\Pinnacle Specification\SDTM_IG_&SDT_VER..xlsx,
                            sheet=Variables,
                            outlib=WORK);
                            
                data P21_SPEC.SD&SDT_NME._VARIABLES;
                    set WORK.VARIABLES;
                run;
            %end;

        %else 
            %do;
                /*Importing Spec details from Pinnacle 21 SDTM Excel Specification if already not imported*/
                %if %sysfunc(exist(P21_SPEC.SD&SDT_NME._DATASETS)) %then 
                    %do;
                        %put NOTE: P21_SPEC.SD&SDT_NME._DATASETS is not refreshed as it is already present;
                    %end;
                %else 
                    %do;
                        %imp_xlsx(  fname=E:\Projects\Instat\CDISC\Pinnacle Specification\SDTM_IG_&SDT_VER..xlsx,
                                    sheet=Datasets,
                                    outlib=WORK);
                        
                        data P21_SPEC.SD&SDT_NME._DATASETS;
                            set WORK.DATASETS;
                        run;
                    %end;
               %if %sysfunc(exist(P21_SPEC.SD&SDT_NME._VARIABLES)) %then 
                    %do;
                        %put NOTE: P21_SPEC.SD&SDT_NME._VARIABLES is not refreshed as it is already present;
                    %end;
                %else 
                    %do;     
                        %imp_xlsx(  fname=E:\Projects\Instat\CDISC\Pinnacle Specification\SDTM_IG_&SDT_VER..xlsx,
                                    sheet=Variables,
                                    outlib=WORK);
                        
                        data P21_SPEC.SD&SDT_NME._VARIABLES;
                            set WORK.VARIABLES;
                        run;
                        %end;
            %end;
    %end;

%if "&dsets." ne "" %then 

    %do;
        %let ___tot=%sysfunc(countw(&dsets.));
    
        %put total number of datasets no: &___tot. ;
        /*Runing all the program based on the list*/
        %do ___ds=1 %to &___tot;
           
            /* before starting a domain, kill the work dataset*/
            proc datasets library=WORK memtype = data kill noprint;
            quit;

            %let inds = %scan(&dsets,&___ds,%str( ));
            %put Started running Dataset: &inds. ;
            
            /*Storing Log in Projects folder*/
            %put The Log is stored in &logroot.&dbpath.\Compare\Logs ;

            proc printto new 
                log="&logroot&dbpath\Compare\Logs\val_&INDS..log";
            run;
           
            %include "&proot\Validation\&cdisc_type\val_&INDS..sas";

            proc printto log=log;
            run;

            %put Completed running Dataset: &inds. ;
            
            /*Deleting the datasets other than functions dataset and clearing the work library*/
            proc datasets library=WORK memtype = data kill noprint;
            quit;
        %end;

        /* Checking Logs */
         %logchk(&logroot.&dbpath.\Compare\Logs); 
    %end;
    
options source notes ;

%mend qc_cdisc_data;
