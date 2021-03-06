Function SSH-ResetPass-Px {
  Param (
    [string] $PxClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $mode = "NORMAL",
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $Resetpasscount = 0 
  $passreset = $false
  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  
  write-log -message "Building Credential for SSH session";
  write-log -message "Mode is $mode";

  if ($mode -eq "PE"){
    $sshusername = "admin" 
    $oldSecurepass = ConvertTo-SecureString "Nutanix/4u" -AsPlainText -Force;
  } elseif ($mode -eq "ERA" ){
    $sshusername = "era" 
    $oldSecurepass = ConvertTo-SecureString "Nutanix.1" -AsPlainText -Force;
  } elseif ($mode -eq "Oracle1" ){
    $sshusername = "oracle" 
    $oldSecurepass = ConvertTo-SecureString "welcome1" -AsPlainText -Force;
  } elseif ($mode -eq "Oracle2" ){
    $sshusername = "root" 
    $oldSecurepass = ConvertTo-SecureString "welcome1" -AsPlainText -Force;
  } elseif ($mode -eq "Oracle3" ){
    $sshusername = "grid" 
    $oldSecurepass = ConvertTo-SecureString "welcome1" -AsPlainText -Force;
  } elseif ($mode -eq "Oracle4" ){
    $sshusername = "kamal" 
    $oldSecurepass = ConvertTo-SecureString "welcome1" -AsPlainText -Force;
  } else {
    $sshusername = "nutanix"
    $oldSecurepass = ConvertTo-SecureString "nutanix/4u" -AsPlainText -Force; 
  }


  do {;
    $Resetpasscount++
    try {;
      try {

        write-log -message "Logging in with Default Creds, username is $sshusername";
        
        $credential = New-Object System.Management.Automation.PSCredential ($sshusername, $oldSecurepass);
        $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey -ea:0;
        $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
      } catch {
        try {

          $credential = New-Object System.Management.Automation.PSCredential ($sshusername, $Securepass);
          $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey -ea:0;
          $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)         
         
          write-log -message "Using specified creds, username is $sshusername";

        } catch {

          write-log -message "Cannot login with any creds" -sev "WARN"

        }
               
      }
      sleep 15

      $shell = $stream.read()

      if ($shell -match "Expired"){

        write-log -message "Prompted to change the SSH pass, changing"

        try{

          write-log -message "Sending Current and new Pass"

          Invoke-SSHStreamExpectSecureAction -ShellStream $stream -ExpectString "New password:" -SecureAction $Securepass -command "Nutanix/4u"

          write-log -message "Sending New Again"

          Invoke-SSHStreamShellCommand -ShellStream $stream -Command $clpassword
          $hide = Get-sshsession | Remove-SSHSession

          write-log -message "Sleeping 1 minute"

          sleep 60

        } catch {

          write-log -message "Error Changing SSH Pass" -sev "ERROR"

        }

      }
      try {

        write-log -message "Checking if SSH Password needs to be changed" 

        $credential = New-Object System.Management.Automation.PSCredential ($sshusername, $Securepass);
        $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey -ea:0
        #line below causes a clean error, the line above does not
        $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
      } catch {

        write-log -message "SSH Password needs to be changed" 

        $credential = New-Object System.Management.Automation.PSCredential ($sshusername, $oldSecurepass);
        $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey -ea:0;  
        $Passresetresult = Invoke-SSHCommand -SSHSession $session -command "echo `"$($clpassword)`" | sudo passwd --stdin $sshusername"
        $hide = Get-sshsession | Remove-SSHSession
        if ($mode -notmatch "Oracle"){

          write-log -message "Sleeping 1 minute"
  
          sleep 60
        }
        $passreset = $true
      }
      
      if ($mode -notmatch "ERA|Oracle"){
        $passreset = $false

        write-log -message "Resetting Prism Portal Password";
  
        try{
          $credential = New-Object System.Management.Automation.PSCredential ($sshusername, $Securepass);
          $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey -ea:0;
          sleep 1
          $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
          $hide = Get-sshsession | Remove-SSHSession
          $session = New-SSHSession -ComputerName $PxClusterIP -Credential $credential -AcceptKey -ea:0;
          sleep 1
          $Passresetresult = Invoke-SSHCommand -SSHSession $session -command "/home/nutanix/prism/cli/ncli user reset-password user-name='$($clusername)' password='$($clpassword)'" -EnsureConnection
          if ($Passresetresult.exitstatus -eq "0"){
  
            write-log -message "Password reset successful."
  
            $passreset = $true
          } elseif  ($Passresetresult.exitstatus -eq "1" -and $Passresetresult.output -match "characters from previous password"){
  
             write-log -message "Password reset already executed."
  
            $passreset = $true       
          } else {
  
            write-log -message "Unknown exit in password change." -sev "WARN"
            write-host $Passresetresult
  
            $passreset = $false
  
          }
        } catch{ 
  
          write-log -message "Cannot connect to Px SSH." -sev "WARN"
  
        }
      } else {
        ## Do some SSH based portal password reset for ERA
      }
    } catch {
      write-log -message "Password reset failure, retry $Resetpasscount out of 3" -sev "WARN"
      $passreset = $false
    }
  } until (($passreset -eq $true) -or $Resetpasscount -ge 3)
  if ($passreset -eq $true){
    $status = "Success"
    write-log -message "Password has been reset"
  } else {
    write-log -message "Password reset failure." -sev "ERROR"
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
  }
  Try {
    write-log -message "Executing session cleanup"
    $hide = Get-sshsession | Remove-SSHSession
  } catch {}
  return $resultobject
};
Export-ModuleMember *