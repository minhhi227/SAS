/**********/
%macro COMPACT_TABLE(IN_TBL,OUT_TBL);
%LET LIB_NM=%SCAN(&IN_TBL.,1,".");
%LET TBL_NM=%SCAN(&IN_TBL.,2,".");
%PUT LIB_NM=&LIB_NM.;
%PUT TBL_NM=&TBL_NM.;

proc sql noprint feedback;
     select case when type = 'char' then 'max(length('||strip(name)||')) as C_'||strip(name) else '8 as N_'|| name  end  
     into :COLS_LIST separated by ', '
     from dictionary.columns where libname="%UPCASE(&LIB_NM)" and MEMNAME="%UPCASE(&TBL_NM)";
quit;
%LET COLS_LIST=&COLS_LIST;
%PUT COLS_LIST=&COLS_LIST;
proc sql noprint;
     create table test as
     select &COLS_LIST from &LIB_NM..&TBL_NM;
     select count(*)
     into :COLS_CNT
     from dictionary.columns where libname="WORK" and MEMNAME="TEST";
quit;
%let COLS_CNT=&COLS_CNT;
%put COLS_CNT=&COLS_CNT;

proc sql noprint;
     select name, substr(name,1,1)   
     into :COL_NM1 - :COL_NM&COLS_CNT., :COL_TYP1 - :COL_TYP&COLS_CNT. 
     from dictionary.columns where libname="WORK" and MEMNAME="TEST";
quit;
proc sql noprint feedback;
     select  &COL_NM1.%do i=2 %to &COLS_CNT.;, &&COL_NM&i. %end;
     into :COL_VAL1 %do j=2 %to &COLS_CNT.;,:COL_VAL&j. %end;
     from TEST;
quit;
%PUT COL_VAL1=&COL_VAL1.; 
%do i=1 %to %to &COLS_CNT.;
     %LET COL_VAL&i=&&COL_VAL&i.; 
%end;
%PUT COL_NM1=&COL_NM1.; 
%PUT COL_TYP1=&COL_TYP1.; 
%PUT COL_VAL1=&COL_VAL1.; 

proc sql noprint feedback;
create table &OUT_TBL. as 
select 

%if "&COL_TYP1." = "C" %then 
     %do; PUT(%SUBSTR(&COL_NM1.,3),$&COL_VAL1..) as %SUBSTR(&COL_NM1.,3) %end; 
%else %do; "%SUBSTR(&COL_NM1.,3)" %end;
     %do i=2 %to &COLS_CNT.;, %if "&&COL_TYP&i." = "C" %then %do; PUT(%SUBSTR(&&COL_NM&i.,3),$&&COL_VAL&i...) as %SUBSTR(&&COL_NM&i.,3) %end; %else %do;  %SUBSTR(&&COL_NM&i.,3) %end; %end;
from &LIB_NM..&TBL_NM.;
quit;
%mend;