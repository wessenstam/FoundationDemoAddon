Function PSR-ERA-ConfigureMSSQL {
  param (
    [string]$SysprepPassword,
    [string]$IP,
    [string]$clusername,
    [string]$clpassword,
    [string]$PEClusterIP,
    [string]$containername,
    [string]$Domainname,
    [string]$eraSQLservername,
    [string]$sename,
    [string]$debug
  )
  write-log -message "Debug level is $debug";
  write-log -message "Building credential object";

  $password = $SysprepPassword | ConvertTo-SecureString -asplaintext -force;
  $LocalCreds = New-Object System.Management.Automation.PsCredential("administrator",$password);
  $DomainCreds = New-Object System.Management.Automation.PsCredential("$($Domainname)\administrator",$password);
  $netbios = ($domainname.split("."))[0]
  $se = $sename -replace (" ",'.')

  $finalizesuccess = $false
  $finalizecount = 0
  $createDBsuccess = $false
  $createDBcount = 0 
  $counttask = 0

  write-log -message "Executing Final ERA Script.";
 
  do{
    $finalizecount++
    write-log -message "Attempt $finalizecount"
    if ($finalizecount -ge 2){
      if($debug -ge 2){

        write-log -message "Debug Level dictates Panick, exiting."

        break
      }
    }
    try {
      $connect = invoke-command -computername $ip -credential $localcreds {
        $script = get-content C:\NTNX-Setup\completebuild.ps1
        $script2 = $script -replace "Stop", 'silentlycontinue'
        $script2 = $script2 -replace "Restart-Computer", 'write "i dont think so"'
        $script2 | out-file C:\NTNX-Setup\completebuild2.ps1
        $argumentList = "-file C:\NTNX-Setup\completebuild2.ps1 -ClusterIP $($args[0]) -UserName $($args[1]) -Password $($args[2]) -containername $($args[3])"
        $jobname = "PowerShell SQL Install";
        $action = New-ScheduledTaskAction -Execute "$pshome\powershell.exe" -Argument  "$argumentList";
        $trigger =New-ScheduledTaskTrigger -Once -At (Get-Date).Date
        #$principal = New-ScheduledTaskPrincipal -UserId "$($env:USERDOMAIN)\$($env:USERNAME)" -LogonType "Interactive"
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -DontStopOnIdleEnd;
        $task = Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $trigger -Settings $settings -runlevel "Highest"
        #-User "administrator" -Password $($args[5]) 
        Get-ScheduledTask "PowerShell SQL Install" | start-scheduledtask

      } -args $PEClusterIP,$clusername,$clpassword,$containername,$debug,$SysprepPassword
      write-log -message "Executing scheduled task";

    } catch {

      write-log -message "Error Creating / Running scheduled task" -sev "ERROR";

      $connect = invoke-command -computername $ip -credential $localcreds {
        Get-ScheduledTask "PowerShell SQL Install" | Unregister-ScheduledTask
      } 
    };
    sleep 30
    try {
      do{
        $counttask++
        sleep 30
        $connect2 = invoke-command -computername $ip -credential $localcreds {
          Get-ScheduledTask "PowerShell SQL Install"
        }    
        if ($connect2.state -eq "4") {
          write-log -message "Task is not ready yet, current state is $($connect2.state), waiting 30 seconds for $counttask times out of 20"
        } else {
          write-log -message "Task is ready, checking results"
        }

      } until ($connect2.state -ne "4" -or $counttask -ge 20)
      $connect3 = invoke-command -computername $ip -credential $localcreds {
        Get-ScheduledTaskinfo "PowerShell SQL Install"
      }     
      if ($connect3.LastTaskResult -eq 0 -or ($connect3.LastTaskResult -eq 1 -and $counttask -ge 2)){
        $finalizesuccess = $true

        write-log -message "SQL Server is finalized with Exit with code $($connect3.LastTaskResult)";

        if ($connect3.LastTaskResult -eq 1){

          write-log -message "The script is known to error with exit 1 after a few cycles, the end result is validated.";

        }

      } else {

        write-log -message "Task Exit with code $($connect3.LastTaskResult)"

      }
    
    } catch {

      write-log -message "Error query task, i dont want to be here." -sev "ERROR";

    }
  } until ($finalizecount -ge 5 -or $finalizesuccess -eq $true)

  write-log -message "Allowing SQL Domain Logins";
  write-log -message "Creating explicit Sysadmin login for $($netbios)\$($se)"
  write-log -message "Creating explicit Sysadmin login for $($netbios)\Domain Admins"

  try{

    write-log -message "Adding Domain Admins"

    $connect4 = invoke-command -computername $ip -credential $localcreds {
      $cn2= new-object System.Data.SqlClient.SqlConnection "server=$($eraSQLservername);database=master;Integrated Security=sspi"
      $cn2.Open()
      $sql2 = $cn2.CreateCommand()
      $sql2.CommandText = @"

EXEC master..sp_addsrvrolemember @loginame = N'$($args[0])\Domain Admins', @rolename = N'sysadmin'

"@
      $rdr2 = $sql2.ExecuteReader()
      $cn2.Close()


      $cn2= new-object System.Data.SqlClient.SqlConnection "server=$($eraSQLservername);database=master;Integrated Security=sspi"
      $cn2.Open()
      $sql2 = $cn2.CreateCommand()
      $sql2.CommandText = @"

EXEC master..sp_addsrvrolemember @loginame = N'$($args[0])\$($args[1])', @rolename = N'sysadmin'

"@
      $rdr2 = $sql2.ExecuteReader()
      $cn2.Close()

      $hide = get-scheduledtask "test" -ea:0 | Unregister-ScheduledTask -confirm:0 -ea:0
      shutdown -r -t 5
    } -args $netbios,$se

    write-log -message "Domain Logins granted, system reboot executed";

    $DomainLogin = $true

  } catch {

    write-log -message "Domain Login Error" -sev "ERROR";

  }

write-log -message "System is being rebooted";
sleep 60

 try{
    write-log -message "Creating Sample databases"

    $connect5 = invoke-command -computername $ip -credential $localcreds {
      invoke-sqlcmd -inputFile "C:\NTNX-Setup\RestoreWWIDatabases.sql" -QueryTimeout 1000
    } -args $netbios,$se

    write-log -message "Database create script executed";

    $Tables = $true

  } catch {

    write-log -message "Create databases Error" -sev "ERROR";

  }

 try{
    write-log -message "Setting recoverymode new databases"

    $connect6 = invoke-command -computername $ip -credential $localcreds {
      Import-Module -Name SQLPS
      Get-ChildItem -Path SQLSERVER:\SQL\Localhost\DEFAULT\Databases |
      Where {$_.name -match "WideWorld" } |
      ForEach-Object {
        $_.RecoveryModel = 'Full'
        $_.Alter()
        $_.Refresh()
      }
    } 

    write-log -message "Recovery Mode set";

    $Recovery = $true

  } catch {

    write-log -message "Setting recoverymode Error" -sev "ERROR";

  }

  if ($finalizesuccess -eq $true -and $DomainLogin -eq $true -and $Tables -eq $true -and $Recovery -eq $true){
    $status = "Success"

    write-log -message "All Done here, full of DB Content";
    write-log -message "Please play with me.";

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