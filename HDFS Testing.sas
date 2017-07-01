libname Libdwh oracle user="test" password="0FO4Y51TGW5EJM" path=dwprod;
LIBNAME SASTEST BASE "/opt/sas/work/test";

DATA SASTEST.V_LOS_RUL_LOG_DETAIL_TBL_1M_1;
set Libdwh.V_LOS_RUL_LOG_DETAIL_TBL_1M;
RUN; 
libname Libdwh oracle user="test" password="0FO4Y51TGW5EJM" path=dwprod;
LIBNAME SASTEST BASE "/opt/sas/work/test";

DATA SASTEST.V_LOS_RUL_LOG_DETAIL_TBL_1M_2;
set Libdwh.V_LOS_RUL_LOG_DETAIL_TBL_1M;
RUN; 
libname Libdwh oracle user="test" password="0FO4Y51TGW5EJM" path=dwprod;
LIBNAME SASTEST BASE "/opt/sas/work/test";

DATA SASTEST.V_LOS_RUL_LOG_DETAIL_TBL_1M_3;
set Libdwh.V_LOS_RUL_LOG_DETAIL_TBL_1M;
RUN; 

libname hdfs sashdat host="sas-node0.deltavn.vn" install="/opt/TKGrid" path="/hps";
LIBNAME SASTEST BASE "/opt/sas/work/test";

DATA hdfs.V_LOS_RUL_LOG_DETAIL_TBL_1M_1;
set SASTEST.V_LOS_RUL_LOG_DETAIL_TBL_1M;
RUN; 

libname hdfs sashdat host="sas-node0.deltavn.vn" install="/opt/TKGrid" path="/hps";
LIBNAME SASTEST BASE "/opt/sas/work/test";

DATA hdfs.V_LOS_RUL_LOG_DETAIL_TBL_1M_2;
set SASTEST.V_LOS_RUL_LOG_DETAIL_TBL_1M;
RUN; 

libname hdfs sashdat host="sas-node0.deltavn.vn" install="/opt/TKGrid" path="/hps";
LIBNAME SASTEST BASE "/opt/sas/work/test";

DATA hdfs.V_LOS_RUL_LOG_DETAIL_TBL_1M_3;
set SASTEST.V_LOS_RUL_LOG_DETAIL_TBL_1M;
RUN; 





