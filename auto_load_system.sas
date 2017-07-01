/* 
 * appserver_autoexec_usermods.sas
 *
 *    This autoexec file extends appserver_autoexec.sas.  Place your site-specific include 
 *    statements in this file.  
 *
 *    Do NOT modify the appserver_autoexec.sas file.  
 *    
 */
options compress=binary fullstimer msglevel=i;
%global  SMChadoop hadooppath defaultlasrpath host signer port valibHadoop  tag tablePrefix smcva libserver;

   options metaport=8561 metaserver="has-sasnode0"  metarepository=Foundation metauser="sasadm@saspw" metapass="SASpw123";

   
   %let SMCVA=SYSTEM Visual Analytics LASR;
   %let SMChadoop=SYSTEM Visual Analytics HDFS;
   %let hadooppath=/Shared Data/HDFS DATA;
   %let defaultlasrpath=/Shared Data/SAS Visual Analytics/DATA;
   %let host=has-sasnode0;
   %let signer =http://has-sasnode0:7980/SASLASRAuthorization;
   %let port =10041;
   %let valibHadoop=/sys;
   %let tag=SYS;
   %let tablePrefix=;
   %let libserver =;



   LIBNAME HPS SASHDAT  PATH="&valibHadoop"  SERVER="&host"  INSTALL="/opt/TKGrid" ;
   LIBNAME VALIBLA SASIOLA  TAG=&tag  PORT=&port HOST="&host"  SIGNER="&signer" ;
   
options mprint mlogic;


%macro registertable( REPOSITORY=Foundation, REPOSID=, LIBRARY=, TABLE=, FOLDER=, TABLEID=, PREFIX= );      
                                         
   %if &syscc<=4 %then %do;                                                                                                                                                             
   	%let REPOSARG=%str(REPNAME="&REPOSITORY.");                                                                                                                  
   	%if ("&REPOSID." ne "") %THEN %LET REPOSARG=%str(REPID="&REPOSID.");                                                                                         
                                                                                                                                                                
   	%if ("&TABLEID." ne "") %THEN %LET SELECTOBJ=%str(&TABLEID.);                                                                                                
   	%else                         %LET SELECTOBJ=%str(&TABLE.);                                                                                                  
                                                                                                                                                                
   	%if ("&FOLDER." ne "") %THEN                                                                                                                                 
      	%PUT INFO: Registering &FOLDER./&SELECTOBJ. to &LIBRARY. library.;                                                                                        
  	 %else                                                                                                                                                        
      	%PUT INFO: Registering &SELECTOBJ. to &LIBRARY. library.;                                                                                                 
                                                                                                                                                                
   	proc metalib;                                                                                                                                                
      	omr (                                                                                                                                                     
	/*         library="&LIBRARY."                                                                                                                                    */
	liburi="SASLibrary?@name='&library'"

		&REPOSARG.                                                                                                                                             
          );                                                                                                                                                    
	 %if ("&TABLEID." eq "") %THEN %DO;                                                                                                                        
         	%if ("&FOLDER." ne "") %THEN %DO;                                                                                                                      
            		folder="&FOLDER.";                                                                                                                                  
         	%end;                                                                                                                                                  
      	  %end;                                                                                                                                                     
      	%if ("&PREFIX." ne "") %THEN %DO;                                                                                                                         
        	 prefix="&PREFIX.";                                                                                                                                     
      	%end;                                                                                                                                                     
      	select ("&SELECTOBJ."); 
                                                                                                                                   
   	run;                                                                                                                                                         
   	quit;                                                                                                                      %end;                                  
                                                                                                                                                                
%mend;  


%macro unregistertable( REPOSITORY=Foundation, REPOSID=, LIBRARY=, TABLE=, FOLDER=, TABLEID=, PREFIX= );                                                          
   %if &syscc<=4 %then %do;                                                                                                                                                              
   	%let REPOSARG=%str(REPNAME="&REPOSITORY.");                                                                                                                  
   	%if ("&REPOSID." ne "") %THEN %LET REPOSARG=%str(REPID="&REPOSID.");                                                                                         
                                                                                                                                                                
  	 %if ("&TABLEID." ne "") %THEN %LET SELECTOBJ=%str(&TABLEID.);                                                                                                
  	 %else                         %LET SELECTOBJ=%str(&TABLE.);                                                                                                  
                                                                                                                                                                
  	 %if ("&FOLDER." ne "") %THEN                                                                                                                                 
    	  %PUT INFO: Registering &FOLDER./&SELECTOBJ. to &LIBRARY. library.;                                                                                        
  	 %else                                                                                                                                                        
   	   %PUT INFO: Registering &SELECTOBJ. to &LIBRARY. library.;                                                                                                 
                                                                                                                                                                
 	 proc metalib;                                                                                                                                                
  	    omr (                                                                                                                                                     
	/*         library="&LIBRARY."                                                                                        	                                            */
	liburi="SASLibrary?@name='&library'"

		&REPOSARG.                                                                                                                                             
          );                                                                                                                                                    
      	%if ("&TABLEID." eq "") %THEN %DO;                                                                                                                        
         %if ("&FOLDER." ne "") %THEN %DO;                                                                                                                      
            folder="&FOLDER.";                                                                                                                                  
         %end;                                                                                                                                                  
      	%end;                                                                                                                                                     
     	%if ("&PREFIX." ne "") %THEN %DO;                                                                                                                         
         prefix="&PREFIX.";                                                                                                                                     
      	%end;                                                                                                                                                     
      	select ("&SELECTOBJ."); 
		UPDATE_RULE=(DELETE); 
                                                                                                                                   
   	run;                                                                                                                                                         
   	quit;                                                                                                                                                        
   %end;                                                                                                                                                             
%mend;  




%macro dataset_TO_hadoop(sourcelib,sourcetable,targettable);                                                                                                                                                              
     /* Generate macros for return code management                                                 */                                                                
    %macro putRC(var);                                                                                                                                              
	%if %SYMEXIST(&VAR.) %then %put &VAR.=&&&VAR..;                                                                                                                
    %mend;                                                                                                                                                          
    %macro putRCs(MSG);                                                                                                                                             
	%put --------------------------------------;                                                                                                                   
	%put &MSG.;                                                                                                                                                    
	%put --------------------------------------;                                                                                                                   
	%putRC(SYSCC);                                                                                                                                                 
	%putRC(SQLRC);                                                                                                                                                 
	%putRC(SYSERR);                                                                                                                                                
	%putRC(SYSLIBRC);                                                                                                                                              
	%putRC(SYSMSG);                                                                                                                                                
	%putRC(SYSRC);                                                                                                                                                 
    %mend;                                                                                                                                                          
    /* Access the data                                                                            */                                                                
                                                                                                                                                                

                                                                                                                                                                
    /*  MACRO: GetNumberGridNodes                                                                 */                                                                
    /*  PURPOSE: Queries the master host on an HPA grid to retrieve the number of nodes           */                                                                
   /*           in the grid.                                                                     */                                                                
   /*  PARMS:  host = The host to query.                                                         */                                                                
   /*          install = The install location for the grid                                       */                                                                
   /*          outvar =The output macro variable in which to place the node count                */                                                                
                                                                                                                                                                 
   %macro GetNumberGridNodes(host=, install=, outvar=NNODES);                                                                                                      
     * Get number of nodes in the grid;                                                                                                                           
                                                                                                                                                                
   %global &outvar.;                                                                                                                                            
   %let out=nodeinfo;                                                                                                                                           
                                                                                                                                                                
      proc hpatest;                                                                                                                                                
        performance host="&host." install="&install." nodes=all;                                                                                                  
        ods html close;                                                                                                                                           
        ods output PerformanceInfo=&out.;                                                                                                                         
      run;                                                                                                                                                         
                                                                                                                                                                
      data _null_;                                                                                                                                                 
         set &out. end=last;                                                                                                                                       
         if last then do;                                                                                                                                          
           call symput("&outvar.",Value);                                                                                                                         
           output;                                                                                                                                                
         end;                                                                                                                                                     
      run;                                                                                                                                                         
   %mend GetNumberGridNodes;                                                                                                                                       
                                                                                                                                                                
  %GetNumberGridNodes(host=&host, install=/opt/TKGrid);                                                                                               
                                                                                                                                                                
   /*  MACRO: GetHDFSOptimalBlockSizeOptions                                                    */                                                                
   /*  PURPOSE: Computes the optimal block size options to use for a data set when              */                                                                
   /*           loading into HDFS                                                                */                                                                
   /*  PARMS:  LIB=    Library containing table                                                  */                                                                
   /*          DATA=   Table name                                                                */                                                                
   /*          NNODES= Number of nodes to be used                                                */                                                                
   /*          OUTVAR= The output variable into which to place the blocksize options             */                                                                
   /*          OUTVAR2=The output variable into which to place the innameonly option             */                                                                
                                                                                                                                                                
  %macro GetHDFSOptimalBlockSizeOptions(lib=WORK, data=, nnodes=, outvar=BLOCKOPTIONS, outvar2=INNAMEONLY);                                                       
                                                                                                                                                                
   * Make output variables global;                                                                                                                              
   %global &outvar.;                                                                                                                                            
   %global &outvar2.;                                                                                                                                           
                                                                                                                                                                
   * Check to see if this is a zero-length data set;                                                                                                            
   %let GHOBSO_ZEROLEN=1;                                                                                                                                       
   data _null_;                                                                                                                                                 
   		set &lib..&data.;                                                                                                                                          
		call symput("GHOBSO_ZEROLEN","0");                                                                                                                            
		stop;                                                                                                                                                         
	run;                                                                                                                                                           
	%if &GHOBSO_ZEROLEN. eq 1 %then %do;                                                                                                                           
    	%global &outvar2.;                                                                                                                                         
		%let &outvar.=;                                                                                                                                               
    	%let &outvar2.=INNAMEONLY;                                                                                                                                 
		%return;                                                                                                                                                      
	%end;                                                                                                                                                          
                                                                                                                                                                
   /* Get data member information;                                                               */                                                                
                                                                                                                                                                
   proc datasets lib=&lib. nolist;                                                                                                                              
      contents data=&data. out=work.tmpblk directory details noprint;                                                                                           
   quit;                                                                                                                                                        
                                                                                                                                                                
   proc sort data=work.tmpblk;                                                                                                                                  
      by memname;                                                                                                                                               
   run;                                                                                                                                                         
                                                                                                                                                                
   data tmpblk;                                                                                                                                                 
      set tmpblk;                                                                                                                                               
      by memname;                                                                                                                                               
                                                                                                                                                                
      padlen = length; /* if not double aligning chars */                                                                                                       
      padlen = floor((length+7)/8) * 8; /* if double aligning chars */                                                                                          
                                                                                                                                                                
      if first.memname then padsize = padlen;                                                                                                                   
      else padsize + padlen;                                                                                                                                    
   run;                                                                                                                                                         
                                                                                                                                                                
   proc sort data=work.tmpblk;                                                                                                                                  
      by memname descending padsize;                                                                                                                            
   run;                                                                                                                                                         
                                                                                                                                                                
   /* Calculate block size;                                                                      */                                                                
                                                                                                                                                                
   data tmpblk2;                                                                                                                                                
      set tmpblk;                                                                                                                                               
      by memname;                                                                                                                                               
                                                                                                                                                                
      if first.memname;                                                                                                                                         
                                                                                                                                                                
      length tblname $ 256;                                                                                                                                     
      length blkstr $ 15;                                                                                                                                       
	  length blksize 8;                                                                                                                                            
	  length innameonly $ 10;                                                                                                                                      
      reclen = padsize;                                                                                                                                         
      nznobs = nobs;                                                                                                                                            
                                                                                                                                                                
      put "-------------- &lib..&data. ----------------";                                                                                                       
	  put "SOURCE TYPE   = " memtype;                                                                                                                              
                                                                                                                                                                
	  /* For views (or any case where we do not have the number of rows),                                                                                          
	     we cannot compute block size, so force block size to 32 MB. */                                                                                            
      if nznobs = 0 or missing(nznobs) then do;                                                                                                                 
	     blksize = 32;                                                                                                                                             
		 suffix="m";                                                                                                                                                  
		 blkstr = trim(left(put(blksize,6.))) || suffix;                                                                                                              
		 put "NUMBER OF OBS NOT AVAILABLE.";                                                                                                                          
		 put "BLOCK SIZE    = " blkstr;                                                                                                                               
      end;                                                                                                                                                      
	  else do;			  /* Number of rows available.  Compute block size */                                                                                             
	      datasize = reclen * nznobs;                                                                                                                              
                                                                                                                                                                
	      put "NUMBER OF OBS = " nznobs;                                                                                                                           
	      put "RECORD LENGTH = " reclen;                                                                                                                           
	      put "DATA SIZE (B) = " datasize;                                                                                                                         
                                                                                                                                                                
		  /* Set innameonly if small data (datasize in KB < 1024k [1 meg])*/                                                                                          
		  if (datasize/1024 < 1024) then do;                                                                                                                          
			innameonly="INNAMEONLY";                                                                                                                                     
			put "USING INNAMEONLY";                                                                                                                                      
		  end;                                                                                                                                                        
		  /* Compute block size since not using INNAMEONLY */                                                                                                         
		  else do;                                                                                                                                                    
		      innameonly="";                                                                                                                                          
		      bytes = floor((datasize+1023)/1024) * 1024; /* Round bytes up */                                                                                        
		      nodes = &nnodes ;                                                                                                                                       
			  put "ROUNDED BYTES = " bytes;                                                                                                                              
			  put "NODE COUNT    = " nodes;                                                                                                                              
                                                                                                                                                                
			  bytes=bytes/1024; * convert to kb;                                                                                                                         
		      blksize = floor(bytes / nodes);                                                                                                                         
                                                                                                                                                                
			  /* Check for block size boundary conditions */                                                                                                             
		      if blksize < 1 then blksize = 1;                                                                                                                        
		      if blksize > 64*1024 then blksize = 64 * 1024;                                                                                                          
                                                                                                                                                                
			  /* Convert to MB if large enough */                                                                                                                        
		      suffix = "k";                                                                                                                                           
		      if blksize > 1024 then do;                                                                                                                              
		         blksize = blksize / 1024;                                                                                                                            
		         suffix = "m";                                                                                                                                        
		      end;                                                                                                                                                    
              blkstr = trim(left(put(blksize,6.))) || suffix;                                                                                                   
	          put "BLOCK SIZE    = " blkstr;                                                                                                                       
		  end;                                                                                                                                                        
	  end;                                                                                                                                                         
                                                                                                                                                                
	  /* Clean up values */                                                                                                                                        
      tblname = trim(lowcase(libname)) || "." || trim(lowcase(memname));                                                                                        
	  length blkoptions $30;                                                                                                                                       
	  if missing(blksize) then                                                                                                                                     
	  	blkoptions="";                                                                                                                                              
	  else                                                                                                                                                         
	  	blkoptions="blocksize=" || blkstr;                                                                                                                          
                                                                                                                                                                
      keep tblname reclen datasize innameonly bytes nodes blkstr blkoptions;                                                                                    
   run;                                                                                                                                                         
                                                                                                                                                                
   proc sort data=tmpblk2;                                                                                                                                      
      by datasize;                                                                                                                                              
   run;                                                                                                                                                         
                                                                                                                                                                
   /* Output optimal block size;                                                                 */                                                                
                                                                                                                                                                
   data _null_;                                                                                                                                                 
      set tmpblk2;                                                                                                                                              
      call symput("&outvar.",blkoptions);                                                                                                                       
      call symput("&outvar2.",innameonly);                                                                                                                      
   run;                                                                                                                                                         
                                                                                                                                                                
   %mend GetHDFSOptimalBlockSizeOptions;                                                                                                                           
                                                                                                                                                                
   %GetHDFSOptimalBlockSizeOptions(lib=&sourcelib, data= &sourcetable , nnodes=&nnodes., outvar=blocksizeoptions, outvar2=innameonly);                                      
                                                                                                                                                                
   %LET SYSCC=0;                                                                                                                                                   
                                                                                                                                                                
   %macro deletedsifexists(lib,name);                                                                                                                              
      %if %sysfunc(exist(&lib..&name.)) %then %do;                                                                                                                 
         proc datasets library=&lib. nolist;                                                                                                                    
         delete &name.;                                                                                                                                         
      quit;                                                                                                                                                        
     %end;                                                                                                                                                           
   %mend deletedsifexists;                                                                                                                                         
                                                                                                                                                                
   /* Remove target data table from Library                                                      */                                                                
   %deletedsifexists(HPS, &targettable);                                                                                                                              
                                                                                                                                                                
   /* Access the data                                                                            */                                                                
                                                                                                                                                                
   LIBNAME HPS SASHDAT  PATH="&valibHadoop"  SERVER="&host"  INSTALL="/opt/TKGrid"  &innameonly.;                                                              
                                                                                                                                                                
   /* Add table                                                                                  */                                                                
   data HPS.&targettable ( &blocksizeoptions.replace=yes );                                                                                                           
      set &sourcelib..&sourcetable;                                                                                                                                         
   run;   

    %registerTable(                                                                                                                                        
              LIBRARY=%str(&smchadoop)                                                                  
            , REPOSITORY=%str(Foundation)                                                                                                                       
            , TABLE=%str(&targettable)                                                                                                                          
            , FOLDER=%str(&hadooppath)                                                                                                          
            );  


%mend;


%macro unload_lasrtable(table);
%let dsid =%sysfunc(open(VALIBLA.&table.));
%if &dsid %then %do;
  %let dsid =%sysfunc(close(&dsid));
  proc lasr port=&port                                                  
         signer="&signer"                                                                               
         ;                                                                                                                                                      
             remove &tag..&table;                                                                                                                          
            performance host="&host";                                                                                                  
         run;       


%end;
%mend;

%macro delete_lasrtable(table);

           
%let dsid =%sysfunc(open(VALIBLA.&table.));
%if &dsid %then %do;
  %let dsid =%sysfunc(close(&dsid));
  proc lasr port= &port                                                  
         signer="&signer"                                                                               
         ;                                                                                                                                                      
             remove hps.&table;                                                                                                                          
            performance host="&host";                                                                                                  
         run;       
%end;
 %unregisterTable(                                                                                                                                        
              LIBRARY=%str(&smcva)                                                                  
            , REPOSITORY=%str(Foundation)                                                                                                                       
            , TABLE=%str(&table)                                                                                                                          
                                                                                                                     
            );
%mend;



%macro hadoop_to_lasr(table, label, tablepath, readahead);

%let labelnm=&label;

%unload_lasrtable(&table);
%if "&tablepath" eq "" %then %do;
    %let tablepath = &defaultlasrpath;
%end;

    proc lasr port= &port 
    data=HPS.&table ( label="&labelnm") signer= "&signer"
	  add %if %UPCASE(&readahead) = YES %then %do; readahead fullcopyto=2 %end; noclass;                                                                                                
    performance host="&host";                                                                                                                              
    run; 
    
    %registerTable(                                                                                                                                        
              LIBRARY=%str(&smcva)                                                                  
            , REPOSITORY=%str(Foundation)                                                                                                                       
            , TABLE=%str(&table)                                                                                                                          
            , FOLDER=%str(&tablepath)                                                                                                          
            );

%mend;


%macro delete_hadoop(table);
%let dsid =%sysfunc(open(HPS.&table.));
%if &dsid %then %do;
  %let dsid =%sysfunc(close(&dsid));
  /*delete hadoop table*/
  proc oliphant host="&host"                    
     install="/opt/TKGrid"                                            
               ;                                                                
            remove &table path="&valibHadoop" ;                                   
  run; 

%unregisterTable(                                                                                                                                        
              LIBRARY=%str(&smchadoop)                                                                  
            , REPOSITORY=%str(Foundation)                                                                                                                       
            , TABLE=%str(&table)                                                                                                                          
            , FOLDER=%str(&hadooppath) 
            );

%end;             
%mend;

%macro append_to_lasr(sourcelib, sourcetable, lasrtable);
/*Append script from sasdatasets to lasr*/

OPTION SET=GRIDINSTALLLOC="/opt/TKGrid";

OPTION SET=GRIDHOST="&host";
data VALIBLA.&lasrtable (append);
  set &sourcelib..&sourcetable;
run;
%mend;



%macro hadoopbatchrun(sourcelib, sourcetable, targettable, targetlabel, tablepath, readahead=no);
%let targettbnm = &targettable;

%delete_hadoop(&targettbnm);
%dataset_to_hadoop(&sourcelib,&sourcetable,&targettbnm);
%hadoop_to_lasr(&targettbnm, &targetlabel, &tablepath, &readahead);

%mend;

%macro direct_load_lasr(sourcelib,sourcetable,targettable,targetlabel, tablepath);

%unload_lasrtable(&targettable);
%let labelnm=&targetlabel;
%if "&tablepath" eq "" %then %do;
    %let tablepath = &defaultlasrpath;
%end;

data VALIBLA.&targettable (label="&labelnm");

  set &sourcelib..&sourcetable;

run;
%registerTable(                                                                                                                                        
              LIBRARY=%str(&smcva)                                                                  
            , REPOSITORY=%str(Foundation)                                                                                                                       
            , TABLE=%str(&targettable)                                                                                                                          
            , FOLDER=%str(&tablepath)                                                                                                          
            );
%mend;

