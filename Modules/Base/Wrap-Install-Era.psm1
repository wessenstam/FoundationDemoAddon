Function Wrap-Install-Era {
  param (
    [object] $datavar,
    [object] $datagen,
    $ServerSysprepfile

  )
 
  write-log -message "Building ERA VM"

  $VM = CMD-Create-VM -DisksContainerName $datagen.DiskContainerName -Subnetmask $datavar.InfraSubnetmask -Networkname $datagen.Nw1Name -VMname $datagen.ERA1Name -ImageName $datagen.ERA_ImageName -cpu 4 -ram 16384 -VMip $datagen.ERA1IP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass

  write-log -message "Resetting ERA SSH Pass"

  $status = SSH-ResetPass-Px -PxClusterIP $datagen.ERA1IP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -mode "ERA"

  write-log -message "Resetting ERA Portal Password"

  REST-ERA-ResetPass -EraIP $datagen.ERA1IP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -debug $datavar.debug

  write-log -message "Accepting ERA EULA"

  REST-ERA-AcceptEULA -EraIP "10.64.96.44" -clpassword $datavar.PEPass -clusername $datavar.PEAdmin

  write-log -message "Register Cluster Stage 1"

  $output = REST-ERA-RegisterClusterStage1 -datavar $datavar -datagen $datagen

  write-log -message "Get Cluster UUID"

  $cluster = REST-ERA-GetClusters -datavar $datavar -datagen $datagen

  write-log -message "Register Cluster Stage 2"

  REST-ERA-RegisterClusterStage2 -datavar $datavar -datagen $datagen -ClusterUUID $cluster.id

  write-log -message "Register PE Networkname"

  REST-ERA-AttachPENetwork -datavar $datavar -datagen $datagen -ClusterUUID $cluster.id

  write-log -message "Wait for SQL Server Image"

  $image = CMD-Wait-ImageUpload -imagename $datagen.ERA_ImageName -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location

  write-log -message "Creating ERA MSSQL VM"

  $VM1 = CMDPSR-Create-VM -DisksContainerName $datagen.EraContainerName -Subnetmask $datavar.InfraSubnetmask -Sysprepfile $ServerSysprepfile -Networkname $datagen.Nw1Name -VMname $datagen.ERA_MSSQLName -ImageName $datagen.ERA_MSSQLImage -cpu 4 -ram 16384 -VMip $datagen.ERA_MSSQLIP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass
     

};
Export-ModuleMember *