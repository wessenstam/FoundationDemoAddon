Function PSR-Add-DomainController {
  param (
    [string]$SysprepPassword,
    [string]$IP,
    [string]$DNSServer,
    [string]$Domainname,
    [string]$debug
  )
  write-log -message "Debug level is $debug";
  write-log -message "Building credential objects (2).";

  $password = $SysprepPassword | ConvertTo-SecureString -asplaintext -force;
  $LocalCreds = New-Object System.Management.Automation.PsCredential("administrator",$password);
  $DomainCreds = New-Object System.Management.Automation.PsCredential("$($Domainname)\administrator",$password);

  $installsuccess = $false
  $installcount = 0
  $promotesuccess = $false
  $promotecount = 0
  $Joincount = 0
  $JoinSuccess = $true

  write-log -message "Joining the machine to the domain.";
 
  do{
    $Joincount++
    try {
      if (-not (Test-Connection -ComputerName $IP -Quiet -Count 1)) {
      
        write-log -message "Could not reach $IP" -sev "WARN"
      
      } else {
      
        write-log -message "$IP is being added to domain $Domainname..."
      
        try {
          Add-Computer -ComputerName $IP -Domain $Domainname -Restart -Localcredential $LocalCreds -credential $DomainCreds 
        } catch {
          sleep 60
          Add-Computer -ComputerName $IP -Domain $Domainname -Restart -Localcredential $LocalCreds -credential $DomainCreds -ea:0
        }
        while (Test-Connection -ComputerName $IP -Quiet -Count 1 -or $countrestart -le 30) {
          
          write-log -message "Machine is restarting"

          $countrestart++
          Start-Sleep -Seconds 2
          }
      
          write-log -message "$IP was added to domain $Domain..."
          sleep 20
       }

    } catch {
      try {
        $connect = invoke-command -computername $ip -credential $DomainCreds {
          (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
        } -ea:0
      } catch {
        $connect = $false 
      }
      if ($connect -eq $true ){

        write-log -message "Machine Domain Join Confirmed"

      } else {

        write-log -message "If you can read this.. $Joincount"

      }
    };
    sleep 30
  } until ($Joincount -ge 5 -or $connect -eq $true)

  write-log -message "Installing AD software";
  write-log -message "Awaiting completion install AD software";

  do{
    $installcount++
    $connect = invoke-command -computername $ip -credential $DomainCreds { 
      try {
        Install-WindowsFeature -Name AD-Domain-Services,GPMC,DNS -IncludeManagementTools -Restart;
      } catch {;
        sleep 60;
      };
    };
    sleep 180
    if ($connect.Success -eq $true){

      write-log -message "Install success";
      write-log -message "Wait for reboot in 45 sec loop.";

      $installsuccess = $true;
    };
  } until ($installcount -ge 5 -or $connect.Success -eq $true)
  
  do {;
    $test = test-connection -computername $ip -ea:0;
    sleep 45;
    $count++;
  } until ($test[0].statuscode -eq 0 -or $count -eq 6 );
  sleep 45

  do{
    $promotecount++

    write-log -message "Promoting next DC in the domain";

    $connect = invoke-command -computername $IP -credential $DomainCreds { 
      try {
        Install-ADDSDomainController -DomainName $args[0] -SafeModeAdministratorPassword $Args[1] -force -credential $args[2] -NoRebootOnCompletion;
        shutdown -r -t 30
      } catch {
        "ERROR"
      }
      sleep 180
    } -args $Domainname,$password,$DomainCreds -ea:0

    if ($connect -notmatch "ERROR"){
      $promotesuccess = $true

      write-log -message "Promote Success, confirmed the end result." 

    } else {

      write-log -message "Promote failed, retrying." -sev "WARN"

    }
  } until ($promotecount -ge 5 -or $promotesuccess -eq $true)

  write-log -message "Sleeping 60 sec";

  sleep 60;
  if ($promotesuccess -eq $true -and $installsuccess -eq $true){
    $status = "Success"

    write-log -message "All Done here, ready for AD Content";
    write-log -message "Please pump me full of lead.";

  } else {
    $status = "Failed"
    write-log -message "Danger Will Robbinson." -sev "ERROR";
  }
  $resultobject =@{
    Result = $status
  };
  return $resultobject
};
Export-ModuleMember *