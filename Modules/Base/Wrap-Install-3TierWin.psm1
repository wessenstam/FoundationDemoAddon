  Function Wrap-Install-3TierWin {
  param (
    [object] $datavar,
    [object] $datagen,
    [string] $basedir,
    [string] $BlueprintsPath,
    $ServerSysprepfile
  )
  $subnet = REST-Query-Subnet -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -networkname $datagen.nw1name -debug $datavar.debug
  sleep 10
  $images = REST-Query-Images -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
  $image = $images.entities | where {$_.spec.name -eq "Windows 2012" }
  sleep 10

  $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug
  $project = $projects.entities | where {$_.spec.name -match "Customer-D"}
  if (!$project){

    write-log -message "Project is not created yet, waiting for LCM to finish."
    write-log -message "Waiting for the last steps in the core to finish."
    write-log -message "Blueprints are required for the next step."

    $count = 0
    do {
      $count++

      write-log -message "Sleeping $count out of 25"

      sleep 110
      $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
      $project = $projects.entities | where {$_.spec.name -match "Customer-D"}
    }until ($project -or $count -ge 25)
  }
  sleep 90
  
  write-log -message "Project UUID is $($project.metadata.uuid)"

  write-log -message "Creating BluePrint"

  $blueprint = REST-Import-Generic-Blueprint -datagen $datagen -datavar $datavar -BPfilepath "$($BlueprintsPath)\Windows3TierApp.json" -ProjectUUID $project.metadata.uuid

  write-log -message "Created BluePrint with $($blueprint.metadata.uuid)"
  write-log -message "Getting newly created blueprint"

  $blueprintdetail = REST-Query-DetailBP -datagen $datagen -datavar $datavar -uuid $($blueprint.metadata.uuid)

  write-log -message "Updating the BP"

  $UpdateBP = REST-Update-Win3Tier-Blueprint -datagen $datagen -datavar $datavar -BPObject $blueprintdetail -snapID $operation.id -BlueprintUUID $blueprint.metadata.uuid -ProjectUUID $project.metadata.uuid -subnet $subnet -image $image

  write-log -message "Launching the BP for Customer D"

  #$Launch = REST-Generic-BluePrint-Launch -datagen $datagen -datavar $datavar -BPUUID $($blueprint.metadata.uuid) -TaskObject ($blueprintdetail.spec.resources.app_profile_list | where {$_.name -eq "Default"}) -appname "3 Tier Windows App"

}

Export-ModuleMember *


