Function REST-Enable-Karbon-PC {
  Param (
    [object] $datagen,
    [object] $datavar
  )
  $clusterIP = $datagen.PCClusterIP

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Enabling Karbon"

  $URL = "https://$($clusterip):9440/PrismGateway/services/rest/v1/genesis"

  write-log -message "Using URL $URL"

  $SET = '{"value":"{\".oid\":\"ClusterManager\",\".method\":\"enable_service_with_prechecks\",\".kwargs\":{\"service_list_json\":\"{\\\"service_list\\\":[\\\"KarbonUIService\\\",\\\"KarbonCoreService\\\"]}\"}}"}'
  $CHECK = '{"value":"{\".oid\":\"ClusterManager\",\".method\":\"is_service_enabled\",\".kwargs\":{\"service_name\":\"KarbonUIService\"}}"}'
  
  try{
    $Checktask1 = Invoke-RestMethod -Uri $URL -method "post" -body $CHECK -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $Checktask1 = Invoke-RestMethod -Uri $URL -method "post" -body $CHECK -ContentType 'application/json' -headers $headers;
    $result = $Checktask1 
  }
  if ($Checktask1 -notmatch "true"){

    write-log -message "Karbon is not enabled yet."

    try{
      $SETtask = Invoke-RestMethod -Uri $URL -method "post" -body $SET -ContentType 'application/json' -headers $headers;
    } catch {
      sleep 10

      write-log -message "Going once"
  
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $SET -ContentType 'application/json' -headers $headers;
    }
  
    sleep 5 
  
    try{
      $Checktask2 = Invoke-RestMethod -Uri $URL -method "post" -body $CHECK -ContentType 'application/json' -headers $headers;
    } catch {
      sleep 10

      write-log -message "Going once"
  
      $Checktask2 = Invoke-RestMethod -Uri $URL -method "post" -body $CHECK -ContentType 'application/json' -headers $headers;
    }
    $result = $Checktask2 
  } else {

    write-log -message "Karbon is already enabled."
    $result = "true"

  }
  if ($result -match "true"){
    $status = "Success"

    write-log -message "All Done here, ready for K8 Cluster";

  } else {
    $status = "Failed"
    write-log -message "Danger Will Robbinson." -sev "ERROR";
  }
  $resultobject =@{
    Result = $status
    Output = $result
  };
  return $resultobject
} 
