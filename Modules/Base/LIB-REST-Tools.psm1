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
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  $filter = $task.entities | where {$_.spec.resources.network.external_ip -eq $targetIP -or $_.spec.resources.network.external_ip -eq $null}

  Return $filter
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
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  
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
  write-log -message "Executing Project UpdateN"
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
    } catch {
      sleep 20
      write-log -message "Retry REST $countretry"
    }
  } until ($RESTSuccess -eq 1 -or $countretry -ge 5)

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
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;

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

  $task = Invoke-RestMethod -Uri $UserGroupURL -method "post" -body $json -ContentType 'application/json' -headers $headers;
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

  $task = Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers;
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
  $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;

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


  write-log -message "We are still implementing this"
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

