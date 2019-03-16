Function Lib-Generate-SSHKey {
  Param (
    [string] $basedir,
    [object] $datavar
  )

  $unixbasedir = $basedir -replace ('\\','/')
  write-log -message "Generating SSHKey"
  $string = 
  Set-Content "$($basedir)\System\Temp\$($datavar.uuid).bat" "c:\progra~1\Git\git-bash.exe -c 'ssh-keygen -t rsa -b 4096 -C `"$($datavar.SenderEMail)`" -f $($unixbasedir)/System/temp/$($datavar.uuid).key -q -P `"`";'" -Encoding ASCII
  start-process "$($basedir)\System\temp\$($datavar.uuid).bat"
  sleep 10
  $PrivateKey = get-content "$($basedir)\System\temp\$($datavar.uuid).key"
  [string]$Public     = get-content "$($basedir)\System\temp\$($datavar.uuid).key.pub"
  $resultobject =@{
    Private = $PrivateKey
    Public  = $Public
  };
  return $resultobject  
} 