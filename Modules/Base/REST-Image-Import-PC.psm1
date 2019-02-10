Function REST-Image-Import-PC {
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

  write-log -message "Building Cluster JSON" 
  $clusterurl = "https://$($PCClusterIP):9440//api/nutanix/v3/clusters/list"
  $ClusterJSON = @"
{
  "kind": "cluster"
}
"@

  write-log -message "Importing Images into PC"

  do {;
    write-log -message "Gathering Cluster UUID"
    try {
      $Clusters = (Invoke-RestMethod -Uri $clusterurl -method "POST" -headers $headers -body $ClusterJSON -ContentType 'application/json').entities
      $cluster = $clusters | where {$_.status.name -notmatch "unnamed|^PC"}
      write-log -message "PE Cluster UUID is $($cluster.metadata.uuid)"
    } catch {;
      write-log -message "We Could not query Px for existing storage containers" -sev "ERROR";
    };
    write-log -message "Building Image Import JSON" 
    $ImageURL = "https://$($PCClusterIP):9440/api/nutanix/v3/images/migrate"  
    $ImageJSON = @"
{
  "image_reference_list":[],
  "cluster_reference":{
    "uuid":"$($cluster.metadata.uuid)",
    "kind":"cluster",
    "name":"string"}
}
"@
    $countimport++;
    $successImport = $false;
    try {;
      $task = Invoke-RestMethod -Uri $ImageURL -method "post" -body $ImageJSON -ContentType 'application/json' -headers $headers;
      $successImport = $true
    } catch {;

      write-log -message "Importing Images into PC Failed, retry attempt $countimport out of 5" -sev "WARN";

      sleep 2
      $successImport = $false;
    }
  } until ($successImport -eq $true -or $countimport -eq 5);
  if ($countimport -eq 5){;
  
    write-log -message "Importing Images into PC after $countimport attempts" -sev "WARN";
  
  };
  if ($successImport -eq $true){
    write-log -message "Importing Images into PC success"
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