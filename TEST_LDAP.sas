/* EDIT: Define Active Directory or LDAP server connection parameters. */

   %let LDAPServer = "10.0.18.31";
   %let LDAPPort   = 389;
   %let BaseDN = "CN=Users,DC=CONTOSO,DC=com";
   %let BindUserDN = "CN=Administrator,CN=Users,DC=CONTOSO,DC=com";
   %let BindUserPW = "Hptvietnam!@#$%";

/* EDIT: Define a filter value and attribute list to return. If you want
   all attributes defined, use %let Attrs=" ";  Double quotes are
   required. */
   
   %let Filter = "(CN=Administrator)";
   
   %let Attrs=  "displayName streetAddress cn company mail employeeID " ||
                "facsimileTelephoneNumber distinguishedName l "         ||
                "mobile otherTelephone physicalDeliveryOfficeName "     ||
                "postalCode name sAMAccountName st "                    ||
                "telephoneNumber co title whenChanged whenCreated";
   
data _null_;

    length entryname $200 attrName $100 value $100 filter $110;
 
    rc =0; handle =0;
    
    server=&LDAPServer;
    port=&LDAPPort;
    base=&BaseDN;
    bindDN=&BindUserDN;
    Pw=&BindUserPW;
 
    /* open connection to LDAP server */
    call ldaps_open(handle, server, port, base, bindDn, Pw, rc);
    if rc ne 0 then do;
       put "LDAPS_OPEN call failed.";
       msg = sysmsg();
       put rc= / msg;
    end;
    else
       put "LDAPS_OPEN call successful.";

    shandle=0;
    num=0;

    filter=&Filter;
      
    /* search and return attributes for objects */
      
    attrs=&Attrs;
 
    /* search the LDAP directory */
    call ldaps_search(handle,shandle,filter, attrs, num, rc);
    if rc ne 0 then do;
       put "LDAPS_SEARCH call failed.";
       msg = sysmsg();
       put rc= / msg;
    end;
    else do;
       put " ";
       put "LDAPS_SEARCH call successful.";
       put "Num entries returned is " num;
       put " ";
    end;

    do eIndex = 1 to num;
      numAttrs=0;
      entryname='';

      /* retrieve each entry name and number of attributes */
     call ldaps_entry(shandle, eIndex, entryname, numAttrs, rc);
     if rc ne 0 then do;
         put "LDAPS_ENTRY call failed.";
         msg = sysmsg();
         put rc= / msg;
      end;
      else do;
         put "  ";
         put "LDAPS_ENTRY call successful.";
         put "Num attributes returned is " numAttrs;
      end;

      /* for each attribute, retrieve name and values */
      do aIndex = 1 to numAttrs;
        attrName='';
        numValues=0;
        call ldaps_attrName(shandle, eIndex, aIndex, attrName, numValues, rc);
        if rc ne 0 then do;
           msg = sysmsg();
           put rc= / msg;
        end;
       else do;
           put "  ";
           put "  ATTRIBUTE name : " attrName;
           put "  NUM values returned : " numValues;
        end;

        do vIndex = 1 to numValues;
          call ldaps_attrValue(shandle, eIndex, aIndex, vIndex, value, rc);
          if rc ne 0 then do;
             msg = sysmsg();
             put rc= / msg;
          end;
          else do;
             put "  Value : " value;        
          output;
          end;
        end;
      end;
    end;

    
    /* free search resources */
    put /;
    call ldaps_free(shandle,rc);
    if rc ne 0 then do;
       put "LDAPS_FREE call failed.";
       msg = sysmsg();
       put rc= / msg;
    end;
    else
       put "LDAPS_FREE call successful.";

  /* close connection to LDAP server */
    put /;
    call ldaps_close(handle,rc);
    if rc ne 0 then do;
       put "LDAPS_CLOSE call failed.";
       msg = sysmsg();
       put rc= / msg;
    end;
    else
       put "LDAPS_CLOSE call successful.";
run;