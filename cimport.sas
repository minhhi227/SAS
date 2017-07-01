/* set vaelib to be the location of your vaelib library - defaults to following path */
/*libname inlib cvp '/opt/sas/resources/geomaps/wlatin';
libname outlib '/opt/sas/resources/geomaps' outencoding='utf-8';
proc copy noclone in=inlib out=outlib;
run;*/







libname vaelib '/opt/sas/resources/geomaps' outencoding="utf-8";
proc cimport 
infile='centlookup.dpo' lib=vaelib; run;

proc cimport 
infile='attrlookup.dpo' lib=vaelib; run;

