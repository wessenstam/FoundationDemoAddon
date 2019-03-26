Function Wrap-Install-Era-Base {
  param (
    [object] $datavar,
    [object] $datagen,
    [string] $basedir,
    $ServerSysprepfile

  )
  do {
    $count++
    sleep 15

    write-log -message "Wait for ERA Server Image"
  
    $image = CMD-Wait-ImageUpload -imagename $datagen.ERA_ImageName -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location
  
    write-log -message "Building ERA VM"
  
    $VM = CMD-Create-VM -DisksContainerName $datagen.DiskContainerName -Subnetmask $datavar.InfraSubnetmask -Networkname $datagen.Nw1Name -VMname $datagen.ERA1Name -ImageNames $datagen.ERA_ImageName -cpu 4 -ram 16384 -VMip $datagen.ERA1IP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass
  
    write-log -message "Resetting ERA SSH Pass"
  
    $status = SSH-ResetPass-Px -PxClusterIP $datagen.ERA1IP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -mode "ERA"
  } until ($status.result -eq "Success" -or $count -ge 3)

  write-log -message "Resetting ERA Portal Password"

  REST-ERA-ResetPass -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug

  write-log -message "Accepting ERA EULA"

  REST-ERA-AcceptEULA -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin

  write-log -message "Register Cluster Stage 1"

  $output = REST-ERA-RegisterClusterStage1 -datavar $datavar -datagen $datagen

  write-log -message "Get Cluster UUID"
  sleep 10
  $count = 0  
  do {
    $count ++
    $cluster = REST-ERA-GetClusters -datavar $datavar -datagen $datagen

    if ($cluster.id -match "[0-9]"){

      write-log -message "Using Cluster $($cluster.id)"

    } else {

      sleep 30
      write-log -message "Cluster is not created yet waiting $count out of 5"

    }
  } until ($cluster.id -match "[0-9]" -or $count -ge 5)
  write-log -message "Register Cluster Stage 2 using cluster $($cluster.id)"

  REST-ERA-RegisterClusterStage2 -datavar $datavar -datagen $datagen -ClusterUUID $cluster.id
  sleep 119

  write-log -message "Register PE Networkname"

  sleep 119
  REST-ERA-AttachPENetwork -datavar $datavar -datagen $datagen -ClusterUUID $cluster.id

  write-log -message "Get Cluster UUID"

  $cluster = REST-ERA-GetClusters -datavar $datavar -datagen $datagen

  write-log -message "Getting SLAs"

  $slas = REST-ERA-GetSLAs -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
  $gold = $slas | where {$_.name -eq "Gold"}

  write-log -message "Using GOLD SLA SLAs $($gold.id)"
  write-log -message "Creating Network Profiles"

  $postgressnw = REST-ERA-PostGresNWProfileCreate -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -Networkname $datagen.Nw1name

  $marianw = REST-ERA-MariaNWProfileCreate -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -Networkname $datagen.Nw1name

  write-log -message "Creating Compute Profile"

  REST-ERA-Create-Low-ComputeProfile -datavar $datavar -datagen $datagen 

  write-log -message "Getting all Profiles"

  $count = 0
  do {
    $count ++
    sleep 119

    write-log -message "$($profiles.count) Profiles found, let me retry."

    $profiles = REST-ERA-GetProfiles -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug 
  } until ($profiles.count -ge 8 -or $count -ge 5)

  write-log -message "We found $($profiles.count) Profiles"

  write-log -message "Forking ERA Oracle" -sev "Chapter"

  $LauchCommand = 'Wrap-Install-Era-Oracle -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -basedir $basedir'
  Lib-Spawn-Wrapper -Type "ERA_Oracle" -datavar $datavar -datagen $datagen -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Install-Era-Oracle.psm1" -LauchCommand $LauchCommand -debug $datavar.debug
  sleep 10

  write-log -message "Forking ERA MSSQL" -sev "Chapter"

  $LauchCommand = 'Wrap-Install-Era-MSSQL -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -basedir $basedir'
  Lib-Spawn-Wrapper -Type "ERA_MSSQL" -datavar $datavar -datagen $datagen -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Install-Era-MSSQL.psm1" -LauchCommand $LauchCommand -debug $datavar.debug
  sleep 10

  write-log -message "Provsioning Maria and Postgres"  -sev "Chapter"

  $marianw = $profiles | where { $_.type -eq "Network" -and $_.EngineType -match "Maria"}
  $SoftwareProfileID = ($profiles | where {$_.name -eq "MARIADB_10.3_OOB"}).id

  Write-log -message "Software Profile ID :"
  ($profiles | where {$_.name -eq "MARIADB_10.3_OOB"}).id

  $computeProfileId = ($profiles | where {$_.name -eq "LOW_OOB_COMPUTE"}).id
  $dbParameterProfileId = ($profiles | where {$_.name -eq "DEFAULT_MARIADB_PARAMS"}).id

  write-log -message "SoftwareProfile ID is $SoftwareProfileID"
  write-log -message "Provision MariaDB Server"

  $operation = REST-ERA-ProvisionServer -dbservername $datagen.ERA_MariaName -networkProfileId $marianw.id -SoftwareProfileID $SoftwareProfileID -computeProfileId $computeProfileId -dbParameterProfileId $dbParameterProfileId -type "mariadb_database" -port "3306" -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -SLA $gold -publicSSHKey $datagen.PublicKey -pocname $datavar.pocname

  $count = 0
  do {
    $result = REST-ERA-Operations -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
    $count++
    
    sleep 60

    write-log -message "Pending Operation completion cycle $count"

    $real = $result.operations | where {$_.id -eq $operation.operationid}

    if ($real.status){

      write-log -message "Server is being built $($real.percentageComplete) % complete."

    }
    if ($real.status -eq 9){
     $operation = REST-ERA-ProvisionServer -dbservername $datagen.ERA_MariaName -networkProfileId $marianw.id -SoftwareProfileID $SoftwareProfileID -computeProfileId $computeProfileId -dbParameterProfileId $dbParameterProfileId -type "mariadb_database" -port "3306" -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -SLA $gold -publicSSHKey $datagen.PublicKey -pocname $datavar.pocname
    }

  } until ($count -ge 18 -or ($real -and $real.status -eq 4) -or $real.percentageComplete -eq 100)

  $DBServers = REST-ERA-GetDBServers -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
  $DBServer = $DBservers | where {$_.name -eq $datagen.ERA_MariaName}

  $operation = REST-ERA-ProvisionDatabase -databasename "MariaDB01" -DBServer $DBServer -networkProfileId $marianw.id -SoftwareProfileID $SoftwareProfileID -computeProfileId $computeProfileId -dbParameterProfileId $dbParameterProfileId -type "mariadb_database" -port "3306" -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -SLA $gold -publicSSHKey $datagen.PublicKey -pocname $datavar.pocname

  write-log -message "Provision PostGres"

  $postgressnw= $profiles | where { $_.type -eq "Network" -and $_.EngineType -match "PostGres"}
  $SoftwareProfileID = ($profiles | where {$_.name -eq "POSTGRES_10.4_OOB"}).id
  $dbParameterProfileId = ($profiles | where {$_.name -eq "DEFAULT_POSTGRES_PARAMS"}).id

  $operation = REST-ERA-ProvisionServer -dbservername $datagen.ERA_PostGName -networkProfileId $postgressnw.id -SoftwareProfileID $SoftwareProfileID -computeProfileId $computeProfileId -dbParameterProfileId $dbParameterProfileId -type "postgres_database" -port "5432" -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -SLA $gold -publicSSHKey $datagen.PublicKey -pocname $datavar.pocname

  $count = 0
  do {
    $result = REST-ERA-Operations -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
    $count++
    
    sleep 30

    write-log -message "Pending Operation completion cycle $count"


    $real = $result.operations | where {$_.id -eq $operation.operationid}

    if ($real.status){

      write-log -message "Server is being built $($real.percentageComplete) % complete."

    }
    if ($real.status -eq 9){
       $operation =REST-ERA-ProvisionServer -dbservername $datagen.ERA_PostGName -networkProfileId $postgressnw.id -SoftwareProfileID $SoftwareProfileID -computeProfileId $computeProfileId -dbParameterProfileId $dbParameterProfileId -type "postgres_database" -port "5432" -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -SLA $gold -publicSSHKey $datagen.PublicKey -pocname $datavar.pocname

    }
  } until ($count -ge 18 -or ($real -and $real.status -eq 4) -or $real.percentageComplete -eq 100)
  
  $DBServers = REST-ERA-GetDBServers -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
  $DBServer = $DBservers | where {$_.name -eq $datagen.ERA_PostGName}

  REST-ERA-ProvisionDatabase -databasename "PostGresDB01" -DBServer $DBServer -networkProfileId $postgressnw.id -SoftwareProfileID $SoftwareProfileID -computeProfileId $computeProfileId -dbParameterProfileId $dbParameterProfileId -type "postgres_database" -port "5432" -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -SLA $gold -publicSSHKey $datagen.PublicKey -pocname $datavar.pocname
  $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug
  $project = $projects.entities | where {$_.spec.name -match "Customer-B"}
  if (!$project){

    write-log -message "Project is not created yet, waiting for LCM to finish."
    write-log -message "Waiting for the last steps in the core to finish."
    write-log -message "Blueprints are required for the next step."

    $count = 0
    do {
      $count++

      write-log -message "Sleeping $count out of 75"

      sleep 110
      $projects = REST-Query-Projects -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
      $project = $projects.entities | where {$_.spec.name -match "Customer-B"}
    }until ($project -or $count -ge 75)
  }
  sleep 90
  
  write-log -message "Project UUID is $($project.metadata.uuid)"

  write-log -message "Creating BluePrint"

  $blueprint = REST-Import-Generic-Blueprint -datagen $datagen -datavar $datavar -BPfilepath "$($BlueprintsPath)\EraDBClone.json" -ProjectUUID $project.metadata.uuid

  write-log -message "Created BluePrint with $($blueprint.metadata.uuid)"
  write-log -message "Getting newly created blueprint"

  $blueprintdetail = REST-Query-DetailBP -datagen $datagen -datavar $datavar -uuid $($blueprint.metadata.uuid)

  $databases = REST-ERA-GetDatabases -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
  $database = $databases | where {$_.name -eq "PostGresDB01"}

  write-log -message "Creating PostGres Snapshot"

  $operation = REST-ERA-CreateSnapshot -datagen $datagen -datavar $datavar -DBUUID $($database.timeMachineId)

  $count = 0
  do {
    $result = REST-ERA-Operations -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
    $count++
    
    sleep 30

    write-log -message "Pending Operation completion cycle $count"


    $real = $result.operations | where {$_.id -eq $operation.operationid}

    if ($real.status){

      write-log -message "Snapshot is $($real.percentageComplete) % complete."

    }
  } until ($count -ge 18 -or ($real -and $real.status -eq 4) -or $real.percentageComplete -eq 100)
  
  write-log -message "Updating the BP"

  $UpdateBP = REST-Update-ERA-SSP-Blueprint -datagen $datagen -datavar $datavar -BPObject $blueprintdetail -snapID $operation.id -BlueprintUUID $blueprint.metadata.uuid -ProjectUUID $project.metadata.uuid -DBname "PostGresDB01"

  write-log -message "Launching the BP Postgres Mode Customer B"

  $Launch = REST-PostGress-SSP-BluePrint-Launch -datagen $datagen -datavar $datavar -BPUUID $($blueprint.metadata.uuid) -taskUUID ($blueprintdetail.spec.resources.app_profile_list | where {$_.name -eq "Default"}).uuid

  $database = $databases | where {$_.name -match "Maria"}

  write-log -message "Creating Maria Snapshot"

  $operation = REST-ERA-CreateSnapshot -datagen $datagen -datavar $datavar -DBUUID $($database.timeMachineId)
  $count = 0
  do {
    $result = REST-ERA-Operations -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
    $count++
    
    sleep 30

    write-log -message "Pending Operation completion cycle $count"


    $real = $result.operations | where {$_.id -eq $operation.operationid}

    if ($real.status){

      write-log -message "Snapshot is $($real.percentageComplete) % complete."

    }
  } until ($count -ge 18 -or ($real -and $real.status -eq 4) -or $real.percentageComplete -eq 100)

  write-log -message "Project UUID is $($project.metadata.uuid)" 
  write-log -message "Getting Latest Spec for existing BP"

  $blueprintdetail = REST-Query-DetailBP -datagen $datagen -datavar $datavar -uuid $($blueprint.metadata.uuid)

  write-log -message "Updating the BP"

  $UpdateBP = REST-Update-ERA-SSP-Blueprint -datagen $datagen -datavar $datavar -BPObject $blueprintdetail -snapID $operation.id -BlueprintUUID $blueprint.metadata.uuid -ProjectUUID $project.metadata.uuid -DBname "MariaDB01"

  write-log -message "Launching the BP Maria Mode Customer B"

  $Launch = REST-Maria-SSP-BluePrint-Launch -datagen $datagen -datavar $datavar -BPUUID $($blueprint.metadata.uuid) -taskUUID ($blueprintdetail.spec.resources.app_profile_list | where {$_.name -eq "Default"}).uuid

}
Export-ModuleMember *


