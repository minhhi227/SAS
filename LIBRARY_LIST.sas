/*Connect to the metadata server.  */

options metaserver="hsi-vasas-srv"
	metaport=8561
	metauser="sasadm@saspw"
	metapass="SASpw123"
	metarepository="Foundation";

/* Begin the query. The DATA statement names the output data set.  */

data metadata_libraries;

/* The LENGTH statement defines variables for function arguments and
assigns the maximum length of each variable.  */

  length liburi upasnuri $256 name $128 type id $17 libref engine $8 path 
mdschemaname schema $256;

/* The KEEP statement defines the variables to include in the 
output data set.  */

  keep name libref engine path mdschemaname schema;

/* The CALL MISSING routine initializes the output variables to missing values.  */

  call missing(liburi,upasnuri,name,engine,libref);

  /* The METADATA_GETNOBJ function specifies to get the SASLibrary objects 
in the repository. The argument nlibobj=1 specifies to get the first object that
matches the requested URI. liburi is an output variable. It will store the URI 
of the returned SASLibrary object. */

  nlibobj=1;
  librc=metadata_getnobj("omsobj:SASLibrary?@Id contains '.'",nlibobj,liburi);

  /* The DO statement specifies a group of statements to be executed as a unit
for each object that is returned by METADATA_GETNOBJ. The METADATA_GETATTR function
is used to retrieve the values of the Name, Engine, and Libref attributes of 
the SASLibrary object.  */

  do while (librc>0);

     /* Get Library attributes */
     rc=metadata_getattr(liburi,'Name',name);
     rc=metadata_getattr(liburi,'Engine',engine);
	  rc=metadata_getattr(liburi,'Libref',libref);
	 
	  /* The METADATA_GETNASN function specifies to get objects associated to the 
library via the UsingPackages association. The n argument specifies to return the 
first associated object for that association type. upasnuri is an output variable. 
It will store the URI of the associated metadata object, if one is found.  */

	    n=1;
	    uprc=metadata_getnasn(liburi,'UsingPackages',n,upasnuri);

	    /* When a UsingPackages association is found, the METADATA_RESOLVE function 
is called to resolve the URI to an object on the metadata server. The CALL MISSING 
routine assigns missing values to output variables.  */

	    if uprc > 0 then do;
	       call missing(type,id,path,mdschemaname,schema);
	       rc=metadata_resolve(upasnuri,type,id);

           /* If type='Directory', the METADATA_GETATTR function is used to get its 
path and output the record */

           if type='Directory' then do;
		      rc=metadata_getattr(upasnuri,'DirectoryName',path);
			  output;
              end; 

           /* If type='DatabaseSchema', the METADATA_GETATTR function is used to get 
the name and schema, and output the record */

           else if type='DatabaseSchema' then do;
               rc=metadata_getattr(upasnuri,'Name',mdschemaname);
               rc=metadata_getattr(upasnuri,'SchemaName',schema);
              output;
              end; 

		/* Check to see if there are any more Directory objects */

            n+1;
            uprc=metadata_getnasn(liburi,'UsingPackages',n,upasnuri);
		  end; /* if uprc > 0 */

	 /* Look for another library */

	 nlibobj+1;
     librc=metadata_getnobj("omsobj:SASLibrary?@Id contains '.'",nlibobj,liburi);
  end; /* do while (librc>0) */
run;

/* Print the metadata_libraries data set */ 

proc print data=metadata_libraries; run;