
function Wrap-Install-PC {
  param(
    $datafixed,
    $datavar,
    $stage,
    $logfile
  )
  $data = $datafixed

  $counter =0
  if ( $stage -ne 1){
    write-log -message "Stage 2, checking prism Central Install status."
    write-log -message "AOS $($datavar.AOSVersion) PC $($datavar.PSVersion)"
    write-log -message "We have to wait for PC Installer now"
    do {
      try{
        $counter ++
        write-log -message "Cycle $counter out of 25(minutes)."
  
        $PEtasks = REST-Task-List -ClusterPC_IP $datavar.PEClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
        $DeployTasks = $PEtasks.entities | where { $_.operation_type -match "Prism Central Deployment"}

        foreach ($item in $DeployTasks){
          if ($item.percentage_complete -eq 100) {
            $Deploycheck = "Success"
  
            write-log -message "PC Deploy task $($item.uuid) is completed."

          } elseif ($item.percentage_complete -ne 100){
  
            write-log -message "PC Deploy is at $($item.percentage_complete) %"
  
            $Deploycheck = "Running"
          }
        }
        if ($Deploycheck -eq "Success"){

          write-log -message "PC should be installed."

        } else{
          sleep 60
        }
      }catch{
        write-log -message "Error caught in loop."
      }
    } until ($Deploycheck -eq "Success" -or $counter -ge 25)

    write-log -message "Reset PC Password" -sev "CHAPTER"

    $status1 = SSH-ResetPass-Px -PxClusterIP $data.PCClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -debug $datavar.debug -mode "PC"
    if ($status1.result -eq "Success"){

      write-log -message "Sleeping 2 minutes for pw reset"

      $count = 0
      do {
        $count++

        write-log -message "Sleeping 30 seconds for $count out of 3"

        sleep 30
      } until ($count -eq 3)

      write-log -message "Prism Central Finalize Login" -sev "CHAPTER"

      REST-Finalize-Px -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPx_IP $data.PCClusterIP -debug $datavar.debug -sename $data.sename -serole $data.serole -SECompany $data.SECompany -EnablePulse $data.EnablePulse
 
      write-log -message "Add Prism Element cluster to Prism Central Cluster" -sev "CHAPTER"

      $status2 = CMD-Add-PEtoPC -PEClusterIP $datavar.PEClusterIP -PCClusterIP $data.PCClusterIP -PEAdmin $datavar.PEAdmin -PEPass $datavar.PEPass -debug $datavar.debug 
      sleep 60

    } else {

      write-log -message "SSH Reset failed, there is no point in proceding.."

    }
 
    if ($status1.result -ne "Success" -or $status2.result -ne "Success"){

      $MasterLoopCounter = 0
      do{
        $MasterLoopCounter++
        try {

          write-log -message "Prism Central needs help, cleaning"
          LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $datafixed -datavar $datavar -mode "PCFailed" -debug $datavar.debug -logfile $logfile
    
          $hide = LIB-Connect-PSNutanix -ClusterName $datavar.PEClusterIP -NutanixClusterUsername $datavar.PEAdmin -NutanixClusterPassword $datavar.PEPass
          $hide = get-ntnxvm | where {$_.vmname -match "^PC"} | Set-NTNXVMPowerOff -ea:0
          $hide = get-ntnxvm | where {$_.vmname -match "^PC"} | Remove-NTNXVirtualMachine -ea:0
          sleep 40
          $status = REST-Install-PC -DisksContainerName $data.DisksContainerName -AOSVersion $datavar.AOSVersion -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPE_IP $datavar.PEClusterIP -PCClusterIP $data.PCClusterIP -InfraSubnetmask $datavar.InfraSubnetmask -InfraGateway $datavar.InfraGateway -DNSServer $datavar.DNSServer -PC1_Name $data.PCNode1Name -PC2_Name $data.PCNode2Name -PC3_Name $data.PCNode3Name -PC1_IP $data.PCNode1IP -PC2_IP $data.PCNode2IP -PC3_IP $data.PCNode3IP -Networkname $data.Nw1Name -PCVersion $($datavar.PCVersion) -PCmode $datavar.PCmode -debug $datavar.debug 
          sleep 119
          write-log -message "Sleeping 30 minutes for install, 8 minutes fixed, the rest dynamic."
          sleep 119
          write-log -message "Prism Central deleted and is reinstalling."
          sleep 119
          write-log -message "We have to wait for PC Installer now"
          sleep 119
          write-log -message "Prism Central installer......"
          sleep 119
          $counter = 0
          $count = 0
          do {
            try{
              $counter ++
              write-log -message "Cycle $counter out of 30(minutes)."
        
              $PEtasks = REST-Task-List -ClusterPC_IP $datavar.PEClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
              $DeployTasks = $PEtasks.entities | where { $_.operation_type -eq "AppDeployment"} | select -last 1
      
              foreach ($item in $DeployTasks){
                if ($item.percentage_complete -eq 100) {
                  $Deploycheck = "Success"
        
                  write-log -message "PC Deploy task $($item.uuid) is completed."
                  write-log -message "PC Deploy task has status $($item.status)."
      
                } elseif ($item.percentage_complete -ne 100){
        
                  write-log -message "PC Deploy is at $($item.percentage_complete) %"
        
                  $Deploycheck = "Running"
                }
              }
              if ($Deploycheck -eq "Success"){
      
                write-log -message "PC is installed."
      
              } else{
                sleep 60
              }
            }catch{
              write-log -message "Error caught in loop."
            }
          } until ($Deploycheck -eq "Success" -or $counter -ge 30)
          
          write-log -message "Running Post installer steps"
    
          $status1 = SSH-ResetPass-Px -PxClusterIP $data.PCClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -debug $datavar.debug -mode "PC"
    
          if ($status1.result -eq "Success" ){
            if ($datavar.pcmode -eq 3){
              write-log -message "Sleeping for PC Scaleout PC Sync"
        
              $count = 0
              do {
                $count++
        
                write-log -message "Sleeping 40 seconds for $count out of 3"
        
                sleep 40
              } until ($count -eq 3)
    
    
            }

            REST-Finalize-Px -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPx_IP $data.PCClusterIP -debug $datavar.debug -sename $data.sename -serole $data.serole -SECompany $data.SECompany -EnablePulse $data.EnablePulse
   
            $status2 = CMD-Add-PEtoPC -PEClusterIP $datavar.PEClusterIP -PCClusterIP $data.PCClusterIP -PEAdmin $datavar.PEAdmin -PEPass $datavar.PEPass -debug $datavar.debug 

            write-log -message "Prism Central Installed, updating"
    
            LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $datafixed -datavar $datavar -mode "PCSuccess" -debug $datavar.debug -logfile $logfile
    
            REST-LCM-Perform-Inventory -datavar $datavar -datagen $data -mode "PC"

            $result = "success"
    
          } else {
    
            $result = "Failed"
    
          }

        } catch {

          write-log -message "I should not be here."

        }
      } until ($result -eq "success" -or $MasterLoopCounter -ge 5)

      

      



    } else {

      $result = "Success"
      LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $datafixed -datavar $datavar -mode "PCSuccess" -debug $datavar.debug -logfile $logfile
      write-log -message "Prism Central Post install completed."
      write-log -message "Running Full LCM Prism Central Inventory (REST)" -sev "CHAPTER"
      REST-LCM-Perform-Inventory -datavar $datavar -datagen $data -mode "PC"
      #$status2 = RPA-LCM-Inventory -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $data.PCClusterIP -debug $datavar.debug -mode "Stage1"

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
