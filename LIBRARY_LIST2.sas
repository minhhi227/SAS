/*Connect to the metadata server.  */

options metaserver="hsi-vasas-srv"
	metaport=8561
	metauser="sasadm@saspw"
	metapass="SASpw123"
	metarepository="Foundation";

data work.Libraries;

/* The LENGTH statement defines variables for function arguments and
assigns the maximum length for each variable.  */

  length LibId LibName $ 32 LibRef LibEngine $ 8 LibPath $ 256
ServerContext uri uri2 type $ 256 server $ 32;

/* The LABEL statement assigns descriptive labels to variables. */

  label
LibId = "Library Id"
LibName = "Library Name"
LibRef = "SAS Libref"
LibEngine = "Library Engine"
ServerContext = "Server Contexts"
LibPath = "Library Path"
;

/* The CALL MISSING routine initializes output variables to missing values.  */

  call missing(LibId,LibName,LibRef,LibEngine,LibPath,
       ServerContext,uri,uri2,type,server);
  n=1;
  n2=1;

  /* The METADATA_GETNOBJ function gets the first Library object. If none 
are found, the program prints an informational message. */
  rc=metadata_getnobj("omsobj:SASLibrary?@Id contains '.'",n,uri);
  if rc<=0 then put "NOTE: rc=" rc 
    "There are no Libraries defined in this repository"
    " or there was an error reading the repository.";

/* The DO statement specifies a group of statements to be executed as a unit
for the object that is returned by METADATA_GETNOBJ. The METADATA_GETATTR 
function gets the values of the Id, Name, LibRef, and Engine attributes 
of the SASLibrary object.  */

  do while(rc>0);
     objrc=metadata_getattr(uri,"Id",LibId);
     objrc=metadata_getattr(uri,"Name",LibName);
objrc=metadata_getattr(uri,"Libref",LibRef);
objrc=metadata_getattr(uri,"Engine",LibEngine);

	 /* The METADATA_GETNASN function gets objects associated 
via the DeployedComponents association. If none are found, the program
prints an informational message. */

	 objrc=metadata_getnasn(uri,"DeployedComponents",n2,uri2);
	 if objrc<=0 then
       do;
         put "NOTE: There is no DeployedComponents association for "
             LibName +(-1)", and therefore no server context.";
	     ServerContext="";
	   end;

 /* When an association is found, the METADATA_GETATTR function gets
the server name. */
 
	   do while(objrc>0);
         objrc=metadata_getattr(uri2,"Name",server);
	     if n2=1 then ServerContext=quote(trim(server));
		 else ServerContext=trim(ServerContext)||" "||quote(trim(server));

/* Look for another ServerContext */
	     n2+1;
         objrc=metadata_getnasn(uri,"DeployedComponents",n2,uri2);
	   end; /*do while objrc*/ 

     n2=1;

	 /* The METADATA_GETNASN function gets objects associated via the 
UsingPackages association. The program prints a message if an 
association is not found.*/

	 objrc=metadata_getnasn(uri,"UsingPackages",n2,uri2);
	 if objrc<=0 then
       do;
         put "NOTE: There is no UsingPackages association for " 
             LibName +(-1)", and therefore no Path.";
	     LibPath="";
	   end;

/* When a UsingPackages association is found, the METADATA_RESOLVE function 
is called to resolve the URI to an object on the metadata server. */

	   do while(objrc>0);
	     objrc=metadata_resolve(uri2,type,id);

	/*if type='Directory', the METADATA_GETATTR function is used to get its path */

	if type='Directory' then objrc=metadata_getattr(uri2,"DirectoryName",LibPath);

	/*if type='DatabaseSchema', the METADATA_GETATTR function is used to get 
the name */

	 else if type='DatabaseSchema' then objrc=metadata_getattr(uri2, "Name", LibPath);
		 else LibPath="*unknown*";

		/* output the records */
	     output;
	     LibPath="";

		/* Look for other directories or database schemas */

         n2+1;
	     objrc=metadata_getnasn(uri,"UsingPackages",n2,uri2);
	   end; /*do while objrc*/ 

     ServerContext="";
     n+1;

		/* Look for other libraries */

	 n2=1;
     rc=metadata_getnobj("omsobj:SASLibrary?@Id contains '.'",n,uri);

  end; /*do while rc*/  

/* The KEEP statement defines the variables to include in the output data set. */

  keep
LibId
LibName
LibRef
LibEngine
ServerContext
LibPath; 
run;

/* Write a basic listing of data */

proc print data=work.Libraries label;
  /* subset results if you wish
     where indexw(ServerContext,'"SASMain"') > 0; */
run;