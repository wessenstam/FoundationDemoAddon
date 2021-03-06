Function Wrap-Import-XPlay-Demo{
   param (
    [object] $datagen,
    [object] $datavar,
    [string] $BlueprintsPath,
    [string] $basedir
   ) 
  
  $subnet = REST-Query-Subnet -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -networkname $datagen.nw1name -debug $datavar.debug
  sleep 10
  $cluster = REST-Query-Cluster -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -targetIP $datagen.PCClusterIP
  sleep 10
  $images = REST-Query-Images -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
  $image = $images.entities | where {$_.spec.name -match "$($datagen.DC_ImageName)"}
  sleep 10
  write-log -message "Unlocking XPlay"

  if ([version]$datavar.PCVersion -lt "5.11"){

    write-log -message "Unlocking XPlay required on $($datavar.PCVersion)"

    $filepath = "$basedir\Binaries\XplayUnlock\unlockxplay_py.py"
    SSH-Unlock-XPlay -PCClusterIP $datagen.PCClusterIP -clusername "nutanix" -clpassword $Datavar.pepass -filename $filepath

    write-log -message "Query Alert Trigger type"

    $AlertTriggerTypes = REST-XPlay-Query-AlertTriggerType -datagen $datagen -datavar $datavar
    
    write-log -message "Using Trigger Type $($AlertTriggerTypes.group_results.Entity_results.entity_id)"

    write-log -message "Query Alert Action type"
  
    $AlertActiontype = REST-XPlay-Query-ActionTypes -ClusterPC_IP $datagen.PCClusterIP -clusername $Datavar.peadmin -clpassword $Datavar.pepass 
  
    write-log -message "Query Alert Type UUID"
  
    $AlertTypeUUID = REST-XPlay-Query-AlertUUID -datagen $datagen -datavar $datavar
    if ($AlertTypeUUID -eq $null){
      write-log -message "0? let me try that again."
      $count = 0
      do {
        sleep 30
        $count ++
        $AlertTypeUUID = REST-XPlay-Query-AlertUUID -datagen $datagen -datavar $datavar
      } until ($AlertTypeUUID -or $count -ge 5)
    }
  
  }

  write-log -message "Query VM Group" 
  
  $groups = REST-Query-Groups -datagen $datagen -datavar $datavar
  $group = $groups.group_results.entity_results | where {$_.data.values.values -match "DevOps"}

  write-log -message "We are using $($group.entity_id)" 
  write-log -message "Creating Alert Policy"

  $Policy = REST-Create-Alert-Policy -datagen $datagen -datavar $datavar -group $group
  sleep 10
  $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
  $project = $projects.entities | where {$_.spec.name -match "Customer-A"}

  write-log -message "Using Cluster $($cluster.metadata.uuid)"
  write-log -message "Using Subnet $($subnet.metadata.uuid)"
  write-log -message "Project UUID is $($project.metadata.uuid)"
  write-log -message "Image UUID is $($image.metadata.uuid)"
  write-log -message "We have to wait for PC LCM - CALM now"
  $exit = 0
  $installcounter = 0
  $installMasterCounter = 0
  $waitforinstallloops = 15
  do{
    $installMasterCounter++
    try {
      do {

        write-log -message "Waiting / Checking Install Status"

        $installcounter++
        $tasks = REST-Task-List -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin 
        $installtask = $tasks.entities | where {$_.operation_type -eq "kLcmUpdateOperation"} | select -last 1
        if ($installtask){

          write-log -message "We found 1 task $($installtask.status) and is $($installtask.percentage_complete) % complete"

        }
        Sleep 60
      } until ($installtask.percentage_complete -eq "100" -or $installcounter -eq $waitforinstallloops)
      if ($installcounter -eq $waitforinstallloops){

        write-log -message "I am not supposed to be here."

        $exit =1 
      } elseif ($installtask.status -match "FAILED|ABORTED"){

        write-log -message "Calm Update failed with $($installtask.progress_message), restarting."

        REST-LCM-Install -datavar $datavar -datagen $datagen -mode "PC" -updates $Updates
        sleep 60

      } elseif ($installtask.status -eq "SUCCEEDED"){

        write-log -message "Calm update Complete."

        $exit =1 
      } else {

        write-log -message "I am not supposed to be here."

      }
    } catch {

      write-log -message "Error caught in loop." -sev "WARN"

    }
  } until ($exit -eq 1 -or $installMasterCounter -ge 3)


  write-log -message "Creating BluePrint"

  $blueprint = REST-Import-Xplay-Blueprint -datagen $datagen -datavar $datavar -BPfilepath "$($BlueprintsPath)\IIS Customer Horizontal Scale.json" -subnetUUID $($subnet.metadata.uuid) -projectUUID $($project.metadata.uuid) -ImageUUID $($image.metadata.uuid) -ClusterUUID $($cluster.metadata.uuid)

  write-log -message "Created BluePrint with $($blueprintUUID.metadata.uuid)"
  write-log -message "Getting newly created blueprint"

  $blueprintdetail = REST-Query-DetailBP -datagen $datagen -datavar $datavar -uuid $($blueprint.metadata.uuid)

  write-log -message "Modifing BP Export"

  $sysprepObject = $blueprintdetail.spec.resources.credential_definition_list | where {$_.name -eq "SysprepCreds"}
  $DomainObject = $blueprintdetail.spec.resources.credential_definition_list | where {$_.name -ne "SysprepCreds"}
  
  write-log -message "Were using $($sysprepObject.secret.attrs.secret_reference.uuid) for sysprep Creds"
  write-log -message "Were using $($DomainObject.secret.attrs.secret_reference.uuid) for domain Creds"

  $update = REST-Update-Xplay-Blueprint -datagen $datagen -datavar $datavar -bpobject $blueprintdetail -blueprintUUID $($blueprint.metadata.uuid) -sysprepObject $sysprepObject -DomainObject $DomainObject

  write-log -message "Blueprint Ready"
  write-log -message "Firing BluePrint"

  $Launch = REST-XPlay-BluePrint-Launch -datagen $datagen -datavar $datavar -BPUUID $($blueprint.metadata.uuid) -taskUUID ($blueprintdetail.spec.resources.app_profile_list | where {$_.name -eq "IIS"}).uuid

  if ([version]$datavar.PCVersion -lt "5.11"){
    
    write-log -message "Create Playbook"

    $playbook = REST-XPlay-Create-Playbook -datagen $datagen -datavar $datavar -AlertTriggerObject $AlertTriggerTypes -AlertActiontypeObject $AlertActiontype -AlertTypeObject $AlertTypeUUID -BluePrintObject $blueprintdetail
  }

}
Export-ModuleMember *