Function Wrap-Install-Era-Oracle {
  param (
    [object] $datavar,
    [object] $datagen,
    [string] $basedir,
    $ServerSysprepfile

  )
  do {
    $count++
    sleep 15

    write-log -message "Wait for Oracle Server Image(s)"
  
    $image = CMD-Wait-ImageUpload -imagename $datagen.Oracle1_0Image -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location
    $image = CMD-Wait-ImageUpload -imagename $datagen.Oracle1_1Image -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location
    $image = CMD-Wait-ImageUpload -imagename $datagen.Oracle1_2Image -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location
  
    write-log -message "Building Oracle VM"
  
    [array]$images += $datagen.Oracle1_0Image
    [array]$images += $datagen.Oracle1_1Image
    [array]$images += $datagen.Oracle1_2Image

    $VM = CMD-Create-VM -DisksContainerName $datagen.DiskContainerName -Subnetmask $datavar.InfraSubnetmask -Networkname $datagen.Nw1Name -VMname $datagen.Oracle_VMName -ImageNames $images -cpu 2 -ram 8192 -cores 4 -VMip $datagen.OracleIP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass
  
    write-log -message "Resetting Oracle SSH Pass 1"
  
    $status = SSH-ResetPass-Px -PxClusterIP $datagen.OracleIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -mode "Oracle1"

    write-log -message "Resetting Oracle SSH Pass 2"
  
    $status = SSH-ResetPass-Px -PxClusterIP $datagen.OracleIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -mode "Oracle2"

    write-log -message "Resetting Oracle SSH Pass 3"
  
    $status = SSH-ResetPass-Px -PxClusterIP $datagen.OracleIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -mode "Oracle3"

    write-log -message "Resetting Oracle SSH Pass 4"
  
    $status = SSH-ResetPass-Px -PxClusterIP $datagen.OracleIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -mode "Oracle4"
  } until ($status.result -eq "Success" -or $count -ge 3)

  write-log -message "Starting Oracle Databases"

  SSH-Startup-Oracle -OracleIP $datagen.OracleIP -clpassword $datavar.PEPass -debug $datavar.debug
    sleep 30
  SSH-Oracle-InsertDemo -OracleIP $datagen.OracleIP -clpassword $datavar.PEPass -debug $datavar.debug -filename1 "$basedir\Binaries\OracleDemo\adump.sh" -filename2 "$basedir\Binaries\OracleDemo\ticker.sh"

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

  write-log -message "Registering Oracle Server with first DB"

  $operation = REST-ERA-RegisterOracle-ERA -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug -ERACluster $cluster -OracleIP $datagen.OracleIP -SLA $gold -dbname "ORCL"
  
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

}
Export-ModuleMember *


