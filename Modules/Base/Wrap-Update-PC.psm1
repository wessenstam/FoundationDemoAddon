Function Wrap-Update-PC {
  param (
    [object] $datavar,
    [object] $datagen

  ) 
  write-log -message "Waiting for Inventory."
  do {
    try{
      $counter ++
      write-log -message "Cycle $counter out of 25(minutes)."
  
      $PEtasks = REST-Task-List -ClusterPC_IP $datavar.PEClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
      $updates = $PEtasks.entities | where { $_.operation_type -match "kLcmInventoryTask"}
      $Inventorycount = 0
      [array]$Results = $null
      foreach ($item in $updates){
        if ( $item.percentage_complete -eq 100) {
          $Results += "Done"

          write-log -message "Inventory $($item.uuid) is completed."
        } elseif ($item.percentage_complete -ne 100){
          $Inventorycount ++
  
          write-log -message "Inventory $($item.uuid) is still running."
  
          $Results += "BUSY"
  
        }
      }
      if ($Results -notcontains "BUSY"){
        write-log -message "Inventory is done."

        $Inventorycheck = "Success"

      } else{
        sleep 60
      }
  
    }catch{
      write-log -message "Error caught in loop."
    }
  } until ($Inventorycheck -eq "Success" -or $counter -ge 25)

  $status = RPA-LCM-Inventory -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $datagen.PCClusterIP -debug $datavar.debug -mode "Stage2"
  if ($status.result -ne "Success"){
    $status = RPA-LCM-Inventory -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $datagen.PCClusterIP -debug $datavar.debug -mode "Stage2"
  }
  $counter = 0
  if ($status.result -ne "Success"){

    write-log -message "Running Full LCM Prism Central Updates (RPA), it needs help"

    REST-LCM-Perform-Inventory -datavar $datavar -datagen $datagen -mode "PC"
    sleep 60

    do {
      try{
        $counter ++
        write-log -message "Cycle $counter out of 25(minutes)."
  
        $PEtasks = REST-Task-List -ClusterPC_IP $datavar.PEClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
        $updates = $PEtasks.entities | where { $_.operation_type -match "kLcmInventoryTask"}
        $Inventorycount = 0
        [array]$Results = $null
        foreach ($item in $updates){
          if ( $item.percentage_complete -eq 100) {
            $Results += "Done"
  
            write-log -message "Inventory $($item.uuid) is completed."
          } elseif ($item.percentage_complete -ne 100){
            $Inventorycount ++
  
            write-log -message "Inventory $($item.uuid) is still running."
  
            $Results += "BUSY"
  
          }
        }
        if ($Results -notcontains "BUSY"){
          $Inventorycheck = "Success"

          write-log -message "Inventory is done."
        } else{
          sleep 60
        }
  
      }catch{
        write-log -message "Error caught in loop."
      }
    } until ($Inventorycheck -eq "Success" -or $counter -ge 25)

    $status = RPA-LCM-Inventory -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $datagen.PCClusterIP -debug $datavar.debug -mode "Stage2"
  }
}

Export-ModuleMember *