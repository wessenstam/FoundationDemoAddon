Function CMD-Create-FSShares {
  param (
    [string] $domainname,
    [string] $syspreppassword,
    [string] $PEClusterIP,
    [string] $clusername,
    [string] $clpassword,
    [string] $debug
  )
  $count1 = 0;
  $count2 = 0;
  $count3 = 0;
  write-log -message "Connecting to PS CMD on Prism Element";
  do{;
    $count3++
    try {;
      $hide = LIB-Connect-PSnutanix -ClusterName $PEClusterIP -NutanixClusterUsername $clusername -NutanixClusterPassword $clpassword;
  
      $count++
      $cluster = Get-NTNXCluster;
      if ($cluster){;
  
        write-log -message "Creating File server Shares";
  
      };
    } catch {;
  
      write-log -message "Not connected." -sev "WARN";
  
    };
    $count = 0;
    write-log -message "The Following FS Share objects will be created:";
    write-log -message "-Home";
    write-log -message "-Department";
    write-log -message "-Public";
    try {
      $contianer = Get-NTNXContainer | where {$_.name -match "default"} | select -first 1;
      $netbios = $domainname.split(".")[0];
      $FSUUID = (Get-NTNXFileServers)[0].uuid;
      sleep 60;
    } catch {;

      write-log -message "Could not find the FS UUID";

      do {
        sleep 60;
        $count++

        write-log -message "Sleeping for fileserver readyness";

        try {
          $FSUUID = (Get-NTNXFileServers)[0].uuid;
          $noerror = "yes"
          } catch {

            write-log -message "File server is not ready yet.";

            $noerror = "no"
          }
      } until ($count -eq 20 -or $noerror -eq "yes")
      
      sleep 60;
    };
    try{
      $hide = join-NTNXdomain -WindowsAdDomainName "$domainname" -WindowsAdUsername "administrator" -WindowsAdPassword "$syspreppassword" -Uuid $FSUUID -EA:0 | out-null;
    } Catch {

      write-log -message "^^^ This error is expected.";  
      write-log -message "File Server is added to the domain.";    

    }
    try{
      sleep 60
      if (!$task1){
        $task1 = New-NTNXFileServerShare -uuid $FSUUID -name "UserHome"  -ProtocolType "SMB" -EnableAccessBasedEnumeration $true -ShareType "HOMES" -ContainerUuid $contianer.containerUuid -EnablePreviousVersion $true
        sleep 60
      }
      if (!$task2){
        $task2 = New-NTNXFileServerShare -uuid $FSUUID -name "Department" -ProtocolType "SMB" -EnableAccessBasedEnumeration $true -ShareType "General" -ContainerUuid $contianer.containerUuid -EnablePreviousVersion $true
        sleep 60
      }
      if (!$task3){
        $task3 = New-NTNXFileServerShare -uuid $FSUUID -name "Public"  -ProtocolType "SMB" -EnableAccessBasedEnumeration $true -ShareType "General" -ContainerUuid $contianer.containerUuid -EnablePreviousVersion $true
      }
    } catch {
    }
  } until (($task1 -and $task2 -and $task3) -or $count3 -eq 5)
  if ($task1 -and $task2 -and $task3){
    $status = "Success"

    write-log -message "Shares have been created.";
    write-log -message "PS Rules";

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