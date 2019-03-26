Function Wrap-Create-KarbonCluster {
  param (
    [object] $datavar,
    [object] $datagen,
    [string] $BlueprintsPath,
    $ServerSysprepfile

  )     
  write-log -message "Enable Karbon" -sev "CHAPTER"

  REST-Enable-Karbon-PC -datavar $datavar -datagen $datagen

  write-log -message "Getting Subnet" 

  $subnet = REST-Query-Subnet -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -networkname $datagen.nw1name -debug $datavar.debug
  sleep 10

  write-log -message "Getting Project" 

  $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
  $project = $projects.entities | where {$_.spec.name -match "Customer-B"}
  if (!$project){
    $count = 0
    do {
      $count++

      write-log -message "Project is not created yet."

      sleep 30
      $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
      $project = $projects.entities | where {$_.spec.name -match "Customer-B"}
    }until ($project -or $count -ge 10)
  }
  sleep 90
  write-log -message "Creating BluePrint"

  $blueprint = REST-Import-Karbon-Blueprint -datagen $datagen -datavar $datavar -BPfilepath "$($BlueprintsPath)\Karbon.json" -subnetUUID $($subnet.metadata.uuid) -projectUUID $($project.metadata.uuid) 

  write-log -message "Created BluePrint with $($blueprintUUID.metadata.uuid)"
  write-log -message "Getting newly created blueprint"

  $blueprintdetail = REST-Query-DetailBP -datagen $datagen -datavar $datavar -uuid $($blueprint.metadata.uuid)

  write-log -message "Modifing BP Export"

  $Keyobject = $blueprintdetail.spec.resources.credential_definition_list | where {$_.name -eq "SSH_KEY"}
  $instancepwobject = ($blueprintdetail.spec.resources.app_profile_list.variable_list | where {$_.name -eq "Instance_Password"})
  $PCPassObject = ($blueprintdetail.spec.resources.app_profile_list.variable_list | where {$_.name -eq "PC_Password"})
  
  write-log -message "Were using $($Keyobject.secret.attrs.secret_reference.uuid) for Key Credential store Creds"

  $update = REST-Update-Karbon-Blueprint -datagen $datagen -datavar $datavar -bpobject $blueprintdetail -blueprintUUID $($blueprint.metadata.uuid) -Keyobject $Keyobject -instancepwobject $instancepwobject -PCPassObject $PCPassObject

  write-log -message "Launching BP $($blueprint.metadata.uuid)."
  
  $Launch = REST-Karbon-BluePrint-Launch -datagen $datagen -datavar $datavar -BPUUID $($blueprint.metadata.uuid) -taskUUID ($blueprintdetail.spec.resources.app_profile_list | where {$_.name -eq "Default"}).uuid

}