/* Include and execute main AutoLoad functionality */
%LET INCLUDELOC=/opt/sas/sashome/SASFoundation/9.4;

/* ------- No edits necessary below this line -------- */
filename inclib "&INCLUDELOC.";
%include inclib ( auto_load.sas );


*libname SDMPROD oracle user=DI_SAS password="3z0gWxvcMy" 
path=dwproddc DB_LENGTH_SEMANTICS_BYTE=NO DBCLIENT_MAX_BYTES=1 READBUFF=10000;
*LIBNAME XXX '/sasdata/BI';
LIBNAME TEST '/opt/BI';

/* USER CODE HERE */



*%direct_load_lasr(TEST, PHUC_MOB_DEL_REPORT_TEST, test_01, test_01, /Shared Data/SAS Visual Analytics/HPT/HDFSTOVA);

%hadoopbatchrun(TEST, PHUC_MOB_DEL_REPORT, test_07, test_07, /Shared Data/SAS Visual Analytics/DATA, readahead=no);
*%hadoopbatchrun(XXX, PHUC_MOB_DEL_REPORT, test_01, test_01, /Shared Data/SAS Visual Analytics/HPT/HDFSTOVA, readahead=yes);
*%hadoopbatchrun(SDMPROD, SDM_FIN_LOAN_PARAMETER_SUM, test_02, test_02, /Shared Data/SAS Visual Analytics/HPT/HDFSTOVA, readahead=yes);
