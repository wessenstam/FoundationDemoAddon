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
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
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
  $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
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
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
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

  $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
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

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $domainparts = $domainname.split(".")
  write-log -message "Building Project Create JSON"

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

  $task = Invoke-RestMethod -Uri $UserGroupURL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  Return $task
} 


Export-ModuleMember *



Function REST-Query-Role-List {
  Param (
    [string] $ClusterPC_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $rolename,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Getting Role UUID"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/roles/list"
    $Payload= @{
    kind="role"
    offset=0
    length=999
  } 

  $JSON = $Payload | convertto-json
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
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

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Getting Role for $RoleUUID"

  $URL = "https://$($ClusterPC_IP):9440/api/nutanix/v3/roles/$($RoleUUID)"

  $task = Invoke-RestMethod -Uri $URL -method "get" -headers $headers;
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

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
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
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;

  Return $result
} 


Function REST-Set-SMTP-Server-Px {
  Param (
    [string] $ClusterPx_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $email_address,
    [string] $email_fqdn,
    [string] $cluuid,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }
  $domainparts = $domainname.split(".")
  write-log -message "Building Project Create JSON"

  ##$UserGroupURL = "https://$($ClusterPx_IP):9440/api/nutanix/v3/projects"
  $json = @"
{
  "spec": {
    "name": "string",
    "resources": {
      "config": {
        "smtp_server": {
          "email_address": "$($email_address)",
          "type": "PLAIN",
          "server": {
            "address": {
              "port": 25,
              "fqdn": "$($email_fqdn)"
            }
          }
        }
      }
    }
  },
  "api_version": "3.1.0",
  "metadata": {
    "kind": "cluster",
    "uuid": "$($cluuid)"
  }
}
"@

  $task = Invoke-RestMethod -Uri $UserGroupURL -method "post" -body $json -ContentType 'application/json' -headers $headers;
  Return $task
} 


Export-ModuleMember *

