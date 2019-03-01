
Function REST-ERA-ResetPass {
  Param (
    [string] $EraIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $debug
  )

  write-log -message "Executing ERA Portal Pass reset"
  write-log -message "Executing using default pass"
  $defaultpass = "Nutanix/4u"

  $URL = "https://$($EraIP):8443/era/v0.8/auth/update"
  $Payload= @{
    password="$clpassword"
  } 
  do {
    write-log -message "Using URL $URL"

    $JSON = $Payload | convertto-json
   # try{
      $credPair = "$($clusername):$($defaultpass)"
      $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
      $headers = @{ Authorization = "Basic $encodedCredentials" }
      $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
  
      write-log -message "Password change Success"
  
      $passreset = $true
   # } catch {
      sleep 10
  
     # try {
     #   write-log -message "Default Password seems changed already, trying new password"
    
     #   $credPair = "$($clusername):$($clpassword)"
     #   $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
     #   $headers = @{ Authorization = "Basic $encodedCredentials" }
     #   $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
     #   $passreset = $true
      ## }
  
   # }
  } until ($passreset -eq $true)

  if ($passreset -eq $true){
    $status = "Success"

    write-log -message "ERA Portal Password has been reset"

  } else {

    write-log -message "ERA Portal Password reset failure." -sev "ERROR"

    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
  }
  Return $resultobject
} 
