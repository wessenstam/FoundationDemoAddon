Function REST-Enable-Flow {
  Param (
    [string] $PCClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $countflow = 0 
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Flow JSON"

  $FlowURL = "https://$($PCClusterIP):9440/api/nutanix/v3/services/microseg"
  $FlowPayload= @{
    state="ENABLE"
  } 
  $FlowJSON = $FlowPayload | convertto-json

  write-log -message "Enaling Flow"
  do {;
    $countFlow++;
    $successflow = $false;
    try {;
      $task = Invoke-RestMethod -Uri $FlowURL -method "post" -body $FlowJSON -ContentType 'application/json' -headers $headers;
      $successflow = $true
    }catch {;

      write-log -message "Enabling Flow Failed, retry attempt $countcalm out of 5" -sev "WARN";

      sleep 2
      $successflow = $false;
    }
  } until ($successflow -eq $true -or $countcalm -eq 5);
  if ($countcalm -eq 5){;
  
    write-log -message "Enabling Flow failed after $countEULA attempts" -sev "WARN";
  
  };
  if ($successflow -eq $true){
    write-log -message "Enaling Flow success"
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