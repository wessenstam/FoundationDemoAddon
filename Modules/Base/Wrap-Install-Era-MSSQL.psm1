Function Wrap-Install-Era-MSSQL {
  param (
    [object] $datavar,
    [object] $datagen,
    [string] $basedir,
    $ServerSysprepfile

  )

  write-log -message "Wait for SQL Server Image"

  $image = CMD-Wait-ImageUpload -imagename $datagen.ERA_MSSQLImage -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location

  write-log -message "Creating ERA MSSQL VM"

  $VM1 = CMDPSR-Create-VM -mode "ReserveIP" -DisksContainerName $datagen.EraContainerName -Subnetmask $datavar.InfraSubnetmask -Sysprepfile $ServerSysprepfile -Networkname $datagen.Nw1Name -VMname $datagen.ERA_MSSQLName -ImageName $datagen.ERA_MSSQLImage -cpu 4 -ram 16384 -VMip $datagen.ERA_MSSQLIP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass

  write-log -message "Join ERA MSSQL VM"

  PSR-Join-Domain -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -ip $datagen.ERA_MSSQLIP -dnsserver $datagen.DC2IP -Domainname $datagen.Domainname

  write-log -message "Finalizing SQL Server VM"

  PSR-ERA-ConfigureMSSQL -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -ip $datagen.ERA_MSSQLIP -Domainname $datagen.Domainname -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -containername $datagen.EraContainerName -sename $datavar.SenderName

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

  write-log -message "Getting SLAs"

  $slas = REST-ERA-GetSLAs -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug
  $gold = $slas | where {$_.name -eq "Gold"}

  write-log -message "Using GOLD SLA SLAs $($gold.id)"

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

  } until ($count -ge 18 -or ($real -and $real.status -eq 4) -or $real.percentageComplete -eq 100)

  sleep 60

  write-log -message "Registering MSSQL Server with second DB"

  $operation = REST-ERA-RegisterMSSQL-ERA -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -MSQLVMIP $datagen.ERA_MSSQLIP -SLA $gold -sysprepPass $datagen.SysprepPassword -dbname "WideWorldImportersDW"
 
}
Export-ModuleMember *


