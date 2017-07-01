/*Connect to the metadata server.  */

options metaserver="hsi-vasas-srv"
	metaport=8561
	metauser="sasadm@saspw"
	metapass="SASpw123"
	metarepository="Foundation";

/*Connect to the metadata server using the metadata system options as 
shown in the first example. */

data work.Identities;

/* The LENGTH statement defines the lengths of variables for function arguments. */
length IdentId IdentName DispName ExtLogin IntLogin DomainName $32 
uri uri2 uri3 uri4 $256;

/* The LABEL statement assigns descriptive labels to variables. */
label
	IdentId    = "Identity Id"
	IdentName  = "Identity Name"
	DispName   = "Display Name"
	ExtLogin   = "External Login"
	IntLogin   = "Is Account Internal?"
	DomainName = "Authentication Domain";

/* The CALL MISSING statement initializes the output variables to missing values. */
call missing(IdentId, IdentName, DispName, ExtLogin, IntLogin, DomainName, 
uri, uri2, uri3, uri4);
n=1;
n2=1;

/* The METADATA_GETNOBJ function specifies to get the Person objects in the repository. 
The n argument specifies to get the first person object that is returned. 
The uri argument will return the actual uri of the Person object. The program prints an 
informational message if no objects are found. */

rc=metadata_getnobj("omsobj:Person?@Id contains '.'",n,uri);
if rc<=0 then put "NOTE: rc=" rc
"There are no identities defined in this repository" 
" or there was an error reading the repository.";

/* The DO statement specifies a group of statements to be executed as a unit. 
The METADATA_GETATTR function gets the values of the Person object's Id, Name, 
and DisplayName attributes. */
do while(rc>0); 
	objrc=metadata_getattr(uri,"Id",IdentId);
	objrc=metadata_getattr(uri,"Name",IdentName); 
	objrc=metadata_getattr(uri,"DisplayName",DispName);

/* The METADATA_GETNASN function gets objects associated via the
InternalLoginInfo association. The InternalLoginInfo association returns
internal logins. The n2 argument specifies to return the first associated object
for that association name. The URI of the associated object is returned in
the uri2 variable. */

objrc=metadata_getnasn(uri,"InternalLoginInfo",n2,uri2);

/* If a Person does not have any internal logins, set their IntLogin
variable to 'No' Otherwise, set to 'Yes'. */
IntLogin="Yes";
DomainName="**None**";
if objrc<=0 then
do;
put "NOTE: There are no internal Logins defined for " IdentName +(-1)".";
IntLogin="No";
end;

/* The METADATA_GETNASN function gets objects associated via the Logins association. 
The Logins association returns external logins. The n2 argument specifies to return 
the first associated object for that association name. The URI of the associated 
object is returned in the uri3 variable. */

objrc=metadata_getnasn(uri,"Logins",n2,uri3);

/* If a Person does not have any logins, set their ExtLogin
variable to '**None**' and output their name. */
if objrc<=0 then
do;
put "NOTE: There are no external Logins defined for " IdentName +(-1)".";
ExtLogin="**None**";
output;
end;

/* If a Person has many logins, loop through the list and retrieve the name of 
each login. */
do while(objrc>0);
objrc=metadata_getattr(uri3,"UserID",ExtLogin);

/* If a Login is associated to an authentication domain, get the domain name. */
DomainName="**None**";
objrc2=metadata_getnasn(uri3,"Domain",1,uri4);
if objrc2 >0 then
do;
 objrc2=metadata_getattr(uri4,"Name",DomainName);
end;

/*Output the record. */
output;

n2+1;

/* Retrieve the next Login's information */
objrc=metadata_getnasn(uri,"Logins",n2,uri3);
end; /*do while objrc*/

/* Retrieve the next Person's information */
n+1;
n2=1;

rc=metadata_getnobj("omsobj:Person?@Id contains '.'",n,uri);
end; /*do while rc*/

/* The KEEP statement specifies the variables to include in the output data set. */
keep IdentId IdentName DispName ExtLogin IntLogin DomainName; 
run;

/* The PROC PRINT statement writes a basic listing of the data. */
proc print data=work.Identities label;
run;

