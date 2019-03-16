Function Wrap-Import-Move-Demo{
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
  $image = $images.entities | where {$_.spec.name -match $datagen.Move_ImageName }
  sleep 10

  $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
  $project = $projects.entities | where {$_.spec.name -match "Customer-C"}
  if (!$project){
    $count = 0
    do {
      $count++

      write-log -message "Project is not created yet."

      sleep 30
      $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
      $project = $projects.entities | where {$_.spec.name -match "Customer-C"}
    }until ($project -or $count -ge 10)
  }
  sleep 90
  
  write-log -message "Using Cluster $($cluster.metadata.uuid)"
  write-log -message "Using Subnet $($subnet.metadata.uuid)"
  write-log -message "Project UUID is $($project.metadata.uuid)"
  write-log -message "Image UUID is $($image.metadata.uuid)"

  write-log -message "Creating BluePrint"

  $blueprint = REST-Import-Move-Blueprint -datagen $datagen -datavar $datavar -BPfilepath "$($BlueprintsPath)\MoveV2.json" -subnetUUID $($subnet.metadata.uuid) -projectUUID $($project.metadata.uuid) -image $image 

  write-log -message "Created BluePrint with $($blueprintUUID.metadata.uuid)"
  write-log -message "Getting newly created blueprint"

  $blueprintdetail = REST-Query-DetailBP -datagen $datagen -datavar $datavar -uuid $($blueprint.metadata.uuid)

  write-log -message "Modifing BP Export"

  $update = REST-Update-Move-Blueprint -datagen $datagen -datavar $datavar -bpobject $blueprintdetail -blueprintUUID $($blueprint.metadata.uuid) -sysprepObject $sysprepObject -DomainObject $DomainObject

  write-log -message "Blueprint Ready"
  write-log -message "Firing BluePrint Install"

  $Launch = REST-Move-BluePrint-Launch1 -datagen $datagen -datavar $datavar -BPUUID $($blueprint.metadata.uuid) -taskUUID ($blueprintdetail.spec.resources.app_profile_list | where {$_.name -eq "Nutanix"}).uuid

  sleep 60

  write-log -message "Firing BluePrint Action"

  $apps = REST-Query-Calm-Apps -datavar $datavar -datagen $datagen
  $app  = $apps.entities | where {$_.status.name -eq "Nutanix Move"}
  if ($app){

    write-log -message "App is found $($app.metadata.uuid)"

  }
  $count = 0
  do {
    $count++
    $appdetail = REST-Query-Calm-DetailedApps -datavar $datavar -datagen $datagen -UUID $app.metadata.uuid
    $Action    = $appdetail.spec.resources.action_list | where {$_.name -eq "EULA_PW"}

    write-log -message "Waiting for APP Running state"
    write-log -message "Current state is $($appdetail.status.state)" 
    if ($appdetail.status.state -eq "Running"){

      write-log -message "App is running, lets go."

    } else {

      sleep 60

    }

  } until ($appdetail.status.state -eq "Running" -or $count -ge 5)

  ##$Launch = REST-Move-BluePrint-LaunchAPP -datavar $datavar -datagen $datagen -action $action -appdetail $appdetail

  write-log -message "Getting Access Token" 

  $token = REST-Move-Login -datagen $datagen

  write-log -message "Registering with token $($token.token)"

  $register = REST-Move-EULA -datagen $datagen -datavar $datavar -token $token

  write-log -message "Configuring Target"

  REST-Move-SetTarget -datagen $datagen -datavar $datavar -Token $token

}
Export-ModuleMember *

