Function Wrap-Create-ADForest-PC {
  param (
    [object] $datavar,
    [object] $datagen,
    $ServerSysprepfile

  )     

  write-log -message "Promoting First DC VM" -sev "CHAPTER"

  PSR-Create-Domain -debug $datavar.debug -IP $datagen.DC1IP -SysprepPassword $datagen.SysprepPassword -DNSServer $datavar.DNSServer -Domainname $datagen.Domainname

  write-log -message "Generating AD Content" -sev "CHAPTER"

  PSR-Generate-DomainContent -SysprepPassword $datagen.SysprepPassword -IP $datagen.DC1IP -Domainname $datagen.Domainname -debug $datavar.debug -sename $datagen.sename

  write-log -message "Creating Second DC VM" -sev "CHAPTER"

  $VM2 = CMDPSR-Create-VM -mode "FixedIP" -DisksContainerName $datagen.DiskContainerName -Subnetmask $datavar.InfraSubnetmask -Sysprepfile $ServerSysprepfile -Networkname $datagen.Nw1Name -VMname $datagen.DC2Name -ImageName $datagen.DC_ImageName -cpu 4 -ram 8192 -VMip $datagen.DC2IP -VMgw $datavar.InfraGateway -DNSServer1 $datagen.DC1IP -DNSServer2 $datagen.DC2IP -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass
    
  write-log -message "Join Second DC" -sev "CHAPTER"
    
  PSR-Add-DomainController -debug $datavar.debug -IP $datagen.DC2IP -SysprepPassword $datagen.SysprepPassword -DNSServer $datavar.DNSServer -Domainname $datagen.Domainname

}