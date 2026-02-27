%macro data_to_xlsx(data=);

    %local path excelfile ts i ndsn thisdsn;

    /* Derive output path (same folder as program, fallback WORK) */
    %let path=%sysfunc(pathname(WORK));
    %if %symexist(_SASPROGRAMFILE) %then %do;
        %let path=%substr(&_SASPROGRAMFILE,1,%length(&_SASPROGRAMFILE)-%length(%scan(&_SASPROGRAMFILE,-1,\)));
    %end;

    /* Create timestamp for filename */
    %let ts=%sysfunc(datetime(),E8601DT19.);
    %let ts=%sysfunc(compress(&ts, -:));

    %let excelfile=&path.VS_DATA_&ts..xlsx;

    /* Open workbook */
    ods excel file="&excelfile" 
    options(embedded_titles='yes' autofilter='all' flow="DATA" autofit_height='no' frozen_headers= "ON");

    /* Loop over datasets */
    %let ndsn=%sysfunc(countw(&data,%str( )));
    %do i=1 %to &ndsn;
        %let thisdsn=%scan(&data,&i,%str( ));

        /* Force each PROC PRINT to a new worksheet */
        ods excel options(sheet_interval='proc' sheet_name="&thisdsn");

        data _renamed;
            set &thisdsn;
            %let dsid=%sysfunc(open(&thisdsn));
            %let nvar=%sysfunc(attrn(&dsid,nvars));
            %do j=1 %to &nvar;
                %let vname=%sysfunc(varname(&dsid,&j));
                %let vlabel=%sysfunc(varlabel(&dsid,&j));
                %if %superq(vlabel) ne %then %do;
                    label &vname = "%sysfunc(strip(&vname))%str(@)%sysfunc(strip(&vlabel))";
                %end;
                %else %do;
                    label &vname = "&vname";
                %end;
            %end;
            %let rc=%sysfunc(close(&dsid));
        run;

        proc print data=_renamed label noobs;
        run;

    %end;

    /* Close workbook */
    ods excel close;

    %put NOTE: Excel workbook created: &excelfile;

%mend data_to_xlsx;

/* Multiple datasets into one workbook */
%data_to_xlsx(data=sashelp.class sashelp.cars sashelp.shoes);

/* Single dataset */
%data_to_xlsx(data=sashelp.class);