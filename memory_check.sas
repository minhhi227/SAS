/**************/
LIBNAME LASRLIB SASIOLA  TAG=HPS  PORT=10011 HOST="sas-node0.deltavn.vn"  
SIGNER="http://sas-node0.deltavn.vn:7980/SASLASRAuthorization" ;

/* Alternatively, use the PRINT procedure */
data lasrmemory;
  set LASRLIB._T_LASRMEMORY;
run;

proc print data=lasrmemory;
    title "Distributed Server Memory Use";
    format _numeric_ sizekmg9.2;
run;

%let sizecols = InMemorySize UncompressedSize 
                CompressedSize TableAllocatedMemory
                InMemoryMappedSize ChildSMPTableMemory;
%let countcols = NumberRecords UseCount RecordLength ComputedColLength;

data tablemem;
    set LASRLIB._T_TABLEMEMORY;
     where inmemorysize>0;
run;

proc print data=tablemem;
    title "Distributed Server Table Memory Usage";
    format &sizecols.  sizekmg9.2;
    format &countcols. 8.;
    sum _numeric_;
run;

/**************/
