Function REST-Install-PC {
  Param (
    [string] $ClusterPE_IP,
    [string] $PCClusterIP,
    [string] $clusername,
    [string] $clpassword,
    [string] $InfraSubnetmask,
    [string] $InfraGateway,
    [string] $DNSServer,
    [string] $PC1_Name,
    [string] $PC2_Name,
    [string] $PC3_Name,
    [string] $PC1_IP,
    [string] $PC2_IP,
    [string] $PC3_IP,
    [string] $AOSVersion,
    [string] $NetworkName,
    [string] $DisksContainerName,
    [string] $PCVersion,
    [string] $PCmode,
    [string] $debug
  )
  $PCinstallcount = 0 
  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  do {
    $PCinstallcount++
    $credPair = "$($clusername):$($clpassword)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    $containerURL = "https://$($ClusterPE_IP):9440/PrismGateway/services/rest/v2.0/storage_containers"
    $networksURL = "https://$($ClusterPE_IP):9440/PrismGateway/services/rest/v2.0/networks"
    $installURL = "https://$($ClusterPE_IP):9440/api/nutanix/v3/prism_central"

    write-log -message "Gathering Storage UUID"
    write-log -message "Searching containers matching $DisksContainerName"

    try {
      $StorageContainer = (Invoke-RestMethod -Uri $containerURL -method "get" -headers $headers).entities | where {$_.name -eq $DisksContainerName}
      write-log -message "Storage UUID is $($StorageContainer.storage_container_uuid)"
    } catch {;
      write-log -message "We Could not query Px for existing storage containers" -sev "ERROR";
    };

    write-log -message "Gathering Network UUID"
    write-log -message "Using PC Version ->$($PCVersion)<-"

    try {
      $Network = (Invoke-RestMethod -Uri $networksURL -method "get" -headers $headers).entities | where {$_.name -eq $NetworkName}
      write-log -message "Network UUID is $($Network.uuid)"
    } catch {;
      write-log -message "We Could not query Px for existing networks" -sev "ERROR";
    };
    if ($pcmode -ne 1){
      $PCJSON = @"
{
  "resources": {
    "should_auto_register":true,
    "version":"$($PCVersion)",
    "virtual_ip":"$($PCClusterIP)",
    "pc_vm_list":[{
      "data_disk_size_bytes":536870912000,
      "nic_list":[{
        "network_configuration":{
          "subnet_mask":"$($InfraSubnetmask)",
          "network_uuid":"$($Network.uuid)",
          "default_gateway":"$($InfraGateway)"
        },
        "ip_list":["$($PC1_IP)"]
      }],
      "dns_server_ip_list":["$DNSServer"],
      "container_uuid":"$($StorageContainer.storage_container_uuid)",
      "num_sockets":8,
      "memory_size_bytes":34359738368,
      "vm_name":"$($PC1_Name)"
    },
    {
      "data_disk_size_bytes":536870912000,
      "nic_list":[{
        "network_configuration":{
          "subnet_mask":"$($InfraSubnetmask)",
          "network_uuid":"$($Network.uuid)",
          "default_gateway":"$($InfraGateway)"
        },
        "ip_list":["$($PC2_IP)"]
      }],
      "dns_server_ip_list":["$($DNSServer)"],
      "container_uuid":"$($StorageContainer.storage_container_uuid)",
      "num_sockets":8,
      "memory_size_bytes":34359738368,
      "vm_name":"$($PC2_Name)"
    },
    {
      "data_disk_size_bytes":536870912000,
      "nic_list":[{
        "network_configuration":{
          "subnet_mask":"$($InfraSubnetmask)",
          "network_uuid":"$($Network.uuid)",
          "default_gateway":"$($InfraGateway)"
        },
        "ip_list":["$($PC3_IP)"]
      }],
      "dns_server_ip_list":["$($DNSServer)"],
      "container_uuid":"$($StorageContainer.storage_container_uuid)",
      "num_sockets":8,
      "memory_size_bytes":34359738368,
      "vm_name":"$($PC3_Name)"
    }]    
  }
}
"@
    } else {
      $PCJSON = @"
{
  "resources": {
    "should_auto_register":false,
    "version":"$($PCVersion)",
    "pc_vm_list":[{
      "data_disk_size_bytes":536870912000,
      "nic_list":[{
        "network_configuration":{
          "subnet_mask":"$($InfraSubnetmask)",
          "network_uuid":"$($Network.uuid)",
          "default_gateway":"$($InfraGateway)"
        },
        "ip_list":["$($PCClusterIP)"]
      }],
      "dns_server_ip_list":["$DNSServer"],
      "container_uuid":"$($StorageContainer.storage_container_uuid)",
      "num_sockets":8,
      "memory_size_bytes":34359738368,
      "vm_name":"$($PC1_Name)"
    }]   
  }
}
"@  }

    write-log -message "Installing Prism Central"

    try { 
      $task = Invoke-RestMethod -Uri $installURL -method "Post" -headers $headers -body $PCJSON -ContentType 'application/json'
      $taskid = $task.task_uuid
    } catch {
      
      write-log -message "Failure installing Prism Central, retry $PCinstallcount out of 5" -sev "WARN"
      sleep 60
      if ($debug -ge 2){
        $task 
        write-host $PCJSON
        $task = Invoke-RestMethod -Uri $installURL -method "Post" -headers $headers -body $PCJSON -ContentType 'application/json'
      
      }
    }
  } Until ($taskid -match "[0-9]" -or $PCinstallcount -eq 5)
  if ($taskid -match "[0-9]"){
    $status = "Success"

    write-log -message "Prism Central is installing in $PCmode node mode, we are done."

  } else {
    $status = "Failed"
    write-log -message "Failure installing Prism Central after 5 tries" -sev "ERROR"
  }
  $resultobject =@{
    Result = $status
    TaskID = $taskid
  }
  return $resultobject
};
Export-ModuleMember *