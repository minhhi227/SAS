/*
PROC SQL;
CREATE TABLE HPTDATA.TEST AS
SELECT COUNT(*) 
FROM HPTDATA.CIR_DATA;
QUIT;
*/

options metaserver="has-vanode0"
	metaport=8561
	metauser="sasdemo"
	metapass="sasdemo@123"
	metarepository="Foundation";

%LET node=10.0.18.160;
OPTIONS COMAMID=TCP REMOTE="&node";
filename rlink "C:\SAS\SASHome\SASFoundation\9.4\connect\saslink\tcpunix.scr";
SIGNON server="SASApp - Logical Workspace Server" ;
RSUBMIT;
libname SASDATA '/data/sas-library';
PROC SQL;
CREATE TABLE SASDATA.TEST AS
SELECT COUNT(*) 
FROM SASDATA.VPB_CIR_DATA;
QUIT;
ENDRSUBMIT;
SIGNOFF;



/*
PROC SQL;
DROP TABLE SASDATA.TEST;
QUIT;
*/