****************************************************************************************;
* ESTABLISH BESTAIR OPTIONS AND LIBRARIES
****************************************************************************************;
%include "\\rfa01\bwh-sleepepi-bestair\Data\SAS\bestair options and libnames.sas";


***************************************************************************************;
* IMPORT BESTAIR ELIGIBILITY DATA FROM REDCAP
***************************************************************************************;

*import data from two different arms simultaneously to conserve computation time;
  data bestair_elig_info(drop = rand_date anth_namecode) rand_set(keep = elig_studyid rand_date anth_namecode) ;
    set bestair.baredcap_nomiss;

    if 60000 le elig_studyid le 99999 and redcap_event_name = "screening_arm_0"
      then output bestair_elig_info;

    if 60000 le elig_studyid le 99999 and rand_date > .
      then output rand_set;

    keep elig_studyid--eligibility_complete journal_dayscompleted journal_daysmaskused rand_date anth_namecode;
  run;

*merge randomization information into eligibility dataset;
  data bestaireligibility;
    merge bestair_elig_info rand_set;

    by elig_studyid;

  run;

  data bestaireligibility_fix;
    set bestaireligibility;

    array numeric_vars[*] _numeric_;
    array char_vars[*] _character_;

    do i = 1 to dim(numeric_vars);
      if (numeric_vars[i] < -2 and vname(numeric_vars[i]) ne "elig_incl01dob") then numeric_vars[i] = .;
    end;

    do j = 1 to dim(char_vars);
      if char_vars[j] in ("-8","-9", "-10") then char_vars[j] = "";
    end;

    drop  embqs_study_id--embletta_qs_complete eligibility_complete i j;
  run;

  proc format;
    value randomized_educationf
    1 = "1: Did not complete high school or equivalent"
    2 = "2: High school graduate"
    3 = "3: At least Bachelors"
    ;
    value race_whitenonhispanicf
    0 = "0: Not [White, Not Hispanic or Latino]"
    1 = "1: White, Not Hispanic or Latino"
    ;
    value CVDstatus_primaryf
    0 = "0: CVD Risk Factors Only"
    1 = "1: Established CVD"
    ;
  run;

  data bestaireligibility_final;
    retain elig_studyid randomized;
    set bestaireligibility_fix;

    if rand_date > . then randomized = 1;
    else randomized = 0;

    format randomized_education randomized_educationf.;

    if randomized = 1 then do;
      if elig_education < 0 or elig_education > 2 then randomized_education = 3;
      else randomized_education = elig_education;

      age_atbaseline = year(rand_date) - year(elig_incl01dob) - 1;
      if month(rand_date) > month(elig_incl01dob) then age_atbaseline = age_atbaseline + 1;
      else if month(rand_date) = month(elig_incl01dob) then do;
        if day(rand_date) ge day(elig_incl01dob) then age_atbaseline = age_atbaseline + 1;
      end;
    end;

    format race_whitenothispanic race_whitenonhispanicf.;

    array check4whitenh[*] elig_raceamerind--elig_raceblack elig_raceother elig_ethnicity;

    do i = 1 to dim(check4whitenh);
      if check4whitenh[i] = 1 then race_whitenothispanic = 0;
    end;

    if race_whitenothispanic = . then do;
      if elig_racewhite = 1 then race_whitenothispanic = 1;
    end;

    format CVDstatus_primary CVDstatus_primaryf.;

    array establishedCVD_criteria[*] elig_incl04ami--elig_incl04ddiabetes elig_incl04ediabetes;

    if elig_incl04cvd = 1 then do;
      do j = 1 to dim(establishedCVD_criteria);
        if establishedCVD_criteria[j] = 1 then CVDstatus_primary = 1;
      end;
      if CVDstatus_primary = . then CVDstatus_primary = 0;
    end; 

    format runin_daysmask_ge13 yesnof.;
    if journal_daysmaskused ge 13 then runin_daysmask_ge13 = 1;
    else if journal_daysmaskused ne . then runin_daysmask_ge13 = 0;

    drop journal_dayscompleted journal_daysmaskused rand_date anth_namecode i j;
  run;

  data bestair.bestaireligibility;
    set bestaireligibility_final;
  run;


*****************************************************************************************;
* DATA CHECKING
*****************************************************************************************;

*create tables of randomized participants missing demographic info;

  proc sql;

    title "Randomized, Missing Age";
      select elig_studyid, anth_namecode from bestaireligibility where rand_date > . and (elig_incl01age < 1 or elig_incl01age = .);
      title;

    title "Randomized, Missing DOB";
      select elig_studyid, anth_namecode from bestaireligibility where (rand_date > . and elig_incl01dob = .);
      title;

    title "Randomized, Missing Gender";
      select elig_studyid, anth_namecode from bestaireligibility where rand_date > . and (elig_gender < 1 or elig_gender = .);
      title;

    title "Randomized, Missing Race";
      select elig_studyid, anth_namecode
      from bestaireligibility
      where rand_date > . and ((elig_raceamerind < 0 or elig_raceamerind = .) or (elig_raceasian < 0 or elig_raceasian = .) or (elig_racehawaiian < 0 or elig_racehawaiian = .)
                    or (elig_raceblack < 0 or elig_raceblack = .) or (elig_racewhite < 0 or elig_racewhite = .) or (elig_raceother < 0 or elig_raceother = .));
      title;

    title "Randomized, Marked 'Other Race', No Race listed";
      select elig_studyid, anth_namecode from bestaireligibility where rand_date > . and (elig_raceother = 1 and (elig_raceotherspecify = '-8' or elig_raceotherspecify = '-9'
        or elig_raceotherspecify = '-10'));
      title;

    title "Randomized, Missing Ethnicity";
      select elig_studyid, anth_namecode from bestaireligibility where rand_date > . and (elig_ethnicity < 1 or elig_ethnicity = .);
      title;

    title "Randomized, Missing Education";
      select elig_studyid, anth_namecode from bestaireligibility where rand_date > . and (elig_education < 1 or elig_education = .);
      title;

  quit;

  data bestairreport;
    set bestaireligibility;

    if 60000 le elig_studyid le 79999 then site = 1;
    else if 80000 le elig_studyid le 89999 then site = 2;
    else site = 3;

    array incl_fixer[*] elig_incl01agerange elig_incl02infconsent elig_incl03osa elig_incl04cvd;
    do i = 1 to dim(incl_fixer);
      if incl_fixer[i] ne 2
        then incl_fixer[i] = .;
    end;

    array excl_fixer[*] elig_excl01ejec--elig_excl07pap elig_excl08sixhrsbed--elig_excl09epworth elig_excl10driver--elig_excl12refusal elig_meetstatus
                        elig_notinterested--elig_otherreason elig_physiciandoesnotgrant;
    do j = 1 to dim(excl_fixer);
      if excl_fixer[j] ne 1
        then excl_fixer[j] = .;
    end;

    if elig_partstatus = 1 then elig_partstatusagree = 1;
    else elig_partstatusagree = .;

    if elig_partstatus = 2 then elig_partstatusdnagr = 1;
    else elig_partstatusdnagr = .;

    drop i j;

  run;

%include "\\rfa01\bwh-sleepepi-bestair\Data\SAS\eligibility\bestair_eligibility_macros.sas";

  *create table that sorts eligibility data by source and other criteria;
    proc sql;
    create table bestairreport_out (total smallint, inc01 smallint, inc02 smallint, inc03 smallint,
                  inc04 smallint,
                  exc01 smallint, exc02 smallint, exc03 smallint, exc04 smallint,
                  exc05 smallint, exc06 smallint, exc07 smallint, exc08 smallint,
                  exc09 smallint, exc10 smallint, exc11 smallint, exc12 smallint,
                  meets smallint, agree smallint, dnagr smallint, dnres smallint, dnbus smallint,
                  dnwrk smallint, dntra smallint, dndis smallint, dntst smallint,
                  dnpas smallint, dnpap smallint, dnoth smallint, dnphy smallint);

    *eligtable_insertmacro, found in "bestair_eligibility_macros.sas", selects and renames variables to be inserted in table;

    %eligtable_insertmacro()
    from bestairreport;

    %eligtable_insertmacro()
    from bestairreport
    where 45 le elig_incl01age le 54;

    %eligtable_insertmacro()
    from bestairreport
    where 55 le elig_incl01age le 75;

    %eligtable_insertmacro()
    from bestairreport
    where site = 1;

    %eligtable_insertmacro()
    from bestairreport
    where site = 2;

    %eligtable_insertmacro()
    from bestairreport
    where elig_source = 1 and elig_meetstatus = 1;

    %eligtable_insertmacro()
    from bestairreport
    where elig_source = 2 and elig_meetstatus = 1;

    %eligtable_insertmacro()
    from bestairreport
    where elig_source = 3 and elig_meetstatus = 1;

    %eligtable_insertmacro()
    from bestairreport
    where elig_source = 4 and elig_meetstatus = 1;

    %eligtable_insertmacro()
    from bestairreport
    where elig_source = 5 and elig_meetstatus = 1;

    %eligtable_insertmacro()
    from bestairreport
    where elig_source = 6 and elig_meetstatus = 1;

    %eligtable_insertmacro()
    from bestairreport
    where elig_meetstatus = 1;

  quit;


  * output table data into csv;
  PROC EXPORT DATA= bestairreport_out
              OUTFILE= "\\rfa01\bwh-sleepepi-bestair\Data\SAS\eligibility\bestairreport_out_&sasfiledate..csv"
              DBMS=CSV LABEL REPLACE;
       PUTNAMES=YES;
  RUN;
