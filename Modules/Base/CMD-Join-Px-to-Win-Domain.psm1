function CMD-Join-PxtoADDomain{
  param (
    [string] $Domainname,
    [string] $SysprepPassword,
    [string] $DC1_IPAddress,
    [string] $dc2_IPaddress,
    [string] $PxClusterIP,
    [string] $peadmin,
    [string] $pepass,
    [string] $debug
  )

  $count3 = 0;
  write-log -message "Connecting to PS CMD on Prism Element";
  do{;
    $count3++
    try {;
      $hide = LIB-Connect-PSnutanix -ClusterName $PxClusterIP -NutanixClusterUsername $PEAdmin -NutanixClusterPassword $PEPass;
  
      $count++
      $cluster = Get-NTNXCluster;
      if ($cluster){;
  
        write-log -message "Joining Px Cluster to the Windows domain";
  
      };
    } catch {;
  
      write-log -message "Not connected." -sev "WARN";
  
    };
    $netbios = $Domainname.split(".")[0];
    
    write-log -message "We determined the netbios name is $netbios";
    write-log -message "Setting up DNS with entries $DC1_IPAddress and $dc2_IPaddress";
    write-log -message "Removing NTP servers, Adding AD NTP Servers";
    
    try {
      $hide = Get-NTNXNtpServer | remove-ntnxntpserver
      $hide = add-ntnxntpserver -arg0 $DC1_IPAddress
      $hide = add-ntnxntpserver -arg0 $DC2_IPAddress

      write-log -message "NTP Setup Success";

    } catch {

      write-log -message "NTP Setup Failure" -sev "WARN";

    }

    write-log -message "Removing DNS servers, Adding AD DNS Servers";
    try{
      $hide = Get-NTNXNameServer | Remove-ntnxnameserver
      $hide = add-ntnxnameserver -arg0 $DC1_IPAddress
      $hide = add-ntnxnameserver -arg0 $dc2_IPaddress

      write-log -message "DNS Setup Success";

    } catch {
      write-log -message "DNS Setup Failure" -sev "WARN";
    }
    $authdom = get-NTNXAuthConfigDirectory;
    if ($authdom.domain -match $Domainname){;
      write-log -message "Px already Joined.";
      write-log -message "See config below";
      $authdom
    } else {
      try {
        $hide = add-NTNXAuthConfigDirectory -ServiceAccountUsername "$($netbios)\administrator" -ServiceAccountPassword $SysprepPassword -DirectoryType "ACTIVE_DIRECTORY" -ConnectionType "LDAP"  -DirectoryUrl "ldap://$($DC1_IPAddress):389" -Domain $DomainName -name $netbios -Groupsearchtype "Recursive";
        
        write-log -message "Px Join Success.";

      } catch {
        sleep 60

        write-log -message "Px Join Failure.";

      }
    }
    sleep 10
    $authdom = get-NTNXAuthConfigDirectory;
  } Until ($authdom -or $count3 -ge 5)
  if ($authdom){
    $status = "Success"
    if ($debug -ge 2){
      write-host $authdom
    }
  } else {
    $status = "Failure"
  }
  $resultobject =@{
    Result = $status
  };
  return $resultobject
};
Export-ModuleMember *
