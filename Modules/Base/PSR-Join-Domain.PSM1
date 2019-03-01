Function PSR-Join-Domain {
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
    write-log -message "How many times am i doing this $Joincount"
    try {
      if (-not (Test-Connection -ComputerName $IP -Quiet -Count 1)) {
      
        write-log -message "Could not reach $IP" -sev "WARN"
      
      } else {
      
        write-log -message "$IP is being added to domain $Domainname..."
      
        try {
          Add-Computer -ComputerName $IP -Domain $Domainname -restart -Localcredential $LocalCreds -credential $DomainCreds -force 

        } catch {
          
          sleep 70

          try {
            $connect = invoke-command -computername $ip -credential $DomainCreds {
              (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
            } -ea:0
          }  catch {  
            write-log -message "I dont want to be here."
          }
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

      write-log -message "Join domain almost always throws an error..."

      sleep 40
      try {
        $connect = invoke-command -computername $ip -credential $DomainCreds {
          (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
        } -ea:0
      } catch {
        $connect = $false 
      }
      if ($connect -eq $true ){
        $Joinsucces = $true

        write-log -message "Machine Domain Join Confirmed"

      } else {

        write-log -message "If you can read this.. $Joincount"

      }
    };
    sleep 30
  } until ($Joincount -ge 5 -or $connect -eq $true)

  


  if ($Joinsucces -eq $true ){
    $status = "Success"

    write-log -message "All Done here, ready for some Content";
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