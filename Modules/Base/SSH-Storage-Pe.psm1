Function SSH-Storage-Pe {
  Param (
    [string] $PEClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $StoragePoolName,
    [string] $ImagesContainerName,
    [string] $DisksContainerName,
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $count = 0 
  write-log -message "Building Credential for SSH session";

  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  $credential = New-Object System.Management.Automation.PSCredential ($clusername, $Securepass);
  $session = New-SSHSession -ComputerName $PEClusterIP -Credential $credential -AcceptKey;

  write-log -message "Setting up Storage for for $PEClusterIP";

  do {;
    $count++
    try {;
      $session = New-SSHSession -ComputerName $PEClusterIP -Credential $credential -AcceptKey;
      
      write-log -message "Checking Storage Pools";
      
      $Existing = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli storagepool ls" -EnsureConnection
      $Currentname = $(($Existing.Output[3] -split (": "))[1]) 
      if ($Currentname -eq $StoragePoolName){

        write-log -message "All Done here";

        $sprename = $true

      } else {

        write-log -message "Storage pool is not renamed yet doing the needful";
        write-log -message "Current name is $Currentname";
        write-log -message "New Name will be $StoragePoolName";
        write-log -message "Executing Name Change for the storage pool.";

        $Rename = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli storagepool edit name=$($Currentname) new-name=$($StoragePoolName)" -EnsureConnection

      }

      write-log -message "Checking Disk Container";
      
      $Existing = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli container ls" -EnsureConnection
      $object = $Existing.Output | ConvertFrom-Csv -Delimiter ":" -Header Name,Value,Something
      $default = ($object | where {$_.name -match "Name"}).value | where {$_ -match "default-container"} | select -first 1
      $Newexisting = ($object | where {$_.name -match "Name"}).value | where {$_ -eq $DisksContainerName} | select -first 1

      if ($Newexisting -eq $DisksContainerName){

        write-log -message "All Done here";

        $SCont1 = $true

      } elseif ($default){

        write-log -message "Disk container is not renamed yet doing the needful";
        write-log -message "Current name is $default";
        write-log -message "New Name will be $DisksContainerName";
        write-log -message "Executing Name Change";

        $Rename = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli container edit name=$($default) new-name=$($DisksContainerName)"  -EnsureConnection

      } elseif (!$Newexisting){

        write-log -message "Container for Disks does not exist yet.";
        write-log -message "New Name will be $DisksContainerName";
        write-log -message "Creating the container";

        $Create = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli container create name=$($DisksContainerName) sp-name=$($StoragePoolName)"  -EnsureConnection
      } else {
        
        write-log -message "Why am i here" -sev "Error";

      }

      write-log -message "Checking Image Container";
      
      $Existing = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli container ls" -EnsureConnection
      $object = $Existing.Output | ConvertFrom-Csv -Delimiter ":" -Header Name,Value,Something
      $Currentname = ($object | where {$_.name -match "Name"}).value | where {$_ -eq $ImagesContainerName} | select -first 1

      if ($Currentname -eq $ImagesContainerName){

        write-log -message "All Done here";

        $SCont2 = $true

      } elseif (!$Currentname){

        write-log -message "Storage container for images does not exist yet.";
        write-log -message "New Name will be $ImagesContainerName";
        write-log -message "Creating the container";

        $Create = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli container create name=$($ImagesContainerName) sp-name=$($StoragePoolName)"  -EnsureConnection
   

      } else {

        write-log -message "We should not be here" -sev "error"

      }
      
    } catch {;
      $nw1completed = $false

      write-log -message "Error Creating networks, Retry" -sev "WARN";

      sleep 2
    }
  } until (($SCont1 -eq $true -and $SCont2 -and $sprename -eq $true) -or $count -ge 6)

 
  if ($nw1completed -eq $true){
    $status = "Success"

  } else {
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
  }
  Try {
    write-log -message "Executing session cleanup"
    $clean = Remove-SSHSession -SSHSession $session
  } catch {}
  return $resultobject
};
Export-ModuleMember *