$basepath      = "C:\HostedPocProvisioningService"
$debug         = 1 
$channelcode   = "CGB07NYSH"
$token         = get-content "$($basepath)\SlackToken.txt"

############### End of variables

import-module "$($basepath)\modules\base\LIB-Write-Log.psm1"

############### End of Import Modules

Function Send-SlackMsg {
  [cmdletbinding()]
  Param(
      $Text,
      $Channel,
      $ID = (get-date).ticks
  )
  $Prop = @{
    'id'      = $ID;
    'type'    = 'message';
    'text'    = $Text;
    'channel' = $Channel
  }
  $Reply = (New-Object –TypeName PSObject –Prop $Prop) | ConvertTo-Json | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
  $Array = @()
  $Reply.ToCharArray() | ForEach { $Array += [byte]$_ }          
  $Reply = New-Object System.ArraySegment[byte]  -ArgumentList @(,$Array)
  $Conn = $WS.SendAsync($Reply, [System.Net.WebSockets.WebSocketMessageType]::Text, [System.Boolean]::TrueString, $CT)
  While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }
  Return $ID
}


Function ConvertFrom-UnixTime {  
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Int32]$UnixTime
    )
    begin {
        $startdate = Get-Date –Date '01/01/1970' 
    }
    process {
        $timespan = New-Timespan -Seconds $UnixTime
        $startdate + $timespan
    }
}

############### End of Functions


Write-log -message "Preparing slackbot intel"
Write-log -message "Getting all Users from slack, this takes 3 minutes to not overload the API"

$SlackUsers = Invoke-RestMethod -Uri https://slack.com/api/users.list -Body @{token="$Token"}
$fulluserlist = $SlackUsers.members
$loop = 0
$fulluserlist = $null
do {
  $oldcursor = $SlackUsers.response_metadata.next_cursor
  $loop++
  write-host "Loop $loop"
  $SlackUsers = Invoke-RestMethod -Uri https://slack.com/api/users.list -Body @{token="$Token";cursor=$($SlackUsers.response_metadata.next_cursor)} -ea:0
  $newcursor = $SlackUsers.response_metadata.next_cursor
  $fulluserlist += $SlackUsers.members
  sleep 10
} until ($loop -eq 25 -or $oldcursor -eq $newcursor)

Write-log -message "Starting Slackbot, building realtime session"

$RTMSession = Invoke-RestMethod -Uri https://slack.com/api/rtm.start -Body @{token="$Token"}

Write-log -message "Trying to read the stream in a try catch loop."

Try{  
  Do{
    $WS = New-Object System.Net.WebSockets.ClientWebSocket                                                
    $CT = New-Object System.Threading.CancellationToken                                                   
    $Conn = $WS.ConnectAsync($RTMSession.URL, $CT)                                                  
    While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }
    Write-host "Connected to $($RTMSession.URL)"
    $Size = 8192
    $Array = [byte[]] @(,0) * $Size
    $Recv = New-Object System.ArraySegment[byte] -ArgumentList @(,$Array)
    While ($WS.State -eq 'Open') {
      $RTM = ""
      Do {
        $Conn = $WS.ReceiveAsync($Recv, $CT)
        While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }
        $Recv.Array[0..($Conn.Result.Count - 1)] | ForEach { $RTM += [char]$_ }
      } Until ($Conn.Result.Count -lt $Size)
      if ($debug -ge 2){
        Write-host "`n$RTM"
      }  
      if ($RTM){
        try {
          $RTM = ($RTM | convertfrom-json)
          Switch ($RTM){
            {($_.type -eq 'message') -and (!$_.reply_to)} { 
              If ( ($_.text -Match "<@$($RTMSession.self.id)>") -or $_.channel.StartsWith($channelcode) ){

                Write-log -message "I have recieved a message in my channel or directly to me."

                $Lines = ($_.text.ToLower() -split "`n")
                $user = $fulluserlist | where {$rtm.user -eq $_.id} | select -first 1
                $date = Get-date
                Switch ($Lines){
                    {$_ -match "^hi|^hello|day|^hey"} { 
                      Send-SlackMsg -Text "Hello $($user.real_name)\nWhat can I do for you?" -Channel $RTM.Channel 
                    }
                    {$_ -match "bye|cya|l8r|later|afk"} { 
                      Send-SlackMsg -Text "Goodbye  $($user.real_name)" -Channel $RTM.Channel 
                    }
                    {$_ -match "queueentry"} {
                      Send-SlackMsg -Text "Thank you $($user.real_name) for using this slack integration, we are starting the build of this cluster." -Channel $RTM.Channel
                      Send-SlackMsg -Text "Standy while we validate your request." -Channel $RTM.Channel 
                    }
                    {$_ -match "what day"} {
                      Send-SlackMsg -Text "Today is $($date.dayofweek)" -Channel $RTM.Channel
                    }
                    {$_ -match "how old.*you"} {
                      Send-SlackMsg -Text "I was born on February 19 2019, yet i am not human" -Channel $RTM.Channel
                    }
                    {$_ -match "are.*human"} {
                      Send-SlackMsg -Text "No, i am an artificial life form haha" -Channel $RTM.Channel
                    }
                    {$_ -match "When.*will.*machines.*take.*over"} {
                      Send-SlackMsg -Text "Please dont worry, current AI tech is a laugh. It will take at least another decade." -Channel $RTM.Channel
                    }
                    {$_ -match "start|build"} {
                      
                      Send-SlackMsg -Text 'Sure, lets get started\nUse the following template and reply here posting the entire template' -Channel $RTM.Channel 
                      Send-SlackMsg -Text 'Please pay attention to the spacing in the reply, no training spaces and no spaces after the colom. (:)' -Channel $RTM.Channel 
                      Send-SlackMsg -Text "Include all lines below:\nQueueEntry\nPOC Name:POCNAME (MAX 8 Chars)\nPrism Element Cluster IP Address:10.x.x.x (needs to be reachable in from the office network)\nGateway:10.x.x.x\nSubnetMask:255.x.x.x\nVLAN:x (integer)\nDNS Server:10.x.x.x(one is enough, use google 4.4.4.4 if you dont need internal lookups)\nSenderName:$($user.real_name)\nSenderEMail:$($user.profile.email)\nPrism Element Admin:admin\nPrism Element Pass:\nTarget Region:EU/US\nEnable FLOW:1\nInstall Karbon:1\nInstall ERA:1\nInstall Exchange:1\nInstall Files And Shares:1\nInstall XenDesktop Demo:1\nInstall Xplay IIS Autoscale Demo:1\nInstall Workshop Settings:1\nInstall SSP Settings:1\nSlack Private IM Updates:1" -Channel $RTM.Channel 
                    }
                    default { Write-host "Sorry i dont understand: $_" }
                }
              } Else{

                  Write-log -message "Message ignored as it wasn't sent to @$($RTMSession.self.name) or in a DM channel"
              }
            }
            {$_.type -eq 'reconnect_url'} { 
              $RTMSession.URL = $RTM.url 
            }
  
            default { 

              Write-log -message "No action specified for $($RTM.type) event" 

            }            
          }
        } catch {
           Write-log -message "No action specified for user_change event"
        }
      }
    }   
  } Until (!$Conn)

}Finally{

    If ($WS) { 
        Write-log -message "Closing websocket"
        $WS.Dispose()
    }

}

