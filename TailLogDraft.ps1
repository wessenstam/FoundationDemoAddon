Param (
  $POCname,
  $mode,
  $user,
  $new
)


$basepath      = "C:\HostedPocProvisioningService"
$debug         = 2 
$channelcode   = "CGB07NYSH"
$token         = get-content "$($basepath)\SlackToken.txt"
$Autoqueue     = "Incoming"                                                      
$manualqueue   = "Manual"                                                     
$readyqueue    = "Ready"                                                      
$queuepath     = "C:\HostedPocProvisioningService\Queue"                      
$logingdir     = "C:\HostedPocProvisioningService\Jobs\Active"

############### End of variables

import-module "$($basepath)\modules\base\LIB-Write-Log.psm1" -DisableNameChecking   
Import-Module "$($basepath)\modules\Queue\Validate-QueueItem.psm1" -DisableNameChecking   

############### End of Import Modules


function Send-DirectMessage {
  param(
    $user,
    $token,
    $message
  )
  $headers = @{ Authorization = "Bearer $token" }  

  $body = @"
{
    "token": "$token",
    "user": "$user",
}
"@ 
  $directopen = Invoke-RestMethod -Uri https://slack.com/api/im.open -method "POST" -Body $body -ContentType 'application/json' -headers $headers;
  #

  $body = @"
{
    "text": "$message",
    "token": "$token",
    "channel": "$($directopen.channel.id)",
}
"@ 

  $directsend = Invoke-RestMethod -Uri https://slack.com/api/chat.postMessage -method "POST" -Body $body -ContentType 'application/json' -headers $headers;

}

## Finding Log File
if ($new){
  do {
    $count++
    $items = get-item "$($logingdir)\*.log"
    $items = $items | where {$_.name -match "^$($POCname)"}
    $item = $items | where {$_.lastwritetime -ge (get-date).addminutes(-2)}
    sleep 5
    if (!$item){
      Send-DirectMessage -user $user -token $token -message "Provisioning is not started or no longer active"
      sleep 110
    }
  } until ($item -or $count -ge 10)
} else {
  $items = get-item "$($logingdir)\*.log"
  $items = $items | where {$_.name -match "^$($POCname)"}
  $item = $items | sort lastwritetime  | select -last 1
}

write $item
sleep 2


$file = get-content $item.fullname
$file2 = $file -join "\n"
Send-DirectMessage -message $file2 -user $user -token $token
do {
  $time = get-item $item
  $filename = $item.fullname
  $reader = new-object System.IO.StreamReader(New-Object IO.FileStream($filename, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [IO.FileShare]::ReadWrite))
  $lastMaxOffset = $reader.BaseStream.Length
  Start-Sleep -m 100
  if ($reader.BaseStream.Length -eq $lastMaxOffset) {
      continue;
  }
   
  $reader.BaseStream.Seek($lastMaxOffset, [System.IO.SeekOrigin]::Begin) | out-null
  
  $line = ""
  while (($line = $reader.ReadLine()) -ne $null) {
      Send-DirectMessage -message $line -user $user -token $token
  }
  
  $lastMaxOffset = $reader.BaseStream.Position

  $lastline = $item | select -last 1
} until ($item.lastwritetime -le (get-date).addminutes(-10))


