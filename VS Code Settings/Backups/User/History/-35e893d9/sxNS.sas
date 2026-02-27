dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\_Restricted\Figures\f-14-3-3-lb.sas  
* DATE:       31Jul2025
* PROGRAMMER: Manivannan Mathialagan
*
* PURPOSE:    Maximum Post-Baseline Clinical Chemistry (SAFFL Population)
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER: 
*   DATE:       
*   PURPOSE:    
************************************************************************************;  
%let pgm=f-14-3-3-lb; 
%let pgmnum=14.3.3;  
%let pgmqc=f_14_3_3_lb; 
%let protdir=&difi2201dsmbu;   
 
%include "&protdir\macros\m-setup.sas";   

*===============================================================================
* 1. Bring in ADLB. 
*===============================================================================;
proc sort data= ads.adlb out = adlb;
	by usubjid paramcd aval adt atm ;
	where saffl='Y' and parcat1='CHEMISTRY' and (ady>=1 and ablfl~='Y' ) /* and paramcd in ("ALT" "AST" "ALP" "TBILI" ) */ ;
run;

data max;
	set adlb;
	by usubjid paramcd aval adt atm;
	if last.paramcd;
	ratio=aval/LBSTNRHI;
run;
 
proc sql;
	create table trtp_n as
	select trtp, count(distinct usubjid) as n
	from adlb
	group by trtp;
quit;

data _null_;
  set trtp_n;
  call symputx(cats("fmt_", strip(trtp)), cats(trtp, " (N=", n, ")"));
run;


proc format ;
	value trt
	1="Iltamiocel"
	2="Placebo"
	;
	
	value $trtpn
	"Iltamiocel" = "&fmt_Iltamiocel"
	"Placebo"    = "&fmt_Placebo"
	;
run;

data myattrmap;
  length ID $8 value $50 fillcolor linecolor linepattern markercolor markersymbol $20;
  ID = "TRTPC";

  value = symget("fmt_Iltamiocel"); fillcolor="blue"; linecolor="blue"; linepattern="solid"; markercolor="blue"; markersymbol="circle"; output;
  value = symget("fmt_Placebo");    fillcolor="red";  linecolor="red";  linepattern="solid"; markercolor="red";  markersymbol="triangle"; output;
run;
options orientation=landscape nobyline;  
ods escapechar = "!";  
%calltf(); 
ods _all_ close;
ods rtf file="&protdir.\figures\&pgm..rtf"  style=style1 nogtitle nogfootnote;   
ods graphics / height=4in width=9in border=off imagefmt=png;    

title1 j=l "Cook MyoSite, Inc." j=c "Confidential" j=r "Page !{pageof}";
title2 j=l "Protocol: DIFI 22-01";
title3 j=l "DATA EXTRACT DATE: &datacut." j=r " ";
title4 j=c "Figure 14.3.3";
title5 j=c "Box Plot of Clinical Chemistry Laboratory Results -- Maximum Post-Baseline";
title6 j=c "(Safety Set)";

footnote1 j=l "!S={bordertopwidth=1}ULN = Upper Limit of Normal.";
footnote2 j=l "Source: Listing 16.2.7.4!n";
footnote3 j=l "&ft99";

proc sgplot data=max dattrmap=myattrmap;
	vbox ratio / category=param group=trtp attrid=TRTPC
			  fillattrs=(transparency=1)
			  lineattrs=(pattern=solid)
			  whiskerattrs=(pattern=solid)
			  groupdisplay=cluster grouporder=ascending clusterwidth=0.4;

	refline 1 2 / axis=y lineattrs=(color=green pattern=shortdash thickness=2);

	keylegend / title="" location=outside position=bottom across=2;

	xaxis label="Parameter";
	yaxis label="Maximum (/ULN)" values=(0 to 2 by 0.5);

	format trtp $trtpn.;
run;

ods rtf close;
ods listing;

data qcfig.&pgmqc;
	set max;;
	format _all_;
	informat _all_;
	keep usubjid parcat1 paramcd param trtpn trtp adt atm aval ratio lbstnrhi;
run;
