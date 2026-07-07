***-------------------------------------------------------------------------------------------------***;
*** Program Name:       run_macro_test.sas                                                          ***;
***                                                                                                 ***;
*** Purpose:            Local runner to execute Adamski macro test programs and validation code.    ***;
***                     Supports testing multiple macros from a single program.                     ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Programmed By:      Manivannan Mathialagan                                                      ***;
*** Created On:         07Jul2026                                                                   ***;
***                                                                                                 ***;
***-------------------------------------------------------------------------------------------------***;
*** Modification History                                                                            ***;
***-------------------------------------------------------------------------------------------------***;
*** Date        | Modified By          | Description                                                ***;
***-------------|----------------------|------------------------------------------------------------***;
*** 07Jul2026   | Manivannan           | Initial version created.                                  ***;
***-------------------------------------------------------------------------------------------------***;

/* Personal Repository Location - to store autoexec programs and testing codes */
%let PERSONAL_REPO = P:\BSP_LocalDev\Manivannan.Mathialag\zzzz_My_SAS_Files\My GitHub\systems-nexus\adamski checks;

/* ADAMSki Repository Location */
%let ADAMSKI_REPO  = P:\BSP_LocalDev\Manivannan.Mathialag\zzzz_My_SAS_Files\My GitHub\adamski\adamski;

/* Including autoexec program */
%include "&PERSONAL_REPO.\adamski_autoexec.sas";

***---------------------------------------------------------------***;
*** Macro:              derive_var_analysis_ratio                 ***;
*** Branch:             feature/derive_var_analysis_ratio         ***;
***---------------------------------------------------------------***;

%include "&ADAMSKI_REPO.\06_macro\derive_var_analysis_ratio.sas";

%include "&PERSONAL_REPO.\001_check_derive_var_analysis_ratio.sas";

***---------------------------------------------------------------***;
*** Macro:              derive_var_pchg                           ***;
*** Branch:             feature/derive_var_pchg                   ***;
***---------------------------------------------------------------***;

%include "&ADAMSKI_REPO.\06_macro\derive_var_pchg.sas";

%include "&PERSONAL_REPO.\002_check_derive_var_pchg.sas";

