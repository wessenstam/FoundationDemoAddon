
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
  $URL1 = "https://$($EraIP):8443/era/v0.8/auth/validate?token=true&expire=15"

  do {
    write-log -message "Using URL $URL"

    $Json = @"
{ "password": "$($clpassword)" }
"@ 

    $credPair = "$($clusername):$($defaultpass)"
    $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
    $headers = @{ Authorization = "Basic $encodedCredentials" }
    try {
      $task = Invoke-RestMethod -Uri $URL1 -method "post" -body $JSON -ContentType 'application/json' -headers $headers; 
    } catch {

      write-log -message "Password is expired"
      try {
        $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers; 
      } catch {
        $task = Invoke-RestMethod -Uri $URL -method "post" -body $JSON -ContentType 'application/json' -headers $headers;
      }
    }

    write-log -message "Password change Success"
    if ($debug -ge 1){
      $json | out-file c:\temp\erapass.json
    }
    $passreset = $true
  

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
