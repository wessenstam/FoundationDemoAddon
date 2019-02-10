Function CMD-Create-FS {
  param (
    $Sysprepfile,
    [string] $DiskContainerName,
    [string] $SysprepPassword,
    [string] $Networkname,
    [string] $Network,   
    [string] $PocName,
    [string] $domainname,
    [string] $DNSServer1,
    [string] $DNSServer2,
    [string] $Gateway,
    [string] $subnetmask,
    [string] $fsiprangeInt,
    [string] $fsnameInt,
    [string] $fsiprangeExt,
    [string] $fSnameExt,
    [string] $CPU = 4,
    [string] $RAM = 16,
    [string] $data,
    [string] $PEClusterIP,
    [string] $clusername,
    [string] $clpassword,
    [string] $debug
  )
  $count1 = 0
  $count2 = 0
  write-log -message "Connecting to PS CMD on Prism Element"

  try {
    $hide = LIB-Connect-PSnutanix -ClusterName $PEClusterIP -NutanixClusterUsername $clusername -NutanixClusterPassword $clpassword

    $count++
    $cluster = Get-NTNXCluster
    if ($cluster){;

      write-log -message "Creating File server on PE Cluster"

    };
  } catch {

    write-log -message "Not connected." -sev "WARN"

  }

  function Convert-IpAddressToMaskLength {
    Param(
      [string] $dottedIpAddressString
      )
    $result = 0; 
    # ensure we have a valid IP address
    [IPAddress] $ip = $dottedIpAddressString;
    $octets = $ip.IPAddressToString.Split('.');
    foreach($octet in $octets)
    {
      while(0 -ne $octet) 
      {
        $octet = ($octet -shl 1) -band [byte]::MaxValue
        $result++; 
      }
    }
    return $result;
  }



  write-log -message "Starting Network Setup";
  try {
    $network = (Get-NTNXNetwork | where { $_.name -match $Networkname }).uuid
    if($network){;
      write-log -message "Network found, UUID Captured.";
      $internal = New-NTNXObject -name FileServerNetworkOpsDTO
      $internal.name           = "$fsnameInt"
      $internal.uuid           = "$network"
      $internal.pool           = "$($fsiprangeInt.split(' ')[0]) $($fsiprangeInt.split(' ')[1])"
      $internal.subnetmask     = "$subnetmask"
      $internal.defaultGateway = "$Gateway"
      $external = New-NTNXObject -name FileServerNetworkOpsDTO
      $external.name           = "$fSnameExt"
      $external.uuid           = "$network"
      $external.pool           = "$fsiprangeExt"
      $external.subnetmask     = "$subnetmask"
      $external.defaultGateway = "$Gateway"
      write-log -message "Done setting up network";    
      write-log -message "The Following FS objects were created:";
      $internal;
      $external;
    } else {;
      write-log -message "Specified VLANID: $Networkname, does not exist, it needs to be created in Prism, exiting" -sev "ERROR";
      write-log -message "Is this a hosted POC???, are we connected to Nutanix Powershell?" -sev "ERROR";
    };
  } catch {;
    write-log -message "Specified VLANID: $Networkname, does not exist, it needs to be created in Prism, exiting" -sev "ERROR";
    write-log -message "Is this a hosted POC???, are we connected to Nutanix Powershell?" -sev "ERROR";
  };


  write-log -message "Setting up FS Object";
  $Principle = New-NTNXObject -NAME GetPrincipalTypeDTO;
  $Principle.protocoltype = "smb";
  $Principle.principalType = "Group";
  $contianer = Get-NTNXContainer | where {$_.name -match $DiskContainerName} | select -first 1;
  $netbios = $domainname.split(".")[0];

  try {;
    New-NTNXFileServer -Name "$($external.name)" -MemoryGiB $RAM -numvcpus $CPU -dnsdomainname "$($domainname)" -GetPrincipalTypeDTO $PRINCIPLE -dnsserverIPaddress $DNSServer1,$DNSServer2 -ntpservers $DNSServer1 -WindowsAdUsername "administrator" -WindowsAdPassword $SysprepPassword -WindowsAdDomainName $domainname -InternalNetwork $internal -ExternalNetworks $external -NumCalculatedNvms 3 -size 1024 -ContainerUuid $contianer.uuid
  } catch {;
    write-log -message "Files command is executed, testing if running";
    sleep 60;
    $countfsVms = (get-ntnxvm | where {$_.vmname -match "FS"}).count;
    if ($countfsVms -ge 2){;
      write-log -message "File servers have been depoyed, configuring";      
    } else {;
      try {;
        New-NTNXFileServer -Name "$($external.name)" -MemoryGiB $RAM -numvcpus $CPU -dnsdomainname "$($domainname)" -dnsserverIPaddress $DNSServer1,$DNSServer2 -ntpservers $DNSServer1 -WindowsAdUsername "administrator" -WindowsAdPassword $SysprepPassword -WindowsAdDomainName $domainname -InternalNetwork $internal -ExternalNetworks $Enternal -NumCalculatedNvms 3 -size 1024 -ContainerUuid $contianer.uuid
      } catch {;
        write-log -message "RETRY: Files command is executed, testing if running" -sev "WARN" ;
        sleep 60;
        $countfsVms = (get-ntnxvm | where {$_.vmname -match "FS"}).count;
      };
    };
  };
  if ($countfsVms -ge 2){;
    write-log -message "File servers have been depoyed, configuring";
    $status = "Success"     
  } else {;
    $status = "failed"
    write-log -message "File servers has failed after retry." -sev "ERROR"  ;      
  };
  $resultobject =@{
    Result = $status
  };
  return $resultobject
};
Export-ModuleMember *