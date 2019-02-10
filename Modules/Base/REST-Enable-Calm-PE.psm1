Function REST-Enable-Calm {
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

  write-log -message "Building CALM JSON"

  $CALMURL = "https://$($PCClusterIP):9440/api/nutanix/v3/services/nucalm"
  $CALMPayload= @{
    state="ENABLE"
    enable_nutanix_apps=$true
  } 
  $CalmJSON = $CALMPayload | convertto-json

  write-log -message "Enaling Calm"
  do {;
    $countcalm++;
    $successCLAM = $false;
    try {;
      $task = Invoke-RestMethod -Uri $CALMURL -method "post" -body $CalmJSON -ContentType 'application/json' -headers $headers;
      $successCLAM = $true
    }catch {;

      write-log -message "Enabling CALM Failed, retry attempt $countcalm out of 5" -sev "WARN";

      sleep 2
      $successCLAM = $false;
    }
  } until ($successCLAM -eq $true -or $countcalm -eq 5);
  if ($countcalm -eq 5){;
  
    write-log -message "Registration failed after $countEULA attempts" -sev "WARN";
  
  };
  if ($successCLAM -eq $true){
    write-log -message "Enaling Calm success"
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