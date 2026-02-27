%macro list_files_to_excel(root=);

    %local datepart timepart ts excelfile;
    %let datepart=%sysfunc(today(), yymmddn8.);
    %let timepart=%sysfunc(compress(%sysfunc(time(), time5.),:));
    %let ts=&datepart._&timepart;

    %let excelfile=&root.\File_List_&ts..xlsx;

    /* Full recursive list of files & folders */
    filename dirpipe pipe "dir ""&root."" /s /b";

    data files;
        infile dirpipe lrecl=500 truncover;
        length fullpath $500 folder $400 filename $200;
        input fullpath $char500.;
        if missing(fullpath) then delete;

        /* Separate folder and filename */
        filename = scan(fullpath, -1, '\');
        folder   = substr(fullpath, 1, length(fullpath) - length(filename) - 1);
    run;

    filename dirpipe clear;

    /* Split into files vs folders */
    data files_only folders_only;
        set files;
        if filename = "" then output folders_only;
        else output files_only;
    run;

    ods listing close;

    ods excel file="&excelfile"
        options(embedded_titles='no' autofilter='all' frozen_headers='on');

    /* Sheet 1: Files */
    ods excel options(sheet_interval='none' sheet_name="Files_List");
    proc report data=files_only nowd;
        columns fullpath folder filename;
        define fullpath / display "Full Path" style(column)=[cellwidth=5in];
        define folder   / display "Folder"    style(column)=[cellwidth=3in];
        define filename / display "File Name" style(column)=[cellwidth=2in];
    run;

    ods excel close;
    ods listing;

    %put NOTE: File listing written to &excelfile.;

%mend;

/* Example call */
%list_files_to_excel(root=P:\Projects\Minoryx\Natural History\BSP);
