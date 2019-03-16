$basepath      = "C:\HostedPocProvisioningService"
$debug         = 1
$channelcode   = "CGB07NYSH"
$token         = get-content "$($basepath)\SlackToken.txt"
$Autoqueue     = "Incoming"                                                      
$manualqueue   = "Manual"                                                     
$readyqueue    = "Ready"                                                      
$queuepath     = "C:\HostedPocProvisioningService\Queue"                      

############### End of variables

import-module "$($basepath)\modules\base\LIB-Write-Log.psm1" -DisableNameChecking   
Import-Module "$($basepath)\modules\Queue\Validate-QueueItem.psm1" -DisableNameChecking   

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
  $Reply = (New-Object -TypeName PSObject -Prop $Prop) | ConvertTo-Json | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }
  $Array = @()
  $Reply.ToCharArray() | ForEach { $Array += [byte]$_ }          
  $Reply = New-Object System.ArraySegment[byte]  -ArgumentList @(,$Array)
  $Conn = $WS.SendAsync($Reply, [System.Net.WebSockets.WebSocketMessageType]::Text, [System.Boolean]::TrueString, $CT)
  While (!$Conn.IsCompleted) { Start-Sleep -Milliseconds 100 }
  Return $ID
}

############### End of Functions


Write-log -message "Preparing slackbot intel"
Write-log -message "Getting all Users from slack, this takes 3 minutes to not overload the API"

$SlackUsers = Invoke-RestMethod -Uri https://slack.com/api/users.list -Body @{token="$Token"}
$fulluserlist = $SlackUsers.members
$loop = 0
$fulluserlist = $null
if ($debug -le 1){
 do {
   $oldcursor = $SlackUsers.response_metadata.next_cursor
   $loop++
   write-host "Loop $loop"
   $SlackUsers = Invoke-RestMethod -Uri https://slack.com/api/users.list -Body @{token="$Token";cursor=$($SlackUsers.response_metadata.next_cursor)} -ea:0
   $newcursor = $SlackUsers.response_metadata.next_cursor
   $fulluserlist += $SlackUsers.members
   sleep 10
 } until ($loop -eq 25 -or $oldcursor -eq $newcursor)
}
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
      if ($debug -ge 3){
        Write-host "`n$RTM"
      }  
      try {
        $RTM = ($RTM | convertfrom-json)
      } catch {
        $RTM =$null
      }
      if ($RTM){   
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
                    Send-SlackMsg -Text "Thank you $($user.real_name) for using this slack integration, we are building a provision config file." -Channel $RTM.Channel
                    $message = $rtm.text -split "\n"
                    $Pocname = (($message | where {$_ -match "POC Name:"}) -split ":")[1]
                    $PEClusterIP = (($message | where {$_ -match "Prism Element Cluster IP Address:"}) -split ":")[1]
                    $Gateway = (($RTM.message | where {$_ -match "Gateway:"}) -split ":")[1]
                    $SubnetMask = (($message | where {$_ -match "SubnetMask:"}) -split ":")[1]
                    $VLAN = (($message | where {$_ -match "VLAN:"}) -split ":")[1]
                    $DNSServer = (($message | where {$_ -match "DNS Server:"}) -split ":")[1]
                    $SenderName = (($message | where {$_ -match "SenderName:"}) -split ":")[1]
                    $SenderEMail = (($message | where {$_ -match "SenderEMail:"}) -split ":")[1]
                    $PEAdmin = (($message | where {$_ -match "Prism Element Admin:"}) -split ":")[1]
                    $PEPass = (($message | where {$_ -match "Prism Element Pass:"}) -split ":")[1]
                    $region = (($message| where {$_ -match "Target Region:"}) -split ":")[1]
                    $flow = (($message | where {$_ -match "Enable FLOW:"}) -split ":")[1]
                    $karbon = (($message | where {$_ -match "Install Karbon:"}) -split ":")[1]
                    $ERA = (($message | where {$_ -match "Install  ERA:"}) -split ":")[1]
                    $Exchange = (($message | where {$_ -match "Install Exchange:"}) -split ":")[1]
                    $Files = (($message | where {$_ -match "Install Files And Shares:"}) -split ":")[1]
                    $XenDesktop = (($message | where {$_ -match "Install XenDesktop Demo:"}) -split ":")[1]
                    $IISXPLAY = (($message | where {$_ -match "Install Xplay IIS Autoscale Demo:"}) -split ":")[1]
                    $workshop = (($message | where {$_ -match "Install Workshop Settings:"}) -split ":")[1]
                    $SSP = (($message | where {$_ -match "Install SSP Settings:"}) -split ":")[1]
                    $SlackIM = (($message | where {$_ -match "Slack Private IM Updates:"}) -split ":")[1]
                    $Ver = "AOS"
                    $date = get-date;
                    $Guid = [guid]::newguid();
                    $Object = New-Object PSObject;
                    $Object | add-member Noteproperty DateCreated         $date;
                    $Object | add-member Noteproperty PEClusterIP         $PEClusterIP;
                    $Object | add-member Noteproperty SenderName          $SenderName;
                    $Object | add-member Noteproperty SenderEMail         $SenderEMail;
                    $Object | add-member Noteproperty PEAdmin             $PEAdmin;
                    $Object | add-member Noteproperty PEPass              $PEPass;
                    $Object | add-member Noteproperty debug               "1"
                    $Object | add-member Noteproperty AOSVersion          "AutoDetect"
                    $Object | add-member Noteproperty PCVersion           "AutoDetect"
                    $Object | add-member Noteproperty Hypervisor          "AutoDetect"
                    $Object | add-member Noteproperty InfraSubnetmask     $SubnetMask;
                    $Object | add-member Noteproperty InfraGateway        $Gateway;
                    $Object | add-member Noteproperty DNSServer           $DNSServer;
                    $object | add-member Noteproperty POCname             $Pocname
                    $object | add-member Noteproperty PCmode              "3"
                    $object | add-member Noteproperty AutoQueueTimer      "15"
                    $object | add-member Noteproperty SystemModel         "AutoDetect"
                    $object | add-member Noteproperty Nw1Vlan             ""
                    $object | add-member Noteproperty Nw2DHCPStart        ""
                    $object | add-member Noteproperty Nw2Vlan             ""
                    $object | add-member Noteproperty Nw2subnet           ""
                    $object | add-member Noteproperty Nw2gw               ""
                    $object | add-member Noteproperty Location            $Region;
                    $object | add-member Noteproperty VersionMethod       $ver;    
                    $object | add-member Noteproperty VPNUser             ""
                    $object | add-member Noteproperty VPNPass             ""
                    $object | add-member Noteproperty VPNURL              ""
                    $object | add-member Noteproperty SetupSSP            $SSP;
                    $object | add-member Noteproperty DemoLab             $workshop;
                    $object | add-member Noteproperty EnableFlow          $flow;
                    $object | add-member Noteproperty DemoXenDeskT        $XenDesktop;
                    $object | add-member Noteproperty InstallEra          $ERA;
                    $object | add-member Noteproperty DemoExchange        $Exchange;
                    $object | add-member Noteproperty InstallKarbon       $karbon;
                    $object | add-member Noteproperty DemoIISXPlay        $IISXPLAY;
                    $object | add-member Noteproperty InstallFiles        $Files;
                    $object | add-member Noteproperty UUID                $Guid.Guid;

                    $object | export-csv "$($queuepath)\$($readyqueue)\$($pocname)-$($Guid).queue"

                    Send-SlackMsg -Text "Standy while we validate your request." -Channel $RTM.Channel 

                    $result = Validate-QueueItem -queuefile "$($queuepath)\$($readyqueue)\$($pocname)-$($Guid).queue" -debug:2 -processingmode "SCAN"
                    foreach ($line in $result){
                      Send-SlackMsg -Text $line -Channel $RTM.Channel
                    }
                  }
                  {$_ -match "what day"} {
                    Send-SlackMsg -Text "Today is $($date.dayofweek)" -Channel $RTM.Channel
                  }
                  {$_ -match "status monitor"} {
                    Send-SlackMsg -Text "Starting Status thread, please mute me." -Channel $RTM.Channel
                    $Pocname = (($message | where {$_ -match ":"}) -split ":")[1]
                    #Start-Process powershell.exe -ArgumentList "C:\HostedPocProvisioningService\TailLogDraft.ps1 -user $($rtm.user) -pocname $($Pocname)"
                    sleep 120
                  }
                  {$_ -match "how old.*you|what your age"} {
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

          {$_.type -eq 'error'} { 
            Break
          } 
          default { 

            Write-log -message "No action specified for $($RTM.type) event" 

          }            
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

