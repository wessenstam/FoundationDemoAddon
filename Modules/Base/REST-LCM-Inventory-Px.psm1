Function REST-LCM-Inventory {
  Param (
    [string] $ClusterPx_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )
  #### Broken...
  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $countflow = 0 
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building LCM JSON"

  $LCMURL = "https://$($ClusterPx_IP):9440/PrismGateway/services/rest/v1/genesis"
  $LCMJSON = @"
{
  ".oid":"LifeCycleManager",
  ".method":"lcm_framework_rpc",
  ".kwargs":{
    "method_class":"LcmFramework",
    "method":"perform_inventory",
    "args":["http://download.nutanix.com/lcm/2.0"]
  }
}
"@
  write-log -message "Running LCM Inventory"
  do {;
    $countLCM++;
    $successLCM = $false;
    try {;
      $task = Invoke-RestMethod -Uri $LCMURL -method "post" -body $LCMJSON -ContentType 'application/json' -headers $headers;
      $successLCM = $true
    } catch {;

      write-log -message "Performing LCM Inventory Failed, retry attempt $countLCM out of 5" -sev "WARN";

      sleep 2
      $successLCM = $false;
    }
  } until ($successLCM -eq $true -or $countLCM -eq 5);
  if ($countLCM -eq 5){;
  
    write-log -message "Performing LCM Inventory after $countLCM attempts" -sev "WARN";
  
  };
  if ($successLCM -eq $true){
    write-log -message "Performing LCM Inventory success"
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