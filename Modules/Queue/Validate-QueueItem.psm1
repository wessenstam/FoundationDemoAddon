Function Validate-QueueItem {
  param (
    [string] $processingmode,
    [string] $outgoingqueue,
    [string] $incomingqueue,
    [string] $Manualqueue,
    [string] $Readyqueue,
    [string] $queuepath,
    [string] $AutoQueueTimer,
    [string] $Queuefile,
    [string] $debug = 2
  )
  $AutoQueueTimer = "-$($AutoQueueTimer)"
  try{
    if ($processingmode -eq "Auto"){;
      $item = get-item "$($queuepath)\$($incomingqueue)\*.queue" -ea:0 | where {$_.CreationTime -lt (get-date).addminutes($AutoQueueTimer) }| select -first 1; 
    } elseif ($processingmode -eq "NOW") {;
      $item = get-item "$($queuepath)\$($Readyqueue)\*.queue" -ea:0 | select -first 1;
    } else {
      $item = get-item $queuefile
    }
  } catch {}
  $Validation = "OK"
  if ($item){
    $object = import-csv $item.fullname
    if ($debug -ge 1){
      write-host "`n$(get-date -format "hh:mm:ss") | INFO  | Processing Item $($object.uuid) for $($object.pocname)"
    }
    ##############
    ## Fixing Known Errors
    ##############

    if ($object.InfraSubnetmask -match "255.*\.0$"){;
      $object.InfraSubnetmask = "255.255.255.0"; 
    } elseif ($object.InfraSubnetmask -match "255.*128$"){;
      $object.InfraSubnetmask = "255.255.255.128";
    } elseif ($object.InfraSubnetmask -match "255.*192$"){;
      $object.InfraSubnetmask = "255.255.255.192";
    } elseif ($object.InfraSubnetmask -match "255.*224$"){;
      $object.InfraSubnetmask = "255.255.255.224";
    };
    if ($object.AOS -eq "59.1"){;
      $object.aos = "5.9.1";
    };

    ##############
    ## Validating Possible Errors
    ##############
    $IPpattern = "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$"
    if ($object.PEClusterIP -match $IPpattern){
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | Prism Element Cluster IP valid."
      }
    } else { 
      $validation = "Error"
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The Cluster Element IP is not a valid IPaddress $($object.PEClusterIP)"
      }
    }
    if ($object.InfraSubnetmask -match $IPpattern){
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | The Cluster Subnetmask is valid."
      }
    } else {;
      $validation = "Error";
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The Cluster Subnetmask is not a valid SubnetMask $($object.InfraSubnetmask)"
      };
    };
    if ($object.InfraGateway -match $IPpattern){
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | The Cluster Element Gateway is valid."
      }
    } else {;
      $validation = "Error";
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The Cluster Element Gateway is not a valid IPaddress $($object.InfraGateway)"
      };
    };
    if ($object.DNSServer -match $IPpattern){
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | The Cluster Element DNSServer is valid."
      }
    } else {;
      $validation = "Error";
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The Cluster Element DNSServer is not a valid IPaddress $($object.DNSServer)"
      };
    };
    if ($object.PEAdmin -match '[~#%&*{}\\:<>!?/|+" @\[\]_.]'){;
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The Admin username contains spaces or special chars, ->$($object.PEAdmin)<-.";
      }
      $validation = "Error";
    } else {
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | The Admin username is validated."      
      }
    }
    if ($object.PEPass -eq $null){;
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The Admin password is blanc, you have to specify the password if you edit the config in the UI.";
      }
      $validation = "Error";
    } elseif ($object.PEPass -notmatch '[~#%&*{}\\:!<>?/|+" @\[\]_.]' -or $object.PEPass -notmatch "[0-9]" -or $object.pepass -notmatch "[a-z].*[a-z]" -or $object.pepass -notmatch "[A-Z].*[A-Z]" -or $object.pepass.length -le 7){;
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | Password does not meet the complexity requirements 2 upper, 2 lower, 1 special, 1 digit and 8 chars long";
      }
      $validation = "Error";
    } else {
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | The Admin Password is validated."      
      }
    }
    if ($object.POCname -match '[~#%&*{}\\:<>?/|+" @\[\]_.]'){;
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The POCname contains Special chars, ->$($object.POCname)<-";
      }
      $validation = "Error";
    } elseif ($object.POCname.length -ge 11){;
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The POCname cannot be longer then 8 chars, Current is ->$($object.POCname.length)<-";
      }
      $validation = "Error";
    } else {
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | The POCname is clean" 
      }
    }
    if ($object.SenderEMail -match '[~#%&*{}\\:<>?/|+" \[\]]'){;
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | Error | The Sender Email contains Special chars, ->$($object.SenderEMail)<-.";
      }
      $validation = "Error";   
    } else {
      if ($debug -ge 1){
        write "$(get-date -format "hh:mm:ss") | INFO  | The Sender Email is validated." 
      } 
    }

    ##############
    ## Validating Version if not debug 1, TODO
    ##############


    ##############
    ## Moving item after validation
    ##############
    if ($validation -ne "OK" -and $processingmode -ne "SCAN"){;
      $processingmode = "Manual";
    };
    if ($processingmode -eq "Manual"){;
      $object | export-csv "$($queuepath)\$($Manualqueue)\$($item.name)";
      $item | remove-item  
    } elseif ($processingmode -eq "Auto" -and $validation -eq "OK") {;
      $object | export-csv "$($queuepath)\$($Readyqueue)\$($item.name)";
      $item | remove-item  
    } elseif ($processingmode -eq "NOW" -and $validation -eq "OK") {;
      $object | export-csv "$($queuepath)\$($outgoingqueue)\$($item.name)";
      $item | remove-item;
    } elseif ($processingmode -eq "SCAN") {;
    
    } else {;
      
    };
    return $validation;
  } else {;
    Write-host "Nothing to Process";
  };
};