dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Tables\t-14-3-1-4-sae.sas    
* DATE:       31DEC2024
* PROGRAMMER: Laurie Drinkwater
*
* PURPOSE:      Summary of Serious Adverse Events by System Organ Class and Preferred Term 
*               (Safety Set)
*
************************************************************************************;
* MODIFICATIONS:  
*   PROGRAMMER:   
*   DATE:           
*   PURPOSE:      
************************************************************************************;     
%let pgm=t-14-3-1-4-sae; 
%let pgmnum=14.3.1.4; 
%let pgmqc=%sysfunc(translate(&pgm,'_','-')); 
%let protdir=&difi2201dsmbu;   

%include "&protdir\macros\m-setup.sas";  
%let subgrp=%str(if upcase(aeser)='YES');  

*===============================================================================
* 1. Include required table program. 
*===============================================================================;
%include "&outdat\macros\mt-14-3-1-ae_new.sas";  
