Function REST-Finalize-Px {
  Param (
    [string] $ClusterPx_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $SENAME,
    [string] $SECompany,
    [string] $SEROLE,
    [string] $EnablePulse,
    [string] $debug
  )###https://pallabpain.wordpress.com/2016/09/14/rest-api-call-with-basic-authentication-in-powershell/

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"

  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building EULA JSON"

  $EULAURL = "https://$($ClusterPx_IP):9440/PrismGateway/services/rest/v1/eulas/accept"
  $EULATURL = "https://$($ClusterPx_IP):9440/PrismGateway/services/rest/v1/eulas"
  $EULAPayload= @{
    username="$($SENAME)"
    companyName="$($SECompany)"
    jobTitle="$($SEROLE)"
  } 
  $EULAJson = $EULAPayload | convertto-json

  write-log -message "Registering Px"
  try {
    $registration = (Invoke-RestMethod -Uri $EULATURL -method "get" -headers $headers).entities.userdetailslist;
  
  } catch {;
    write-log -message "We Could not query Px for existing registration" -sev "WARN";
  };
  if ($registration.username -eq $SENAME ){;

    write-log -message "Px $ClusterPx_IP is already registrered";

    $successEULA = $true;
    $registration
  } else {;
    do {;
      $countEULA++;
      $successEULA = $false;
      try {;
        Invoke-RestMethod -Uri $EULAURL -method "post" -body $EULAJson -ContentType 'application/json' -headers $headers;
        $successEULA = $true;
      }catch {;
  
        write-log -message "Registration failed, retry attempt $countEULA out of 5" -sev "WARN";
        sleep 2
        $successEULA = $false;
      }
    } until ($successEULA -eq $true -or $countEULA -eq 5);
    if ($countEULA -eq 5){;
  
      write-log -message "Registration failed after $countEULA attempts" -sev "WARN";

    };
  };

  
  if ($EnablePulse -eq 0){

    write-log -message "Building Pulse JSON"  

    $PulseURL = "https://$($ClusterPx_IP):9440/PrismGateway/services/rest/v1/pulse"
    $PulsePayload=@{
        enable="false"
        enableDefaultNutanixEmail="false"
        isPulsePromptNeeded="false"
    }
    $PulseJson = $PulsePayload | convertto-json

    write-log -message "Disabling Pulse"

    do {
      $countPulse++
      $Pulsestatus = $false
      try {
        Invoke-RestMethod -Uri $PulseURL -method "put" -body $PulseJson -ContentType 'application/json' -headers $headers;
        $Pulsestatus = $true

      }catch {
        
        write-log -message "Disabling pulse failed, retry attempt $countPulse out of 5" -sev "WARN"

        $Pulsestatus = $false
        sleep 2
      }
    } until ($Pulsestatus -eq $true -or $countPulse -eq 5)
    if ($countPulse -eq 5){

      write-log -message "Disabling Pulse failed after $countEULA attempts" -sev "WARN"

    };
  } else {
    $Pulsestatus -eq $true
  }
  if ($successEULA -eq $true -and $Pulsestatus -eq $true){
    $status = "Success"
  } else {
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
  }
  return $resultobject
};
Export-ModuleMember *