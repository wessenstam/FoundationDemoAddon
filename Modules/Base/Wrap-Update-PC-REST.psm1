Function Wrap-Update-PC-REST {
  param (
    [object] $datavar,
    [object] $datagen,
    [object] $logfile

  )
  
  write-log -message "Waiting for Inventory."

  Function Wait-Task{
    do {
      try{
        $counter++
        write-log -message "Wait for inventory Cycle $counter out of 25(minutes)."
    
        $PCtasks = REST-Task-List -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
        $LCMTasks = $PCtasks.entities | where { $_.operation_type -match "kLcmRootTask"}
        $Inventorycount = 0
        [array]$Results = $null
        foreach ($item in $LCMTasks){
          if ( $item.percentage_complete -eq 100) {
            $Results += "Done"
     
            write-log -message "Inventory $($item.uuid) is completed."
          } elseif ($item.percentage_complete -ne 100){
            $Inventorycount ++
    
            write-log -message "Inventory $($item.uuid) is still running."
            write-log -message "We found 1 task $($item.status) and is $($item.percentage_complete) % complete"
    
            $Results += "BUSY"
    
          }
        }
        if ($Results -notcontains "BUSY" -or !$LCMTasks){

          write-log -message "Inventory is done."
     
          $Inventorycheck = "Success"
     
        } else{
          sleep 60
        }
    
      }catch{
        write-log -message "Error caught in loop."
      }
    } until ($Inventorycheck -eq "Success" -or $counter -ge 10)
  }

  do {
    $counter2++
    
    write-log -message "Checking Results"
    sleep 60
    $result = REST-LCM-Query-Groups -datagen $datagen -datavar $datavar -mode "PC"
  
    if ($result.total_entity_count -lt 1){ 
  
      write-log -message "There are no updates, retry $counter2 out of 16"
      
      Wait-Task
      sleep 110
      $result = REST-LCM-Query-Groups -datagen $datagen -datavar $datavar -mode "PC"
    }
    if ($counter2 -eq 5 -or $counter2 -eq 12){

      write-log -message "Running LCM Inventory Again"

      REST-LCM-Perform-Inventory -datavar $datavar -datagen $datagen -mode "PC"
      sleep 115
    }
  } until ($result.total_entity_count -ge 1 -or $counter2 -ge 16)

  $UUIDs = ($result.group_results.entity_results.data |where {$_.name -eq "entity_uuid"}).values.values | sort -unique

  write-log -message "We have $($uuids.count) applications to be updated, seeking version"

  foreach ($app in $UUIDs){
    $Entity = [PSCustomObject]@{
      UUID        = $app
      Version     = (($result.group_results.entity_results | where {$_.data.values.values -eq $app}).data | where {$_.name -eq "version"}).values.values | select -last 1
    }
    [array]$Updates += $entity     
  }
  write-log -message "Building a LCM update Plan"

  REST-LCM-BuildPlan -datavar $datavar -datagen $datagen -mode "PC" -updates $Updates

  write-log -message "Installing Updates"

  REST-LCM-Install -datavar $datavar -datagen $datagen -mode "PC" -updates $Updates
  $exit = 0
  $installcounter = 0
  $installMasterCounter = 0
  $waitforinstallloops = 20
  sleep 90
  do{
    $installMasterCounter++
    try {
      $installcounter = 0
      do {

        write-log -message "Waiting / Checking Install Status"

        $installcounter++
        $tasks = REST-Task-List -ClusterPC_IP $datagen.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin 
        $installtask = $tasks.entities | where {$_.operation_type -eq "kLcmUpdateOperation"} | select -last 1
        if ($installtask){

          write-log -message "We found 1 task $($installtask.status) and is $($installtask.percentage_complete) % complete"

        }
        Sleep 60
      } until ($installtask.percentage_complete -eq "100" -or $installcounter -ge $waitforinstallloops)
      if ($installcounter -eq $waitforinstallloops){

        write-log -message "This is taking too long."
        write-log -message "There is more work to do."

        $exit =1 
      } elseif ($installtask.status -match "FAILED|ABORTED"){
        
        write-log -message "Calm Update failed with $($installtask.progress_message), restarting."
        
        write-log -message "Prism Central needs help, rebooting"

        LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $data -datavar $datavar -mode "CalmFailed" -debug $datavar.debug -logfile $logfile

        $hide = LIB-Connect-PSNutanix -ClusterName $datavar.PEClusterIP -NutanixClusterUsername $datavar.PEAdmin -NutanixClusterPassword $datavar.PEPass

        $hide = get-ntnxvm | where {$_.vmname -match "^PC"} | Set-NTNXVMPowerState -transition "ACPI_REBOOT" -ea:0
        sleep 110
        REST-LCM-Perform-Inventory -datavar $datavar -datagen $datagen -mode "PC"
        sleep 115
        write-log -message "Keep Calm"
        sleep 115
        write-log -message "Keep Calm"
        sleep 115
        $result = REST-LCM-Query-Groups -datagen $datagen -datavar $datavar -mode "PC"
        $UUIDs = ($result.group_results.entity_results.data |where {$_.name -eq "entity_uuid"}).values.values | sort -unique
        foreach ($app in $UUIDs){
          $Entity = [PSCustomObject]@{
            UUID        = $app
            Version     = (($result.group_results.entity_results | where {$_.data.values.values -eq $app}).data | where {$_.name -eq "version"}).values.values | select -last 1
          }
          [array]$Updates += $entity     
        }
        REST-LCM-BuildPlan -datavar $datavar -datagen $datagen -mode "PC" -updates $Updates
        sleep 40
        REST-LCM-Install -datavar $datavar -datagen $datagen -mode "PC" -updates $Updates
        sleep 60

      } elseif ($installtask.status -eq "SUCCEEDED"){

        write-log -message "Calm update Complete."
        LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $datagen -datavar $datavar -mode "CalmSuccess" -debug $datavar.debug -logfile $logfile

        $exit =1 
      } else {

        write-log -message "I am not supposed to be here."

      }
    } catch {

      write-log -message "Error caught in loop." -sev "WARN"

    }
  } until ($exit -eq 1 -or $installMasterCounter -ge 3)
  return $updates
}

