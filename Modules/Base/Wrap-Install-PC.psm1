function Wrap-Install-PC {
  param(
    $datafixed,
    $datavar,
    $stage
  )
  $data = $datafixed
  $hide = LIB-Connect-PSNutanix -ClusterName $datavar.PEClusterIP -NutanixClusterUsername $datavar.PEAdmin -NutanixClusterPassword $datavar.PEPass
  $pcvm = Get-NTNXVM | where {$_.vmname -eq $data.PCNode1Name}
  if ($pcvm -and $stage -ne 1){

    write-log -message "Prism Central is already installed or running."
    write-log -message "Sleeping 6 minutes"

    $count = 0
    do {
      $count++

      write-log -message "Sleeping 2 minutes for $count out of 3"

      sleep 120
    } until ($count -eq 3)

    write-log -message "Reset PC Password" -sev "CHAPTER"

    $status = SSH-ResetPass-Px -PxClusterIP $data.PCClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -debug $datavar.debug -mode "PC"
    if ($status.result -eq "Success"){

      write-log -message "Sleeping 6 minutes for pw reset"

      $count = 0
      do {
        $count++

        write-log -message "Sleeping 2 minutes for $count out of 3"

        sleep 120
      } until ($count -eq 3)

    } else {

      write-log -message "SSH Reset failed, attempting registration regardless."

    }
    write-log -message "Prism Central Finalize Login" -sev "CHAPTER"

    REST-Finalize-Px -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPx_IP $data.PCClusterIP -debug $datavar.debug -sename $data.sename -serole $data.serole -SECompany $data.SECompany -EnablePulse $data.EnablePulse
 
    write-log -message "Add Prism Element cluster to Prism Central Cluster" -sev "CHAPTER"

    $status1 = CMD-Add-PEtoPC -PEClusterIP $datavar.PEClusterIP -PCClusterIP $data.PCClusterIP -PEAdmin $datavar.PEAdmin -PEPass $datavar.PEPass -debug $datavar.debug 
    sleep 60

    write-log -message "Running Full LCM Prism Central Inventory (RPA)" -sev "CHAPTER"

    $status2 = RPA-LCM-Inventory -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $data.PCClusterIP -debug $datavar.debug -mode "Stage1"

    if ($status1.result -ne "Success" ){

      write-log -message "Prism Central needs help, cleaning"

      $hide = LIB-Connect-PSNutanix -ClusterName $datavar.PEClusterIP -NutanixClusterUsername $datavar.PEAdmin -NutanixClusterPassword $datavar.PEPass
      $hide = get-ntnxvm | where {$_.vmname -match "^PC"} | Set-NTNXVMPowerOff -ea:0
      $hide = get-ntnxvm | where {$_.vmname -match "^PC"} | Remove-NTNXVirtualMachine -ea:0
      sleep 25
      $status = REST-Install-PC -DisksContainerName $data.DisksContainerName -AOSVersion $datavar.AOSVersion -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPE_IP $datavar.PEClusterIP -PCClusterIP $data.PCClusterIP -InfraSubnetmask $datavar.InfraSubnetmask -InfraGateway $datavar.InfraGateway -DNSServer $datavar.DNSServer -PC1_Name $data.PCNode1Name -PC2_Name $data.PCNode2Name -PC3_Name $data.PCNode3Name -PC1_IP $data.PCNode1IP -PC2_IP $data.PCNode2IP -PC3_IP $data.PCNode3IP -Networkname $data.Nw1Name -PCVersion $($datavar.PCVersion) -PCmode $datavar.PCmode -debug $datavar.debug 
      
      write-log -message "Sleeping 30 minutes for install"

      $count = 0
      do {
        $count++

        write-log -message "Sleeping 2 minutes for $count out of 15"

        sleep 120
      } until ($count -eq 15)

      write-log -message "Running Post installer steps"

      SSH-ResetPass-Px -PxClusterIP $data.PCClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -debug $datavar.debug -mode "PC"

      write-log -message "Sleeping 6 minutes for pw reset"

      $count = 0
      do {
        $count++

        write-log -message "Sleeping 40 seconds for $count out of 3"

        sleep 40
      } until ($count -eq 3)

      REST-Finalize-Px -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPx_IP $data.PCClusterIP -debug $datavar.debug -sename $data.sename -serole $data.serole -SECompany $data.SECompany -EnablePulse $data.EnablePulse

      $status1 = CMD-Add-PEtoPC -PEClusterIP $datavar.PEClusterIP -PCClusterIP $data.PCClusterIP -PEAdmin $datavar.PEAdmin -PEPass $datavar.PEPass -debug $datavar.debug 

      $status2 = RPA-LCM-Inventory -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $data.PCClusterIP -debug $datavar.debug -mode "Stage1"

      if ($status1.result -ne "Success" ){

        write-log -message "Prism Central Installed"

        $result = "Success"

      } else {

        $result = "Failed"

      }

    } else {

      $result = "Success"

      write-log -message "Prism Central Post install completed."

    }

  } else {

    $status = REST-Install-PC -DisksContainerName $data.DisksContainerName -AOSVersion $datavar.AOSVersion -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPE_IP $datavar.PEClusterIP -PCClusterIP $data.PCClusterIP -InfraSubnetmask $datavar.InfraSubnetmask -InfraGateway $datavar.InfraGateway -DNSServer $datavar.DNSServer -PC1_Name $data.PCNode1Name -PC2_Name $data.PCNode2Name -PC3_Name $data.PCNode3Name -PC1_IP $data.PCNode1IP -PC2_IP $data.PCNode2IP -PC3_IP $data.PCNode3IP -Networkname $data.Nw1Name -PCVersion $($datavar.PCVersion) -PCmode $datavar.PCmode -debug $datavar.debug   

    write-log -message "Prism Central install started."

    $result = "Partial"
  };

  if ($result -match "Success"){
    $status = "Success"

    write-log -message "PC Install Completed";
    write-log -message "Loveing it";

    $result

  } elseif ($result -eq "Partial") {
    
    $status = "Success"

    write-log -message "Ill be back.";

  } else {

    $status = "Failed"

    write-log -message "Danger Will Robbinson." -sev "ERROR";

  }
  $resultobject =@{
    Result = $status
  };
  return $resultobject
}
Export-ModuleMember *
