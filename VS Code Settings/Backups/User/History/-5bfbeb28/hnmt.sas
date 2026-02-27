dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-3-1-10-sae-brel.sas    
* DATE:       31DEC2024
* PROGRAMMER: Laurie Drinkwater
*
* PURPOSE:      Summary of Biopsy Procedure-Related Serious Adverse Events by System Organ Class and Preferred Term 
*               (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*   PROGRAMMER:   
*   DATE:           
*   PURPOSE:      
************************************************************************************;     
%let pgm=t-14-3-1-10-sae-brel; 
%let pgmnum=14.3.1.10; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu;   

%include "&protdir\macros\m-setup.sas"; 
%let subgrp=%str( if (index(upcase(AESER),'YES')>0 )and index(upcase(aerel2),'POS')>0 or index(upcase(aerel2),'PRO')>0 or index(upcase(aerel2),'DEF')>0  and lowcase(aeser)='yes');   

*===============================================================================
* 1. Include required table program. 
*===============================================================================;
%include "&outdat\macros\mt-14-3-1-ae-bio_NEW.sas";  
