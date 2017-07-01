
/*Connect to the metadata server using the metadata system options as 
shown in the first example. */

data users_grps;

/* The LENGTH statement defines variables for function arguments and 
assigns the maximum length of each variable.  */  

  length uri name dispname group groupuri $256 
id MDUpdate $20;
  
/* The CALL MISSING routine initializes output variables to missing values.*/

  n=1;
	  call missing(uri, name, dispname, group, groupuri, id, MDUpdate);

    
  /* The METADATA_GETNOBJ function specifies to get the Person objects 
in the repository. The n argument specifies to get the first Person object that is
returned. The uri argument will return the actual uri of the Person object that 
is returned. The program prints an informational message if no Person objects 
are found. */

      nobj=metadata_getnobj("omsobj:Person?@Id contains '.'",n,uri);
  if nobj=0 then put 'No Persons available.';

/* The DO statement specifies a group of statements to be executed as a unit
for the Person object that is returned by METADATA_GETNOBJ. The METADATA_GETATTR 
function gets the values of the object's Name and DisplayName attributes. */

  else do while (nobj > 0);
     rc=metadata_getattr(uri, "Name", Name);
     rc=metadata_getattr(uri, "DisplayName", DispName);


/* The METADATA_GETNASN function gets objects associated via the IdentityGroups 
association. The a argument specifies to return the first associated object for 
that association type. The URI of the associated object is returned in the 
groupuri variable.  */

   a=1;
	 grpassn=metadata_getnasn(uri,"IdentityGroups",a,groupuri);
	    
		/* If a person does not belong to any groups, set their group
	      variable to 'No groups' and output their name. */

	 if grpassn in (-3,-4) then do;
            group="No groups";
	    output;
	 end;

	    /* If the person belongs to many groups, loop through the list
	      and retrieve the Name and MetadataUpdated attributes of each group, 
			outputting each on a separate record. */

	 else do while (grpassn > 0);
		rc2=metadata_getattr(groupuri, "Name", group);
		rc=metadata_getattr(groupuri, "MetadataUpdated", MDUpdate);
		a+1;
		output;
        grpassn=metadata_getnasn(uri,"IdentityGroups",a,groupuri);
     end;
	   
	   /* Retrieve the next person's information */

     n+1;
     nobj=metadata_getnobj("omsobj:Person?@Id contains '.'",n,uri);
  end;

/* The KEEP statement specifies the variables to include in the output data set. */

  keep name dispname MDUpdate group;
run;

   /* Display the list of users and their groups */
proc report data=users_grps nowd headline headskip;
  columns name dispname group MDUpdate;
  define name / order 'User Name' format=$30.;
  define dispname / order 'Display Name' format=$30.;
  define group / order 'Group' format=$30.;
  define MDUpdate / display 'Updated' format=$20.;
  break after name / skip;
run;