Function CMD-Upload-ISOImages {
  param (
   $ISOurlData,
   [string] $PEClusterIP,
   [string] $peadmin,
   [string] $ContainerName,
   [string] $pepass,
   [string] $DCImage,
   [string] $debug
  )

  $count5 = 0

  $nametemp = ($ISOurlData | gm | where {$_.membertype -eq "noteproperty"}).name
  Foreach ($item in $nametemp){
    if ($item -ne $dcimage){
      [array]$names += $item
    }
  }
  
  write-log -message "We have $($names.count) images to process";

  do {
    $count1 = 0
    $count2 = 0
    $count3 = 0
    $count4 = 0
    $count5++
    $ip = $null
    write-log -message "Connecting to PS CMD on Prism Element";
  
    try {;
      $hide = LIB-Connect-PSnutanix -ClusterName $PEClusterIP -NutanixClusterUsername $PEAdmin -NutanixClusterPassword $PEPass;
    
      $count++
      $cluster = Get-NTNXCluster;
      if ($cluster){;
    
        write-log -message "Uploading images";
    
      };
    } catch {;
    
      write-log -message "Not connected." -sev "WARN";
    
    };

    $countrunning = (GET-NTNXTASK | where {$_.operationtype -match "ImageCreate" -and $_.progressstatus -match "running|queued"}).count
    $countfailed  = (GET-NTNXTASK | where {$_.operationtype -match "ImageCreate" -and $_.progressstatus -match "failed"}).count
    if ($countrunning -le 3 -or $countfailed -ge 1){

      write-log -message "Pushing DC image first"
      $name = $dcimage
      $image = $null
      $image = (get-ntnximage | where {$_.name -match $name} -ea:0);
      if (!$image){
        write-log -message "Working on $name"
        $container = Get-NTNXContainer | where {$_.name -match $Containername};
        $importspec = New-NTNXObject -Name ImageImportSpecDTO;
        $importspec.url = $ISOurlData.$($name)
        $importspec.containerUuid = $container.containerUuid;
        $importspec.containername = $container.name;
        try {
          if ($name -match "ISO"){
            $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "iso_image" -ImageImportSpec $importspec;
          } else {
            $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "disk_image" -ImageImportSpec $importspec;
          }
            
          write-log -message "Container is $($container.containerUuid)"
          write-log -message "URL is $($ISOurlData.$($name))"
          write-log -message "Task is running :"

        } catch {
  
          write-log -message "Container is $($container.containerUuid)"
          write-log -message "URL is $($ISOurlData.$($name))"
          write-log -message "Error Uploading" -sev "WARN"
  
          if ($name -match "ISO"){
            $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "iso_image" -ImageImportSpec $importspec;
          } else {
            $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "disk_image" -ImageImportSpec $importspec;
          }
        };
      };
      do{

        write-log -message "Uploading $name first as we need $dcimage for AD etc."
        write-log -message "Looping 2 minutes, cycle $count out of 2000"

        $count ++
        $image = (get-ntnximage | where {$_.name -eq $name} -ea:0);
        sleep 115
        $hide = LIB-Connect-PSnutanix -ClusterName $PEClusterIP -NutanixClusterUsername $PEAdmin -NutanixClusterPassword $PEPass;  
      } until ($image -or $count -ge 2000)
      foreach ($name in $names){
        write-log -message "Start Processing"
        $image = $null
        $image = (get-ntnximage | where {$_.name -match $name} -ea:0);
        if (!$image){
          write-log -message "Working on $name"
          $container = Get-NTNXContainer | where {$_.name -match $Containername};
          $importspec = New-NTNXObject -Name ImageImportSpecDTO;
          $importspec.url = $ISOurlData.$($name)
          $importspec.containerUuid = $container.containerUuid;
          $importspec.containername = $container.name;
          try {
            if ($name -match "ISO"){
              $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "iso_image" -ImageImportSpec $importspec;
            } else {
              $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "disk_image" -ImageImportSpec $importspec;
            }
  
            
            write-log -message "Container is $($container.containerUuid)"
            write-log -message "URL is $($ISOurlData.$($name))"
            write-log -message "Task is running :"

          } catch {
  
            write-log -message "Container is $($container.containerUuid)"
            write-log -message "URL is $($ISOurlData.$($name))"
            write-log -message "Error Uploading" -sev "WARN"
  
            if ($name -match "ISO"){
              $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "iso_image" -ImageImportSpec $importspec;
            } else {
              $task = New-NTNXImage -name "$name" -Annotation "$name" -ImageType "disk_image" -ImageImportSpec $importspec;
            }
          };
        };
      };
    } else {;

      write-log -message "Image Upload is already running.";

      $result = "Success"
    };
  } until ($result -eq "Success" -or $count5 -eq 5)
  $resultobject =@{
    Result = $result
  };
  return $resultobject
};
Export-ModuleMember *