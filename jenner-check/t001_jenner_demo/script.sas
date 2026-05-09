/* ----------------------------------------------------------------- *
 * Small Jenner demo — SDTM-style demographics summary.
 *   * builds a tiny DM-like dataset inline (no external data needed)
 *   * derives an age-group flag the way an ADaM step might
 *   * shows counts by treatment arm and age group with PROC FREQ
 * Runs in a couple of seconds.
 * ----------------------------------------------------------------- */

data dm;
    length USUBJID $11 ARM $12 SEX $1 AGEGRP $7;
    input USUBJID $ ARM $ AGE SEX $;
    if AGE < 18 then AGEGRP = "<18";
    else if AGE < 65 then AGEGRP = "18-64";
    else AGEGRP = ">=65";
    datalines;
STUDY-001-01 PLACEBO     45 F
STUDY-001-02 PLACEBO     52 M
STUDY-001-03 PLACEBO     67 F
STUDY-001-04 PLACEBO     33 M
STUDY-001-05 PLACEBO     71 F
STUDY-002-01 ACTIVE_LOW  29 F
STUDY-002-02 ACTIVE_LOW  44 M
STUDY-002-03 ACTIVE_LOW  58 F
STUDY-002-04 ACTIVE_LOW  62 M
STUDY-002-05 ACTIVE_LOW  74 F
STUDY-003-01 ACTIVE_HIGH 38 M
STUDY-003-02 ACTIVE_HIGH 47 F
STUDY-003-03 ACTIVE_HIGH 55 M
STUDY-003-04 ACTIVE_HIGH 68 F
STUDY-003-05 ACTIVE_HIGH 73 M
;
run;

title "Demographics by treatment arm";
proc freq data=dm;
    tables ARM*AGEGRP / nocum nopercent;
run;

title "Mean age by arm";
proc means data=dm n mean min max maxdec=1;
    class ARM;
    var AGE;
run;

title;
