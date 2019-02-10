Function SSH-Manage-SoftwarePE {
  Param (
    [string] $ClusterPE_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $PCversion,
    [string] $FilesVersion, 
    [string] $Model,
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $Filesdownloadcount = 0 
  $pcdownloadcount = 0 
  $pcstatuscheck = 0
  $AFSStatuscheck = 0 

  write-log -message "Building Credential for SSH session";

  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  $credential = New-Object System.Management.Automation.PSCredential ($clusername, $Securepass);

  do {;
    $pcdownloadcount++
    $pcstatuscheck = 0
    try {;
      $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
      write-log -message "Downloading the latest PC, Telling AOS to do their own work.";
      $PossiblePCVersions = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=PRISM_CENTRAL_DEPLOY" -EnsureConnection
      $PCDownloadStatus = (Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=PRISM_CENTRAL_DEPLOY name='$($truePCversion)'" -EnsureConnection).output
      $object = ($PossiblePCVersions.Output | ConvertFrom-Csv -Delimiter : )
      if ($PCversion -ne "Latest"){

        write-log -message "Checking if requested version is possible."

        $MatchingVersion = $object.'Prism Central Deploy' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | where {$_ -eq $PCversion}
        if ($matchingversion){

          write-log -message "Requested version found $truePCversion"

          $truePCversion = $MatchingVersion
        } else {;
  
          write-log -message "Version $PCversion not found as available within this AOS Version. Using latest."

          $PCversion = "Latest";
        };
      };
      if ($PCversion -eq "Latest"){
        $truePCversion = $object.'Prism Central Deploy' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | select -last 1

        write-log -message "We are using $truePCversion"

      } 
      write-log -message "Starting the download of Prism Central $truePCversion"

      $PCDownload = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software download software-type='PRISM_CENTRAL_DEPLOY' name='$($truePCversion)'" -EnsureConnection
      if ($debug -ge 2){
        $PCDownload
      }
      do {
        $pcstatuscheck++
        $PCDownloadStatus = (Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=PRISM_CENTRAL_DEPLOY name='$($truePCversion)'" -EnsureConnection).output
        sleep 90
        if ($debug -ge 2){
          $PCDownloadStatus
        }
        write-log -message "Still downloading Prism Central." 
      } until ($pcstatuscheck -ge 40 -or $PCDownloadStatus -match "completed")
      if ($pcstatuscheck -ge 40){

        write-log -message "AOS Could not download PC in time" -sev "ERROR"

      } 
      if ($PCDownloadStatus -match "Completed"){
        $PCDownloadCompleted = $true
      }
    } catch {;
      $PCDownloadCompleted = $false

      write-log -message "Error Downloading / Uploading PC, Retry" -sev "WARN";

      sleep 2
    };
  } until (($PCDownloadCompleted -eq $true) -or $pcdownloadcount -ge 5)

  write-log -message "Prism Central Downloads Completed";
  write-log -message "Downloading the latest Files, Auto Versioning";

  do {;
    $Filesdownloadcount++
    $AFSStatuscheck = 0
    try {;
      $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
      $PossibleFilesVersions = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=FILE_SERVER" -EnsureConnection
      if ($PossibleFilesVersions -notmatch "\[None\]"){
        $object = ($PossibleFilesVersions.Output | ConvertFrom-Csv -Delimiter : )
        if ($FilesVersion -ne "Latest"){
  
          write-log -message "Requested version found $FilesVersion"
          write-log -message "Checking if requested version is possible."
  
          $MatchingVersion = $object.'Prism Central Deploy' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | where {$_ -eq $FilesVersion}
          if ($matchingversion){
            $trueFilesVersion = $matchingversion
          } else {;
            $FilesVersion = "Latest";
  
            write-log -message "Version $FilesVersion not found as available within this AOS Version. Using latest." 
  
          };
        };
        if ($FilesVersion -eq "Latest"){
          $trueFilesVersion = $object.'Acropolis File Services' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | select -last 1
          write-log -message "We are using Version $trueFilesVersion for Files"
        
        }
        write-log -message "Starting the download of Files $trueFilesVersion"
        $AFSDownload = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software download software-type='FILE_SERVER' name='$($trueFilesVersion)'" -EnsureConnection
        if ($debug -ge 2){
          $AFSDownload
        }
        do {
          $AFSStatuscheck++
          $AFSDownloadStatus = (Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=FILE_SERVER name='$($trueFilesVersion)'" -EnsureConnection).output
          sleep 60
          if ($debug -ge 2){
            $AFSDownloadStatus
          }

          write-log -message "Still downloading Files."

        } until ($AFSStatuscheck -ge 30 -or $AFSDownloadStatus -match "completed")
      } else {

        write-log -message "There are no Files downloads available"

        $NCCDownloadStatus = "Completed"        
      }
      if ($AFSDownloadCompleted -ge 30){

        write-log -message "AOS Could not download Files in time" -sev "ERROR"

      }
      if ($AFSDownloadStatus -match "Completed"){
        $AFSDownloadCompleted = $true
      }
    } catch {;
      $AFSDownloadCompleted = $false

      write-log -message "Error Downloading / Uploading Files, Retry" -sev "WARN";
      
      sleep 2
    };
  } until (($AFSDownloadCompleted -eq $true) -or $Filesdownloadcount -ge 5) 

  write-log -message "Files Downloads Completed";
  write-log -message "Downloading the latest NCC, Auto Versioning";

  do {;
    $NCCdownloadcount++
    $NCCStatusCheck = 0
    try {;
      $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
      $PossibleNCCVersions = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=NCC" -EnsureConnection
      if ($PossibleNCCVersions.output -notmatch "\[None\]"){
        $object = ($PossibleNCCVersions.Output | ConvertFrom-Csv -Delimiter : )
        $trueNCCVersion = $object.'NCC' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | select -last 1

        write-log -message "We found Version $trueNCCVersion available for download"
        write-log -message "Starting the download of NCC Version $trueNCCVersion"

        $NCCDownload = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software download software-type='NCC' name='$($trueNCCVersion)'" -EnsureConnection
        if ($debug -ge 2){
          $NCCDownload
        }
        do {
          $NCCStatusCheck++
          $NCCDownloadStatus = (Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=NCC name='$($trueNCCVersion)'" -EnsureConnection).output
          sleep 60
          if ($debug -ge 2){
            $NCCDownloadStatus
          }

          write-log -message "Still downloading NCC, which is weird."

        } until ($NCCStatusCheck -ge 10 -or $NCCDownloadStatus -match "completed")
      } else {

        write-log -message "There are no NCC downloads available"

        $NCCDownloadStatus = "Completed"
      }
      if ($NCCStatusCheck -ge 10){

        write-log -message "NCC Could not be downloaded in time"

      }

      if ($NCCDownloadStatus -match "Completed"){
        $NCCDownloadCompleted = $true
      }
    } catch {;
      $NCCDownloadCompleted = $false

      write-log -message "Error Downloading / Uploading NCC, Retry" -sev "WARN";
      
      sleep 2
    };
  } until (($NCCDownloadCompleted -eq $true) -or $NCCdownloadcount -ge 5)  

  write-log -message "NCC Downloads Completed";
  write-log -message "Checking AOS Downloads";

  do {;
    $NOSdownloadcount++
    $NOSStatusCheck = 0
    try {;
      $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
      $PossibleNOSVersions = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=NOS" -EnsureConnection
      if ($PossibleNOSVersions.output -notmatch "\[None\]"){
        $object = ($PossibleNOSVersions.Output | ConvertFrom-Csv -Delimiter : )
        $trueNOSVersion = $object.'NOS' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | select -last 1

        write-log -message "We found Version $trueNOSVersion available for download"
        write-log -message "Starting the download of NOS Version $trueNOSVersion"

        $NOSDownload = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software download software-type='NOS' name='$($trueNOSVersion)'" -EnsureConnection
        if ($debug -ge 2){
          $NCCDownload
        }
        do {
          $NOSStatusCheck++
          $NOSDownloadStatus = (Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=NOS name='$($trueNOSVersion)'" -EnsureConnection).output
          sleep 60
          if ($debug -ge 2){
            $NOSDownloadStatus
          }

           write-log -message "Still downloading AOS Updates." 

        } until ($NOSStatusCheck -ge 20 -or $NOSDownloadStatus -match "completed")
      } else {

        write-log -message "There are no NOS downloads available"

        $NOSDownloadStatus = "Completed"
      }
      if ($NOSStatusCheck -ge 20){

        write-log -message "NOS Could not be downloaded in time" 

      }
      if ($NOSDownloadStatus -match "Completed"){
        $NOSDownloadCompleted = $true
      }
    } catch {;
      $NOSDownloadCompleted = $false

      write-log -message "Error Downloading / Uploading NOS" 
      
      sleep 2
    };
  } until (($NOSDownloadCompleted -eq $true) -or $NOSdownloadcount -ge 5)
 
  write-log -message "AOS Downloads Completed";  
  write-log -message "Checking HyperVisor Downloads";

  do {;
    $HVdownloadcount++
    $HVStatusCheck = 0
    try {;
      $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
      $PossibleHVVersions = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=HYPERVISOR" -EnsureConnection
      if ($PossibleHVVersions.output -notmatch "\[None\]"){
        $object = ($PossibleHVVersions.Output | ConvertFrom-Csv -Delimiter : )
        $trueHVVersion = $object.'NOS' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | select -last 1

        write-log -message "We found Version $trueHVVersion available for download"
        write-log -message "Starting the download of HyperVisor Version $trueHVVersion"

        $HVDownload = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software download software-type='HYPERVISOR' name='$($trueHVVersion)'" -EnsureConnection
        if ($debug -ge 2){
          $HVDownload
        }
        do {
          $HVStatusCheck++
          $HVDownloadStatus = (Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=HYPERVISOR name='$($trueHVVersion)'" -EnsureConnection).output
          sleep 60
          if ($debug -ge 2){
            $HVDownloadStatus
          }

          write-log -message "Still downloading new HyperVisor updates."

        } until ($HVStatusCheck -ge 10 -or $HVDownloadStatus -match "completed")
      } else {

        write-log -message "There are no HyperVisor downloads available"

        $HVDownloadStatus = "Completed"
      }
      if ($HVStatusCheck -ge 20){

        write-log -message "The HyperVisor update Could not be downloaded in time" 

      }
      if ($HVDownloadStatus -match "Completed"){
        $HVDownloadCompleted = $true
      }
    } catch {;
      $HVDownloadCompleted = $false

      write-log -message "Error Downloading / Uploading the hypervisor" 
      
      sleep 2
    };
  } until (($HVDownloadCompleted -eq $true) -or $HVdownloadcount -ge 5)

  write-log -message "HyperVisor Downloads Completed";
  write-log -message "Checking Firware Downloads";

  do {;
    $HVdownloadcount++
    try {;
      $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
      $PossibleFWVersions = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=FIRMWARE_DISK" -EnsureConnection
      if ($PossibleFWVersions.output -notmatch "\[None\]"){
        $object = ($PossibleFWVersions.Output | ConvertFrom-Csv -Delimiter : )
        $trueHVVersion = $object.'NOS' | where {$_ -match "[0-9]" -and $_ -notmatch "bytes|in-progress"} | sort { [version]$_} | select -last 1

        write-log -message "We found Version $trueFWVersion available for download"
        write-log -message "Starting the download of Diskfirmware Version $trueFWVersion"

        $FWDownload = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software download software-type='FIRMWARE_DISK' name='$($trueFWVersion)'" -EnsureConnection
        if ($debug -ge 2){
          $FWDownload
        }
        do {
          $FWStatusCheck++
          $FWDownloadStatus = (Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software list software-type=FIRMWARE_DISK name='$($trueFWVersion)'" -EnsureConnection).output
          sleep 60
          if ($debug -ge 2){
            $FWownloadStatus
          }

          write-log -message "Still firmware updates."

        } until ($FWStatusCheck -ge 20 -or $FWDownloadStatus -match "completed")
      } else {

        write-log -message "There are no Firmware downloads available"

        $FWDownloadStatus = "Completed"
      }
      if ($FWStatusCheck -ge 20){

        write-log -message "The Firmware update Could not be downloaded in time" 

      }
      if ($FWDownloadStatus -match "Completed"){
        $FWDownloadCompleted = $true
      }
    } catch {;
      $FWDownloadCompleted = $false

      write-log -message "Error Downloading / Uploading the Firmware updates" 
      
      sleep 2
    };
  } until (($FWDownloadCompleted -eq $true) -or $FWdownloadcount -ge 5)

  write-log -message "Enabling Autodownload"

  try {;
    $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
    $Autodownloadresult = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software automatic-download enable=1" -EnsureConnection

    write-log -message "Auto Download Enabled"

  } catch {
    $session = New-SSHSession -ComputerName $ClusterPE_IP -Credential $credential -AcceptKey;
    $Autodownloadresult = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli software automatic-download enable=1" -EnsureConnection

    write-log -message "Auto Download Enabled"
    
  }
  if ($debug -ge 2){
    $Autodownloadresult
  }

  if ($AFSDownloadCompleted -eq $true -and $PCDownloadCompleted -eq $true -and $NCCDownloadCompleted -eq $true -and $NOSDownloadCompleted -eq $true -and $HVDownloadCompleted -eq $true -and $FWDownloadCompleted -eq $true){
    $status = "Success"

    write-log -message "All Downloads completed successfully"

  } else {
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
    PCVersion = $truePCversion
    FilesVersion = $trueFilesVersion
  }
  Try {

    write-log -message "Executing session cleanup"

    Remove-SSHSession -SSHSession $session
  } catch {}
  return $resultobject
};
Export-ModuleMember *