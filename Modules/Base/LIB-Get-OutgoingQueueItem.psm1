function Lib-Get-OutgoingQueueItem{
	param(
    [string] $queuepath,
    [string] $Outgoing,
    [string] $Archive
	)
	$item = get-item "$($queuepath)\$($Outgoing)\*.queue" -ea:0 | select -first 1 
  if ($item){
    $object = import-csv $item
    try {
      move-item -path $($item.fullname) "$($queuepath)\$($Archive)\" 
    } catch {
      remove-item $($item.fullname) -Force
      
    }
  } else {

  }
  return $object
}