Function REST-WorkShopConfig-Px {
  Param (
    [string] $ClusterPx_IP,
    [string] $clpassword,
    [string] $clusername,
    [string] $POCName,  
    [string] $VERSION,
    [string] $Mode,
    [string] $debug
  )

  write-log -message "Debug level is $debug";
  write-log -message "Building Credential object"
  $count = 0 
  $credPair = "$($clusername):$($clpassword)"
  $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
  $headers = @{ Authorization = "Basic $encodedCredentials" }

  write-log -message "Building JSON Array" 

  [array]$JSONA += @"
{"type":"custom_login_screen","key":"color_in","value":"#ADD100"}
"@
  [array]$JSONA += @"
{"type":"custom_login_screen","key":"color_out","value":"#11A3D7"}
"@
  if ($mode -eq "PC"){
  [array]$JSONA += @"
{"type":"custom_login_screen","key":"product_title","value":"$($POCName),Prism-Central-$($VERSION)"}
"@
  } else {
  [array]$JSONA += @"
{"type":"custom_login_screen","key":"product_title","value":"$($POCName),Prism-Element-$($VERSION)"}
"@    
  }
  [array]$JSONA += @"
{"type":"custom_login_screen","key":"title","value":"Nutanix.HandsOnWorkshops.com"}
"@
  [array]$JSONA += @"
{"type":"UI_CONFIG","username":"system_data","key":"disable_2048","value":true}
"@
  [array]$JSONA += @"
{"type":"UI_CONFIG","key":"autoLogoutGlobal","value":7200000}
"@
  [array]$JSONA += @"
{"type":"UI_CONFIG","key":"autoLogoutOverride","value":0}
"@
  [array]$JSONA += @"
{"type":"UI_CONFIG","key":"welcome_banner","value":"https://Nutanix.HandsOnWorkshops.com/workshops/6070f10d-3aa0-4c7e-b727-dc554cbc2ddf/start/"}
"@
  $URL = "https://$($ClusterPx_IP):9440/PrismGateway/services/rest/v1/application/system_data"
  
  write-log -message "Importing $($JSONA.count) JSONs"

  foreach ($json in $JSONA){
    try {
      Invoke-RestMethod -Uri $URL -method "post" -body $json -ContentType 'application/json' -headers $headers -ea:0;
    } catch {;
  
      write-log -message "JSON Already Applied"

    }
  };
  ## Some error out, ignoring
  $resultobject =@{
    Result = "Success"

  }
  return $resultobject
};
Export-ModuleMember *