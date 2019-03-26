Function SSH-Startup-Oracle {
  Param (
    [string] $OracleIP,
    [string] $clpassword,
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $count = 0 
  write-log -message "Building Credential for SSH session";

  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  $credential = New-Object System.Management.Automation.PSCredential ('oracle', $Securepass);
  $session = New-SSHSession -ComputerName $OracleIP -Credential $credential -AcceptKey;

  write-log -message "Starting Oracle Databases";

  do {;
    $count++
    try {;
      $session = New-SSHSession -ComputerName $OracleIP -Credential $credential -AcceptKey;
      
      write-log -message "Executing.....";

      $stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
      sleep 10
      $stream.Write("sqlplus / as sysdba`n")
      sleep 20
      $stream.Write("startup;`n")
      sleep 20
      $output = $stream.Read()
      write-log -message "Testing the database started status";
      
      $result = Invoke-SSHCommand -SSHSession $session -command "ps -ef | grep pmon" -EnsureConnection

      if ($debug -ge 2){
        write-host $output
      }

    } catch {;
      $output = $false

      write-log -message "Error starting Oracle Databases" -sev "WARN";

      sleep 2
    };
  } until (($output -match 'ORACLE instance started') -or $count -ge 5)

 
  if ($result.output -match $netbios){
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
    Remove-SSHSession -SSHSession $session
  } catch {}
  return $resultobject
};
Export-ModuleMember *