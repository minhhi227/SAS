/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Wednesday, May 11, 2016     TIME: 3:16:35 PM
PROJECT: Daily Sales Report_Script _ 08JAN2016
PROJECT PATH: D:\Project_transfer\Daily Sales Report\Daily Sales Report_Script _ 08JAN2016.egp
---------------------------------------- */

/* Library assignment for SASApp_VA.SASUAT */
;

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;

/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend;

ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HtmlBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome/SASEnterpriseGuide/6.1/Styles/HtmlBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: Main code   */
%LET _CLIENTTASKLABEL='Main code';
%LET _CLIENTPROJECTPATH='D:\Project_transfer\Daily Sales Report\Daily Sales Report_Script _ 08JAN2016.egp';
%LET _CLIENTPROJECTNAME='Daily Sales Report_Script _ 08JAN2016.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;

OPTIONS COMPRESS=YES;
DATA APPS_ALL (KEEP=app_id opera_date approve_date id_no lsm_schemeid product loanamount_not_insurance
			insurance term installment posnumber cc_code dsa_code tsa_code_app ins_flag sub_product
			sub_channel);
SET sdmprod.mv_apps_all_mis;
IF datepart(opera_date) >=intnx('month', DATE()-1, -2, 'b')
	AND product in ('TW','CDL','PL','CRC');
RUN;

/*proc sql;*/
/*create table check_ as*/
/*select **/
/*from APPS_ALL_DAILY*/
/*where Appl_ID=6654893*/
/*;*/
/*quit;*/

OPTIONS COMPRESS=YES;
DATA CNT_ALL (KEEP=APPLID disbursaldate lad_app_req_loanamount_n insurance_fee amtfin emi);
SET sdmprod.mv_lea_agreement_dtl_mis;
IF datepart(disbursaldate) >=intnx('month', DATE()-1, -2, 'b');
RUN;

OPTIONS COMPRESS=YES;
PROC SQL;
CREATE TABLE APPS_ALL_DAILY AS
select input(t.app_id,10.) as Appl_ID, t.opera_date AS Appl_Datetime
	,datepart(t.opera_date)AS Appl_Date format=date9.
	,month(datepart(t.opera_date))as Appl_Month
	,t.approve_date, t.id_no as Customer_ID_No
	,t.lsm_schemeid as Scheme_ID,t.product as Product_Type,t1.laah_la_activity_id as Application_Status
	,t1.laah_edit_d as Appl_Status_Dt,t.loanamount_not_insurance as Required_Amt
	,t.insurance as Insurance_Amt
	,(t.loanamount_not_insurance + t.insurance) as Loan_Amt,t.term as Tenure, . as Disbursal_Dt FORMAT=DATE9.
	,. as Disbursed_month,0 as Disbursed_Flag, t.installment as EMI_Amt
	,t.posnumber as Pos_ID, p.province as Province_Name, p.region, t.cc_code as CC_CD
	,t.dsa_code as DSA_CD, t.tsa_code_app as TSA_CD, t.Ins_Flag
	,
	(CASE      
		WHEN t1.laah_la_activity_id in ('PDOC','DOV','DISBDTL','DII','FINISH') 
		THEN 1   
		ELSE 0
    END) AS Approved_Flag
	,date()-1 as FTD_Date format=date9.
	,(case when t.product in ('TW','CDL') then p.region
             when t.product='CRC' then 'CRC'
             when t.sub_product in ('XSell','Topup') then t.sub_product
             when t.sub_channel in ('DSA L@W','DSA self') then 'DSA'
             when t.sub_channel ='RAINBOW' then 'Rainbow'
             when t.sub_channel ='KGK' then 'KGK'
             when t.sub_channel ='THIENTU' then 'ThienTu'
             when t.sub_channel ='KS' then 'KIOSK'
             when t.sub_channel in ('L@W-TeleInhouse','New To bank-TeleInhouse','SNA') then 'Inhouse'
             else 'CC' end) as Product_SubChannel
	,(case when t.product in('TW','CDL')then 'Region'
             when t.product='CRC' then 'CRC'
             when t.sub_product in ('XSell','Topup') then 'X-sell+Topup'
             when t.sub_channel in ('DSA L@W','DSA self') then 'DSA'
             when t.sub_channel in ('RAINBOW','KGK','THIENTU') then 'Third Party'
             when t.sub_channel ='KS' then 'KIOSK'
             when t.sub_channel in ('L@W-TeleInhouse','New To bank-TeleInhouse','SNA') then 'In House'
             else 'CC' end) as Product_Channel              
from APPS_ALL t
inner join sdmprod.mv_app_last_status_mis t1 on t.app_id=t1.app_id_c
left join sdmprod.v_f1_province_by_poscode p on p.pos_code=t.posnumber;
QUIT;

OPTIONS COMPRESS=YES;
PROC SQL;
CREATE TABLE CNT_NORMAL_PROD AS
select input(t.app_id,10.) as Appl_ID, t.opera_date as Appl_Datetime
		,datepart(t.opera_date) as Appl_Date format=date9.
		,month(datepart(t.opera_date))as Appl_Month
		,t.approve_date, t.id_no as Customer_ID_No, t.lsm_schemeid as Scheme_ID
		, t.product as Product_Type,'FINISH' as Application_Status,l.disbursaldate as Appl_Status_Dt
		, l.lad_app_req_loanamount_n as Required_Amt,l.insurance_fee as Insurance_Amt
       ,l.amtfin as Loan_Amt ,t.term as Tenure, datepart(l.disbursaldate) as Disbursal_Dt FORMAT=DATE9.
		, month(datepart(l.disbursaldate))as Disbursed_month
		, 1 as Disbursed_Flag, l.emi as EMI_Amt
       ,t.posnumber as Pos_ID, p.province as Province_Name,p.region, t.cc_code as CC_CD
		,t.dsa_code as DSA_CD,t.tsa_code_app as TSA_CD, t.ins_flag
       , 1 as Approved_Flag
       ,date()-1 as FTD_Date format=date9.
       ,case when t.product in('TW','CDL')then p.region
             when t.product='CRC' then 'CRC'
             when t.sub_product in ('XSell','Topup') then t.sub_product
             when t.sub_channel in ('DSA L@W','DSA self') then 'DSA'
             when t.sub_channel ='RAINBOW' then 'Rainbow'
             when t.sub_channel ='KGK' then 'KGK'
             when t.sub_channel ='THIENTU' then 'ThienTu'
             when t.sub_channel ='KS' then 'KIOSK'
             when t.sub_channel in ('L@W-TeleInhouse','New To bank-TeleInhouse','SNA') then 'Inhouse'
             else 'CC' end as Product_SubChannel
       ,case when t.product in('TW','CDL')then 'Region'
             when t.product='CRC' then 'CRC'
             when t.sub_product in ('XSell','Topup') then 'X-sell+Topup'
             when t.sub_channel in ('DSA L@W','DSA self') then 'DSA'
             when t.sub_channel in ('RAINBOW','KGK','THIENTU') then 'Third Party'
             when t.sub_channel ='KS' then 'KIOSK'
             when t.sub_channel in ('L@W-TeleInhouse','New To bank-TeleInhouse','SNA') then 'In House'
             else 'CC' end as Product_Channel              
from cnt_all l 
inner join sdmprod.mv_apps_all_mis t on input(t.app_id,10.)=l.applid
left join sdmprod.v_f1_province_by_poscode p on p.pos_code=t.posnumber
where t.product in ('TW','CDL','PL');
QUIT;

OPTIONS COMPRESS=YES;
PROC SQL;
CREATE TABLE CNT_CRC_PROD AS
select input(t.app_id,10.)as Appl_ID, t.opera_date as Appl_Datetime
		,datepart(t.opera_date) as Appl_Date format=date9.
		,month(datepart(t.opera_date))as Appl_Month,t.approve_date, t.id_no as Customer_ID_No
		, t.lsm_schemeid as Scheme_ID, t.product as Product_Type
        ,'FINISH' as Application_Status, sdm.OPENED_DT as Appl_Status_Dt
		, t.loanamount_not_insurance as Required_Amt,t.insurance as Insurance_Amt
        ,(t.loanamount_not_insurance + t.insurance) as Loan_Amt ,t.term as Tenure
		,datepart(sdm.OPENED_DT) as Disbursal_Dt FORMAT=DATE9.
		,month(datepart(sdm.OPENED_DT))as Disbursed_month
		,1 as Disbursed_Flag, . as EMI_Amt
        ,t.posnumber as Pos_ID, '' as Province_Name,'' as region, t.cc_code as CC_CD,t.dsa_code as DSA_CD
		,t.tsa_code_app as TSA_CD, t.ins_flag
        , 1 as Approved_Flag
        ,date()-1 as FTD_Date format=date9.
        ,'CRC' AS Product_SubChannel
        ,'CRC' AS Product_Channel              
from SDMPROD.sdm_com_card_info sdm 
inner join SDMPROD.mv_apps_all_MIS t on INPUT(t.app_id,10.)=sdm.APPL_ID
where t.product ='CRC' and datepart(sdm.OPENED_DT) >= intnx('month', DATE()-1, -2, 'b');
QUIT;

OPTIONS COMPRESS=YES;
DATA ALL_INFORMATION 
(keep=Appl_ID	Appl_Datetime Appl_Date Appl_Month APPROVE_DATE Customer_ID_No	
Scheme_ID Product_Type  Application_Status Appl_Status_Dt Required_Amt Disbursal_Dt 
Disbursed_month Disbursed_Flag Loan_Amt Tenure EMI_Amt Insurance_Amt Pos_ID 
Province_Name REGION	CC_CD	DSA_CD	TSA_CD	INS_FLAG Approved_Flag Product_SubChannel 
Product_Channel FTD_Date);
SET APPS_ALL_DAILY CNT_NORMAL_PROD CNT_CRC_PROD;
RUN;

OPTIONS COMPRESS=YES;
PROC SQL;
CREATE TABLE ALL_INFORMATION1 AS
SELECT t.*, 
		CASE  
   		WHEN t.Product_Type in ('TW', 'CDL') THEN day(date()-1)
   		ELSE 
        	CASE  
        	WHEN day(date()) = 1 THEN  intck('WEEKDAY', intnx('month', date(),-1,'B'),  intnx('month', date(),-1,'E'))
        	WHEN (day(date()) = 2 AND weekday(date()) in (1, 7)) or (day(date()) = 3 AND weekday(date()) in (1, 2)) 
        	THEN 1
        	ELSE intck('WEEKDAY', intnx('month', date(), 0), date())
			END
		END as WorkDays,
		CASE 
			WHEN t.Product_Type in ('TW', 'CDL')
   			THEN day(intnx('month',date()-1,0,'end'))
   			ELSE intck('WEEKDAY', intnx('month', date()-1, 0,'B'),  intnx('month', date()-1, 0, 'E'))+1
		END as Total_Working_Days
FROM ALL_INFORMATION t;

QUIT;

/*change target*/
PROC SQL;
CREATE TABLE ALL_INFO_W_TARGET AS 
SELECT * FROM ALL_INFORMATION1
 OUTER UNION CORR 
(SELECT t1.Month, t1.Product_Type, t1.Product_Channel, 
          t1.Product_SubChannel, t1.Target
      FROM SASUAT.SALES_TARGET_CURRENTMONTH t1
      WHERE t1.Month = INTNX('MONTH',DATE()-1, 0))
;
Quit;

OPTIONS COMPRESS=YES;
PROC SQL;
CREATE TABLE APPROVED_FTD AS
SELECT DATEPART(APPROVE_DATE) AS REPORTING_DATE FORMAT=DATE9., PRODUCT_TYPE
	, SUM(APPROVED_FLAG) AS APPROVED_FTD
FROM ALL_INFO_W_TARGET
WHERE DISBURSED_FLAG=0
GROUP BY DATEPART(APPROVE_DATE),PRODUCT_TYPE;
QUIT;

OPTIONS COMPRESS=YES;
PROC SQL;
CREATE TABLE CLIENT_FTD AS
SELECT appl_date AS REPORTING_DATE FORMAT=DATE9., product_type, count(distinct customer_id_no) as total_client_ftd
FROM ALL_INFO_W_TARGET
where product_type in ('TW','CDL')
group by appl_date, product_type;
QUIT;


OPTIONS COMPRESS=YES;
PROC SQL;
CREATE TABLE DISBURSED_FTD AS
SELECT DISBURSAL_DT AS REPORTING_DATE FORMAT=DATE9., product_type, SUM(DISBURSED_FLAG) as DISBURSED_FTD
FROM ALL_INFO_W_TARGET
WHERE DISBURSED_FLAG=1
group by DISBURSAL_DT, product_type;
QUIT;

PROC SORT DATA=CLIENT_FTD OUT=CLIENT_FTD NODUPKEY;
  BY REPORTING_DATE Product_Type ;
RUN ;

PROC SORT DATA=APPROVED_FTD OUT=APPROVED_FTD NODUPKEY;
  BY REPORTING_DATE Product_Type ;
RUN ;

PROC SORT DATA=DISBURSED_FTD OUT=DISBURSED_FTD NODUPKEY;
  BY REPORTING_DATE Product_Type ;
RUN ;

OPTIONS COMPRESS=YES;
DATA FTD_SUM;
MERGE APPROVED_FTD CLIENT_FTD DISBURSED_FTD;
BY REPORTING_DATE PRODUCT_TYPE;
RUN;

OPTIONS COMPRESS=YES;
DATA SASUAT.VINH_SALES_PORTFOLIO;
SET ALL_INFO_W_TARGET;
RUN;

OPTIONS COMPRESS=YES;
DATA SASUAT.VINH_SALES_PORTFOLIO_FTD (drop=DISBURSED_FTD approved_ftd);
SET FTD_SUM;
IF REPORTING_DATE >= INTNX('DAY',DATE()-1,-10);
sum_of_approved_flag=approved_ftd;
sum_of_disbursed_flag=DISBURSED_FTD;
RUN;
/**/
data SASUAT.VINH_SALES_PORTFOLIO;
set SASUAT.VINH_SALES_PORTFOLIO;
if disbursal_dt=date() then delete;
run;

data sasuat.VINH_SALES_PORTFOLIO_FTD;
set sasuat.VINH_SALES_PORTFOLIO_FTD;
if reporting_date = date() then delete;
run;
/**/
/* proc sql;*/
/* create table test as*/
/*select * from SASUAT.VINH_SALES_PORTFOLIO;*/
/*quit;*/
/**/

data bk;
set SASUAT.VINH_SALES_PORTFOLIO;
run;

proc sql;
update SASUAT.VINH_SALES_PORTFOLIO
	set Product_SubChannel='XSell'
	where Product_SubChannel='X-sell';

/*proc sql;*/
/*update SASUAT.VINH_SALES_PORTFOLIO*/
/*	set WorkDays=23*/
/*	where WorkDays=22;*/

/*proc sql;*/
/*create table a as*/
/*select t.Product_Type, count(t.Appl_ID)*/
/*from SASUAT.VINH_SALES_PORTFOLIO t*/
/*where t.Appl_Date='21mar2016'd*/
/*group by t.Product_Type*/
/*;*/
/*quit;*/
/**/
/*proc sql;*/
/*create table check_ as*/
/*select **/
/*from SASUAT.VINH_SALES_PORTFOLIO t*/
/*where t.product_type='TW' and t.disbursed_flag=0 and t.Appl_Date='21mar2016'd*/
/*;*/
/*quit;*/

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
