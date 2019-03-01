Function REST-Enable-Karbon {
  Param (
    [string] $PCClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $countcalm = 0 
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Karbon JSON"

  $CALMURL = "https://$($PCClusterIP):9440/api/nutanix/v3/services/karbon"
  $CALMPayload= @{
    state="ENABLE"
  } 
  $CalmJSON = $CALMPayload | convertto-json

  write-log -message "Enaling Karbon"
  do {;
    $countkarbon++;
    $successkarbon= $false;
    try {;
      $task = Invoke-RestMethod -Uri $CALMURL -method "post" -body $CalmJSON -ContentType 'application/json' -headers $headers;
      $successkarbon = $true
    }catch {;

      write-log -message "Enabling Karbon Failed, retry attempt $countkarbon out of 5" -sev "WARN";

      sleep 2
      $successkarbon = $false;
    }
  } until ($successkarbon -eq $true -or $countkarbon -eq 5);
  if ($countkarbon -eq 5){;
  
    write-log -message "Registration failed after $countEULA attempts" -sev "WARN";
  
  };
  if ($successkarbon -eq $true){
    write-log -message "Enaling Karbon success"
    $status = "Success"
  } else {
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
    TaskUUID = $task.task_uuid
  }
  return $resultobject
};
Export-ModuleMember *