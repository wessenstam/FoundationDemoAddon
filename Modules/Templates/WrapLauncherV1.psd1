

$loggingdir2 = "$($basedir)\jobs\Spawns"
$queuepath  = "$($basedir)\Queue\Spawns"
$item1 = get-item "$($queuepath)\$($QueueFile1)" -ea:0 | select -first 1
$datavar = import-csv $item1
$item2 = get-item "$($queuepath)\$($QueueFile2)" -ea:0 | select -first 1
$datagen = import-csv $item2
$logfile    = "$($loggingdir2)\$($Type)-$($datavar.UUID).log"

start-transcript -path $logfile 

write-log -message "Logging Activated for $Type Job Spawner" -sev "CHAPTER"
write-log -message "Getting Queue File $($queuepath)\$($QueueFile)"
write-log -message "Processing queue item ID $($datavar.UUID)";
$datagen.privatekey = get-content "$($basedir)\system\temp\$($datavar.uuid).key"

If ($datavar.debug -ge 2){

  write-log -message "Working with Dynamic dataset:" -sev "CHAPTER"

  $datavar | fl
  
  write-log -message "Working with Generated dataset:" -sev "CHAPTER"
  
  $datagen | fl
}

$ServerSysprepfile = LIB-Server-SysprepXML -Password $datavar.PEPass

$ISOurlData1 = LIB-Config-ISOurlData -region $datavar.Location
$ISOurlData2 = LIB-Config-ISOurlData -region "Backup"

write-log -message "Loading Wrapper Function" -sev "CHAPTER"
