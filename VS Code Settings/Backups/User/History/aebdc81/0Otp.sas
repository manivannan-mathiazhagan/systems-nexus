dm "log;clear;lst;clear";
************************************************************************************;
* VERISTAT INCORPORATED                                                     
************************************************************************************;
* PROGRAM:    P:\Projects\Cook MyoSite\DIFI - 22-01\Biostats\DSMB\Figures\f-14-3-2-vs.sas  
* DATE:       21Jul2025
* PROGRAMMER: Shashi
*
* PURPOSE:    Mean Plot of Vital Signs by Timepoint (Safety Set)
*
************************************************************************************;
* MODIFICATIONS: 
*   PROGRAMMER: 
*   DATE:       
*   PURPOSE:    
************************************************************************************;  
%let pgm=f-14-3-2-vs; 
%let pgmnum=14.3.2;  
%let pgmqc=f_14_3_2_vs; 
%let protdir=&difi2201dsmb;   
 
%include "&protdir\macros\m-setup.sas";   

proc format;
  value trt
    1 = "Iltamiocel"
    2 = "Placebo"
    3 = "Overall";
  value vstpt_fmt
    1 = "Pre Procedure"
    2 = "Post Procedure";
run;

*===============================================================================
* 1. Bring in ADVS and compute Mean � 95% CI
*===============================================================================;

data advs;
set ads. advs;
trtp="Overall";
trtpn=3;
 where saffl='Y' and paramcd ne "HGT";
run;

proc sort ;
  by trtp paramn param paramcd avisitn avisit vstptnum vstpt;
  
run;
proc means data=advs noprint;
  by trtp paramn param paramcd avisitn avisit vstptnum vstpt;
  var aval;
  output out=advs_mean n=n mean=mean stddev=std;
run;

data advs_mean;
	length VISIT_DIS $200.;
  set advs_mean;
  if n > 0 and std > . then do;
    stderr = std / sqrt(n);
    lower  = mean - 1.96 * stderr;
    upper  = mean + 1.96 * stderr;
  end;
  newvisn = avisitn + (vstptnum *0.1);

  if newvisn eq 10.1 then VISIT_DIS = "SCR"	; else
  if newvisn eq 20.1 then VISIT_DIS = "BIOPSY!n PRE"	; else
  if newvisn eq 20.2 then VISIT_DIS = "BIOPSY POST"	; else
  if newvisn eq 40.1 then VISIT_DIS = "INJ PRE"	; else
  if newvisn eq 40.2 then VISIT_DIS = "INJ POST"	; else
  if newvisn eq 60.1 then VISIT_DIS = "WK1"	; else
  if newvisn eq 90.1 then VISIT_DIS = "MN6"	; else
  if newvisn ne . and AVISIT ne "Rescreening" then do; put "WAR" "NING: Need to review Code for Visit: " avisit; end;

  where n >= 3 and avisit ne "Unscheduled Visit";
run;

*===============================================================================
* 2. Define Attribute Map for Treatment Colors and Markers
*===============================================================================;
data myattrmap;
  length id $8 value $20 markercolor $20 linecolor $20 markersymbol $20;
  input id $ value $ markercolor $ linecolor $ markersymbol $;
  datalines;
TRTPC   Placebo       red     red     Circle
TRTPC   Iltamiocel    blue    blue    Triangle
;
run;

*===============================================================================
* 3. ODS Setup and Titles
*===============================================================================;
options orientation=landscape nobyline;
ods escapechar = "!";  
%calltf(); 
ods _all_ close;

ods rtf file="&outdat\open session\&pgm..rtf" style=style1 nogtitle nogfootnote;
ods graphics / height=4.5in width=8.5in border=off imagefmt=png;
*===============================================================================
* TITLES AND FOOTNOTES (STATIC) - COMMON TO ALL PANELS
*===============================================================================;
title1 j=l "Cook MyoSite, Inc." j=c "Confidential" j=r "Page !{pageof}";
title2 j=l "Protocol: DIFI 22-01";
title3 j=l "DATA EXTRACT DATE: &datacut." j=r " ";
title4 j=c "Figure &pgmnum";
title5 j=c "Mean Plot of Vital Signs by Timepoint";
title6 j=c "(Safety Set)";

footnote1 j=l "Source: Listing 16.2.7.2!n";
footnote2 j=l "&ft99";

*===============================================================================
* PREPARE FORMATTED X-AXIS LABELS USING A FORMAT
*===============================================================================;
proc sort data=advs_mean out=advs_sorted;
  by paramN newvisn;
run;

proc sql noprint;
  select distinct put(newvisn, best12.) || '=' || quote(strip(VISIT_DIS))
  into :fmtlist separated by ' '
  from advs_sorted
  where not missing(vstpt);
quit;

proc format;
  value $visfmt
    &fmtlist;
run;

*===============================================================================
* GENERATE PANELLED PLOTS WITH PARAM TITLE AND CUSTOM X-AXIS LABELS
*===============================================================================;

data _null_;
  set advs_sorted;
  by paramN;
  if first.paramN then call symputx('thisparam', strip(put(paramN,best.)));
  if last.paramN then do;
    call execute('
      title7 j=l "Parameter: ' || strip(param) || '";
      proc sgplot data=advs_sorted(where=(paramcd="' || strip(paramcd) || '"));
        styleattrs datalinepatterns=(solid shortdash)
                   datasymbols=(circle triangle)
                   datacolors=(blue red)
                   datacontrastcolors=(blue red);
        
        /* Line plot with error bars */
        series x=newvisn y=mean / group=trtp markers
               lineattrs=(thickness=2) name="series" groupdisplay=cluster   clusterwidth=0.4;
        
        highlow x=newvisn low=lower high=upper / group=trtp 
                lineattrs=(pattern=solid thickness=1) name="hlow" groupdisplay=cluster   clusterwidth=0.4;

        /* Scatter points with CI */
        scatter x=newvisn y=mean / group=trtp 
                yerrorlower=lower yerrorupper=upper 
                name="scatter" groupdisplay=cluster   clusterwidth=0.4;

        xaxis label=" " type=discrete discreteorder=data
              valueshint values=(10.1 20.1 20.2 40.1 40.2 60.1 90.1)
              valuesdisplay=("SCR" "BIOPSY PRE" "BIOPSY POST" "INJ PRE" "INJ POST" "WK1" "MN6")
              valueattrs=(size=8) fitpolicy=rotate 
              labelattrs=(family="Arial" size=10pt) offsetmin=0.1;

        yaxis label="Mean Value with 95% CI" 
              labelattrs=(family="Arial" size=10pt) valueattrs=(size=8) grid;

        keylegend "series" / location=outside position=bottom 
                   valueattrs=(family="Arial" size=10pt) ;

      run;
      title7;
    ');
  end;
run;



ods rtf close;
ods listing;
