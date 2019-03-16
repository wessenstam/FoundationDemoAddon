function Wrap-Slack-Log{
  param(
    $datavar,
    $datagen,
    $ParentLogfile,
    $basepath
  )

  $token = get-content "$($basepath)\SlackToken.txt"
  if ($token){  
    
    Write-log -message "Preparing slackbot intel"
    Write-log -message "Getting all Users from slack, this takes 3 minutes to not overload the API"
    
    $SlackUsers = Invoke-RestMethod -Uri https://slack.com/api/users.list -Body @{token="$Token"}
    $fulluserlist = $SlackUsers.members
    $loop = 0
    $fulluserlist = $null

    do {
      $oldcursor = $SlackUsers.response_metadata.next_cursor
      $loop++
      write-host "Loop $loop Loaded $($fulluserlist.count) users"
      $SlackUsers = Invoke-RestMethod -Uri https://slack.com/api/users.list -Body @{token="$Token";cursor=$($SlackUsers.response_metadata.next_cursor)} -ea:0
      $newcursor = $SlackUsers.response_metadata.next_cursor
      $fulluserlist += $SlackUsers.members
      $user = $fulluserlist | where {$_.profile.email -eq $($datavar.SenderEmail)}
      sleep 6
    } until ($loop -eq 25 -or $user)

   
    Write-log -message "Seeking User ID for $($datavar.SenderEmail)"
    
    if ($user){

      Write-log -message "Sending Slack Notifications to $($user.real_name) with ID $($user.id)"
      Write-log -message "Grabbing Logfile with $($datavar.uuid)"
      Write-log -message "Starting Direct Session"

      $counter = 0 
      $currentsize = 0
      $countmessage = 0
      Slack-Send-DirectMessage -message "Starting 1 Click Demo SlackBot" -user $user.id -token $token
      do {
        $counter++
        $message = $null
        [array]$filesize = get-content $ParentLogfile
        if ($currentsize -eq 0){
          $file1 = $filesize
        } else {
          $file1 = $filesize | select-object -Skip $currentsize 
        }
        $file2 = $file1 | select -first 150
        if ($datavar.debug -ge 2){

          Write-log -message "Current Filesize is $currentsize"
          Write-log -message "New File size will be $($file2.count)"

        }
        #-and $line -notmatch "[!@#$%^;&*()`"{}<>]"
        [int]$currentsize = $currentsize + $file2.count
        Foreach ($line in $file2){
          $pattern = '[\\/]'
          $line = $line -replace $pattern, '-'
          if ($line -match "^### " -and $datavar.slackbot -eq 1){
            [array]$message += ($line -replace "^### ", 'Chapter Started: ') + "\n"       
          } elseif ($line -match "^### " -and $datavar.slackbot -gt 1 ){
            [array]$message += ($line -replace "^### ", '\n\n\nChapter Started: ') + "\n\n\n"
          } elseif ($datavar.slackbot -eq 2 -and $line -match "\d{2}:\d{2}:\d{2} \| INFO|WARN|ERROR.*\| .*" ){
            [array]$message += $line + "\n"
          }
        }
        if ($message){
          $countmessage++

          Write-log -message "Sending Slack Message to $($user.id)"
          Write-log -message "Message is $($message.count) lines"
          Write-log -message "A total of $countmessage messages where sent."

          Slack-Send-DirectMessage -message $message -user $user.id -token $token
        }
        if ($datavar.debug -ge 2){
          sleep 15
        } else {
          sleep 60
        }
        
      } until ($counter -eq 1000)
    } else {

      Write-log -message "User $($Datavar.SenderEmail) was not found."

    }
  } else {

    Write-log -message "Slack Token is not installed." -sev "WARN"

  }
}