{
  "spec": {
    "description": "string",
    "resources": {
      "service_definition_list": [
        {
          "port_list": [
            {
              "protocol": "string",
              "exposed_port": "string",
              "exposed_address": "string",
              "endpoint_name": "string",
              "target_port": "string",
              "container_spec": {}
            }
          ],
          "singleton": false,
          "description": "string",
          "action_list": [
            {
              "critical": false,
              "description": "string",
              "type": "string",
              "runbook": {
                "task_definition_list": [
                  {
                    "target_any_local_reference": {
                      "kind": "string",
                      "type": "string",
                      "uuid": "string",
                      "categories": {},
                      "name": "string"
                    },
                    "retries": "string",
                    "description": "string",
                    "uuid": "string",
                    "child_tasks_local_reference_list": [
                      {
                        "kind": "app_task",
                        "name": "string",
                        "uuid": "string"
                      }
                    ],
                    "attrs": {},
                    "timeout_secs": "string",
                    "type": "string",
                    "variable_list": [
                      {
                        "val_type": "string",
                        "description": "string",
                        "uuid": "string",
                        "value": "string",
                        "label": "string",
                        "attrs": {},
                        "editables": {},
                        "type": "string",
                        "name": "string"
                      }
                    ],
                    "name": "string"
                  }
                ],
                "description": "string",
                "variable_list": [
                  {
                    "val_type": "string",
                    "description": "string",
                    "uuid": "string",
                    "value": "string",
                    "label": "string",
                    "attrs": {},
                    "editables": {},
                    "type": "string",
                    "name": "string"
                  }
                ],
                "uuid": "string",
                "main_task_local_reference": {
                  "kind": "app_task",
                  "name": "string",
                  "uuid": "string"
                },
                "name": "string"
              },
              "attrs": {},
              "uuid": "string",
              "name": "string"
            }
          ],
          "uuid": "string",
          "name": "string",
          "tier": "string",
          "depends_on_list": [
            {
              "kind": "string",
              "type": "string",
              "uuid": "string",
              "categories": {},
              "name": "string"
            }
          ],
          "editables": {},
          "config_reference": {
            "kind": "app_service",
            "name": "string",
            "uuid": "string"
          },
          "variable_list": [
            {
              "val_type": "string",
              "description": "string",
              "uuid": "string",
              "value": "string",
              "label": "string",
              "attrs": {},
              "editables": {},
              "type": "string",
              "name": "string"
            }
          ],
          "container_spec": {}
        }
      ],
      "substrate_definition_list": [
        {
          "instance_name": "string",
          "description": "string",
          "action_list": [
            {
              "critical": false,
              "description": "string",
              "type": "string",
              "runbook": {
                "task_definition_list": [
                  {
                    "target_any_local_reference": {
                      "kind": "string",
                      "type": "string",
                      "uuid": "string",
                      "categories": {},
                      "name": "string"
                    },
                    "retries": "string",
                    "description": "string",
                    "uuid": "string",
                    "child_tasks_local_reference_list": [
                      {
                        "kind": "app_task",
                        "name": "string",
                        "uuid": "string"
                      }
                    ],
                    "attrs": {},
                    "timeout_secs": "string",
                    "type": "string",
                    "variable_list": [
                      {
                        "val_type": "string",
                        "description": "string",
                        "uuid": "string",
                        "value": "string",
                        "label": "string",
                        "attrs": {},
                        "editables": {},
                        "type": "string",
                        "name": "string"
                      }
                    ],
                    "name": "string"
                  }
                ],
                "description": "string",
                "variable_list": [
                  {
                    "val_type": "string",
                    "description": "string",
                    "uuid": "string",
                    "value": "string",
                    "label": "string",
                    "attrs": {},
                    "editables": {},
                    "type": "string",
                    "name": "string"
                  }
                ],
                "uuid": "string",
                "main_task_local_reference": {
                  "kind": "app_task",
                  "name": "string",
                  "uuid": "string"
                },
                "name": "string"
              },
              "attrs": {},
              "uuid": "string",
              "name": "string"
            }
          ],
          "readiness_probe": {
            "connection_type": "string",
            "retries": "5",
            "connection_port": 22,
            "timeout_secs": "string",
            "address": "string",
            "delay_secs": "string",
            "disable_readiness_probe": true,
            "login_credential_local_reference": {
              "kind": "app_credential",
              "name": "string",
              "uuid": "string"
            }
          },
          "config_reference": {
            "kind": "app_substrate",
            "name": "string",
            "uuid": "string"
          },
          "create_spec": {},
          "instance_power_state": "string",
          "platform_data": "string",
          "instance_address": "string",
          "name": "string",
          "uuid": "string",
          "instance_id": "string",
          "editables": {},
          "os_type": "string",
          "type": "string",
          "variable_list": [
            {
              "val_type": "string",
              "description": "string",
              "uuid": "string",
              "value": "string",
              "label": "string",
              "attrs": {},
              "editables": {},
              "type": "string",
              "name": "string"
            }
          ]
        }
      ],
      "credential_definition_list": [
        {
          "username": "string",
          "description": "string",
          "uuid": "string",
          "secret": {},
          "editables": {},
          "type": "string",
          "passphrase": {},
          "name": "string"
        }
      ],
      "type": "string",
      "app_profile_list": [
        {
          "deployment_create_list": [
            {
              "percent_fault_tolerance": 0,
              "description": "string",
              "action_list": [
                {
                  "critical": false,
                  "description": "string",
                  "type": "string",
                  "runbook": {
                    "task_definition_list": [
                      {
                        "target_any_local_reference": {
                          "kind": "string",
                          "type": "string",
                          "uuid": "string",
                          "categories": {},
                          "name": "string"
                        },
                        "retries": "string",
                        "description": "string",
                        "uuid": "string",
                        "child_tasks_local_reference_list": [
                          {
                            "kind": "app_task",
                            "name": "string",
                            "uuid": "string"
                          }
                        ],
                        "attrs": {},
                        "timeout_secs": "string",
                        "type": "string",
                        "variable_list": [
                          {
                            "val_type": "string",
                            "description": "string",
                            "uuid": "string",
                            "value": "string",
                            "label": "string",
                            "attrs": {},
                            "editables": {},
                            "type": "string",
                            "name": "string"
                          }
                        ],
                        "name": "string"
                      }
                    ],
                    "description": "string",
                    "variable_list": [
                      {
                        "val_type": "string",
                        "description": "string",
                        "uuid": "string",
                        "value": "string",
                        "label": "string",
                        "attrs": {},
                        "editables": {},
                        "type": "string",
                        "name": "string"
                      }
                    ],
                    "uuid": "string",
                    "main_task_local_reference": {
                      "kind": "app_task",
                      "name": "string",
                      "uuid": "string"
                    },
                    "name": "string"
                  },
                  "attrs": {},
                  "uuid": "string",
                  "name": "string"
                }
              ],
              "min_replicas": "1",
              "max_replicas": "1",
              "substrate_local_reference": {
                "kind": "app_substrate",
                "name": "string",
                "uuid": "string"
              },
              "num_fault_tolerance": 0,
              "brownfield_instance_list": [
                {
                  "instance_id": "string",
                  "instance_name": "string",
                  "address": [
                    "string"
                  ],
                  "platform_data": {}
                }
              ],
              "fault_domain_scope": "string",
              "name": "string",
              "package_local_reference_list": [
                {
                  "kind": "app_package",
                  "name": "string",
                  "uuid": "string"
                }
              ],
              "uuid": "string",
              "depends_on_list": [
                {
                  "kind": "string",
                  "type": "string",
                  "uuid": "string",
                  "categories": {},
                  "name": "string"
                }
              ],
              "editables": {},
              "type": "GREENFIELD",
              "options": {},
              "variable_list": [
                {
                  "val_type": "string",
                  "description": "string",
                  "uuid": "string",
                  "value": "string",
                  "label": "string",
                  "attrs": {},
                  "editables": {},
                  "type": "string",
                  "name": "string"
                }
              ],
              "published_service_local_reference_list": [
                {
                  "kind": "app_published_service",
                  "name": "string",
                  "uuid": "string"
                }
              ]
            }
          ],
          "uuid": "string",
          "description": "string",
          "action_list": [
            {
              "critical": false,
              "description": "string",
              "type": "string",
              "runbook": {
                "task_definition_list": [
                  {
                    "target_any_local_reference": {
                      "kind": "string",
                      "type": "string",
                      "uuid": "string",
                      "categories": {},
                      "name": "string"
                    },
                    "retries": "string",
                    "description": "string",
                    "uuid": "string",
                    "child_tasks_local_reference_list": [
                      {
                        "kind": "app_task",
                        "name": "string",
                        "uuid": "string"
                      }
                    ],
                    "attrs": {},
                    "timeout_secs": "string",
                    "type": "string",
                    "variable_list": [
                      {
                        "val_type": "string",
                        "description": "string",
                        "uuid": "string",
                        "value": "string",
                        "label": "string",
                        "attrs": {},
                        "editables": {},
                        "type": "string",
                        "name": "string"
                      }
                    ],
                    "name": "string"
                  }
                ],
                "description": "string",
                "variable_list": [
                  {
                    "val_type": "string",
                    "description": "string",
                    "uuid": "string",
                    "value": "string",
                    "label": "string",
                    "attrs": {},
                    "editables": {},
                    "type": "string",
                    "name": "string"
                  }
                ],
                "uuid": "string",
                "main_task_local_reference": {
                  "kind": "app_task",
                  "name": "string",
                  "uuid": "string"
                },
                "name": "string"
              },
              "attrs": {},
              "uuid": "string",
              "name": "string"
            }
          ],
          "editables": {},
          "variable_list": [
            {
              "val_type": "string",
              "description": "string",
              "uuid": "string",
              "value": "string",
              "label": "string",
              "attrs": {},
              "editables": {},
              "type": "string",
              "name": "string"
            }
          ],
          "name": "string"
        }
      ],
      "published_service_definition_list": [
        {
          "port_list": [
            {
              "protocol": "string",
              "exposed_port": "string",
              "exposed_address": "string",
              "endpoint_name": "string",
              "target_port": "string",
              "container_spec": {}
            }
          ],
          "singleton": false,
          "description": "string",
          "action_list": [
            {
              "critical": false,
              "description": "string",
              "type": "string",
              "runbook": {
                "task_definition_list": [
                  {
                    "target_any_local_reference": {
                      "kind": "string",
                      "type": "string",
                      "uuid": "string",
                      "categories": {},
                      "name": "string"
                    },
                    "retries": "string",
                    "description": "string",
                    "uuid": "string",
                    "child_tasks_local_reference_list": [
                      {
                        "kind": "app_task",
                        "name": "string",
                        "uuid": "string"
                      }
                    ],
                    "attrs": {},
                    "timeout_secs": "string",
                    "type": "string",
                    "variable_list": [
                      {
                        "val_type": "string",
                        "description": "string",
                        "uuid": "string",
                        "value": "string",
                        "label": "string",
                        "attrs": {},
                        "editables": {},
                        "type": "string",
                        "name": "string"
                      }
                    ],
                    "name": "string"
                  }
                ],
                "description": "string",
                "variable_list": [
                  {
                    "val_type": "string",
                    "description": "string",
                    "uuid": "string",
                    "value": "string",
                    "label": "string",
                    "attrs": {},
                    "editables": {},
                    "type": "string",
                    "name": "string"
                  }
                ],
                "uuid": "string",
                "main_task_local_reference": {
                  "kind": "app_task",
                  "name": "string",
                  "uuid": "string"
                },
                "name": "string"
              },
              "attrs": {},
              "uuid": "string",
              "name": "string"
            }
          ],
          "uuid": "string",
          "tier": "string",
          "depends_on_list": [
            {
              "kind": "string",
              "type": "string",
              "uuid": "string",
              "categories": {},
              "name": "string"
            }
          ],
          "editables": {},
          "config_reference": {
            "kind": "app_published_service",
            "name": "string",
            "uuid": "string"
          },
          "type": "K8S_SERVICE",
          "options": {},
          "variable_list": [
            {
              "val_type": "string",
              "description": "string",
              "uuid": "string",
              "value": "string",
              "label": "string",
              "attrs": {},
              "editables": {},
              "type": "string",
              "name": "string"
            }
          ],
          "name": "string"
        }
      ],
      "default_credential_local_reference": {
        "kind": "app_credential",
        "name": "string",
        "uuid": "string"
      },
      "package_definition_list": [
        {
          "image_spec": {},
          "description": "string",
          "action_list": [
            {
              "critical": false,
              "description": "string",
              "type": "string",
              "runbook": {
                "task_definition_list": [
                  {
                    "target_any_local_reference": {
                      "kind": "string",
                      "type": "string",
                      "uuid": "string",
                      "categories": {},
                      "name": "string"
                    },
                    "retries": "string",
                    "description": "string",
                    "uuid": "string",
                    "child_tasks_local_reference_list": [
                      {
                        "kind": "app_task",
                        "name": "string",
                        "uuid": "string"
                      }
                    ],
                    "attrs": {},
                    "timeout_secs": "string",
                    "type": "string",
                    "variable_list": [
                      {
                        "val_type": "string",
                        "description": "string",
                        "uuid": "string",
                        "value": "string",
                        "label": "string",
                        "attrs": {},
                        "editables": {},
                        "type": "string",
                        "name": "string"
                      }
                    ],
                    "name": "string"
                  }
                ],
                "description": "string",
                "variable_list": [
                  {
                    "val_type": "string",
                    "description": "string",
                    "uuid": "string",
                    "value": "string",
                    "label": "string",
                    "attrs": {},
                    "editables": {},
                    "type": "string",
                    "name": "string"
                  }
                ],
                "uuid": "string",
                "main_task_local_reference": {
                  "kind": "app_task",
                  "name": "string",
                  "uuid": "string"
                },
                "name": "string"
              },
              "attrs": {},
              "uuid": "string",
              "name": "string"
            }
          ],
          "service_local_reference_list": [
            {
              "kind": "app_service",
              "name": "string",
              "uuid": "string"
            }
          ],
          "uuid": "string",
          "version": "string",
          "editables": {},
          "config_reference": {
            "kind": "app_package",
            "name": "string",
            "uuid": "string"
          },
          "type": "string",
          "options": {},
          "variable_list": [
            {
              "val_type": "string",
              "description": "string",
              "uuid": "string",
              "value": "string",
              "label": "string",
              "attrs": {},
              "editables": {},
              "type": "string",
              "name": "string"
            }
          ],
          "name": "string"
        }
      ],
      "client_attrs": {}
    },
    "cluster_reference": {
      "kind": "cluster",
      "name": "string",
      "uuid": "string"
    },
    "name": "string",
    "availability_zone_reference": {
      "kind": "availability_zone",
      "name": "string",
      "uuid": "string"
    }
  },
  "api_version": "string",
  "metadata": {
    "last_update_time": "2019-02-10T10:01:03.622Z",
    "kind": "blueprint",
    "uuid": "string",
    "project_reference": {
      "kind": "project",
      "name": "string",
      "uuid": "string"
    },
    "spec_version": 0,
    "creation_time": "2019-02-10T10:01:03.622Z",
    "spec_hash": "string",
    "should_force_translate": true,
    "owner_reference": {
      "kind": "user",
      "name": "string",
      "uuid": "string"
    },
    "categories": {},
    "name": "string"
  }
}