Function LIB-Send-Confirmation{
  param(
    [string] $reciever,
    $datavar,
    $datagen,
    $Logfile,
    $debug,
    $validation,
    $stage,
    $mode
  )
  do {
    $failed = $false
    try {
      $IP = "10.68.25.94" ## (Get-NetIPAddress |WHERE {$_.AddressState -EQ "Preferred" -and $_.ipaddress -notmatch "::|^10.10|^127.0"}).ipaddress
      $url = "http://$($ip)"
      if ($mode -eq "Start"){
        $MailSubject = "Foundation Addon Provisioning Started for $($datavar.pocname)";
        $body += "<h2>Foundation Addon Provisioning Started for $($datavar.pocname)</h2>";
      } elseif($mode -eq "FailedVPN") {
        $MailSubject = "Foundation Addon Provisioning Failed for $($datavar.pocname): VPN Issue";
        $body += "<h2>Foundation Addon Provisioning Failed for $($datavar.pocname)</h2>";
        $body += "<b>No VPN Active</b>"
      } elseif($mode -eq "FailedStage") {
        $MailSubject = "Foundation Addon Provisioning Failed for $($datavar.pocname): VPN Issue";
        $body += "<h2>Foundation Addon Provisioning Failed for $($datavar.pocname)</h2>";
        $body += "<b>System failed on $stage</b>"
      } elseif($mode -eq "FailedImages") {
        $MailSubject = "Foundation Addon Provisioning Failed for $($datavar.pocname): Images not present.";
        $body += "<h2>Foundation Addon Provisioning Failed for $($datavar.pocname)</h2>";
        $body += "<b>Image not present</b>"
      } elseif($mode -eq "Locked"){
        $MailSubject = "Foundation Addon Provisioning is locked for $($datavar.pocname)";
        $body += "<h2>Foundation Addon Provisioning is locked for $($datavar.pocname)</h2>";
        $body += "<b>This request is terminated.</b>"
      } elseif($mode -eq "Queued"){
        $MailSubject = "Foundation Addon Provisioning is queued for $($datavar.pocname)";
        $body += "<h2>Foundation Addon Provisioning is queued for $($datavar.pocname)</h2>";
        $body += "<b>The item will be submitted for auto queue once validated.</b>"
        $body += "<b>There is a 15 minute delay to add or change options.</b>"
      } elseif($mode -eq "QueueError"){
        $MailSubject = "Foundation Addon Provisioning failed validation for $($datavar.pocname)";
        $body += "<h2>Foundation Addon Provisioning failed validation for $($datavar.pocname)</h2>";
        $body += "<b>This item needs to be manually corrected.</b>"
        $body += "<b>Please read the error below:.</b><br>"
        foreach ($line in $validation){
          $body += "$line <br>"
        }
      } elseif($mode -eq "SingleUser"){
        $MailSubject = "Foundation Addon Provisioning Single Threaded mode active, request $($datavar.pocname) queued";
        $body += "<h2>Foundation Addon Provisioning is queued for $($datavar.pocname)</h2>";
        $body += "<b>The item will be submitted for auto queue once validated.</b>"
        $body += "<b>There are other provisioning instances running that have locked multithreaded execution.</b>"
        $body += "<b>You will be notified once it starts.</b>"   
      } else {
        $MailSubject = "Foundation Addon Provisioning Finished for $($datavar.pocname)";
        $body += "<h2>Foundation Addon Provisioning Finished for $($datavar.pocname)</h2>";
        $body += "<b>Enjoy</b>"  
      }
      $MailTo = $reciever;
      $body += "<br>";
      $body += "For realtime progress, options, logging and instructions visit our <a href=$($URL)>Website</a><br>";
      $body += "<br>";
      $body += "Variable Data:";
      $body += $datavar | ConvertTo-Html -As List;
      $body += "<br>";
      $body += "<br>";
      if ($mode -notmatch "queue"){
        $body += "Deducted Data:";
        $body += $datagen | ConvertTo-Html -As List;
        $body += "<br>";
      }
      $body += "<br>";
      if ($debug -ge 1 -and $mode -match "end|FailedVPN"){
        $body += "<br>";
        $body += "<br>";
        $body += "Logging:"; 
        foreach ($line in (get-content $logfile)){;
          $body += $line;
          $body += "<br>";
        };
      };
      if ($mode -eq "Start"){
        $body += "Possible commands are:<br>"
        $body += "Debug:0|1|2&nbsp&nbsp&nbsp1 enables email logging, 2 is 1+RPA console open.<br>"
        $body += "PCmode:1|3&nbsp&nbsp&nbsp Nr of PC nodes: 1 is default, 3 disables Karban.<br>"
        $body += "PCversion:5.9.2|5.10.01&nbsp&nbsp&nbsp PC Version 5.9.2 or 5.10.0.1, default auto picks based on AOS.<br>"
      };
      Send-MailMessage -BodyAsHtml -body $body -to $reciever -from $datagen.smtpsender -port $datagen.smtpport -smtpserver $datagen.smtpserver -subject $MailSubject
      if ($reciever -ne $supportemail){
        Send-MailMessage -BodyAsHtml -body $body -to $datagen.supportemail -from $datagen.smtpsender -port $datagen.smtpport -smtpserver $datagen.smtpserver -subject "Admin Copy, Foundation system activated"
      }   

      sleep 15
      
    } catch {
      $failed -eq $true
    }
  } until ($failed -eq $false)
};

