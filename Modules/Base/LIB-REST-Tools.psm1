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
  $filter = $task.entities | where {$_.spec.resources.network.external_ip -eq $targetIP -or $_.spec.resources.network.external_ip -eq $null}

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
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
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
    [object] $BluePrint,
    [object] $datavar
  )

  $credPair = "$($datavar.PEadmin):$($datavar.PEPass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  $alertActiontype = $AlertActiontypeObject.entities | where {$_.status.resources.display_name -eq "REST API"}
  $BPAppID = $(($BluePrintObject.spec.resources.app_profile_list | where {$_.name -eq "IIS"}).uuid)
  write-log -message "Replacing JSON String Variables"
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
            "alert_uid": "A$($AlertTypeUUID.group_results.entity_results.entity_id)",
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
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 


Function REST-ERA-AttachPENetwork {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $ClusterUUID
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building ERA Network Registration JSON"

  $URL = "https://$($datagen.ERA1IP):8443/era/v0.8/resources/networks"

  write-log -message "Using URL $URL"
  write-log -message "Using IP $($datagen.era1ip)"

  $Json = @"
{
    "name":  "Automation-Network-01",
    "type":  "DHCP",
    "clusterId":  "a62091ef-691f-434d-a8c2-90ef672f963d",
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
    sleep 10
    $task = Invoke-RestMethod -Uri $URL -method "POST" -body $JSON -ContentType 'application/json' -headers $headers;

    write-log -message "Going once"
  }  
  Return $task
} 

Function REST-ERA-GetClusters {
  Param (
    [object] $datavar,
    [object] $datagen,
    [string] $ClusterUUID
  )

  write-log -message "Debug level is $debug";
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

  write-log -message "Debug level is $debug";
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

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $credPair = "$($datavar.peadmin):$($datavar.pepass)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building EULA Accept JSON"

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

