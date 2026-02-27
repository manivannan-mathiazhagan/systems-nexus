***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    TLF_Packager.sas                                                                 ***;
***                                                                                                 ***;
*** Purpose:       Packages all RTF and PDF files from a specified folder into a single,            ***;
***                bookmarked PDF with a clickable Table of Contents (TOC).                         ***;
***                Utilizes the Python script TLF_Packager.py for all core operations.              ***;
***                RTF-to-PDF conversion is controlled per file in Excel ("Converter" column):      ***;
***                  - Use Microsoft Word for files marked "WORD"                                   ***;
***                  - Use LibreOffice for files marked "LIBREOFFICE"                               ***;
***                The default converter (for all RTFs) can be specified via macro argument.        ***;
***                Supports user-driven review and approval of bookmarks/order via Excel.           ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By: Manivannan Mathialagan                                                           ***;
***                                                                                                 ***;
*** Created On:    22-May-2025                                                                      ***;
***-------------------------------------------------------------------------------------------------***;
*** Parameters:                                                                                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Name           | Description                                 | Default value   | Required       ***;
***----------------|---------------------------------------------|-----------------|----------------***;
*** input_path     | Path to folder containing RTF and/or PDF    |   None          |    Yes         ***;
***                | files to be packaged.                       |                 |                ***;
***----------------|---------------------------------------------|-----------------|----------------***;
*** delete_pdfs    | Y/N flag: delete PDFs converted from RTFs   |   Y             |    No          ***;
***                | after merging.                              |                 |                ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
***   - PDF:      Single merged PDF with bookmarks and clickable TOC, placed in the input folder.   ***;
***   - Excel:    Worksheet for user review/approval of bookmark titles, order, and converter.      ***;
***   - Log:      TXT log file streaming all Python output for audit/troubleshooting.               ***;
***-------------------------------------------------------------------------------------------------***;
*** Macro Variables:    None                                                                        ***;
*** Data sets:          None                                                                        ***;
*** Variables:          None                                                                        ***;
*** Other Files:        Dynamically named PDF, Excel, and TXT log files in input folder.            ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies:                                                                                   ***;
***                                                                                                 ***;
*** - Python 3 (with openpyxl, PyMuPDF, pywin32 installed)                                          ***;
*** - Microsoft Word (for RTF-to-PDF conversion)                                                    ***;
*** - TLF_Packager.py script in P:\Biostatistics\PDF Tool\                                          ***;
***-------------------------------------------------------------------------------------------------***;
*** Example Usage:                                                                                  ***;
***                                                                                                 ***;
*** %TLF_Packager(input_path=E:\Study\Output\Listings);                                             ***;
*** %TLF_Packager(input_path=E:\Study\Output\Tables, delete_pdfs=N);             					***;
***-------------------------------------------------------------------------------------------------***;
*** Notes:                                                                                          ***;
***                                                                                                 ***;
***   1. The Python script creates an Excel worksheet listing all files, their titles/bookmarks.    ***;
***   2. After Excel review, merging and conversion proceed as indicated in worksheet.              ***;
***   3. Word must be installed and accessible for full function.              						***;
***-------------------------------------------------------------------------------------------------***;

%macro TLF_Packager(input_path=, delete_pdfs=Y);
    %local scriptpath pyexe ts base folder_name output_pdf logfile batfile;

    /* Path to Python script and executable */
    %let scriptpath=P:\Biostatistics\PDF Tool\TLF_Packager.py;
    %let pyexe=C:\Program Files\Python313\python.exe;

    /* Generate timestamp in YYYYMMDD_HHMMSS format */
   %let ts = %sysfunc(putn(%sysfunc(today()), yymmddn8.))_%sysfunc(compress(%sysfunc(putn(%sysfunc(time()), time8.)), :));
    %put NOTE: Timestamp generated as &ts.;

    /* Extract last folder name to decide output base name */
    %let folder_name = %scan(&input_path, -1, \);

    %if %sysfunc(index(%upcase(&folder_name), TABLE)) %then %let base = Tables;
    %else %if %sysfunc(index(%upcase(&folder_name), LISTING)) %then %let base = Listings;
    %else %if %sysfunc(index(%upcase(&folder_name), FIGURE)) %then %let base = Figures;
    %else %let base = TLFs;

    %let batfile = &input_path.\run_tlf_packager_&ts..bat;
    %let logfile = &input_path.\log_&base._&ts..txt;
    %let output_pdf = &base._&ts..pdf;

    %put NOTE: BATFILE: &batfile;
    %put NOTE: LOGFILE: &logfile;
    %put NOTE: SCRIPTPATH: &scriptpath;
    %put NOTE: PYEXE: &pyexe;
    %put NOTE: OUTPUT_PDF: &output_pdf;

    /* Generate BAT file to invoke Python */
    data _null_;
        file "&batfile.";
        put '@echo off';
        put 
          '"' "&pyexe." '" ' 
          '"' "&scriptpath." '" '
          '"' "&input_path." '" '
          '"' "&output_pdf." '" '
          '"' "&delete_pdfs." '" '
          '> "' "&logfile." '" 2>&1';
    run;

    /* Execute the BAT file */
    options noxwait;
    x """&batfile.""";

    /* Clean up the BAT file */
    x "del ""&batfile."" "; 

%mend;

/* Example Call */
%TLF_Packager(input_path=P:\Projects\Fusion Pharmaceuticals Inc\FPI-2265-201-202\Biostat\DSUR\Tables);
