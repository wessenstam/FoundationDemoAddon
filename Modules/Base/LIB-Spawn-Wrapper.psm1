Function Lib-Spawn-Wrapper {
  param (
    [object]$datavar,
    [object]$datagen,
    [string]$sysprepfile,
    [string]$ModuleDir,
    [string]$Lockdir,
    [string]$parentuuid,
    [string]$basedir,
    [string]$ProdMode,
    [bool]  $interactive,
    [string]$psm1file,
    [string]$LauchCommand,
    [string]$Type
  )
  write-log -message "Debug level is $debug";
  write-log -message "Building Launcher";


  if ($prodmode -ne 1){
    $Basescript = get-content "$($basedir)\Base-Outgoing-Queue-Processor-In Dev.ps1"
  } else {
    $Basescript = get-content "$($basedir)\Base-Outgoing-Queue-Processor.ps1"
  }
  $loader = $null
  foreach ($line in $basescript){
    [array]$loader += $line
    if ($line -match "#-----End Loader-----"){
      break
    }
  }
  write-log -message "Creating Queue File";

  $datavar | export-csv "$($basedir)\Queue\Spawns\$($type)-$($parentuuid)-1.queue"
  $datagen | export-csv "$($basedir)\Queue\Spawns\$($type)-$($parentuuid)-2.queue"

  write-log -message "Loading template";

  $template = get-content "$($basedir)\Modules\Templates\WrapLauncherV1.psd1"

  write-log -message "Loading Queue File";

  [array]$queuefile1 =  '$QueueFile1 = ' + "`"$($type)-$($parentuuid)-1.queue`"`n"
  [array]$queuefile2 =  '$QueueFile2 = ' + "`"$($type)-$($parentuuid)-2.queue`"`n"

  write-log -message "Loading the wrapper";

  $wrapper = get-content $psm1file
  $wrapper = $wrapper.replace('Export-ModuleMember *', "")

  write-log -message "Compiling Script";

  [array]$script =  $loader
         $script += "###QueueFile"
         $script += $queuefile1
         $script += $queuefile2
         $script += "###Type"
         $script += "`$type = " + "`"$type`""
         $script += "###Template"
         $script += $template
         $script += "###Wrapper"
         $script += $wrapper
         $script += "###Execute"
         $script += $LauchCommand
         $script += "stop-transcript"

  $script | out-file "$($basedir)\Queue\Spawns\$($type)-$($parentuuid).ps1"
  $jobname = "$($Type)-$($parentuuid)";
  Get-ScheduledTask $jobname -ea:0 | stop-scheduledtask -ea:0
  Get-ScheduledTask $jobname -ea:0 | unregister-scheduledtask -confirm:0 -ea:0
  [string]$script = "$($basedir)\Queue\Spawns\$($type)-$($parentuuid).ps1"
  $action = New-ScheduledTaskAction -Execute "$pshome\powershell.exe" -Argument $script
  $trigger =New-ScheduledTaskTrigger -Once -At (Get-Date).Date 
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -DontStopOnIdleEnd;
  $task = Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $trigger  -Settings $settings;
  if ($debug -lt 2){
    Get-ScheduledTask $jobname | start-scheduledtask
  } else {
    write-log -message "Please start on your own";
  }
};
Export-ModuleMember *
 


Function Lib-Get-Wrapper-Results {
  param (
    [object]$datavar,
    [object]$datagen,
    [string]$ModuleDir,
    [string]$parentuuid,
    [string]$basedir,
    [string]$debug
  )
  write-log -message "Debug level is $debug";
  write-log -message "Getting Scheduled Tasks";

  

  
  do {
    $Looper++
    [array]$tasks = Get-ScheduledTask | where {$_.taskname -match $parentuuid -and ($_.taskname -notmatch "^slack")}

    write-log -message "We found $($tasks.count) to process";

    [array] $allready = $null
    write-log "Cycle $looper out of 200"
    if ($tasks){
      Foreach ($task in $tasks){
        if ($task.state -eq "ready"){
    
          write-log -message "Task $($task.taskname) is ready."
    
          $allReady += 1
    
        } else {
    
          $allReady += 0

          write-log -message "Task $($task.taskname) is $($task.state)."
    
        };
      };
      sleep 60
    } else {
      $allReady = 1

      Write-log -message "There are no jobs to process."

    }
  } until ($Looper -ge 200 -or $allReady -notcontains 0)

  if ($allReady -eq 1 -and $tasks.count -ge 1){
    
    write-log -message "Grabbing logs for $($tasks.count) Jobs";
    $Slack = Get-ScheduledTask | where {$_.taskname -match $parentuuid -and $_.taskname -match "^Slack"} -ea:0
    $Slack | stop-scheduledtask -ea:0 
    $Slack | unregister-scheduledtask -ea:0 -confirm:0
    foreach ($Task in $tasks){
      $type = ($($task.taskname) -split "-")[0]
      $log = "$($basedir)\Jobs\Spawns\$($task.taskname).log"

      Write-log -message "Adding Log content for $type." -sev "CHAPTER"

      get-content $log

      Write-log -message "Removing task for $type with id $parentuuid" -sev "CHAPTER"

      Get-ScheduledTask $task.taskname | unregister-scheduledtask -ea:0 -confirm:0
      if ($debug -lt 3){
        remove-item "$($basedir)\Jobs\Spawns\$($task.taskname).log" -ea:0 -force -confirm:0
        remove-item "$($basedir)\Queue\Spawns\$($task.taskname).ps1" -ea:0 -force -confirm:0
        remove-item "$($basedir)\Queue\Spawns\$($task.taskname)-1.queue" -ea:0 -force -confirm:0
        remove-item "$($basedir)\Queue\Spawns\$($task.taskname)-2.queue" -ea:0 -force -confirm:0
        remove-item "$($basedir)\Jobs\Spawns\$($Slack.taskname).log" -ea:0 -force -confirm:0
      } else {
        Write-log -message "Please remove job and queue manually."
      }
    }
  }
};
Export-ModuleMember *