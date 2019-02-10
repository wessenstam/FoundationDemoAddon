Function PSR-Create-Domain {
  param (
    [string] $SysprepPassword,
    [string] $IP,
    [string] $DNSServer,
    [string] $Domainname,
    [string] $debug
  )
  $netbios = $Domainname.split(".")[0]

  write-log -message "Debug level is $debug";
  write-log -message "Building credential object.";

  $password = $SysprepPassword | ConvertTo-SecureString -asplaintext -force;
  $credential = New-Object System.Management.Automation.PsCredential("administrator",$password);

  write-log -message "Installing AD software";
  write-log -message "Awaiting completion install AD software";

  try {  
    $connect = invoke-command -computername $ip -credential $credential { Install-WindowsFeature -Name AD-Domain-Services,GPMC,DNS -IncludeManagementTools -Restart};
  } catch {

    write-log -message "Retry Promote First DC." -sev "WARN";

    $connect = invoke-command -computername $ip -credential $credential { Install-WindowsFeature -Name AD-Domain-Services,GPMC,DNS -IncludeManagementTools -Restart};
  }
  write-log -message "Waiting in a 15 second loop before the machine is online again.";
  do {;
    sleep 15;
    $test = test-connection -computername $ip -ea:0;
    $count++;
  } until ($test[0].statuscode -eq 0 -or $count -eq 6 );
  write-log -message "Creating Forest";
  try {
    $connect = invoke-command -computername $ip -credential $credential { Install-ADDSForest -DomainNetbiosName $Args[2] -DomainName $args[0] -SafeModeAdministratorPassword $Args[1] -force} -args $Domainname,$password,$netbios;
  } catch {
    write-log -message "Retry Promote First DC." -sev "WARN"
    sleep 60
    $connect = invoke-command -computername $ip -credential $credential { Install-ADDSForest -DomainNetbiosName $Args[2] -DomainName $args[0] -SafeModeAdministratorPassword $Args[1] -force} -args $Domainname,$password,$netbios;
  }
  write-log -message "Sleeping 120 seconds additional to the completion.";
  write-log -message "Awaiting completion Forest creation";
  sleep 120;
  write-log -message "Setting DNS Server Forwarder $DNSServer.";
  try{
    $connect = invoke-command -computername $ip -credential $credential { $dns = set-dnsserverforwarder -ipAddress $args[0]} -args $DNSServer;
  } catch {
    write-log -message "Retry DNS Record.";
    sleep 60
    $connect = invoke-command -computername $ip -credential $credential { $dns = set-dnsserverforwarder -ipAddress $args[0]} -args $DNSServer;
  }
  write-log -message "Waiting for settings to apply";
  sleep 60;
  write-log -message "Checking DNS Server Forwarder";
  try {
    $result = invoke-command -computername $ip -credential $credential {
      (get-dnsserverforwarder ).ipAddress[0].ipAddresstostring
    } 
  } catch {
    $result = invoke-command -computername $ip -credential $credential {
      (get-dnsserverforwarder ).ipAddress[0].ipAddresstostring
    } 
  }
  if ($result -match $DNSServer){
    $status = "Success"

    write-log -message "We are all done here, one to beam up.";

  } else {
    $status = "Failed"
    Write-host $result
    write-log -message "Danger Will Robbinson." -sev "ERROR";

  }
  $resultobject =@{
    Result = $status
    Object = $result
  };
  return $resultobject
};
Export-ModuleMember *