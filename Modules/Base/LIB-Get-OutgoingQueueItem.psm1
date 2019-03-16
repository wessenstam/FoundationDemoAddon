function Lib-Get-OutgoingQueueItem{
	param(
    [string] $queuepath,
    [string] $Outgoing,
    [string] $Archive,
    [string] $prodmode
	)
	$item = get-item "$($queuepath)\$($Outgoing)\*.queue" -ea:0 | select -first 1 
  if ($item){
    $object = import-csv $item

    ## Some Global Roles for Compatibility

    if ($object.debug -lt 1){

      write-log -Message "Debug is set lower then 1, raising to minimal"

      $object.debug = 1
    }

     if ($object.SetupSSP -ne 1){

      write-log -Message "SSP is required, cannot be disabled"

      $object.SetupSSP = 1
    }   

    if (($object.InstallKarbon -eq 1 -or $object.DemoIISXPlay -eq 1) -and $object.pcmode -eq 3){

      write-log -Message "Forcing PC Scale out to 1 node."

      $object.pcmode = 1
    }

    if ($object.DemoXenDeskT -eq 1 -and $object.InstallFiles -eq 0){

      write-log -Message "Files cannot be disabled with XenDesktop Enabled."

      $object.InstallFiles = 1
    }

    if ($object.AOSVersion -eq "5.10.1"){

      write-log -Message "Downgrading PC for best install success"
      
      $object.pcversion = "5.10.1"
    } 
    if ($prodmode -eq 1 -and $object.debug -lt 2){
      try {
        move-item -path $($item.fullname) "$($queuepath)\$($Archive)\" 
      } catch {
        remove-item $($item.fullname) -Force     
      }
    } elseif ($prodmode -eq 1 -and $object.debug -ge 2){

      write-log -Message "Not touching debug files in prod mode."

      $object = $null
    } elseif ($prodmode -ne 1 -and $object.debug -ge 2){

      write-log -Message "This is mine."

      try {
        move-item -path $($item.fullname) "$($queuepath)\$($Archive)\" 
      } catch {
        remove-item $($item.fullname) -Force     
      }

    } elseif ($prodmode -eq 0 -and $object.debug -le 2) {

      write-log -Message "I am a none prod mode daemon, staying away from none debug files"

      $object = $null

    } else {

      write-log -Message "I should not be here"

      $object = $null

    }
  } else {

  }
  return $object
}