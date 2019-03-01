Function SSH-Unlock-XPlay {
  Param (
    [string] $PCClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $filename,   
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli

  $count = 0 
  write-log -message "Building Credential for SSH session";
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  $credential = New-Object System.Management.Automation.PSCredential ($clusername, $Securepass);
  $session = New-SSHSession -ComputerName $PCClusterIP -Credential $credential -AcceptKey;
  
  write-log -message "Building session";

  do {;
    $count++
    try {;
      $session = New-SSHSession -ComputerName $PCClusterIP -Credential $credential -AcceptKey
      
      write-log -message "Uploading the file $filename"
      write-log -message "To Its destination /home/nutanix/tmp/"

      $upload = Set-SCPFile -LocalFile $filename -RemotePath "/home/nutanix/tmp/" -ComputerName $PCClusterIP -Credential $credential -AcceptKey $true

      write-log -message "Executing Unlock";

      sleep 10

      $Unlock = Invoke-SSHCommand -SSHSession $session -command "/usr/bin/python2.7 /home/nutanix/tmp/unlockxplay_py.py" -EnsureConnection
      $completed = 1
      $Unlock.ExitStatus

    } catch {

      write-log -message "Failure during upload or unlock";

    }

  } until (($completed -eq 1 -and $Unlock.ExitStatus -eq 0 ) -or $count -ge 6)
 
  if ($completed -eq 1 -and $Unlock.ExitStatus -eq 0){

    write-log -message "One small step for man, one giant leap for mankind.";

    $status = "Success"
  } else {
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
    Output = $result.output
  }
  Try {
    write-log -message "Executing session cleanup"
    $clean = Remove-SSHSession -SSHSession $session
  } catch {}
  return $resultobject
};
Export-ModuleMember *