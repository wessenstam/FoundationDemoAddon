Function SSH-RoleMapping-Px {
  Param (
    [string] $PxClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $domainname,
    [string] $admingroup = "Domain Admins",
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $count = 0 
  write-log -message "Building Credential for SSH session";

  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  $credential = New-Object System.Management.Automation.PSCredential ($clusername, $Securepass);
  $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey;
  $netbios = $domainname.split(".")[0]

  write-log -message "Setting up Role mappings for $netbios";

  do {;
    $count++
    try {;
      $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey;
      
      write-log -message "Setting the values";
      
      $SetRoleMapping = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli authconfig add-role-mapping role=ROLE_CLUSTER_ADMIN entity-type=group name='$($netbios)' entity-values='$($admingroup)'" -EnsureConnection
      
      write-log -message "Testing the values";
      
      $result = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli authconfig list-role-mappings name='$($netbios)'" -EnsureConnection
    } catch {;
      $PCDownloadCompleted = $false

      write-log -message "Error setting rolemapping through NCLI PC, Retry" -sev "WARN";

      sleep 2
    };
  } until (($result.output -match $netbios) -or $count -ge 5)

 
  if ($result.output -match $netbios){
    $status = "Success"

  } else {
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
    Output = $result.output
  }
  Try {
    write-log -message "Executing session cleanup"
    Remove-SSHSession -SSHSession $session
  } catch {}
  return $resultobject
};
Export-ModuleMember *