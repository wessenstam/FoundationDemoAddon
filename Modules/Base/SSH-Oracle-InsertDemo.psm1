Function SSH-Oracle-InsertDemo {
  Param (
    [string] $OracleIP,
    [string] $clpassword,
    [string] $filename1,   
    [string] $filename2,
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli

  $count = 0 
  write-log -message "Building Credential for SSH session";
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  $credential = New-Object System.Management.Automation.PSCredential ('oracle', $Securepass);
  $session = New-SSHSession -ComputerName $OracleIP -Credential $credential -AcceptKey;
  
  write-log -message "Building session";

  do {;
    $count1++
    try {;
      $session = New-SSHSession -ComputerName $OracleIP -Credential $credential -AcceptKey

      write-log -message "Installing dos2unix"

      $Install = Invoke-SSHCommand -SSHSession $session -command "sudo yum install dos2unix -y" -EnsureConnection
      sleep 10
      
      write-log -message "Uploading the file $filename1"
      write-log -message "To Its destination /home/oracle/Downloads/"

      $upload = Set-SCPFile -LocalFile $filename1 -RemotePath "/home/oracle/Downloads/" -ComputerName $OracleIP -Credential $credential -AcceptKey $true

      write-log -message "Setting XBit";

      $chmod = Invoke-SSHCommand -SSHSession $session -command "chmod +x /home/oracle/Downloads/adump.sh" -EnsureConnection

      sleep 10

      write-log -message "Converting";

      $chmod = Invoke-SSHCommand -SSHSession $session -command "dos2unix /home/oracle/Downloads/adump.sh" -EnsureConnection

      sleep 10

      write-log -message "Executing";

      $Execute1 = Invoke-SSHCommand -SSHSession $session -command "nohup bash /home/oracle/Downloads/adump.sh &" -EnsureConnection

      $completedp1 = 1
      $Execute1.ExitStatus

    } catch {

      write-log -message "Failure during upload or execute";

    }

  } until (($completedp1 -eq 1 -and $Execute1.ExitStatus -eq 0 ) -or $count1 -ge 6)

  do {;
    $count2++
    try {;
      $session = New-SSHSession -ComputerName $OracleIP -Credential $credential -AcceptKey
      
      write-log -message "Uploading the file $filename2"
      write-log -message "To Its destination /home/oracle/Downloads/"

      $upload = Set-SCPFile -LocalFile $filename2 -RemotePath "/home/oracle/Downloads/" -ComputerName $OracleIP -Credential $credential -AcceptKey $true

      write-log -message "Setting XBit";

      $chmod = Invoke-SSHCommand -SSHSession $session -command "chmod +x /home/oracle/Downloads/ticker.sh" -EnsureConnection


      sleep 10

      write-log -message "Converting";

      $chmod = Invoke-SSHCommand -SSHSession $session -command "dos2unix /home/oracle/Downloads/ticker.sh" -EnsureConnection

      sleep 10

      write-log -message "Executing";

      $Execute2 = Invoke-SSHCommand -SSHSession $session -command "nohup bash /home/oracle/Downloads/ticker.sh &" -EnsureConnection

      $completedp2 = 1
      $Execute2.ExitStatus

    } catch {

      write-log -message "Failure during upload or execute";

    }

  } until (($completedp2 -eq 1 -and $Execute1.ExitStatus -eq 0 ) -or $count -ge 6)
  if ($completedp1 -eq 1 -and $Execute1.ExitStatus -eq 0 -and $completedp2 -eq 1 -and $Execute2.ExitStatus -eq 0){

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