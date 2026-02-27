*************************************************************************;
*** Macro Name:    REPORT_IT.SAS                                      ***;
*** Macro Version: 001                                                ***;
***                                                                   ***;
*** Purpose:       To create ODS RTF output from dataset by 		  ***;
***                 automating the PROC REPORT code       			  ***;
***                                                                   ***;
*** SAS Version:   9.4                                                ***;
*** Programmed By: Manivannan Mathialagan                             ***;
*** Created On:    25SEP2019	                                      ***;
***                                                                   ***;
***-------------------------------------------------------------------***;
*** Parameters:                                                       ***;
***-------------------------------------------------------------------***;
*** Name     | Description                               | Default    ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** REP_DATA | Name of dataset present in work library   | OUTDATA    ***;
***          |  which is used as input for proc report   |            ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** VAR_LIST | List of variables to be displayed         | blank      ***;
***          |   separated by space                      |            ***;
***          |                                           |            ***;
*** Notes: 	 |	   1) needed order should be maintained  | 	     	  ***;
***     	 |	   2) should starts with _page _page2    |			  ***;
***			 |     3) As used Chiltern macros - wrap, 	 |		      ***;
***			 |		 titles, pagebrk					 |			  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** GRP_LIST | List of variables to be grouped     		 | blank      ***;
***          |   separated by space                      |            ***;
***          |                                           |            ***;
*** Notes: 	 |	  1) The Variables should be present in  |	          ***;
***			 |		the VAR_LIST						 |			  ***;
***     	 |	  2) can be blank if no need of grouping | 			  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** ORD_LIST | List of variables to be ordered     		 | blank      ***;
***          |   separated by space                      |            ***;
***          |                                           |            ***;
*** Notes: 	 |	  1) The Variables should be present in  |			  ***;
***			 |		the VAR_LIST						 |			  ***;
***     	 |	  2) can be blank if no need of ordering |			  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** NOP_LIST | List of noprint variables in proc report  | blank      ***;
***          |   separated by space                      |            ***;
***          |                                           |            ***;
*** Notes: 	 |	   1) The Variables should be present in | 			  ***;
***			 |		the VAR_LIST						 |			  ***;
***     	 |	   2) can be blank if no need of ordering| 			  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** LAB_LIST | List of Labels for each display variables | blank      ***;
***          |   separated by $                          |            ***;
***          |                                           |            ***;
*** Notes:	 | 1) If  7 variables in areVAR_LIST and  	 |		      ***;
***			 |		   4 are NOPRINT variables - then    | 			  ***;
***			 |		   3 variables which are displayed	 |			  ***; 
***			 |		   needed to be given label   		 |		      ***;
***     	 | 2) can add newline character, space       |            ***;
***          |         macro variable(N, N99, TRT99)     | 			  ***; 
***			 |		   as per need						 |			  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** WID_LIST | List of Width for each display variables  | blank      ***;
***          |  separated by $                           |            ***;
***          |                                           |            ***;
*** Notes: 	 |	1) If there are 7 variables in VAR_LIST  | 	  		  ***;
***			 |	  and 4 are NOPRINT variables - then     | 			  ***; 
***			 |	  3 variables which are displayed needed |		      ***;
***			 |	   to be given Width 					 |		      ***;
***     	 |	2) To be Given in precentage             |    		  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** ESC_CHAR | escape character to use in proc report    | ~		  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** SPT_CHAR | Split character to use in proc report     | @		  ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** COMP_BLK | Compute block statements if needed        | blank      ***;
***          |                                           |            ***;
***-------------------------------------------------------------------***;
*** Output(s):                                                        ***;
***                                                                   ***;
*** Macro Variables:    Variable defined in VAR (or VAR1 and VAR2 if  ***;
***                     required                                      ***;
***                                                                   ***;
*** Data sets:          None                                          ***;
***                                                                   ***;
*** Data set Variables: None                                          ***;
***                                                                   ***;
*** SAS Options:        None                                          ***;
***                                                                   ***;
*** Macros Called: 		titles										  ***;	
***-------------------------------------------------------------------***;
*** Change Control                                                    ***;
***                                                                   ***;
*** Name         - Date    - Description of Change                    ***;
***-------------------------------------------------------------------***;
*** 									                              ***;
***              -         -                                          ***;
***                                                                   ***;
*************************************************************************;

%macro REPORT_IT(REP_DATA=OUTDATA,
                VAR_LIST=,
                GRP_LIST=,
                ORD_LIST=,
                LAB_LIST=,
                WID_LIST=,
                NOP_LIST=,
                ESC_CHAR=%str(~),
                SPT_CHAR=%str(@),
                COMP_BLK=);

     /*   Creating text needed for display in proc report*/
     /*   counting the total number of variables - needed for proc report*/
     %let VAR_CNT=%sysfunc(countw(&VAR_LIST,%str( )));

     /*   count of noprint variables*/
     %let NOP_CNT=%sysfunc(countw(&NOP_LIST,%str( )));
     %put &=VAR_CNT. &=NOP_CNT.;

     /*   getting only the display variables - starts */
     /*   first assigning the total list of variables - and then deleting the noprint variables from list*/
     %let DIS_LIST=&VAR_LIST.;

     /*   first line - column definition*/
     %let OUT_STR = %str( column &VAR_LIST. ;);

     /*   removing noprint variables from list */
     %do _i = 1 %to &NOP_CNT.;
           %let NOP_VAR = %scan(&NOP_LIST.,&_i);
           %let DIS_LIST = %sysfunc(strip(%sysfunc(tranwrd(%sysfunc(tranwrd(%sysfunc(tranwrd(&DIS_LIST.,_page2,%str( ))),_page,%str( ))),&NOP_VAR,%str( )))));
     %end;

     /*   display variables after removing noprint values*/
     %put &=DIS_LIST.;

     /*   getting only the display variables - ends */
     /*   define statements for each variable - starts*/
     %do _j = 1 %to &VAR_CNT.;
           %let CUR_VAR = %scan(&VAR_LIST.,&_j);

           /*   adding group - if the variable is in grp_list*/
           %if %index(&GRP_LIST,&CUR_VAR.) gt 0 %THEN
                %do;
                     %let GRP = GROUP;
                %end;
           %else
                %do;
                     %let GRP = %str( );
                %end;

           /*   adding order - if the variable is in ord_list*/
           %if %index(&ORD_LIST,&CUR_VAR.) gt 0 %then
                %do;
                     %let ORD = %str(order order = internal);
                %end;
           %else
                %do;
                     %let ORD = %str( );
                %end;

           /*   adding noprint - if the variable is in nop_list*/
           %if %index(&NOP_LIST,&CUR_VAR.) gt 0 %then
                %do;
                     %let NOP = %str(noprint);
                     %LET NUMB = %str( );
                %end;

           /*   assigning label and rtf tags if needed*/
           %else %if %index(&ORD_LIST,&CUR_VAR.) ne 0 |  %index(&grp_LIST,&CUR_VAR.) ne 0 %then
                %do;

                     data _null_;
                           NUMB=findw("&DIS_LIST.","&CUR_VAR.",' ','E');
                           call symputx('NUMB',NUMB);
                     run;

                     %let CUR_WID = %scan(&WID_LIST.,&NUMB.,$);                     
                     %let CUR_LAB = %scan(&LAB_LIST.,&NUMB.,$);
                     %let NOP = %str( style(column) = [cellwidth = &CUR_WID.%] "&CUR_LAB." );
                      
                %end;
           %else %if %index(&ORD_LIST,&CUR_VAR.) eq 0 and  %index(&grp_LIST,&CUR_VAR.) eq 0 %then
                %do;

                     data _null_;
                           NUMB=findw("&DIS_LIST.","&CUR_VAR.",' ','E');
                           call symputx('NUMB',NUMB);
                     run;

                     %let CUR_WID = %scan(&WID_LIST.,&NUMB.,$);
                     %let CUR_LAB = %scan(&LAB_LIST.,&NUMB.,$);
                     %let NOP = %str( DISPLAY style(column) = [cellwidth = &CUR_WID.%] "&CUR_LAB." );
                           
                %end;

           /*         Appending all needed string */
           %let OUT_STR = &OUT_STR. %str(DEFINE &CUR_VAR. / &GRP.  &ORD. &NOP. ;);
     %end;

     /*   display in log - for checking*/
     %put &=OUT_STR.;

     /*printing the data starts*/
     ods escapechar="&ESC_CHAR.";

     proc printto print="!temp\_sas&sysjobid._1.txt" new;

     proc report data = &REP_DATA. nowindows headline headskip spacing=1 split='~' missing;      
           ;
           
            /*         using the text created*/
            &OUT_STR.
            
            /*         adding the compute blocks*/
            &COMP_BLK.
		   
           
     run;

proc printto;
run; 
%mend REPORT_IT;
