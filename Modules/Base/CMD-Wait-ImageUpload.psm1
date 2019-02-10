Function CMD-Wait-ImageUpload {
  param (
    [string] $imagename,
    [string] $PEClusterIP,
    [string] $clusername,
    [string] $clpassword,
    [string] $debug
  )
  $count1 = 0;
  $count2 = 0;
  $count3 = 0;
  write-log -message "Connecting to PS CMD on Prism Element";
  do{;
    $count3++
    try {;
      $hide = LIB-Connect-PSnutanix -ClusterName $PEClusterIP -NutanixClusterUsername $clusername -NutanixClusterPassword $clpassword;
  
      $count++
      $cluster = Get-NTNXCluster;
      if ($cluster){;
  
        write-log -message "Checking if Images is uploaded";
  
      };
    } catch {;
  
      write-log -message "Not connected." -sev "WARN";
  
    };
    $count=0
    do{;
      $image = (get-ntnximage | where {$_.name -match $imagename});
      $hide = LIB-Connect-PSnutanix -ClusterName $PEClusterIP -NutanixClusterUsername $clusername -NutanixClusterPassword $clpassword;
      $count++
      if ($image){
        if ($image.imageState -eq "ACTIVE"){
          
          write-log -message "$imagename Image is present";
        } else {
          sleep 120
        }
      } else {
        
        write-log -message "Image is not present, waiting 2 minutes for 2000 loops, Max 2.7 days";
  
        sleep 120
      }
    } until ($image.imageState -eq "ACTIVE" -or $count -ge 2000)
    if ($count -ge 2000){
  
      write-log -message "Image not present" -sev "ERROR";
  
      $result = "Failed"
  
    } else {
  
      write-log -message "All Images present, ready to roll"
  
      $result = "Success"   
    }
  } until ($result -eq "Success" -or $count3 -ge 5)  
  $resultobject =@{
    Result = $result
  };
  return $resultobject
};
Export-ModuleMember *