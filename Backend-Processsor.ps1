#### UserVariables
$Debug                      = 2

#### Program Variables
$logingdir                  = "C:\HostedPocProvisioningService\System\Logging"
$BaseThreadlogingdir        = "C:\HostedPocProvisioningService\Jobs\Active"
$ArchiveThreadlogingdir     = "C:\HostedPocProvisioningService\Jobs\Archive"
$ModuleDir                  = "C:\HostedPocProvisioningService\Modules"
$daemons                    = "C:\HostedPocProvisioningService\Daemons"
$Lockdir                    = "C:\HostedPocProvisioningService\Lock"
$queuepath 			            = "C:\HostedPocProvisioningService\Queue"
$incomingqueue              = "Incoming"
$Manualqueue                = "Manual"
$Outgoing                   = "Outgoing"
$ready                      = "Ready"
$AutoQueueTimer             = 15
$SingleModelck              = "$($Lockdir)\Single.lck"

#### Loading
Import-Module "$($ModuleDir)\Queue\Get-IncommingQueueItem.psm1"
Import-Module "$($ModuleDir)\Queue\Validate-QueueItem.psm1"
Import-Module "$($ModuleDir)\Base\Lib-Send-Confirmation.psm1"
Import-Module "$($ModuleDir)\Base\LIB-Config-DetailedDataSet.psm1"
Import-Module "$($ModuleDir)\Base\LIB-Write-Log.psm1"


$Guid = [guid]::newguid()
$logfile  = "$($logingdir)\Backend-$($Guid.guid).log"


start-transcript -path $logfile

# Program log cleanup
write-host "$(get-date -format "hh:mm:ss") | INFO  | Starting Log Cleanup"
$oldFiles = get-item "$($logingdir)\Backend-*.log" | where {$_.lastwritetime -le ((get-date).adddays(-2))}
if ($oldfiles){
  write-host "$(get-date -format "hh:mm:ss") | INFO  | Removing $($oldfiles.count) logfiles"
  remove-item $oldFiles -force
}

$date = get-date

# Program is on a one minute loop
write-host "$(get-date -format "hh:mm:ss") | INFO  | Backend Process active"
do {
  $singleusermode = (get-item $SingleModelck -ea:0).lastwritetime | where {$_ -ge (get-date).addminutes(-90)}
  $object = Get-IncommingueueItem -queuepath $queuepath -incoming $incomingqueue -AutoQueueTimer $AutoQueueTimer -ready $ready
  $datagen = LIB-Config-DetailedDataSet -ClusterPE_IP $object.PEClusterIP -pocname $object.POCname -debug $object.debug -Sendername $object.Sendername
  if ($object){
    Lib-Send-Confirmation -reciever $object.SenderEMail -datavar $object -mode "Queued" -debug $object.debug -datagen $datagen
  }
  $validation = Validate-QueueItem -processingmode "Auto" -incomingqueue $incomingqueue -queuepath $queuepath -outgoingqueue $Outgoing -Readyqueue $Ready -Manualqueue $Manualqueue -AutoQueueTimer $AutoQueueTimer
  if ($validation -match "Error"){
    Lib-Send-Confirmation -reciever $object.SenderEMail -datavar $object -mode "QueueError" -debug $object.debug -validation $validation  -datagen $datagen
  }
  if (!$singleusermode){
    $validation = Validate-QueueItem -processingmode "NOW" -incomingqueue $incomingqueue -queuepath $queuepath -outgoingqueue $Outgoing -Readyqueue $Ready -Manualqueue $Manualqueue
    if ($validation -match "Error"){
      Lib-Send-Confirmation -reciever $object.SenderEMail -datavar $object -mode "QueueError" -debug $object.debug -validation $validation  -datagen $datagen
    }
  } else {
    if ($object){
      Lib-Send-Confirmation -reciever $object.SenderEMail -datavar $object -mode "SingleUser" -debug $object.debug -datagen $datagen
    } 
    write-host "$(get-date -format "hh:mm:ss") | INFO  | Daemons are not executing as long as single user mode is active, outgoing queue processing disabled."
  }
  sleep 10
  $count++
  if ($date.hour -match "04"){
    $items = get-item "$($BaseThreadlogingdir)\*.log" -ea:0| where {$_.lastwritetime -lt (get-date).addhours(-22)}
    if ($items){
      $items | % { move-item -path $_.fullname -destination "$($ArchiveThreadlogingdir)\" -force}
    }
  } 
} until ($count -eq 3)

