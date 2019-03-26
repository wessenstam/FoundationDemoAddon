Function REST-Query-ADGroups {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building UserGroup Query JSON"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/user_groups/list"
  $Payload= @{
    kind="user_group"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try { 
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going Once"

  }

  Return $task
}

Function REST-LCM-BuildPlan {
  Param (
    [object] $datagen,
    [object] $datavar,
    [string] $mode,
    [object] $Updates
  )
  if ($mode -eq "PC"){
    $clusterIP = $datagen.PCClusterIP
  }  else {
    $clusterip = $datavar.PEClusterIP
  }  
  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing LCM List Query"

  $URL = "https://$($clusterip):9440/PrismGateway/services/rest/v1/genesis"

  write-log -message "Using URL $URL"

  $Start= '{"value":"{\".oid\":\"LifeCycleManager\",\".method\":\"lcm_framework_rpc\",\".kwargs\":{\"method_class\":\"LcmFramework\",\"method\":\"generate_plan\",\"args\":[\"http://download.nutanix.com/lcm/2.0\",['
  $End = ']]}}"}'
  
  foreach ($item in $updates){
    $update = "[\`"$($item.uuid)\`",\`"$($item.version)\`"],"
    $start = $start + $update
  }
  $start = $start.Substring(0,$start.Length-1)
  $start = $start + $end
  [string]$json = $start
  write-log -message "Using URL $json"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Import-Karbon-Blueprint {
  Param (
    [string] $BPfilepath,
    [object] $datagen,
    [object] $datavar,
    [string] $subnetUUID,
    [string] $ProjectUUID
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"

  $jsonstring = get-content $BPfilepath

  write-log -message "Replacing JSON String Variables"

  #$jsonstring = $jsonstring -replace "--SSHPrivateKEYREF---", $($datagen.PrivateKey)
  $jsonstring = $jsonstring -replace "---PUBLICKKEYREF---", $($datagen.PublicKey)
  $jsonstring = $jsonstring -replace "---SUBNETREF---", $($subnetUUID)
  $jsonstring = $jsonstring -replace "---PCIPREF---", $($datagen.PCClusterIP)
  $jsonstring = $jsonstring -replace "---PROJECTREF---", $($ProjectUUID)
  $jsonstring = $jsonstring -replace "---PECLUSTERNAMEREF---", $($datavar.POCNAME)
  $jsonstring = $jsonstring -replace "---NETWORKNAMEREF---", $($datagen.NW1Name)
  $jsonstring = $jsonstring -replace "---KARBONIPRANGEREF---", $($datagen.KarbonIPRange)
  $jsonstring = $jsonstring -replace "---CONTAINERNAMEREF---", $($datagen.KarbonContainerName)
  $jsonstring = $jsonstring -replace '---PCPASSREF---', ''
  $jsonstring = $jsonstring -replace '---INSTANCEPASSWORD---', ''
  $jsonstring = $jsonstring -replace '---PCUSERNAMEREF---', $($datavar.PEAdmin)
  $jsonstring = $jsonstring -replace '"value": "---SSHPrivateKEYREF---"', ''
  $jsonstring = $jsonstring -replace '"is_secret_modified": true },', '"is_secret_modified": false }'

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/import_json"

  if ($datavar.debug -eq 2){
    $jsonstring | out-file "C:\temp\Karbon.json"
  }

  write-log -message "Executing Import"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 



Function REST-Update-Karbon-Blueprint {
  Param (
    [object] $BPObject,
    [string] $BlueprintUUID,
    [object] $datagen,
    [object] $Keyobject,
    [object] $DomainObject,
    [object] $instancePWobject,
    [object] $PCPassObject,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"

foreach ($line in $datagen.PrivateKey){
  [string]$Keystring += $line + '\n' 
}
$Keystring = $Keystring.Substring(0,$Keystring.Length-2)
$JSON1 = @"
{
 "credential_definition_list":  [
    {
    "username":  "centos",
    "description":  "",
    "uuid":  "$($Keyobject.uuid)",
    "secret":  {
                   "attrs":  {
                                 "is_secret_modified":  true,
                                 "secret_reference":  "$($Keyobject.secret.attrs.secret_reference.uuid)"
                             },
                   "value": "$Keystring" 
               },
    "editables":  {
                      "username":  true
                  },
    "type":  "KEY",
    "name":  "SSH_KEY"
   }
  ]
}
"@

$JSON2 = @"
{
    "val_type":  "STRING",
    "description":  "",
    "uuid":  "$($instancePWobject.uuid)",
    "label":  "",
    "attrs":  {
                  "is_secret_modified":  true,
                  "secret_reference":  {
                                           "uuid":  "$($instancePWobject.secret.attrs.secret_reference.uuid)"
                                       }
              },
    "type":  "SECRET",
    "name":  "INSTANCE_PASSWORD",
    "value" : "$($datavar.PEPass)"
}
"@
$JSON3 = @"
{
    "val_type":  "STRING",
    "description":  "",
    "uuid":  "$($PCPassObject.uuid)",
    "label":  "",
    "attrs":  {
                  "is_secret_modified":  true,
                  "secret_reference":  {
                                           "uuid":  "$($PCPassObject.secret.attrs.secret_reference.uuid)"
                                       }
              },
    "type":  "SECRET",
    "name":  "PC_PASSWORD",
    "value" : "$($datavar.PEPass)"
}
"@
  $json
  $newBPObject = $BPObject
  $newBPObject.psobject.members.remove("Status")
  $newBPObject.spec.resources.credential_definition_list = ($JSON1 | convertfrom-json).credential_definition_list

  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "PC_PASSWORD"}) | add-member noteproperty value $datavar.pepass
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "INSTANCE_PASSWORD"}) | add-member noteproperty value $datavar.pepass


  $json = $newBPObject | convertto-json -depth 100
  $json = $json -replace '"---REPLACEME---"', $Keystring

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BlueprintUUID)"

  if ($datavar.debug -eq 2){
    $json | out-file "C:\temp\Karbon3.json"
  }
  write-log -message "Updating Import with Creds for $BlueprintUUID"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 

Function REST-Import-Move-Blueprint {
  Param (
    [string] $BPfilepath,
    [object] $datagen,
    [object] $datavar,
    [string] $subnetUUID,
    [object] $image,
    [string] $ProjectUUID
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"

  $jsonstring = get-content $BPfilepath

  write-log -message "Replacing JSON String Variables"

  $jsonstring = $jsonstring -replace "---IMAGEUUIDREF---", $($image.metadata.uuid)
  $jsonstring = $jsonstring -replace "---IMAGENAMEREF---", $($datagen.Move_ImageName)
  $jsonstring = $jsonstring -replace "---SUBNETREF---", $($subnetUUID)
  $jsonstring = $jsonstring -replace "---PROJECTREF---", $($ProjectUUID)
  $jsonstring = $jsonstring -replace "---MOVEVMNAME---", $($datagen.Move_VMName)
  $jsonstring = $jsonstring -replace "---MOVEVMIP---", $($datagen.MoveIP)

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/import_json"

  if ($datavar.debug -eq 2){
    $jsonstring | out-file "C:\temp\Move1.json"
  }

  write-log -message "Executing Import"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 



Function REST-Update-Move-Blueprint {
  Param (
    [object] $BPObject,
    [string] $BlueprintUUID,
    [object] $datagen,
    [object] $Keyobject,
    [object] $DomainObject,
    [object] $instancePWobject,
    [object] $PCPassObject,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"

  $newBPObject = $BPObject
  $newBPObject.psobject.members.remove("Status")
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "LOCAL"}).secret | add-member noteproperty value $datavar.pepass
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "LOCAL"}).secret.attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "move"}).secret | add-member noteproperty value $datavar.pepass
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "move"}).secret.attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "move_password"}) | add-member noteproperty value $datavar.pepass
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "move_password"}).attrs.is_secret_modified = 'true'


  $json = $newBPObject | convertto-json -depth 100

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BlueprintUUID)"

  if ($datavar.debug -eq 2){
    $json | out-file "C:\temp\Move2.json"
  }
  write-log -message "Updating Import with Creds for $BlueprintUUID"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 



Function REST-LCM-Install {
  Param (
    [object] $datagen,
    [object] $datavar,
    [string] $mode,
    [object] $Updates
  )
  if ($mode -eq "PC"){
    $clusterIP = $datagen.PCClusterIP
  }  else {
    $clusterip = $datavar.PEClusterIP
  }  
  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing LCM List Query"

  $URL = "https://$($clusterip):9440/PrismGateway/services/rest/v1/genesis"

  write-log -message "Using URL $URL"

  $Start= '{"value":"{\".oid\":\"LifeCycleManager\",\".method\":\"lcm_framework_rpc\",\".kwargs\":{\"method_class\":\"LcmFramework\",\"method\":\"perform_update\",\"args\":[\"http://download.nutanix.com/lcm/2.0\",['
  $End = ']]}}"}'
  
  foreach ($item in $updates){
    $update = "[\`"$($item.uuid)\`",\`"$($item.version)\`"],"
    $start = $start + $update
  }
  $start = $start.Substring(0,$start.Length-1)
  $start = $start + $end
  [string]$json = $start
  write-log -message "Using URL $json"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 
Function REST-LCM-Query-Groups {
  Param (
    [object] $datagen,
    [object] $datavar,
    [string] $mode
  )
  if ($mode -eq "PC"){
    $clusterIP = $datagen.PCClusterIP
  }  else {
    $clusterip = $datavar.PEClusterIP
  }  
  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing LCM List Query"

  $URL = "https://$($clusterip):9440/api/nutanix/v3/groups"

  write-log -message "Using URL $URL"

$Payload= @"
{
  "entity_type": "lcm_available_version",
  "grouping_attribute": "entity_uuid",
  "group_member_count": 1000,
  "group_member_attributes": [
    {
      "attribute": "uuid"
    },
    {
      "attribute": "entity_uuid"
    },
    {
      "attribute": "entity_class"
    },
    {
      "attribute": "status"
    },
    {
      "attribute": "version"
    },
    {
      "attribute": "dependencies"
    },
    {
      "attribute": "order"
    }
  ]
}
"@ 

  $JSON = $Payload 
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.group_results.entity_results.count) items."

  Return $task
} 

Function REST-LCM-Perform-Inventory {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $mode
  )
  if ($mode -eq "PC"){
    $clusterIP = $datagen.PCClusterIP
  }  else {
    $clusterip = $datavar.PEClusterIP
  }  
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  write-log -message "Connecting to $clusterip"
  write-log -message "Mode is $mode"
  write-log -message "SE Name is $($datagen.sename)"
  $URL = "https://$($clusterip):9440/PrismGateway/services/rest/v1/genesis"
  $json1 = @"
{
    "value":"{\".oid\":\"LifeCycleManager\",\".method\":\"lcm_framework_rpc\",\".kwargs\":{\"method_class\":\"LcmFramework\",\"method\":\"configure\",\"args\":[\"http://download.nutanix.com/lcm/2.0\",null,null,true]}}"
}
"@
  $json2 = @"
{
    "value":"{\".oid\":\"LifeCycleManager\",\".method\":\"lcm_framework_rpc\",\".kwargs\":{\"method_class\":\"LcmFramework\",\"method\":\"perform_inventory\",\"args\":[\"http://download.nutanix.com/lcm/2.0\"]}}"
}
"@
  try{
    $setAutoUpdate = Invoke-RestMethod -Uri $URL -method "post" -body $JSON1 -ContentType 'application/json' -headers $headers;
    $Inventory = Invoke-RestMethod -Uri $URL -method "post" -body $JSON2 -ContentType 'application/json' -headers $headers;
  
    write-log -message "AutoUpdated set and Inventory started"
  } catch {
    sleep 10
    write-log -message "Going once"
    $setAutoUpdate = Invoke-RestMethod -Uri $URL -method "post" -body $JSON1 -ContentType 'application/json' -headers $headers;
    $Inventory = Invoke-RestMethod -Uri $URL -method "post" -body $JSON2 -ContentType 'application/json' -headers $headers;
  }
  Return $Inventory

} 

Function REST-Task-List {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )
  ## This is silent on purpose
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/tasks/list"
  $Payload= @{
    kind="task"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try { 
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going Once"

  }
  Return $task
} 

Function REST-Query-ADGroup {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $uuid,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building UserGroup Query JSON"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/user_groups/$($uuid)"

  try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;

    write-log -message "Going once"

  }

  Return $task
} 

Function REST-Query-Subnet {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $networkname,   
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Subnet Query JSON"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/subnets/list"
  $Payload= @{
    kind="subnet"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json

  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;  
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
    
    write-log -message "Going once"

  }
  if ($task.entities.count -eq 0){

    write-log -message "0? Let me try that again after a small nap."

    do {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
      sleep 30
      $count++

      write-log -message "Cycle $count Getting Subnets, current items found is $($task.entities.count)"
    } until ($count -ge 10 -or $task.entities.count -ge 1)
  }
  write-log -message "We found $($task.entities.count) items."
  $result = $task.entities | where {$_.spec.name -eq $networkname}
  Return $result
} 

Function REST-Create-UserGroup {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $customer,
    [string] $domainname,
    [string] $grouptype,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $domainparts = $domainname.split(".")
  write-log -message "Building UserGroup Create JSON"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/user_groups"
  $json = @"
{
  "spec": {
    "resources": {
      "directory_service_user_group": {
        "distinguished_name":"cn=$($customer)-$($grouptype),ou=groups,ou=$($customer),ou=customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])"
      }
    }
  },
  "api_version": "3.1.0",
  "metadata": {
    "kind": "user_group",
    "categories": {},
    "name": "$($customer)-$($grouptype)"
  }
}
"@
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  }catch{

    write-log -message "Going once"

    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  }
  Return $task
} 


Function REST-Query-Cluster {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $targetIP,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Cluster Query JSON"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/clusters/list"
  $Payload= @{
    kind="cluster"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  if ($task.entities.count -eq 0){

    write-log -message "0? Let me try that again after a small nap."

    do {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
      sleep 30
      $count++

      write-log -message "Cycle $count Getting Clusters, current items found is $($task.entities.count)"
    } until ($count -ge 10 -or $task.entities.count -ge 1)
  }
  write-log -message "We found $($task.entities.count) clusters, filtering."

  $filter = $task.entities | where {$_.spec.resources.network.external_ip -eq $targetIP -or $_.spec.resources.network.external_ip }
  Return $filter
} 

Function REST-Query-DetailCluster {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $uuid,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Cluster Query JSON"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/clusters/$($uuid)"
  try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-ERA-Create-Low-ComputeProfile {
  Param (
    [object] $datagen,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"
  $json = @"
{
  "type": "Compute",
  "topology": "ALL",
  "dbVersion": "ALL",
  "properties": [{
    "name": "CPUS",
    "value": "1",
    "description": "Number of CPUs in the VM"
  }, {
    "name": "CORE_PER_CPU",
    "value": 4,
    "description": "Number of cores per CPU in the VM"
  }, {
    "name": "MEMORY_SIZE",
    "value": 16,
    "description": "Total memory (GiB) for the VM"
  }],
  "name": "LOW_OOB_COMPUTE"
}
"@

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/profiles"

  write-log -message "Creating Profile LOW_OOB_COMPUTE"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 

Function REST-ERA-GetProfiles {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Query All ERA Profiles"

  $URL = "https://$($EraIP):8443/era/v0.8/profiles"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;
  } catch {

    write-log -message "Going once"

    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET"  -headers $headers;
  }

  Return $task
} 


Function REST-ERA-ProvisionDatabase {
  Param (
    [object] $dbserver,
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [object] $ERACluster,
    [object] $SLA,
    [string] $debug,
    [string] $publicSSHKey,
    [string] $networkProfileId,
    [string] $SoftwareProfileID,
    [string] $computeProfileId,
    [string] $dbParameterProfileId,
    [string] $Type,
    [string] $Port,
    [string] $Databasename
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Using databasename DB_$($dbservername)"
  write-log -message "Using NetworkID $($networkProfileId)"
  write-log -message "Using ComputeID $($computeProfileId)"
  write-log -message "Using DBParamID $($dbParameterProfileId)"
  write-log -message "Using Databasename  $($Databasename)"
  write-log -message "Using Type $($Type)"
  write-log -message "Using Port $($Port)"

  $URL = "https://$($EraIP):8443/era/v0.8/databases/provision"
  $JSON = @"
{
  "databaseType": "$($Type)",
  "databaseName": "$($databasename)",
  "clusterId": "$($ERACluster.id)",
  "dbParameterProfileId": "$($dbParameterProfileId)",
  "useExistingDBserver": true,
  "timeMachineInfo": {
    "name": "$($Type)_TM",
    "description": "",
    "slaId": "$($SLA.ID)",
    "schedule": {
      "snapshotTimeOfDay": {
        "hours": 1,
        "minutes": 0,
        "seconds": 0
      },
      "continuousSchedule": {
        "enabled": true,
        "logBackupInterval": 30,
        "snapshotsPerDay": 1
      },
      "weeklySchedule": {
        "enabled": true,
        "dayOfWeek": "FRIDAY"
      },
      "monthlySchedule": {
        "enabled": true,
        "dayOfMonth": "8"
      },
      "quartelySchedule": {
        "enabled": true,
        "startMonth": "JANUARY",
        "dayOfMonth": "8"
      },
      "yearlySchedule": {
        "enabled": false,
        "dayOfMonth": 31,
        "month": "DECEMBER"
      }
    },
    "tags": [],
    "autoTuneLogDrive": true
  },
  "provisionInfo": [{
    "name": "application_type",
    "value": "$($Type)"
  }, {
    "name": "listener_port",
    "value": "$($Port)"
  }, {
    "name": "database_size",
    "value": "200"
  }, {
    "name": "working_dir",
    "value": "/tmp"
  }, {
    "name": "auto_tune_staging_drive",
    "value": true
  }, {
    "name": "host_ip",
    "value": "$($dbserver.ip)"
  }, {
    "name": "db_password",
    "value": "$($Clpassword)"
  }]
}
"@
  if ($debug -ge 2){
    $json | out-file c:\temp\ERAMDBcr.json
  }
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch{

    write-log -message "Going once."

    sleep 60
    try {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    } catch {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    }
  }
  Return $task
} 

Function REST-ERA-RegisterOracle-ERA {
  Param (
    $dbname,
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [object] $ERACluster,
    [string] $OracleIP,
    [object] $SLA,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Oracle Server Registration JSON"
  write-log -message "Using databasename $($dbname) using ip $OracleIP"

  $URL = "https://$($EraIP):8443/era/v0.8/databases"
  $JSON = @"
{
  "vmAdd": true,
  "applicationInfo": [{
    "name": "application_type",
    "value": "oracle_database"
  }, {
    "name": "listener_port",
    "value": "1521"
  }, {
    "name": "working_dir",
    "value": "/tmp"
  }, {
    "name": "era_deploy_base",
    "value": "/opt/era_base"
  }, {
    "name": "create_era_drive",
    "value": true
  }, {
    "name": "vm_ip",
    "value": "$($OracleIP)"
  }, {
    "name": "vm_username",
    "value": "oracle"
  }, {
    "name": "grid_home",          
    "value": ""
  }, {
    "name": "oracle_home",
    "value": "/u02/app/oracle/product/12.1.0/dbhome_1"
  }, {
    "name": "vm_password",
    "value": "$($clpassword)"
  }, {
    "name": "oracle_sid",
    "value": "$($dbname)"
  }],
  "forcedInstall": true,
  "clusterId": "$($ERACluster.id)",
  "tags": [],
  "timeMachineInfo": {
    "name": "$($dbname)_TM",
    "description": "$($dbname)_TM",
    "slaId": "$($SLA.ID)",
    "schedule": {
      "snapshotTimeOfDay": {
        "hours": 1,
        "minutes": 0,
        "seconds": 0
      },
      "continuousSchedule": {
        "enabled": true,
        "logBackupInterval": 30,
        "snapshotsPerDay": 1
      },
      "weeklySchedule": {
        "enabled": true,
        "dayOfWeek": "THURSDAY"
      },
      "monthlySchedule": {
        "enabled": true,
        "dayOfMonth": "21"
      },
      "quartelySchedule": {
        "enabled": true,
        "startMonth": "JANUARY",
        "dayOfMonth": "21"
      },
      "yearlySchedule": {
        "enabled": false,
        "dayOfMonth": 31,
        "month": "DECEMBER"
      }
    },
    "tags": [],
    "autoTuneLogDrive": true
  },
  "applicationSlaName": "$($sla.name)",
  "applicationType": "oracle_database",
  "autoTuneStagingDrive": true,
  "eraBaseDirectory": "/opt/era_base",
  "applicationHost": "$($OracleIP)",
  "vmIp": "$($OracleIP)",
  "vmUsername": "oracle",
  "vmPassword": "$($clpassword)",
  "applicationName": "$($dbname)",
  "vmDescription": "Oracle 12 Server"
}
"@
  if ($debug -ge 2){
    $json | out-file c:\temp\ERAOracle.json
  }
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch{

    write-log -message "Going once."

    sleep 60
    try {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    } catch {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    }
  }
  Return $task
} 


Function REST-ERA-ProvisionServer {
  Param (
    [string] $dbservername,
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [object] $ERACluster,
    [object] $SLA,
    [string] $debug,
    [string] $publicSSHKey,
    [string] $networkProfileId,
    [string] $SoftwareProfileID,
    [string] $computeProfileId,
    [string] $dbParameterProfileId,
    [string] $Type,
    [string] $Port,
    [string] $POCNAME
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Maria Server Provision JSON"
  write-log -message "Using databasename DB_$($dbservername)"
  write-log -message "Using NetworkID $($networkProfileId)"
  write-log -message "Using ComputeID $($computeProfileId)"
  write-log -message "Using DBParamID $($dbParameterProfileId)"
  write-log -message "Using POC Name  $($POCNAME)"  
  write-log -message "Using SoftwareProfile  $($SoftwareProfileID)"
  write-log -message "Using Type $($Type)"
  write-log -message "Using Port $($Port)"

  $URL = "https://$($EraIP):8443/era/v0.8/dbservers/create"
  $JSON = @"
{
  "actionArguments": [{
    "name": "vm_name",
    "value": "$($dbservername)"
  }, {
    "name": "working_dir",
    "value": "/tmp"
  }, {
    "name": "era_deploy_base",
    "value": "/opt/era_base"
  }, {
    "name": "compute_profile_id",
    "value": "$($computeProfileId)"
  }, {
    "name": "client_public_key",
    "value": "$($publicSSHKey)"
  }, {
    "name": "network_profile_id",
    "value": "$($networkProfileId)"
  }],
  "description": "Launches the rocket",
  "clusterId": "$($ERACluster.id)",
  "softwareProfileId": "$($SoftwareProfileID)"
}
"@
  if ($debug -ge 2){
    $json | out-file c:\temp\ERADB.json
  }
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch{

    write-log -message "Going once."

    sleep 60
    try {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    } catch {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    }
  }
  Return $task
} 





Function REST-ERA-AcceptEULA {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $uuid,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building EULA Accept JSON"

  $URL = "https://$($EraIP):8443/era/v0.8/auth/validate"
  $Payload= @{
    eulaAccepted="true"
  } 
  $JSON = $Payload | convertto-json
  try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {

    write-log -message "Going once"

    sleep 60
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;
  }  
  Return $task
} 

Function REST-ERA-GetDBServers {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Get ERA DB Servers"

  $URL = "https://$($EraIP):8443/era/v0.8/dbservers"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;
  } catch {

    write-log -message "Going once"

    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET"  -headers $headers;
  }

  Return $task
} 

Function REST-ERA-GetDatabases {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Get ERA DB Servers"

  $URL = "https://$($EraIP):8443/era/v0.8/databases"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;
  } catch {

    write-log -message "Going once"

    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET"  -headers $headers;
  }

  Return $task
} 



Function REST-ERA-PostGresNWProfileCreate {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $NetworkName,
    [string] $debug
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building PostGres Network Creation JSON"

  $URL = "https://$($EraIP):8443/era/v0.8/profiles"
  $JSON = @"
{
  "engineType": "postgres_database",
  "type": "Network",
  "topology": "ALL",
  "dbVersion": "ALL",
  "properties": [{
    "name": "VLAN_NAME",
    "value": "$($NetworkName)",
    "description": "Name of the vLAN"
  }],
  "name": "PostGresNW"
}
"@
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch {

    write-log -message "Going once"

    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-ERA-MariaNWProfileCreate {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $NetworkName,
    [string] $debug
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building MariaDB Network Creation JSON"

  $URL = "https://$($EraIP):8443/era/v0.8/profiles"
  $JSON = @"
{
  "engineType": "mariadb_database",
  "type": "Network",
  "topology": "ALL",
  "dbVersion": "ALL",
  "properties": [{
    "name": "VLAN_NAME",
    "value": "$($NetworkName)",
    "description": "Name of the vLAN"
  }],
  "name": "MariaNW"
}
"@
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }

  Return $task
} 

Function REST-ERA-RegisterMSSQL-ERA {
  Param (
    $dbname,
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [object] $ERACluster,
    [string] $MSQLVMIP,
    [object] $SLA,
    [string] $sysprepPass,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building MSSQL Server Registration JSON"
  write-log -message "Using databasename $($dbname)"

  $URL = "https://$($EraIP):8443/era/v0.8/databases"
  $JSON = @"
{
  "vmAdd": true,
  "applicationInfo": [{
    "name": "application_type",
    "value": "sqlserver_database"
  }, {
    "name": "era_manage_log",
    "value": true
  }, {
    "name": "sql_login_used",
    "value": false
  }, {
    "name": "same_as_admin",
    "value": true
  }, {
    "name": "create_era_drive",
    "value": true
  }, {
    "name": "recovery_model",
    "value": "Full-logged"
  }, {
    "name": "era_deploy_base",
    "value": "C:\\NTNX\\ERA_BASE"
  }, {
    "name": "vm_ip",
    "value": "$($MSQLVMIP)"
  }, {
    "name": "vm_username",
    "value": "administrator"
  }, {
    "name": "vm_password",
    "value": "$($sysprepPass)"
  }, {
    "name": "instance_name",
    "value": "MSSQLSERVER"
  }, {
    "name": "database_name",
    "value": "$($dbname)"
  }, {
    "name": "sysadmin_username_win",
    "value": "administrator"
  }, {
    "name": "sysadmin_password_win",
    "value": "$($sysprepPass)"
  }],
  "forcedInstall": true,
  "clusterId": "$($ERACluster.id)",
  "tags": [],
  "timeMachineInfo": {
    "name": "$($dbname)_TM",
    "description": "",
    "slaId": "$($SLA.ID)",
    "schedule": {
      "snapshotTimeOfDay": {
        "hours": 1,
        "minutes": 0,
        "seconds": 0
      },
      "continuousSchedule": {
        "enabled": true,
        "logBackupInterval": 30,
        "snapshotsPerDay": 1
      },
      "weeklySchedule": {
        "enabled": true,
        "dayOfWeek": "SUNDAY"
      },
      "monthlySchedule": {
        "enabled": true,
        "dayOfMonth": "3"
      },
      "quartelySchedule": {
        "enabled": true,
        "startMonth": "JANUARY",
        "dayOfMonth": "3"
      },
      "yearlySchedule": {
        "enabled": false,
        "dayOfMonth": 31,
        "month": "DECEMBER"
      }
    },
    "tags": [],
    "autoTuneLogDrive": true
  },
  "applicationSlaName": "$($sla.name)",
  "applicationType": "sqlserver_database",
  "autoTuneStagingDrive": false,
  "eraBaseDirectory": "C:\\NTNX\\ERA_BASE",
  "applicationHost": "$($MSQLVMIP)",
  "vmIp": "$($MSQLVMIP)",
  "vmUsername": "administrator",
  "vmPassword": "$($sysprepPass)",
  "applicationName": "$($dbname)"
}
"@
  if ($debug -ge 2){
    $json | out-file c:\temp\ERAMSSQL.json
  }
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch{

    write-log -message "Going once."

    sleep 60
    try {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    } catch {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
    }
  }
  Return $task
} 





Function REST-ERA-GetSLAs {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $uuid,
    [string] $debug
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  $URL = "https://$($EraIP):8443/era/v0.8/slas"

  try {
    $task = Invoke-RestMethod -Uri $URL -method "GET" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-ERA-Operations {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $uuid,
    [string] $debug
  )
  #this is a silent module on purpose
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  $URL = "https://$($EraIP):8443/era/v0.8/operations/short-info"

  try {
    $task = Invoke-RestMethod -Uri $URL -method "GET" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

function Slack-Send-DirectMessage {
  param(
    $user,
    $token,
    $message
  )
  $headers = @{ Authorization = "Bearer $token" }  

  $body = @"
{
    "token": "$token",
    "user": "$user",
}
"@ 
  $directopen = Invoke-RestMethod -Uri https://slack.com/api/im.open -method "POST" -Body $body -ContentType 'application/json' -headers $headers;
  #

  $body = @"
{
    "text": "$message",
    "token": "$token",
    "channel": "$($directopen.channel.id)",
}
"@ 

  $directsend = Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -method "POST" -Body $body -ContentType 'application/json' -headers $headers;

}

Function REST-Query-Projects {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing Project List Query"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/projects/list"
  $Payload= @{
    kind="project"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.entities.count) items."

  Return $task
} 
Function REST-Query-Calm-Apps {
  Param (
    [object] $datavar,
    [object] $datagen
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Query Calm Apps"

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/apps/list"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.PCClusterIP)"

  $Payload= @{
    kind="app"
    offset=0
    length=250
  } 

  $JSON = $Payload | convertto-json
  write-host  $JSON
  try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -Body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "POST" -Body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-Query-Calm-DetailedApps {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $uuid
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Query Calm $($UUID) App Detailed"

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/apps/$($UUID)"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.PCClusterIP)"

  $JSON = $Payload | convertto-json
  write-host  $JSON
  try {
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-Move-BluePrint-LaunchAPP {
  Param (
    [object] $appdetail,
    [object] $action,
    [object] $datagen,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
  "spec": {
    "target_uuid": "$($appdetail.metadata.uuid)",
    "target_kind": "Application",
    "args": []
  },
  "api_version": "3.0",
  "metadata": {
    "project_reference": {
      "kind": "project",
      "uuid": "$($appdetail.metadata.project_reference.uuid)"
    },
    "name": "Nutanix Move",
    "spec_version": 5,
    "kind": "app"
  }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/apps/$($appdetail.metadata.uuid)/actions/$($Action.uuid)/run"

  write-log -message "Executing App Launch for APP $($appdetail.metadata.uuid) using Action ID $($Action.uuid)"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Move-Login {
  Param (
    [object] $appdetail,
    [object] $action,
    [object] $datagen,
    [object] $datavar
  )

  $credPair = "nutanix:nutanix/4u"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
    "username":"nutanix",
    "password":"nutanix/4u"
}
"@ 
  $URL = "https://$($datagen.MoveIP)/v1/users/login"

  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Move-EULA {
  Param (
    [object] $Token,
    [object] $datagen,
    [object] $datavar
  )

  $headers = @{ Authorization = $token.token }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
  "EulaAccepted":true,
  "TelemetryOn":true,
  "NewPassword":"$($datavar.PEPass)"
}
"@ 
  $URL = "https://$($datagen.MoveIP)/v1/configure"

  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Move-SetTarget {
  Param (
    [object] $Token,
    [object] $datagen,
    [object] $datavar
  )

  $headers = @{ Authorization = $token.token }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
  "IPorFQDN":"$($datavar.PEClusterIP)",
  "Name":"$($datavar.POCName)",
  "Password":"$($datavar.pepass)",
  "Username":"$($datavar.peadmin)"
}
"@ 
  $URL = "https://$($datagen.MoveIP)/v1/targets"
  if ($datavar.debug -ge 2){
    $json | out-file c:\temp\move2.json
  }
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 





Function REST-Update-Project {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [array]  $Subnet,
    [array]  $consumer,
    [array]  $projectadmin,
    [array]  $cluster,
    [string] $customer,    
    [array]  $admingroup,
    [array]  $usergroup,    
    [array]  $Project,
    [int] $Projectspec,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  write-log -message "Executing Project Update"
  [int]$spec 
  $UserGroupURL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/projects_internal/$($project.metadata.uuid)"
  $json = @"

{
  "spec": {
    "access_control_policy_list": [{
        "acp": {
          "name": "ACP PAdmin for $customer",
          "resources": {
            "role_reference": {
              "kind": "role",
              "uuid": "$($ProjectAdmin.metadata.uuid)"
            },
            "user_reference_list": [

            ],
            "filter_list": {
              "context_list": [{
                  "entity_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": {
                      "entity_type": "all"
                    },
                    "right_hand_side": {
                      "collection": "ALL"
                    }
                  }],
                  "scope_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": "PROJECT",
                    "right_hand_side": {
                      "uuid_list": [
                        "$($project.metadata.uuid)"
                      ]
                    }
                  }]
                },
                {
                  "entity_filter_expression_list": [{
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "category"
                      },
                      "right_hand_side": {
                        "collection": "ALL"
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "cluster"
                      },
                      "right_hand_side": {
                        "uuid_list": [
                          "$($cluster.metadata.uuid)"
                        ]
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "directory_service"
                      },
                      "right_hand_side": {
                        "collection": "ALL"
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "environment"
                      },
                      "right_hand_side": {
                        "collection": "SELF_OWNED"
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "image"
                      },
                      "right_hand_side": {
                        "collection": "ALL"
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "marketplace_item"
                      },
                      "right_hand_side": {
                        "collection": "SELF_OWNED"
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "project"
                      },
                      "right_hand_side": {
                        "uuid_list": [
                          "$($project.metadata.uuid)"
                        ]
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "role"
                      },
                      "right_hand_side": {
                        "collection": "ALL"
                      }
                    }
                  ],
                  "scope_filter_expression_list": [

                  ]
                },
                {
                  "entity_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": {
                      "entity_type": "user"
                    },
                    "right_hand_side": {
                      "collection": "ALL"
                    }
                  }],
                  "scope_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": "PROJECT",
                    "right_hand_side": {
                      "uuid_list": [
                        "$($project.metadata.uuid)"
                      ]
                    }
                  }]
                },
                {
                  "entity_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": {
                      "entity_type": "user_group"
                    },
                    "right_hand_side": {
                      "collection": "ALL"
                    }
                  }],
                  "scope_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": "PROJECT",
                    "right_hand_side": {
                      "uuid_list": [
                        "$($project.metadata.uuid)"
                      ]
                    }
                  }]
                }
              ]
            },
            "user_group_reference_list": [{
              "kind": "user_group",
              "name": "$($admingroup.status.resources.directory_service_user_group.distinguished_name)",
              "uuid": "$($admingroup.metadata.uuid)"
            }]
          },
          "description": "prismui-desc-a8527482f0b1123"
        },
                  "operation": "ADD",
        "metadata": {
          "kind": "access_control_policy"
        }
      },
      {
        "acp": {
          "name": "ACP PAdmin for $customer",
          "resources": {
            "role_reference": {
              "kind": "role",
              "uuid": "$($Consumer.metadata.uuid)"
            },
            "user_reference_list": [

            ],
            "filter_list": {
              "context_list": [{
                  "entity_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": {
                      "entity_type": "all"
                    },
                    "right_hand_side": {
                      "collection": "ALL"
                    }
                  }],
                  "scope_filter_expression_list": [{
                    "operator": "IN",
                    "left_hand_side": "PROJECT",
                    "right_hand_side": {
                      "uuid_list": [
                        "$($project.metadata.uuid)"
                      ]
                    }
                  }]
                },
                {
                  "entity_filter_expression_list": [{
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "category"
                      },
                      "right_hand_side": {
                        "collection": "ALL"
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "cluster"
                      },
                      "right_hand_side": {
                        "uuid_list": [
                          "$($cluster.metadata.uuid)"
                        ]
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "image"
                      },
                      "right_hand_side": {
                        "collection": "ALL"
                      }
                    },
                    {
                      "operator": "IN",
                      "left_hand_side": {
                        "entity_type": "marketplace_item"
                      },
                      "right_hand_side": {
                        "collection": "SELF_OWNED"
                      }
                    }
                  ],
                  "scope_filter_expression_list": [

                  ]
                }
              ]
            },
            "user_group_reference_list": [{
              "kind": "user_group",
              "name": "$($usergroup.status.resources.directory_service_user_group.distinguished_name)",
              "uuid": "$($usergroup.metadata.uuid)"
            }]
          },
          "description": "prismui-desc-9838f052a82f"
        },
        "operation": "ADD",
        "metadata": {
          "kind": "access_control_policy"
        }
      }
    ],
    "project_detail": {
      "name": "$($project.spec.name)", 
      "resources": {
        "resource_domain": {
          "resources": [{
              "limit": 1717986918400,
              "resource_type": "STORAGE"
            },
            {
              "limit": 40,
              "resource_type": "VCPUS"
            },
            {
              "limit": 85899345920,
              "resource_type": "MEMORY"
            }
          ]
        },
        "account_reference_list": [

        ],
        "environment_reference_list": [

        ],
        "user_reference_list": [

        ],
        "external_user_group_reference_list": [{
            "kind": "user_group",
            "name": "$($admingroup.status.resources.directory_service_user_group.distinguished_name)",
            "uuid": "$($admingroup.metadata.uuid)"
          },
          {
            "kind": "user_group",
            "name": "$($usergroup.status.resources.directory_service_user_group.distinguished_name)",
            "uuid": "$($usergroup.metadata.uuid)"
          }
        ],
        "subnet_reference_list": [{
          "kind": "subnet",
          "name": "$($subnet.spec.name)",
          "uuid": "$($subnet.metadata.uuid)"
        }]
      },
      "description": "$($project.spec.description)"
    },
    "user_list": [

    ],
    "user_group_list": [

    ]
  },
  "api_version": "3.1",
  "metadata": {
    "kind": "project",
    "uuid": "$($project.metadata.uuid)",
    "project_reference": {
      "kind": "project",
      "name": "$($project.spec.name)", 
      "uuid": "$($project.metadata.uuid)"
    },
    "spec_version": $($Projectspec),
    "owner_reference": {
      "kind": "user",
      "uuid": "00000000-0000-0000-0000-000000000000",
      "name": "admin"
    },
    "categories": {

    }
  }
}

"@
  $countretry = 0
  do {
    $countretry ++
    try{
      $task = Invoke-RestMethod -Uri $UserGroupURL -method "put" -body $json -ContentType 'application/json' -headers $headers;
      $RESTSuccess = 1
      sleep 10
    } catch {
      sleep 20
      write-log -message "Retry REST $countretry"
    }
  } until ($RESTSuccess -eq 1 -or $countretry -ge 6)

  if ($RESTSuccess -eq 1){
    write-log -message "Project Update Success"
  } else {
    write-log -message "Project Update Failed" 
  }
  Return $task
} 

Function REST-Create-KarbonCluster {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $VMNetworkUUID,    
    [string] $PEClusterUUID,
    [string] $KarbonImageUUID, 
    [string] $StorageContainerName,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  write-log -message "Executing Project K8 Cluster"

  $UserGroupURL = "https://$($ClusterPC_IP):7050/acs/k8s/cluster"

  write-log -message "Using URL $UserGroupURL"

  $json = @"
{
  "name": "Karbon",
  "description": "Demo Cluster",
  "vm_network": "$($VMNetworkUUID)",
  "k8s_config": {
    "service_cluster_ip_range": "172.19.0.0/16",
    "network_cidr": "172.20.0.0/16",
    "fqdn": "",
    "workers": [{
      "cpu": 4,
      "memory_mib": 8192,
      "image": "$($KarbonImageUUID)",
      "disk_mib": 122880
    }, {
      "cpu": 4,
      "memory_mib": 8192,
      "image": "$($KarbonImageUUID)",
      "disk_mib": 122880
    }, {
      "cpu": 4,
      "memory_mib": 8192,
      "image": "$($KarbonImageUUID)",
      "disk_mib": 122880
    }],
    "masters": [{
      "cpu": 2,
      "memory_mib": 4096,
      "image": "$($KarbonImageUUID)",
      "disk_mib": 122880
    }],
    "os_flavor": "centos",
    "network_subnet_len": 24,
    "version": "v1.10.3"
  },
  "cluster_ref": "$($PEClusterUUID)",
  "logging_config": {
    "enable_app_logging": false
  },
  "storage_class_config": {
    "metadata": {
      "name": "default-storageclass"
    },
    "spec": {
      "cluster_ref": "$($PEClusterUUID)",
      "user": "$($clusername)",
      "password": "$($clpassword)",
      "storage_container": "$($StorageContainerName)",
      "file_system": "ext4",
      "flash_mode": false
    }
  },
  "etcd_config": {
    "num_instances": 3,
    "name": "POC041",
    "resource_config": {
      "cpu": 2,
      "memory_mib": 8192,
      "image": "$($KarbonImageUUID)",
      "disk_mib": 40960
    }
  }
}
"@
  try{
    $task = Invoke-RestMethod -Uri $UserGroupURL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    IF ($DEBUG -GE 2  ){
      $JSON | OUT-FILE C:\TEMP\kARBON.JSON
    }
    write-log -message "Going once"
    $task = Invoke-RestMethod -Uri $UserGroupURL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  }
  sleep 5
  Return $task
} 

Function REST-Get-ACPs {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing ACPs List"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/access_control_policies/list"
  $Payload= @{
    kind="access_control_policy"
    offset=0
    length=250
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.entities.count) items."

  Return $task
} 


Function REST-Create-Project {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $customer,
    [string] $domainname,
    [string] $UserGroupName,    
    [string] $UserGroupUUID,
    [string] $AdminGroupName,
    [string] $AdminGroupUUID,
    [string] $SubnetName,    
    [string] $SubnetUUID,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $domainparts = $domainname.split(".")
  write-log -message "Executing Project Create"

  $UserGroupURL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/projects"
  $json = @"
{
  "spec": {
    "name": "$($customer) Project 1",
    "resources": {
      "resource_domain":{  
         "resources":[  
            {  
               "limit":40,
               "resource_type":"VCPUS"
            },
            {  
               "limit":1717986918400,
               "resource_type":"STORAGE"
            },
            {  
               "limit":85899345920,
               "resource_type":"MEMORY"
            }
         ]
      },
      "subnet_reference_list":[  
         {  
            "kind":"subnet",
            "name":"$($SubnetName)",
            "uuid":"$($SubnetUUID)"
         }
      ],
      "external_user_group_reference_list": [
        {  
           "kind":"user_group",
           "uuid":"$($UserGroupUUID)",
           "name":"$($UserGroupName)"
        },
        {  
           "kind":"user_group",
           "uuid":"$($AdminGroupUUID)",
           "name":"$($AdminGroupName)"
        }
      ],

      "user_reference_list": [
      ]
    },
    "description": "SSP Definition for $($customer)"
  },
  "api_version": "3.1.0",
  "metadata": {
    "kind": "project",
    "spec_version": 0,
    "owner_reference":{  
       "kind":"user",
       "uuid":"00000000-0000-0000-0000-000000000000",
       "name":"admin"
    },
    "categories": {

    }
  }
}
"@
  try{
    $task = Invoke-RestMethod -Uri $UserGroupURL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"
    $task = Invoke-RestMethod -Uri $UserGroupURL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  }

  sleep 5
  Return $task

} 





Function REST-Create-ACP-RoleMap {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $Customer,
    [array]  $role,
    [array] $group,
    [array] $project,
    [string] $GroupType,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  write-log -message "Executing ACP Create"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/access_control_policies"
  $json = @"
{
  "spec": {
    "name": "ACP $($Customer) for $($GroupType)",
    "resources": {
      "role_reference": {
        "kind": "role",
        "uuid": "$($role.metadata.uuid)"
      },
      "user_reference_list": [],
      "filter_list": {
        "context_list": [{
          "entity_filter_expression_list": [{
            "operator": "IN",
            "left_hand_side": {
              "entity_type": "ALL"
            },
            "right_hand_side": {
              "collection": "ALL"
            }
          }],
          "scope_filter_expression_list": [{
              "operator": "IN",
              "right_hand_side": {
                "uuid_list": ["$($project.metadata.uuid)"]
              },
              "left_hand_side": "PROJECT"
            }

          ]
        }]
      },
      "user_group_reference_list": [{
        "kind": "user_group",
        "uuid": "$($group.metadata.uuid)"
      }]
    },
    "description": "ACP $($Customer) for $($GroupType)"
  },
  "metadata": {
    "kind": "access_control_policy"
  }
}
"@
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  }catch{
    sleep 10

    write-log -message "Going once"
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  }
  Return $task
} 


Function REST-Query-Role-List {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $rolename,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing Role UUID list"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/roles/list"
    $Payload= @{
    kind="role"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.entities.count) items, filtering."

  $result = $task.entities | where {$_.spec.name -eq $rolename}
  Return $result
} 

Function REST-Query-Role-Object {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $RoleUUID,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Getting Role for $RoleUUID"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/roles/$($RoleUUID)"
  try{
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  }

  Return $task
} 

Function REST-Create-Role-Object {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $roleName,
    [object] $consumerroleObject,
    [string] $projectUUID,
    [string] $projectName,
    [string] $debug
  )

  write-log -message "This function is not used yet."

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Creating Duplicate $rolename Role"
  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/roles"
$json = @"
{
  "spec": {
    "name": "$($roleName) V2",
    "resources": {
      "permission_reference_list": 
      $($consumerroleObject.spec.resources.permission_reference_list |ConvertTo-Json)
    },
    "description": "$($consumerroleObject.spec.description)"
  },
  "api_version": "3.1.0",
  "metadata": {
    "spec_version": 0,
    "kind": "role",
    "project_reference": {
      "kind": "project",
      "name": "$($projectName)",
      "uuid": "$($projectUUID)"
    }
  }
}
"@
  try {
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  

  Return $result
} 


Function REST-Query-DetailBP {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $uuid
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.PEAdmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Getting Blueprint Detail for $uuid"

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($uuid)"

  write-log -message "URL is $url"

  try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers

    write-log -message "Going once"
  }  
  Return $task
} 


Function REST-Import-Xplay-Blueprint {
  Param (
    [string] $BPfilepath,
    [object] $datagen,
    [object] $datavar,
    [string] $subnetUUID,
    [string] $ImageUUID,
    [string] $ProjectUUID,
    [string] $ClusterUUID
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"

  $jsonstring = get-content $BPfilepath

  write-log -message "Replacing JSON String Variables"

  $jsonstring = $jsonstring -replace "---NLBIP---", $($datagen.IISNLBIP)
  $jsonstring = $jsonstring -replace "---DOMAINNAME---", $($datagen.Domainname)
  $jsonstring = $jsonstring -replace "---SUBNETREF---", $($subnetUUID)
  $jsonstring = $jsonstring -replace "---IMAGEREF---", $($ImageUUID)
  $jsonstring = $jsonstring -replace "---PROJECTREF---", $($ProjectUUID)
  $jsonstring = $jsonstring -replace "---CLUSTERREF---", $($ClusterUUID)
  $jsonstring = $jsonstring -replace '"uuid": "---BLUEPRINTREF---",', ''
  $jsonstring = $jsonstring -replace '"value": "---SYSPREPPASS---"', ''
  $jsonstring = $jsonstring -replace '"is_secret_modified": true },', '"is_secret_modified": false }'

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/import_json"

  if ($datavar.debug -eq 2){
    $jsonstring | out-file "C:\temp\IIS.json"
  }

  write-log -message "Executing Import"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 




Function REST-Update-Xplay-Blueprint {
  Param (
    [object] $BPObject,
    [string] $BlueprintUUID,
    [object] $datagen,
    [object] $sysprepObject,
    [object] $DomainObject,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"

$JSON = @"
{
 "credential_definition_list":  [
    {
        "username":  "administrator",
        "description":  "",
        "uuid":  "$($sysprepObject.uuid)",
        "secret":  {
                       "attrs":  {
                                     "is_secret_modified":  true,
                                     "secret_reference":  {
                                                              "uuid":  "$($sysprepObject.secret.attrs.secret_reference.uuid)"
                                                          }
                                 },
                       "value": "$($datagen.SysprepPassword)"
                   },
        "editables":  {
                          "secret":  true
                      },
        "type":  "PASSWORD",
        "name":  "SysprepCreds"
    },
    {
        "username":  "administrator",
        "description":  "",
        "uuid":  "$($DomainObject.uuid)",
        "secret":  {
                       "attrs":  {
                                     "is_secret_modified":  true,
                                     "secret_reference":  {
                                                              "uuid":  "$($DomainObject.secret.attrs.secret_reference.uuid)"
                                                          }
                                 },
                       "value": "$($datagen.SysprepPassword)"
                   },
        "editables":  {
                          "secret":  true
                      },
        "type":  "PASSWORD",
        "name":  "DomainCreds"
    }
  ],
  "state":  "ACTIVE"
}
"@

  $newBPObject = $BPObject
  $newBPObject.psobject.members.remove("Status")
  $newBPObject.spec.resources.credential_definition_list = ($JSON | convertfrom-json).credential_definition_list

  $json = $newBPObject | convertto-json -depth 100

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BlueprintUUID)"

  if ($datavar.debug -eq 2){
    $json | out-file "C:\temp\BPUpdate2.json"
  }
  write-log -message "Updating Import with Creds for $BlueprintUUID"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 

Function REST-Query-Images {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing Images List Query"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/images/list"
  $Payload= @{
    kind="image"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  if ($task.entities.count -eq 0){

    write-log -message "0? Let me try that again after a small nap."

    do {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
      sleep 30
      $count++

      write-log -message "Cycle $count Getting Images types, current items found is $($task.entities.count)"
    } until ($count -ge 10 -or $task.entities.count -ge 1)
  }
  write-log -message "We found $($task.entities.count) items."

  Return $task
} 

Function REST-Create-Alert-Policy {
  Param (
    [object] $datagen,
    [object] $group,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
  "auto_resolve": true,
  "created_by": "admin",
  "description": "API Generated for XPlay Demo",
  "enabled": true,
  "error_on_conflict": true,
  "filter": "entity_type==vm;(group_entity_type==abac_category;group_entity_id==$($group.entity_id))",
  "impact_types": [
    "Performance"
  ],
  "last_updated_timestamp_in_usecs": 0,
  "policies_to_override": null,
  "related_policies": null,
  "title": "AppFamily:DevOps - VM CPU Usage",
  "trigger_conditions": [
    {
      "condition": "vm.hypervisor_cpu_usage_ppm=gt=400000",
      "condition_type": "STATIC_THRESHOLD",
      "severity_level": "CRITICAL"
    }
  ],
  "trigger_wait_period_in_secs": 0
}
"@ 

  $URL = "https://$($datagen.PCClusterIP):9440/PrismGateway/services/rest/v2.0/alerts/policies"

  if ($datavar.debug -eq 2){
    $Json | out-file "C:\temp\Alert.json"
  }

  write-log -message "Executing Import"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 


Function REST-Query-Groups {
  Param (
    [object] $datagen,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing Images List Query"

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/groups"
$Payload= @"
{
  "entity_type": "category",
  "query_name": "eb:data:General-1551028671919",
  "grouping_attribute": "abac_category_key",
  "group_sort_attribute": "name",
  "group_sort_order": "ASCENDING",
  "group_count": 20,
  "group_offset": 0,
  "group_attributes": [{
    "attribute": "name",
    "ancestor_entity_type": "abac_category_key"
  }, {
    "attribute": "immutable",
    "ancestor_entity_type": "abac_category_key"
  }, {
    "attribute": "cardinality",
    "ancestor_entity_type": "abac_category_key"
  }, {
    "attribute": "description",
    "ancestor_entity_type": "abac_category_key"
  }, {
    "attribute": "total_policy_counts",
    "ancestor_entity_type": "abac_category_key"
  }, {
    "attribute": "total_entity_counts",
    "ancestor_entity_type": "abac_category_key"
  }],
  "group_member_count": 5,
  "group_member_offset": 0,
  "group_member_sort_attribute": "value",
  "group_member_sort_order": "ASCENDING",
  "group_member_attributes": [{
    "attribute": "name"
  }, {
    "attribute": "value"
  }, {
    "attribute": "entity_counts"
  }, {
    "attribute": "policy_counts"
  }, {
    "attribute": "immutable"
  }]
}
"@ 

  $JSON = $Payload 
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.group_results.entity_results.count) items."

  Return $task
} 


Function REST-XPlay-BluePrint-Launch {
  Param (
    [object] $datagen,
    [string] $BPuuid,
    [string] $taskUUID,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
 "spec": {
   "app_profile_reference": {
     "kind": "app_profile",
     "name": "IIS",
     "uuid": "$taskUUID"
   },
   "runtime_editables": {
     "action_list": [
       {
       }
     ],
     "service_list": [
       {
       }
     ],
     "credential_list": [
       {
       }
     ],
     "substrate_list": [
       {
       }
     ],
     "package_list": [
       {
       }
     ],
     "app_profile": {
     },
     "task_list": [
       {
       }
     ],
     "variable_list": [
       {
       }
     ],
     "deployment_list": [
       {
       }
     ]
   },
   "app_name": "IIS-000"
 }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BPuuid)/simple_launch"
  if ($debug -ge 2){
    $Json | out-file c:\temp\bplaunch.json
  }

  write-log -message "Executing Launch for $BPuuid"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Import-Generic-Blueprint {
  Param (
    [string] $BPfilepath,
    [object] $datagen,
    [string] $ProjectUUID,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"

  $jsonstring = get-content $BPfilepath
  $jsonstring = $jsonstring -replace "---PROJECTREF---", $($ProjectUUID)
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/import_json"

  write-log -message "Executing Import"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $jsonstring -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-PostGress-SSP-BluePrint-Launch {
  Param (
    [object] $datagen,
    [string] $BPuuid,
    [string] $taskUUID,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
 "spec": {
   "app_profile_reference": {
     "kind": "app_profile",
     "name": "PostGresDB01_DEV",
     "uuid": "$taskUUID"
   },
   "runtime_editables": {
     "action_list": [
       {
       }
     ],
     "service_list": [
       {
       }
     ],
     "credential_list": [
       {
       }
     ],
     "substrate_list": [
       {
       }
     ],
     "package_list": [
       {
       }
     ],
     "app_profile": {
     },
     "task_list": [
       {
       }
     ],
     "variable_list": [
       {
       }
     ],
     "deployment_list": [
       {
       }
     ]
   },
   "app_name": "PostGresDB01 Database Clone"
 }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BPuuid)/simple_launch"
  if ($debug -ge 2){
    $Json | out-file c:\temp\bplaunch.json
  }

  write-log -message "Executing Launch for $BPuuid"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Generic-BluePrint-Launch {
  Param (
    [object] $datagen,
    [string] $BPuuid,
    [object] $taskobject,
    [object] $datavar,
    [string] $appname
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
 "spec": {
   "app_profile_reference": {
     "kind": "app_profile",
     "name": "$($taskobject.name)",
     "uuid": "$($taskobject.uuid)"
   },
   "runtime_editables": {
     "action_list": [
       {
       }
     ],
     "service_list": [
       {
       }
     ],
     "credential_list": [
       {
       }
     ],
     "substrate_list": [
       {
       }
     ],
     "package_list": [
       {
       }
     ],
     "app_profile": {
     },
     "task_list": [
       {
       }
     ],
     "variable_list": [
       {
       }
     ],
     "deployment_list": [
       {
       }
     ]
   },
   "app_name": "$($appname)"
 }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BPuuid)/simple_launch"
  if ($debug -ge 2){
    $Json | out-file c:\temp\Genbplaunch.json
  }

  write-log -message "Executing Launch for $BPuuid"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Maria-SSP-BluePrint-Launch {
  Param (
    [object] $datagen,
    [string] $BPuuid,
    [string] $taskUUID,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
 "spec": {
   "app_profile_reference": {
     "kind": "app_profile",
     "name": "MariaDB01_DEV",
     "uuid": "$taskUUID"
   },
   "runtime_editables": {
     "action_list": [
       {
       }
     ],
     "service_list": [
       {
       }
     ],
     "credential_list": [
       {
       }
     ],
     "substrate_list": [
       {
       }
     ],
     "package_list": [
       {
       }
     ],
     "app_profile": {
     },
     "task_list": [
       {
       }
     ],
     "variable_list": [
       {
       }
     ],
     "deployment_list": [
       {
       }
     ]
   },
   "app_name": "MariaDB01 Database Clone"
 }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BPuuid)/simple_launch"
  if ($debug -ge 2){
    $Json | out-file c:\temp\bplaunch.json
  }

  write-log -message "Executing Launch for $BPuuid"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 
Function REST-ERA-CreateSnapshot {
  Param (
    [string] $DBUUID,
    [object] $datagen,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"
  $json = @"
{
  "actionHeader": [{
    "name": "snapshotName",
    "value": "Dev_Start"
  }]
}
"@

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/tms/$($DBUUID)/snapshots"

  write-log -message "Creating Snapshot for $DBUUID"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 

Function REST-Update-Splunk-Blueprint {
  Param (
    [object] $BPObject,
    [object] $Subnet,
    [object] $image,
    [string] $BlueprintUUID,
    [object] $datagen,
    [string] $ProjectUUID,
    [object] $datavar,
    [string] $SERVER_NAME
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"
  foreach ($line in $datagen.PrivateKey){
    [string]$Keystring += $line + "`n" 
  }
  $Keystring = $Keystring.Substring(0,$Keystring.Length-1)
  $newBPObject = $BPObject
  if ($datavar.debug -eq 2){
    $json = $newBPObject| convertto-json -depth 100
    $json | out-file "C:\temp\Splunk1.json"
  }
  $newBPObject.psobject.members.remove("Status")
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "SPLUNK_ADMIN_PASSWORD"}) | add-member noteproperty value $datavar.pepass -force
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "SPLUNK_ADMIN_PASSWORD"}).attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "SPLUNK_LICENSE"}) | add-member noteproperty value "123" -force
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "SPLUNK_ADMIN_PASSWORD"}).attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "INSTANCE_PUBLIC_KEY"}).value = $datagen.publickey
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "SERVER_NAME"}).value = "$($SERVER_NAME)"
  $newBPObject.spec.resources.substrate_definition_list.create_spec.resources.nic_list.subnet_reference.uuid = $subnet.metadata.uuid
  $newBPObject.spec.resources.substrate_definition_list.create_spec.resources.nic_list.subnet_reference.name = $subnet.spec.name
  (($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.disk_list.data_source_reference)[0] | add-member noteproperty uuid $image.metadata.uuid -force
  $newBPObject.metadata.project_reference.uuid = $ProjectUUID
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "Splunk_VM"}).secret | add-member noteproperty value $Keystring -force
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "Splunk_VM"}).secret.attrs.is_secret_modified = 'true'

  $json = $newBPObject | convertto-json -depth 100

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BlueprintUUID)"

  if ($datavar.debug -eq 2){
    $json | out-file "C:\temp\Splunk2.json"
  }
  write-log -message "Updating Import with Creds for $BlueprintUUID"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 

Function REST-Update-HasiCorp-Blueprint {
  Param (
    [object] $BPObject,
    [object] $Subnet,
    [object] $image,
    [string] $BlueprintUUID,
    [object] $datagen,
    [string] $ProjectUUID,
    [object] $datavar,
    [string] $SERVER_NAME
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"
  foreach ($line in $datagen.PrivateKey){
    [string]$Keystring += $line + "`n" 
  }
  $Keystring = $Keystring.Substring(0,$Keystring.Length-1)
  $newBPObject = $BPObject
  if ($datavar.debug -eq 2){
    $json = $newBPObject| convertto-json -depth 100
    $json | out-file "C:\temp\Splunk1.json"
  }
  $newBPObject.psobject.members.remove("Status")

  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "INSTANCE_PUBLIC_KEY"}).value = $datagen.publickey
  ($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.nic_list.subnet_reference.uuid = $subnet.metadata.uuid
  ($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.nic_list.subnet_reference.name = $subnet.spec.name
  ($newBPObject.spec.resources.substrate_definition_list)[1].create_spec.resources.nic_list.subnet_reference.uuid = $subnet.metadata.uuid
  ($newBPObject.spec.resources.substrate_definition_list)[1].create_spec.resources.nic_list.subnet_reference.name = $subnet.spec.name
  #($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.disk_list.data_source_reference | add-member noteproperty uuid $image.metadata.uuid -force
  #($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.disk_list.data_source_reference | add-member noteproperty name $image.spec.name -force
  #($newBPObject.spec.resources.substrate_definition_list)[1].create_spec.resources.disk_list.data_source_reference | add-member noteproperty uuid $image.metadata.uuid -force
  #($newBPObject.spec.resources.substrate_definition_list)[1].create_spec.resources.disk_list.data_source_reference | add-member noteproperty name $image.spec.name -force
  $newBPObject.metadata.project_reference.uuid = $ProjectUUID
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "CentOS_Key"}).secret | add-member noteproperty value $Keystring -force
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "CentOS_Key"}).secret.attrs.is_secret_modified = 'true'

  $json = $newBPObject | convertto-json -depth 100

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BlueprintUUID)"

  if ($datavar.debug -eq 2){
    $json | out-file "C:\temp\Splunk2.json"
  }
  write-log -message "Updating Import with Creds for $BlueprintUUID"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 

Function REST-Update-Win3Tier-Blueprint {
  Param (
    [object] $BPObject,
    [object] $Subnet,
    [object] $image,
    [string] $BlueprintUUID,
    [object] $datagen,
    [string] $ProjectUUID,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $newBPObject = $BPObject
  $newBPObject.psobject.members.remove("Status")

  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "DbPassword"}) | add-member noteproperty value $datavar.pepass -force
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "DbPassword"}).attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.nic_list.subnet_reference.uuid = $subnet.metadata.uuid
  ($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.nic_list.subnet_reference.name = $subnet.spec.name
  ($newBPObject.spec.resources.substrate_definition_list)[1].create_spec.resources.nic_list.subnet_reference.uuid = $subnet.metadata.uuid
  ($newBPObject.spec.resources.substrate_definition_list)[1].create_spec.resources.nic_list.subnet_reference.name = $subnet.spec.name
  (($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.disk_list.data_source_reference)[0] | add-member noteproperty uuid $image.metadata.uuid -force
  (($newBPObject.spec.resources.substrate_definition_list)[0].create_spec.resources.disk_list.data_source_reference)[1] | add-member noteproperty uuid ($newBPObject.spec.resources.package_definition_list | where {$_.name -eq "MSSQL2014_ISO"}).uuid -force
  (($newBPObject.spec.resources.substrate_definition_list)[1].create_spec.resources.disk_list.data_source_reference)[0] | add-member noteproperty uuid $image.metadata.uuid -force
  $newBPObject.metadata.project_reference.uuid = $ProjectUUID
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "WIN_VM_CRED"}).secret | add-member noteproperty value $datavar.pepass -force
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "WIN_VM_CRED"}).secret.attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "SQL_CRED"}).secret | add-member noteproperty value $datavar.pepass -force
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "SQL_CRED"}).secret.attrs.is_secret_modified = 'true'

  $json = $newBPObject | convertto-json -depth 100

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BlueprintUUID)"

  if ($datavar.debug -eq 2){
    $json | out-file "C:\temp\Splunk2.json"
  }
  write-log -message "Updating Import with Creds for $BlueprintUUID"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 

Function REST-Update-ERA-SSP-Blueprint {
  Param (
    [object] $BPObject,
    [string] $BlueprintUUID,
    [object] $datagen,
    [string] $ProjectUUID,
    [object] $datavar,
    [string] $dbname,
    [string] $snapID
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Loading Json"
  foreach ($line in $datagen.PrivateKey){
    [string]$Keystring += $line + "`n" 
  }
  $Keystring = $Keystring.Substring(0,$Keystring.Length-1)
  $newBPObject = $BPObject
  if ($datavar.debug -eq 2){
    $json = $newBPObject| convertto-json -depth 100
    $json | out-file "C:\temp\ERAClone1.json"
  }
  $newBPObject.psobject.members.remove("Status")
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "cloned_db_password"}) | add-member noteproperty value $datavar.pepass -force
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "cloned_db_password"}).attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "era_ip"}).value = $datagen.ERA1IP
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "cloned_db_public_key"}).value = $datagen.publickey
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "source_db_name"}).value = "$($dbname)"
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "source_snapshot_id"}).value = ""
  ($newBPObject.spec.resources.app_profile_list.variable_list | where {$_.name -eq "cloned_db_name"}).value = "$($dbname)_DEV"
  $newBPObject.metadata.project_reference.uuid = $ProjectUUID
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "db_server_creds"}).secret | add-member noteproperty value $Keystring -force
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "db_server_creds"}).secret.attrs.is_secret_modified = 'true'
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "era_creds"}).secret | add-member noteproperty value $datavar.pepass -force
  ($newBPObject.spec.resources.credential_definition_list | where {$_.name -eq "era_creds"}).secret.attrs.is_secret_modified = 'true'

  $json = $newBPObject | convertto-json -depth 100

  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BlueprintUUID)"

  if ($datavar.debug -eq 2){
    $json | out-file "C:\temp\ERAClone2.json"
  }
  write-log -message "Updating Import with Creds for $BlueprintUUID"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "PUT" -body $json -ContentType 'application/json' -headers $headers
    Return $RespErr
  }

  Return $task
} 



Function REST-Move-BluePrint-Launch1 {
  Param (
    [object] $datagen,
    [string] $BPuuid,
    [string] $taskUUID,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
 "spec": {
   "app_profile_reference": {
     "kind": "app_profile",
     "name": "Nutanix",
     "uuid": "$taskUUID"
   },
   "runtime_editables": {
     "action_list": [
       {
       }
     ],
     "service_list": [
       {
       }
     ],
     "credential_list": [
       {
       }
     ],
     "substrate_list": [
       {
       }
     ],
     "package_list": [
       {
       }
     ],
     "app_profile": {
     },
     "task_list": [
       {
       }
     ],
     "variable_list": [
       {
       }
     ],
     "deployment_list": [
       {
       }
     ]
   },
   "app_name": "Nutanix Move"
 }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BPuuid)/simple_launch"
  if ($debug -ge 2){
    $Json | out-file c:\temp\bplaunch.json
  }

  write-log -message "Executing Launch for $BPuuid"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-Karbon-BluePrint-Launch {
  Param (
    [object] $datagen,
    [string] $BPuuid,
    [string] $taskUUID,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
 "spec": {
   "app_profile_reference": {
     "kind": "app_profile",
     "name": "Default",
     "uuid": "$taskUUID"
   },
   "runtime_editables": {
     "action_list": [
       {
       }
     ],
     "service_list": [
       {
       }
     ],
     "credential_list": [
       {
       }
     ],
     "substrate_list": [
       {
       }
     ],
     "package_list": [
       {
       }
     ],
     "app_profile": {
     },
     "task_list": [
       {
       }
     ],
     "variable_list": [
       {
       }
     ],
     "deployment_list": [
       {
       }
     ]
   },
   "app_name": "Karbon Installer"
 }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BPuuid)/simple_launch"
  if ($debug -ge 2){
    $Json | out-file c:\temp\bplaunch.json
  }

  write-log -message "Executing Launch for $BPuuid"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 

Function REST-XPlay-Query-Playbooks {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing Images List Query"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/action_rules/list"
  $Payload= @{
    kind="action_rule"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.entities.count) items."

  Return $task
} 

Function REST-XPlay-Query-ActionTypes {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Executing ActionTypes Query"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/action_types/list"
  $Payload= @{
    kind="action_type"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10
    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  }
  write-log -message "We found $($task.entities.count) items."
  if ($task.entities.count -eq 0){

    write-log -message "0? Let me try that again after a small nap."

    do {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
      sleep 30
      $count++

      write-log -message "Cycle $count Getting action types, current items found is $($task.entities.count)"
    } until ($count -ge 10 -or $task.entities.count -ge 1)
  }
  Return $task
} 

Function REST-Query-DetailPlaybook {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $uuid,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Playbook Query JSON"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/action_rules/$($uuid)"
  try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-Query-DetailAlertPolicy {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $uuid,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Alert Query JSON"

  $URL = "https://$($ClusterPC_IP):9440/PrismGateway/services/rest/v2.0/alerts/policies/$($uuid)"
  try {
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-XPlay-Create-Playbook {
  Param (
    [object] $datagen,
    [object] $AlertTriggerObject,
    [object] $AlertActiontypeObject,
    [object] $AlertTypeObject,
    [object] $BluePrintObject,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  $alertActiontype = $AlertActiontypeObject.entities | where {$_.status.resources.display_name -eq "REST API"}
  $BPAppID = $(($BluePrintObject.spec.resources.app_profile_list | where {$_.name -eq "IIS"}).uuid)
  write-log -message "Replacing JSON String Variables"
  write-log -message "Using Action Type $($alertActiontype.metadata.uuid)"
  write-log -message "Using Alert Trigger $($AlertTriggerObject.group_results.Entity_results.entity_id)"
  write-log -message "Using Alert Type $($AlertTypeObject.group_results.entity_results.entity_id)"
  write-log -message "Using Blueprint $($BluePrintObject.metadata.uuid)"
  write-log -message "Using BP App $($BPAppID)"


$Json = @"
{
  "api_version": "3.1",
  "metadata": {
    "kind": "action_rule",
    "spec_version": 0
  },
  "spec": {
    "resources": {
      "name": "IIS Xplay Demo",
      "description": "IIS Xplay Demo",
      "is_enabled": true,
      "should_validate": true,
      "trigger_list": [
        {
          "display_name": "",
          "action_trigger_type_reference": {
            "kind": "action_trigger_type",
            "uuid": "$($AlertTriggerObject.group_results.Entity_results.entity_id)",
            "name": "alert_trigger"
          },
          "input_parameter_values": {
            "alert_uid": "A$($AlertTypeObject.group_results.entity_results.entity_id)",
            "severity": "[\"critical\"]",
            "source_entity_info_list": "[]"
          }
        }
      ],
      "execution_user_reference": {
        "kind": "user",
        "name": "admin",
        "uuid": "00000000-0000-0000-0000-000000000000"
      },
      "action_list": [
        {
          "action_type_reference": {
            "kind": "action_type",
            "uuid": "$($alertActiontype.metadata.uuid)",
            "name": "rest_api_action"
          },
          "display_name": "",
          "input_parameter_values": {
            "username":  "$($datavar.PEadmin)",
            "request_body":  "{\n \"spec\": {\n   \"app_profile_reference\": {\n     \"kind\": \"app_profile\",\n     \"name\": \"IIS\",\n     \"uuid\": \"$($BPAppID)\"\n   },\n   \"runtime_editables\": {\n     \"action_list\": [\n       {\n       }\n     ],\n     \"service_list\": [\n       {\n       }\n     ],\n     \"credential_list\": [\n       {\n       }\n     ],\n     \"substrate_list\": [\n       {\n       }\n     ],\n     \"package_list\": [\n       {\n       }\n     ],\n     \"app_profile\": {\n     },\n     \"task_list\": [\n       {\n       }\n     ],\n     \"variable_list\": [\n       {\n       }\n     ],\n     \"deployment_list\": [\n       {\n       }\n     ]\n   },\n   \"app_name\": \"IIS-{{trigger[0].source_entity_info.uuid}}\"\n }\n}",
            "url":  "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/blueprints/$($BluePrintObject.metadata.uuid)/simple_launch",
            "headers":  "Content-Type: application/json",
            "password":  "$($datavar.PEPass)",
            "method":  "POST"
          },
          "should_continue_on_failure": false,
          "max_retries": 0
        }
      ]
    }
  }
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/action_rules"
  if ($debug -ge 2){
    $Json | out-file c:\temp\bplaunch.json
  }

  write-log -message "Executing Playbook Create for alert "
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;

    write-log -message "Nutanix is the best..."

  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 


Function REST-XPlay-Query-AlertTriggerType {
  Param (
    [object] $datagen,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Replacing JSON String Variables"
$Json = @"
{
  "entity_type": "trigger_type",
  "group_member_attributes": [
    {
      "attribute": "name"
    },
    {
      "attribute": "display_name"
    }
  ],
  "group_member_count": 20
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/groups"
  if ($debug -ge 2){
    $Json | out-file c:\temp\bplaunch.json
  }

  write-log -message "Executing Alert Type Query"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }
  if ($task.total_group_count -eq 0){

    write-log -message "0? Let me try that again after a small nap."
    $count = 0
    do {
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
      sleep 30
      $count++

      write-log -message "Cycle $count Getting Alert trigger types, current items found is $($task.total_group_count)"
    } until ($count -ge 10 -or $task.total_group_count -ge 1)
  }
  Return $task
} 

Function REST-XPlay-Query-AlertUUID {
  Param (
    [object] $datagen,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Alert UUID JSON"
$Json = @"
{
  "entity_type": "alert_check_schema",
  "group_member_attributes": [
    {
      "attribute": "alert_title"
    },
    {
      "attribute": "_modified_timestamp_usecs_"
    },
    {
      "attribute": "alert_uid"
    }
  ],
  "group_member_sort_attribute": "_modified_timestamp_usecs_",
  "group_member_sort_order": "DESCENDING",
  "group_member_count": 100,
  "filter_criteria": "alert_title==AppFamily:DevOps - VM CPU Usage;alert_uid!=[no_val]"
}
"@ 
  $URL = "https://$($datagen.PCClusterIP):9440/api/nutanix/v3/groups"

  write-log -message "Executing Alert UUID Query"
  write-log -message "Using URL $URL"

  try{
    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  } catch {
    sleep 10

    write-log -message "Going once"

    $task = Invoke-RestMethod -Uri $URL -method "post" -body $Json -ContentType 'application/json' -headers $headers;
  }

  Return $task
} 




Function REST-ERA-RegisterClusterStage1 {
  Param (
    [object] $datavar,
    [object] $datagen
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Cluster Registration JSON"

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/clusters"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.era1ip)"

  $Json = @"
{
  "name": "EraCluster",
  "description": "Era Cluster Description",
  "ip": "$($datavar.peclusterip)",
  "username": "$($datavar.peadmin)",
  "password": "$($datavar.pepass)",
  "status": "UP",
  "version": "v2",
  "cloudType": "NTNX",
  "properties": [
    {
      "name": "ERA_STORAGE_CONTAINER",
      "value": "$($datagen.EraContainerName)"
    }
  ]
}
"@ 
  try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {

    write-log -message "Going once"

    sleep 60
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;
  }  
  Return $task
} 


Function REST-ERA-AttachPENetwork {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $ClusterUUID
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building ERA Network Registration JSON"

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/resources/networks"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.era1ip)"
  write-log -message "Registering Cluster: $ClusterUUID"

  $Json = @"
{
    "name":  "Automation-Network-01",
    "type":  "DHCP",
    "clusterId":  "$($ClusterUUID)",
    "managed":  true,
    "properties":  [

                   ],
    "propertiesMap":  {

                      }
}
"@ 
  try {
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;
  } catch {

    write-log -message "Going once"

    sleep 119
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers; 
  }  
  Return $task
} 

Function REST-ERA-GetClusters {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $ClusterUUID
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Query ERA Clusters"

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/clusters"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.era1ip)"

  try {
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-ERA-GetNetworks {
  Param (
    [object] $datavar,
    [object] $datagen
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Query ERA Networks"

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/resources/networks"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.era1ip)"

  try {
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "GET" -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-ERA-RegisterClusterStage2 {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $ClusterUUID
  )

  write-log -message "Debug level is $($datavar.debug)";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building Stage 2 JSON"

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/clusters/$($ClusterUUID)/json"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.era1ip)"

  $Json = @"
{
  "protocol": "https",
  "ip_address": "$($datavar.peclusterip)",
  "port": "9440",
  "creds_bag": {
    "username": "$($datavar.peadmin)",
    "password": "$($datavar.pepass)"
  }
}
"@

  $filename = "$((get-date).ticks).json"
  $json | out-file $filename
  $filepath = (get-item $filename).fullname

  $fileBin = [System.IO.File]::ReadAlltext($filePath)
  #$fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes);
  $boundary = [System.Guid]::NewGuid().ToString(); 
  $LF = "`r`n";
  
  $bodyLines = ( 
      "--$boundary",
      "Content-Disposition: form-data; name=`"file`"; filename=`"$filename`"",
      "Content-Type: application/json$LF",
      $fileBin,
      "--$boundary--$LF" 
  ) -join $LF

 
  #remove-item $filename -force -ea:0

  try {
    $task = Invoke-RestMethod -Uri $URL -method POST -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines -headers $headers;
  } catch {
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method POST -InFile $filepath -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 






Export-ModuleMember *

