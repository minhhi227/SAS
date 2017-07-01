/*Connect to the metadata server.  */

options metaserver="hsi-vasas-srv"
	metaport=8561
	metauser="sasadm@saspw"
	metapass="SASpw123"
	metarepository="Foundation";

/*Connect to the metadata server using the metadata system options 
shown in the first example.*/

data logins;

  /* The LENGTH statement defines variables for function arguments and assigns
the maximum length for each variable.  */
  
  length LoginObjId UserId IdentId AuthDomId $ 17
         IdentType $ 32
         Name DispName Desc uri uri2 uri3 AuthDomName $ 256;

/* The CALL MISSING routine initializes the output variables to missing values.  */

  call missing
(LoginObjId, UserId, IdentType, IdentId, Name, DispName, Desc, AuthDomId, AuthDomName);
  call missing(uri, uri2, uri3);
  n=1;

 /* The METADATA_GETNOBJ function specifies to get the Login objects 
in the repository. The n argument specifies to get the first object that
matches the uri requested in the first argument. The uri argument is an output 
variable. It will store the actual uri of the Login object that is returned. 
The program prints an informational message if no objects are found. */

  objrc=metadata_getnobj("omsobj:Login?@Id contains '.'",n,uri);
  if objrc<=0 then put "NOTE: rc=" objrc 
    "There are no Logins defined in this repository"
    " or there was an error reading the repository.";

/* The DO statement specifies a group of statements to be executed as a unit
for the Login object that is returned by METADATA_GETNOBJ. The METADATA_GETATTR 
function gets the values of the object's Id and UserId attributes. */

  do while(objrc>0);
     arc=metadata_getattr(uri,"Id",LoginObjId);
     arc=metadata_getattr(uri,"UserId",UserId);
  
/* The METADATA_GETNASN function specifies to get objects associated 
via the AssociatedIdentity association. The AssociatedIdentity association name 
returns both Person and IdentityGroup objects, which are subtypes of the Identity
metadata type. The URIs of the associated objects are returned in the uri2 variable. 
If no associations are found, the program prints an informational message. */

     n2=1;
     asnrc=metadata_getnasn(uri,"AssociatedIdentity",n2,uri2);
     if asnrc<=0 then put "NOTE: rc=" asnrc 
       "There is no Person or Group associated with the " UserId "user ID.";

/* When an association is found, the METADATA_RESOLVE function is called to 
resolve the URI to an object on the metadata server. */

     else do;
       arc=metadata_resolve(uri2,IdentType,IdentId);

	/* The METADATA_GETATTR function is used to get the values of each identity's 
Name, DisplayName and Desc attributes. */

       arc=metadata_getattr(uri2,"Name",Name);
       arc=metadata_getattr(uri2,"DisplayName",DispName);
       arc=metadata_getattr(uri2,"Desc",Desc);
     end;
  
 /* The METADATA_GETNASN function specifies to get objects associated 
via the Domain association. The URIs of the associated objects are returned in 
the uri3 variable. If no associations are found, the program prints an 
informational message. */ 
  
     n3=1;
     autrc=metadata_getnasn(uri,"Domain",n3,uri3);
     if autrc<=0 then put "NOTE: rc=" autrc 
       "There is no Authentication Domain associated with the " UserId "user ID.";
 
		/* The METADATA_GETATTR function is used to get the values of each 
AuthenticationDomain object's Id and Name attributes. */

     else do;
       arc=metadata_getattr(uri3,"Id",AuthDomId);
       arc=metadata_getattr(uri3,"Name",AuthDomName);
     end;

     output;

  /* The CALL MISSING routine reinitializes the variables back to missing values. */

  call missing(LoginObjId, UserId, IdentType, IdentId, Name, DispName, Desc, AuthDomId, 
AuthDomName);

 /* Look for more Login objects */

 n+1;
  objrc=metadata_getnobj("omsobj:Login?@Id contains '.'",n,uri);
  end;  

/* The KEEP statement specifies the variables to include in the output data set.  */

  keep LoginObjId UserId IdentType Name DispName Desc AuthDomId AuthDomName; 
run;

/* The PROC PRINT statement prints the output data set. */
proc print data=logins;
   var LoginObjId UserId IdentType Name DispName Desc AuthDomId AuthDomName;
run;