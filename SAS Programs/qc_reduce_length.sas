***-------------------------------------------------------------------------------------------------***;
*** Macro Name:    qc_reduce_length.sas                                                             ***;
***                                                                                                 ***;
*** Purpose:       Reduce all character variables in dataset to minimum length required for content ***;
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
*** DSN      | Name of input dataset                                  | No default      |   Yes     ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DESC     | Expected Label of Output dataset                       | No default      |   No      ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** FRMT     | Variables with format values if any variable needs to  | No default      |   No      ***;
***          | be displayed with format/informat                      |                 |           ***;
***          | for e.g: format ASTDT AENDT date9. TRTSDTM datetime20. |                 |           ***;
***          |                                                        |                 |           ***;
***----------|--------------------------------------------------------|-----------------|-----------***;
*** DEBUG    | Used for debugging - if it is given as Y, the          |     N           |   No      ***; 
***          |  intermediate datasets will not be deleted             |                 |           ***;
***-------------------------------------------------------------------------------------------------***;
*** Output(s):                                                                                      ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Data sets:          &dsn.                                                                       ***;
***                                                                                                 ***;
*** Variables:          None                                                                        ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Dependencies                                                                                    ***;
***                                                                                                 ***;
*** Data sets:          None                                                                        ***;
***                                                                                                 ***;
*** Macro Variables:    None                                                                        ***;
***                                                                                                 ***;
*** Macros:             None                                                                        ***;
***                                                                                                 ***;
*** Other:              1) if parameter - DESC is passed, the dataset will be updated with label    ***;
***                     else the dataset will be created with old label                             ***;
***                                                                                                 ***;
***                     2) if parameter - FRMT is passed, the dataset will be updated with format   ***;
***                     for variables and format/ informat values, else the variables will be       ***;
***                     created without format / informat                                           ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;

%macro qc_reduce_length(dsn,
						desc,
						frmt,
						DEBUG=N); 

/*Executing only if Dataset exists*/
%if %sysfunc(exist(&dsn.)) %then 
    %do;
      
   
        data &dsn.;
            set &dsn;
        run;

        %let OBS=&sysnobs.;

        /* Reducing length only if dataset has records*/
        %if &obs. gt 0 %then 
            %do;


                data _null_;
                    set &dsn; 
                    array qqq(*) _character_;
                    call symput('siz',put(dim(qqq),5.-L));
                    stop;
                run;

                data _null_;
                    set &dsn end=done;
                    array qqq(&siz) _character_;
                    array www(&siz.);
                    if _n_=1 then do i= 1 to dim(www);
                        www(i)=0;
                    end;
                    do i = 1 to &siz.;
                        www(i)=max(www(i),length(qqq(i)));
                    end;
                    retain _all_;
                    if done then 
                        do;
                            do i = 1 to &siz.;
                                length vvv $50;
                                vvv=vname(qqq(i))|| ' char(' || compress(put(www(i),best.)) || ')';
                                if i ne &siz. then vvv=strip(vvv) || ', ';
                                call symput('lll'||put(i,3.-L),vvv) ;
                            end;
                        end;
                run;

                proc sql;
                    alter table &dsn.
                    modify 
                        %do i = 1 %to &siz.;
                            &&lll&i
                        %end;
                    ;
                quit;

                run;
                
                /* Assigning Label based on desc parameter */
                %if "&desc." ne "" %then 
                    %do;
                        data &dsn (label=&desc);
                            set &dsn;
                            informat _all_;
                            format _all_;

                            %if "&frmt." ne "" %then 
                                %do;
                                    &frmt. ;
                                %end;

                        run; 
                %end;

                %else
                    %do;
                        data &dsn;
                            set &dsn;
                            informat _all_;
                            format _all_;

                            %if "&frmt." ne "" %then 
                                %do;
                                    &frmt. ;
                                %end;

                        run; 
                %end;

            %end;

        %else 
            %do;
                /* Setting length as 1 - if no records is present */
                proc contents data =&dsn. out=WORK.CON1 noprint;
                run;

                proc sql noprint;
                    create table CHR as select name from WORK.CON1 where type eq 2;         
                quit;

                data chr1;
                    set chr;
                    length upd_var $2000. vname $40.;
                    vname = strip(name)||" char(1)";

                    if _n_ eq 1 then upd_var = VNAME;
                    else upd_var = strip(upd_var)||' , '||strip(vname);
                    retain upd_var;

                    call symputx('UPD_LEN',upd_var);
                run;

                proc sql noprint;
                    alter table &dsn. modify &UPD_LEN.;
                quit;
                
                /* Assigning Label based on desc parameter */
                %if "&desc." ne "" %then 
                    %do;
                        data &dsn (label=&desc);
                            set &dsn;
                            informat _all_;
                            format _all_;

                            %if "&frmt." ne "" %then 
                                %do;
                                    &frmt. ;
                                %end;

                        run; 
                %end;

                %else
                    %do;
                        data &dsn;
                            set &dsn;
                            informat _all_;
                            format _all_;

                            %if "&frmt." ne "" %then 
                                %do;
                                    &frmt. ;
                                %end;
                        run; 
                %end;

            %end;
            
        /*Deleting Intermediate datasets created*/
        %if "&DEBUG." ne "Y" %then
            %do;
                /*Deleting Intermediate datasets created*/
                proc datasets lib=WORK nolist;
                    delete CON1 CHR CHR1 ;
                    quit;
                run;
            %end;
    
    %end;
%else
    %do;
        /*Raising a Log note if Dataset not exists*/
        %put Dataset &DSN. does not exists.;
    %end;


%mend qc_reduce_length;
