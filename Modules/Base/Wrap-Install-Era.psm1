Function Wrap-Install-Era {
  param (
    [object] $datavar,
    [object] $datagen,
    $ServerSysprepfile

  )
  do {
    $count++
    sleep 15

    write-log -message "Wait for ERA Server Image"
  
    $image = CMD-Wait-ImageUpload -imagename $datagen.ERA_ImageName -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location
  
    write-log -message "Building ERA VM"
  
    $VM = CMD-Create-VM -DisksContainerName $datagen.DiskContainerName -Subnetmask $datavar.InfraSubnetmask -Networkname $datagen.Nw1Name -VMname $datagen.ERA1Name -ImageName $datagen.ERA_ImageName -cpu 4 -ram 16384 -VMip $datagen.ERA1IP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass
  
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

  write-log -message "Getting all Profiles"
  sleep 60
  
  if ($profiles.count -le 9){
    sleep 119

    write-log -message "$($profiles.count) Profiles found, let me retry."

    $profiles = REST-ERA-GetProfiles -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug 
  }

  write-log -message "We found $($profiles.count) Profiles"

  $marianw = $profiles | where { $_.type -eq "Network" -and $_.EngineType -match "Maria"}
  $SoftwareProfileID = ($profiles | where {$_.name -eq "MARIADB_10.3_OOB"}).id

  Write-log -message "Software Profile ID :"
  ($profiles | where {$_.name -eq "MARIADB_10.3_OOB"}).id

  $computeProfileId = ($profiles | where {$_.name -eq "DEFAULT_OOB_COMPUTE"}).id
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

  write-log -message "Wait for SQL Server Image"

  $image = CMD-Wait-ImageUpload -imagename $datagen.ERA_MSSQLImage -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location

  write-log -message "Creating ERA MSSQL VM"

  $VM1 = CMDPSR-Create-VM -mode "ReserveIP" -DisksContainerName $datagen.EraContainerName -Subnetmask $datavar.InfraSubnetmask -Sysprepfile $ServerSysprepfile -Networkname $datagen.Nw1Name -VMname $datagen.ERA_MSSQLName -ImageName $datagen.ERA_MSSQLImage -cpu 4 -ram 16384 -VMip $datagen.ERA_MSSQLIP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass

  write-log -message "Join ERA MSSQL VM"

  PSR-Join-Domain -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -ip $datagen.ERA_MSSQLIP -dnsserver $datagen.DC2IP -Domainname $datagen.Domainname

  write-log -message "Finalizing SQL Server VM"

  PSR-ERA-ConfigureMSSQL -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -ip $datagen.ERA_MSSQLIP -Domainname $datagen.Domainname -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -containername $datagen.EraContainerName -sename $datavar.SenderName

  write-log -message "Registering MSSQL Server with first DB"

  $operation = REST-ERA-RegisterMSSQL-ERA -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -MSQLVMIP $datagen.ERA_MSSQLIP -SLA $gold -sysprepPass $datagen.SysprepPassword -dbname "WideWorldImporters"
  
  $count = 0
  do {
    $result = REST-ERA-Operations -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
    $count++
    
    sleep 60

    write-log -message "Pending Operation completion cycle $count"

    $real = $result.operations | where {$_.id -eq $operation.operationid}

    if ($real.status){

      write-log -message "Database is beeing registered $($real.percentageComplete) % complete."

    }
    if ($real.status -eq 9){
     $operation = REST-ERA-ProvisionServer -dbservername $datagen.ERA_MariaName -networkProfileId $marianw.id -SoftwareProfileID $SoftwareProfileID -computeProfileId $computeProfileId -dbParameterProfileId $dbParameterProfileId -type "mariadb_database" -port "3306" -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -SLA $gold -publicSSHKey $datagen.PublicKey -pocname $datavar.pocname
    }

  } until ($count -ge 18 -or ($real -and $real.status -eq 4) -or $real.percentageComplete -eq 100)

  sleep 60

  write-log -message "Registering MSSQL Server with second DB"

  $operation = REST-ERA-RegisterMSSQL-ERA -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -MSQLVMIP $datagen.ERA_MSSQLIP -SLA $gold -sysprepPass $datagen.SysprepPassword -dbname "WideWorldImportersDW"

}
Export-ModuleMember *


