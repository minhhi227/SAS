* Program reclass.macros.v4.sas for BINARY data;
* Created by Nancy Cook (BWH, HMS, HSPH);
* Macros for Reclassification Statistics for Binary Outcomes;
* Macro RECLASS for Hosmer-Lemeshow-like Reclassification Calibration Statistics;
* Macro NRICAT to compute net reclssification improvement (NRI);
* Uses non-null variance;
* Macro CONTNRI for continuous NRI;
* Macro IDIMACRO to compute integrated discrimination improvement (IDI);
* DETAIL = 2 for detailed output, 1 for limited, 0 for none (eg., to save in a file);

* EXAMPLE USAGE OF MACROS;
* %reclass(probs,1,outxy,pdx,pdxy,4,0.05,0.10,0.20);
* %reclass(probs,1,outxy,pdx,pdxy,4,0.05,0.10,0.20,test=1);
* %nricat(probs,1,outxy,pdx,pdxy,4,0.05,0.10,0.20);
* %idimacro(probs,1,outxy,pdx,pdxy);
* %contnri(probs,1,outxy,pdx,pdxy);

****************************************************************;

%macro RECLASS(DSNAME,DETAIL,STATVAR,PROB1,PROB2,NCAT,C1,C2,C3,C4,C5,C6,C7,C8,C9,TEST=0);
*  Macro to compute calibration statistics for KxK (K=NCAT) table;
*  Formed using categs of predicted probs (eg 0, 5, 10, 20%);
*  Counts categs for DF;
*  Computes statistics for all and for cells with n>=20;
*  Allows up to 10 categories (usually 3 or 4);
*  Allows extra for test data -> specify TEST=1 in macro call;

*  Variables:
*  DSNAME = dataset name;
*  DETAIL = 2 for detailed printout, 1 for limited, 0 for none;
*  STATVAR = outcome variable (coded 0,1);
*  PROB1 = probability for model 1;
*  PROB2 = probability for model 2;
*  NCAT = number of categories in classification;
*  C1-C9 = category cutpoints (there should be ncat-1 cutpoints);


title2 Reclassification for &NCAT Categories with CutPoints = %do j = 1 %to &ncat; &&c&j %end;;

   data calc; set &DSNAME;
   stat=&STATVAR;
   prob1=&PROB1;
   prob2=&PROB2;
   * compute product terms for J statistic;
   var1=prob1*(1-prob1);
   var2=prob2*(1-prob2);
   k=&ncat;
   if prob1>. and prob2>.;

   * compute categories - set to above cutpoints;
   %do i=1 %to &ncat-1;
     cut&i=&&c&i;
   %end;
   cut&ncat=1.01;
      
   array cut {10} cut1-cut10;
   array pcat {10} pcat1-pcat10;
   if .<prob1<cut1 then pcat1=1;
   if .<prob2<cut1 then pcat2=1;
   do i=2 to &ncat;
     if cut(i-1)<=prob1<cut(i) then pcat1=i;
     if cut(i-1)<=prob2<cut(i) then pcat2=i;
   end;

   * look at number of categories moved;
   diffcat=pcat2-pcat1;
   * truncate diffcat;
   if diffcat>2 then diffcat2=2;
      else if .<diffcat<-2 then diffcat2=-2;
      else diffcat2=diffcat;
   run;


   *** check output needed;
   %if &detail=2 %then %do;
   proc freq data=calc;
   tables pcat1*pcat2;
   title3 "Reclassification table for &PROB2 vs &PROB1";
   run;
   %end;

   ods listing exclude all;
   ods output CrossTabFreqs=classfreqs;
   proc freq data=calc;
   tables pcat1*diffcat2;
   title3 "Reclassification table for &PROB2 vs &PROB1";
   run;

   proc sort data=classfreqs; by pcat1;
   data reclass; set classfreqs; by pcat1;
   retain pctup1 pctup2 pctd1 pctd2 pctsame;
   if first.pcat1 then do;
      pctup1=0; pctup2=0; pctd1=0; pctd2=0; pctsame=0;
   end;
   if diffcat2=0 then pctsame=RowPercent;
     else if diffcat2=1 then pctup1=RowPercent;
     else if diffcat2=2 then pctup2=RowPercent;
     else if diffcat2=-1 then pctd1=RowPercent;
     else if diffcat2=-2 then pctd2=RowPercent;
   if pcat1=. then do;
     if diffcat2=0 then pctsame=Percent;
     else if diffcat2=1 then pctup1=Percent;
     else if diffcat2=2 then pctup2=Percent;
     else if diffcat2=-1 then pctd1=Percent;
     else if diffcat2=-2 then pctd2=Percent;
   end;
   if last.pcat1 then do;
     pctup=pctup1+pctup2;
     pctdown=pctd1+pctd2;
     pctreclass=100-pctsame;
     * compute categories again - set to above cutpoints;
     ncat=&ncat;
     %do i=1 %to &ncat-1;
         cut&i=&&c&i;
     %end;
     if &ncat<10 then do;
       %do i=&ncat %to 9;
         cut&i=.;
       %end;
     end;
     keep ncat cut1-cut9 pcat1 pctup1 pctup2 pctd1 pctd2 pctup pctdown pctsame pctreclass;
     output;
   end;  
   run;
   ods listing exclude none;
   run;
   %if &detail>0 %then %do;
   proc print data=reclass;
   run;
   %end;
      
   %if &detail=2 %then %do;
    proc freq data=calc;
    tables pcat1*pcat2*stat/ list;
    title3 "Calibration table for &PROB2 vs &PROB1";
    run;
   %end;
   
   ods listing exclude all;
   ods output Summary=calibs;
   proc means data=calc n sum mean median min max;
     * Eliminate missing from all variables;
     where stat ne . and prob1 ne . and prob2 ne .;
     class pcat1 pcat2;
     types pcat1*pcat2;
     var prob1 prob2 var1 var2 stat k; 
   run;
   
   /* Compute 10-year risks from 8-year if necessary;
   data risk10; set calibs;
     risk1_10=1-(1-prob1_Mean)**1.25;
     risk2_10=1-(1-prob2_Mean)**1.25;
     stat_10=1-(1-stat_Mean)**1.25;
   run;
   proc print data=risk10;
   var pcat1 pcat2 stat_N stat_Sum prob1_Mean prob2_Mean stat_Mean
       risk1_10 risk2_10 stat_10;
   title3 "Estimated 8 and 10-Year Risks";
   run;
   */

   ods listing exclude none;
   run;
   %if &detail>0 %then %do;
   proc print data=calibs;
   var pcat1 pcat2 stat_N stat_Sum prob1_Mean prob2_Mean
       stat_Mean var1_Sum var2_Sum;
   title3 "Estimated Risks";
   run;
   %end;
   
   data calterms calstats(keep= ncat maxcat dfmax nccat df chisq1 pcalib1
            chisq_adj1 pcal_adj1 chisq2 pcalib2 chisq_adj2 pcal_adj2 
            dfj jsq1 pj1 jsq_adj1 pj_adj1 jsq2 pj2 jsq_adj2 pj_adj2) ; 
     set calibs end=eof;
     retain chisq1 chisq_adj1 chisq2 chisq_adj2
            jsq1 jsq_adj1 jsq2 jsq_adj2 nccat nreclass ncorr 0;
     num1=(stat_Sum - prob1_Sum)**2;
     denom1=prob1_Sum*(1-prob1_Mean);
     denom12=(prob1_Sum+1)*(1-prob1_Mean+1/prob1_N);
     chisq1=chisq1 + num1/denom1;
     chisq_adj1=chisq_adj1 + num1/denom12;
     phi1=var1_Sum/denom1;
     jsq1=jsq1 + num1/(phi1*denom1);
     * Note: evaluate adjusted Jsq, but do not print;
     jsq_adj1=jsq_adj1 + num1/(phi1*denom12);
     num2=(stat_Sum - prob2_Sum)**2;
     denom2=prob2_Sum*(1-prob2_Mean);
     denom22=(prob2_Sum+1)*(1-prob2_Mean+1/prob2_N);
     chisq2=chisq2 + num2/denom2;
     chisq_adj2=chisq_adj2 + num2/denom22;
     phi2=var2_Sum/denom2;
     jsq2=jsq2 + num2/(phi2*denom2);
     jsq_adj2=jsq_adj2 + num2/(phi2*denom22);
     nccat=nccat+1;

     OEratio1=stat_Sum/prob1_Sum;
     OEratio2=stat_Sum/prob2_Sum;
     if stat_Sum>0 then do;
       sdo=sqrt(1/stat_Sum);
       OEcil1=OEratio1*exp(-1.96*sdo);
       OEciu1=OEratio1*exp(1.96*sdo);
       OEcil2=OEratio2*exp(-1.96*sdo);
       OEciu2=OEratio2*exp(1.96*sdo);
     end;
    
     * compute those reclass correctly;
     if pcat2 ne pcat1 then nreclass=nreclass+stat_N;
     %do i=1 %to &ncat-1;
        cut&i=&&c&i;
        if pcat2>pcat1 and pcat2=&i+1 then do;
            * put pcat2= pcat1= cut&i= stat_Sum= stat_Mean= stat_N=;
            if stat_Mean>=cut&i then ncorr=ncorr+stat_N;
        end;
        else if pcat2<pcat1 and pcat2=&i then do;
            * put pcat2= pcat1= cut&i= stat_Sum= stat_Mean= stat_N=;
            if stat_Mean<cut&i then ncorr=ncorr+stat_N;
        end;
     %end;

     output calterms;
     if eof then do;
       dfmax=k_Mean*k_Mean-2;
       df=nccat-2;
       %if &test=1 %then %do; df=df+1; %end;
       if df>0 then do;
         pcalib1=1-probchi(chisq1,df);
         pcal_adj1=1-probchi(chisq_adj1,df);
         pcalib2=1-probchi(chisq2,df);
         pcal_adj2=1-probchi(chisq_adj2,df);
       end;
       dfj=nccat-1;
       %if &test=1 %then %do; dfj=dfj+1; %end;
       if dfj>0 then do;
         pj1=1-probchi(jsq1,dfj);
         pj_adj1=1-probchi(jsq_adj1,dfj);
         pj2=1-probchi(jsq2,dfj);
         pj_adj2=1-probchi(jsq_adj2,dfj);
       end;
       ncat=&ncat;
       maxcat=ncat**2;
       if nreclass >0 then pctcorr=ncorr/nreclass;
       output calstats;
     end;
     run;

   %if &detail=2 %then %do;
   proc print data=calterms;
   var pcat1 pcat2 num1 denom1 denom12 phi1 num2 denom2 denom22 phi2
       nreclass ncorr pctcorr OEratio1 OEcil1 OEciu1 OEratio2 OEcil2 OEciu2;
   title3 "Calibration Terms for &PROB2 vs &PROB1 in Predicting &STATVAR";
   title4 "Using ALL Cross-Classified Cells";
   run;
   %end;
   %if &detail>0 %then %do;
   proc print data=calstats;
   var ncat maxcat dfmax nccat df chisq1 pcalib1 chisq_adj1 pcal_adj1
       chisq2 pcalib2 chisq_adj2 pcal_adj2 ;
   title3 "Calibration Statistics for &PROB2 vs &PROB1 in Predicting &STATVAR";
   title4 "Using ALL Cross-Classified Cells";
   %if &test=1 %then %do;
     title5 "For TEST Set";
   %end;
   run;
   %end;

   data caltermsb calstatsb (keep= ncat maxcat dfmax nccat df chisq1 pcalib1
            chisq_adj1 pcal_adj1 chisq2 pcalib2 chisq_adj2 pcal_adj2 
            dfj jsq1 pj1 jsq_adj1 pj_adj1 jsq2 pj2 jsq_adj2 pj_adj2);
    set calibs end=eof;
     retain chisq1 chisq_adj1 chisq2 chisq_adj2
            jsq1 jsq_adj1 jsq2 jsq_adj2 nccat nreclass ncorr 0;
     * only save cells with count at least 20;
    if stat_N >=20 then do;
     num1=(stat_Sum - prob1_Sum)**2;
     denom1=prob1_Sum*(1-prob1_Mean);
     denom12=(prob1_Sum+1)*(1-prob1_Mean+1/prob1_N);
     chisq1=chisq1 + num1/denom1;
     chisq_adj1=chisq_adj1 + num1/denom12;
     phi1=var1_Sum/denom1;
     jsq1=jsq1 + num1/(phi1*denom1);
     jsq_adj1=jsq_adj1 + num1/(phi1*denom12);
     num2=(stat_Sum - prob2_Sum)**2;
     denom2=prob2_Sum*(1-prob2_Mean);
     denom22=(prob2_Sum+1)*(1-prob2_Mean+1/prob2_N);
     chisq2=chisq2 + num2/denom2;
     chisq_adj2=chisq_adj2 + num2/denom22;
     phi2=var2_Sum/denom2;
     jsq2=jsq2 + num2/(phi2*denom2);
     jsq_adj2=jsq_adj2 + num2/(phi2*denom22);
     nccat=nccat+1;

     OEratio1=stat_Sum/prob1_Sum;
     OEratio2=stat_Sum/prob2_Sum;
     if stat_Sum>0 then do;
       sdo=sqrt(1/stat_Sum);
       OEcil1=OEratio1*exp(-1.96*sdo);
       OEciu1=OEratio1*exp(1.96*sdo);
       OEcil2=OEratio2*exp(-1.96*sdo);
       OEciu2=OEratio2*exp(1.96*sdo);
     end;
    
     * compute those reclass correctly;
     if pcat2 ne pcat1 then nreclass=nreclass+stat_N;
     %do i=1 %to &ncat-1;
        cut&i=&&c&i;
        if pcat2>pcat1 and pcat2=&i+1 then do;
            * put pcat2= pcat1= cut&i= stat_Sum= stat_Mean= stat_N=;
            if stat_Mean>=cut&i then ncorr=ncorr+stat_N;
        end;
        else if pcat2<pcat1 and pcat2=&i then do;
            * put pcat2= pcat1= cut&i= stat_Sum= stat_Mean= stat_N=;
            if stat_Mean<cut&i then ncorr=ncorr+stat_N;
        end;
     %end;

     output caltermsb;
    end;
     if eof then do;
       dfmax=k_Mean*k_Mean-2;
       df=nccat-2;
       %if &test=1 %then %do; df=df+1; %end;
       if df>0 then do;
         pcalib1=1-probchi(chisq1,df);
         pcal_adj1=1-probchi(chisq_adj1,df);
         pcalib2=1-probchi(chisq2,df);
         pcal_adj2=1-probchi(chisq_adj2,df);
       end;
       dfj=nccat-1;
       %if &test=1 %then %do; dfj=dfj+1; %end;
       if dfj>0 then do;
         pj1=1-probchi(jsq1,dfj);
         pj_adj1=1-probchi(jsq_adj1,dfj);
         pj2=1-probchi(jsq2,dfj);
         pj_adj2=1-probchi(jsq_adj2,dfj);
       end;
       ncat=&ncat;
       maxcat=ncat**2;
       if nreclass >0 then pctcorr=ncorr/nreclass;
       output calstatsb;
     end;
     run;

   %if &detail=2 %then %do;
   proc print data=caltermsb;
   var pcat1 pcat2 num1 denom1 denom12 phi1 num2 denom2 denom22 phi2
       nreclass ncorr pctcorr OEratio1 OEcil1 OEciu1 OEratio2 OEcil2 OEciu2;
   title3 "Calibration Terms for &PROB2 vs &PROB1 in Predicting &STATVAR";
   title4 "Using Cross-Classified Cells with N >= 20";
   run;
   %end;
   %if &detail>0 %then %do;
   proc print data=calstatsb;
   var ncat maxcat dfmax nccat df chisq1 pcalib1 chisq_adj1 pcal_adj1
       chisq2 pcalib2 chisq_adj2 pcal_adj2;
   title3 "Calibration Statistics for &PROB2 vs &PROB1 in Predicting &STATVAR";
   title4 "Using Cross-Classified Cells with N >= 20";
   %if &test=1 %then %do;
     title5 "For TEST Set";
   %end;
   run;
   %end;

   title2; run;

* Usage:
* %reclass(probs,1, outxy, pdx, pdxy, 4, 0.05, 0.10, 0.20);
* %reclass(probs,1, outxy, pdx, pdxy, 4, 0.05, 0.10, 0.20, test=1);
%mend RECLASS;

****************************************************************;

%macro NRICAT(DSNAME,DETAIL,STATVAR,PROB1,PROB2,NCAT,C1,C2,C3,C4,C5,C6,C7,C8,C9);
* Macro to compute Net Reclassification Index (NRI) of Pencina, Stat Med 2007; 
* Uses up to 10 categories with cutpoints c1-c9;

*  Variables:
*  DSNAME = dataset name;
*  DETAIL = 2 for detailed printout, 1 for limited, 0 for none;
*  STATVAR = outcome variable (coded 0,1);
*  PROB1 = probability for model 1;
*  PROB2 = probability for model 2;
*  NCAT = number of categories in classification;
*  C1-C9 = category cutpoints (should have ncat-1 cutpoints);

title2 NRI for &NCAT Categories with CutPoints = %do j = 1 %to &ncat; &&c&j %end;;

data nri1; set &dsname;
* compute diffs in probs;
stat=&STATVAR;
prob1=&PROB1;
prob2=&PROB2;
diffp=prob2-prob1;
if prob1>. and prob2>.;

* compute categories - set to above cutpoints;
%do i=1 %to &ncat-1;
  cut&i=&&c&i;
%end;
cut&ncat=1.01;
    
array cut {10} cut1-cut10;
array pcat {10} pcat1-pcat10;
if .<prob1<cut1 then pcat1=1;
if .<prob2<cut1 then pcat2=1;
do i=2 to &ncat;
   if cut(i-1)<=prob1<cut(i) then pcat1=i;
   if cut(i-1)<=prob2<cut(i) then pcat2=i;
end;

if pcat2 ne . and pcat1 ne . then do;
  if pcat2>pcat1 then disc=1;
  else if pcat2=pcat1 then disc=0;
  else if pcat2<pcat1 then disc=-1;
end;  
* look at number of categories moved;
   diffcat=pcat2-pcat1;
run;

*** Control output as needed ***;
%if &detail=2 %then %do;
proc means data=nri1 n sum mean median stddev min max;
var prob1 prob2 diffp disc diffcat stat;
run;
%end;

%if &detail=2 %then %do;
proc freq data=nri1;
tables pcat1*pcat2 stat*pcat1*pcat2;
tables stat*(disc diffcat) / chisq;
run;
%end;

ods listing exclude all;
ods output CrossTabFreqs=freqs;
ods output ChiSq=chisq;
run;
proc freq data=nri1;
tables stat*disc / chisq;
run;
ods output ChiSq=chisq2;
run;
proc freq data=nri1;
tables stat*diffcat / chisq;
run;
ods listing exclude none;

data trend; set chisq;
* if df=1;
if Statistic="Mantel-Haenszel Chi-Square";
chitrend=Value;
ptrend=1-probchi(chitrend,1);
keep chitrend ptrend;
run;
data trend2; set chisq2;
* if df=1;
if Statistic="Mantel-Haenszel Chi-Square";
chitrend2=Value;
ptrend2=1-probchi(chitrend2,1);
keep chitrend2 ptrend2;
run;


%if &detail=2 %then %do;
proc print data=freqs;
run;
%end;

data nri; set freqs end=eof;
retain up_case down_case up_contr down_contr ncase ncontr 0;
if stat=1 and disc=1 then up_case=RowPercent/100;
   else if stat=1 and disc=-1 then down_case=RowPercent/100;
   else if stat=0 and disc=1 then up_contr=RowPercent/100;
   else if stat=0 and disc=-1 then down_contr=RowPercent/100;
* Number of cases and controls is the same for pd and pred;
if stat=1 and _type_='10' then ncase=Frequency;
   else if stat=0 and _type_='10' then ncontr=Frequency;

if eof then do;
  %if ncase=0 or ncontr=0 %then %do;
     nri=.; znri=.; p2nri=.;
     %goto exit;
  %end;
  ri_case=up_case-down_case;
  ri_contr=down_contr-up_contr;
  nri=ri_case+ri_contr;

  *** Null variance (use non-null);
  vri_case_null=(up_case+down_case)/ncase;
  vri_contr_null=(up_contr+down_contr)/ncontr;
  vnri_null=vri_case_null+vri_contr_null;
  *** Non-null variance - use this;
  vri_case=(up_case+down_case-(up_case-down_case)**2)/ncase;
  vri_contr=(up_contr+down_contr-(up_contr-down_contr)**2)/ncontr;
  vnri=vri_case+vri_contr;

  senri=sqrt(vnri);
  nricil=nri-1.96*senri;
  nriciu=nri+1.96*senri;
  if vri_case>0 then zri_case=ri_case/sqrt(vri_case);
  if vri_contr>0 then zri_contr=ri_contr/sqrt(vri_contr);
  if vnri>0 then znri=nri/sqrt(vnri);
  p2ri_case=2*(1-probnorm(abs(zri_case)));
  p2ri_contr=2*(1-probnorm(abs(zri_contr)));
  p2nri=2*(1-probnorm(abs(znri)));
  output;
  keep ncase ncontr
       up_case down_case up_contr down_contr
       ri_case ri_contr nri vri_case vri_contr vnri senri nricil nriciu
       zri_case zri_contr znri p2ri_case p2ri_contr p2nri
       ;
end;

data _all_; merge nri trend trend2; 
* compute categories again - set to above cutpoints;
%do i=1 %to &ncat-1;
  cut&i=&&c&i;
%end;
if &ncat<10 then do;
  %do i=&ncat %to 9;
    cut&i=.;
  %end;
end;
ncat=&ncat;
run;

%if &detail>0 %then %do;
proc print data=_all_;
var    ncase ncontr ncat cut1-cut9
       up_case down_case up_contr down_contr 
       ri_case ri_contr nri vri_case vri_contr vnri senri nricil nriciu
       zri_case zri_contr znri p2ri_case p2ri_contr p2nri
       chitrend ptrend chitrend2 ptrend2
       ;
run;
%end;
title2; run;
* Usage:
* %nricat(probs,1,outxy,pdx,pdxy,4,0.05,0.10,0.20);
%exit: %mend NRICAT;

****************************************************************;

%macro IDIMACRO(DSNAME,DETAIL,OUT01,PROB1,PROB2);
*  Macro to compute difference in Yates slopes or
     integrated discrimination improvement (IDI) from Pencina, 2007;

*  Variables:
*  DSNAME = dataset name;
*  DETAIL = 1 or 2 for limited printout, 0 for none;
*  OUT01 = outcome variable (coded 0,1) (if 1,2 alter signs);
*  PROB1 = probability for model 1;
*  PROB2 = probability for model 2;

data ididat; set &dsname;
diffprob=&prob2-&prob1;
if &prob1>. and &prob2>.;
run;

%if &detail<2 %then %do;
ods listing exclude all;
%end;
ods output TTests=tstats;
ods output Statistics=unistats;
proc ttest data=ididat;
class &out01;
var &prob1 &prob2 diffprob;
title2 "Test of Difference in Yates Slope (IDI)";
run;

data idi1; set unistats end=eof;
retain yates1 yse1 ycil1 yciu1 yates2 yse2 ycil2 yciu2
       diffcase dcasese dcasecil dcaseciu diffcont dcontse dcontcil dcontciu
       idi idicil idiciu;
* Note: Yates slopes are negative since outcome coded 0,1;
* And CIs are reversed;
if _n_=3 then do;
  yates1=-Mean;
  yse1=StdErr;
  ycil1=-UpperCLMean;
  yciu1=-LowerCLMean;
end;
else if _n_=6 then do;
  yates2=-Mean;
  yse2=StdErr;
  ycil2=-UpperCLMean;
  yciu2=-LowerCLMean;
end;
else if _n_=8 then do;
  diffcase=Mean;
  dcasese=StdErr;
  dcasecil=LowerCLMean;
  dcaseciu=UpperCLMean;
end;
else if _n_=7 then do;
  diffcont=Mean;
  dcontse=StdErr;
  dcontcil=LowerCLMean;
  dcontciu=UpperCLMean;
end;
else if _n_=9 then do;
  idi=-Mean;
  idise=StdErr;
  idicil=-UpperCLMean;
  idiciu=-LowerCLMean;
end;
if eof then do;
   rel_idi=yates2/yates1 - 1;
   * Compute normal zscore based on Pencina;
   normse=sqrt((dcasese)**2 +(dcontse)**2);
   if normse>0 then zidi=idi/normse;
   p2idi=2*(1-probnorm(abs(zidi)));
   output;
end;
keep yates1 yse1 ycil1 yciu1 yates2 yse2 ycil2 yciu2
     diffcase dcasese dcasecil dcaseciu diffcont dcontse dcontcil dcontciu
     idi idise idicil idiciu rel_idi normse zidi p2idi;
run;

data idi2; set tstats end=eof;
if _n_=6 then do;
  idit=-tValue;
  idip=Probt;
  output;
  keep idit idip;
end;

data _idi_; merge idi1 idi2;
run;
ods listing exclude none;
%if &detail>0 %then %do;
proc print data=_idi_;
run;
%end;
title2; run;

* Usage:
* %idimacro(probs,1,outxy,pdx,pdxy,outxy);
%mend IDIMACRO;

****************************************************************;

%macro CONTNRI(DSNAME,DETAIL,STATVAR,PROB1,PROB2);
* Macro to compute NRI with any up or down (no categories); 
* Control output of frequency tables and means below;
*  Variables:
*  DSNAME = dataset name;
*  DETAIL = 2 for detailed printout, 1 for limited, 0 for none;
*  STATVAR = outcome variable (coded 0,1);
*  PROB1 = probability for model 1;
*  PROB2 = probability for model 2;

title2 Test of Continuous NRI for &PROB2 vs &PROB1 ;

data nri1; set &dsname;
* compute diffs in probs;
stat=&STATVAR;
prob1=&PROB1;
prob2=&PROB2;
diffp=prob2-prob1;
if prob1>. and prob2>.;

if prob2>prob1 then disc=1;
  else if prob2=prob1 then disc=0;
  else if prob2<prob1 then disc=-1;
run;

*** Control output as needed ***;
%if &detail=2 %then %do;
proc means data=nri1 n sum mean median stddev min max;
var prob1 prob2 diffp disc stat;
run;
%end;

%if &detail=2 %then %do;
proc freq data=nri1;
tables stat*disc / chisq;
run;
%end;

ods listing exclude all;
ods output CrossTabFreqs=freqs;
ods output ChiSq=chisq;
run;
proc freq data=nri1;
tables stat*disc / chisq;
run;
ods listing exclude none;

data trend; set chisq;
* if df=1;
if Statistic="Mantel-Haenszel Chi-Square";
chitrend=Value;
ptrend=1-probchi(chitrend,1);
keep chitrend ptrend;
run;

%if &detail=2 %then %do;
proc print data=freqs;
run;
%end;

data nri; set freqs end=eof;
retain up_case down_case up_contr down_contr ncase ncontr 0;
if stat=1 and disc=1 then up_case=RowPercent/100;
   else if stat=1 and disc=-1 then down_case=RowPercent/100;
   else if stat=0 and disc=1 then up_contr=RowPercent/100;
   else if stat=0 and disc=-1 then down_contr=RowPercent/100;
* Number of cases and controls is the same for pd and pred;
if stat=1 and _type_='10' then ncase=Frequency;
   else if stat=0 and _type_='10' then ncontr=Frequency;

if eof then do;
  %if ncase=0 or ncontr=0 %then %do;
     nri=.; znri=.; p2nri=.;
     %goto exit;
  %end;
  ri_case=up_case-down_case;
  ri_contr=down_contr-up_contr;
  nri=ri_case+ri_contr;
  * corrected variance to reflect binomial;
  vri_case=4*up_case*(1-up_case)/ncase;
  vri_contr=4*up_contr*(1-up_contr)/ncontr;
  vnri=vri_case+vri_contr;
  senri=sqrt(vnri);
  nricil=nri-1.96*senri;
  nriciu=nri+1.96*senri;
  if vri_case ne 0 then zri_case=ri_case/sqrt(vri_case);
  if vri_contr ne 0 then zri_contr=ri_contr/sqrt(vri_contr);
  if vnri ne 0 then znri=nri/sqrt(vnri);
  p2ri_case=2*(1-probnorm(abs(zri_case)));
  p2ri_contr=2*(1-probnorm(abs(zri_contr)));
  p2nri=2*(1-probnorm(abs(znri)));
  output;
  keep ncase ncontr
       up_case down_case up_contr down_contr
       ri_case ri_contr nri vri_case vri_contr vnri senri nricil nriciu
       zri_case zri_contr znri p2ri_case p2ri_contr p2nri
       ;
end;

data _all_; merge nri trend ; 
run;

%if &detail>0 %then %do;
proc print data=_all_;
var    ncase ncontr 
       up_case down_case up_contr down_contr 
       ri_case ri_contr nri vri_case vri_contr vnri senri nricil nriciu
       zri_case zri_contr znri p2ri_case p2ri_contr p2nri
       chitrend ptrend
       ;
run;
%end;
title2; run;
* Usage:
* %contnri(probs,1,outxy,pdx,pdxy);
%exit: %mend CONTNRI;

****************************************************************;

