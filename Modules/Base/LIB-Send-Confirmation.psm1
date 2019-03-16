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
        $MailSubject = "1 Click Demo Provisioning Started for $($datavar.pocname)";
        $body += "<h2>1 Click Demo Provisioning Started for $($datavar.pocname)</h2>";
      } elseif($mode -eq "FailedVPN") {
        $MailSubject = "1 Click Demo Provisioning Failed for $($datavar.pocname): VPN Issue";
        $body += "<h2>1 Click Demo Provisioning Failed for $($datavar.pocname)</h2>";
        $body += "<b>No VPN Active</b>"
      } elseif($mode -eq "FailedStage") {
        $MailSubject = "1 Click Demo Provisioning Failed for $($datavar.pocname): VPN Issue";
        $body += "<h2>1 Click Demo Provisioning Failed for $($datavar.pocname)</h2>";
        $body += "<b>System failed on $stage</b>"
      } elseif($mode -eq "CalmSuccess") {
        $MailSubject = "Foundation update for $($datavar.pocname) Calm Updates were successful";
        $body += "<h2>Calm Updates were successful</h2>";
        $body += "Completion time will ~25 minutes from now";
      } elseif($mode -eq "CalmFailed") {
        $MailSubject = "Foundation delayed for $($datavar.pocname) Calm Updates failed.";
        $body += "<h2>Foundation delayed for $($datavar.pocname) Calm Updates failed.</h2>";
        $body += "The system will retry updates, this will cause a 25 minute delay";
      } elseif($mode -eq "PCSuccess") {
        $MailSubject = "Foundation update for $($datavar.pocname) PC was successfully installed";
        $body += "<h2>Foundation update for $($datavar.pocname) PC was successfully installed</h2>";
        $body += "Completion time will be ~40 minutes from now.";
      } elseif($mode -eq "PCFailed") {
        $MailSubject = "Foundation delayed for $($datavar.pocname) PC Install failed.";
        $body += "<h2>Foundation delayed for $($datavar.pocname) PC Install failed.</h2>";
        $body += "The system will retry updates, this will cause a 25-35 minute delay";
      } elseif($mode -eq "FailedImages") {
        $MailSubject = "1 Click Demo Provisioning Failed for $($datavar.pocname): Images not present.";
        $body += "<h2>1 Click Demo Provisioning Failed for $($datavar.pocname)</h2>";
        $body += "<b>Image not present</b>"
      } elseif($mode -eq "Locked"){
        $MailSubject = "1 Click Demo Provisioning is locked for $($datavar.pocname)";
        $body += "<h2>1 Click Demo Provisioning is locked for $($datavar.pocname)</h2>";
        $body += "<b>This request is terminated.</b>"
      } elseif($mode -eq "Queued"){
        $MailSubject = "1 Click Demo Provisioning is queued for $($datavar.pocname)";
        $body += "<h2>1 Click Demo Provisioning is queued for $($datavar.pocname)</h2>";
        $body += "<b>The item will be submitted for auto queue once validated.</b>"
        $body += "<b>There is a 15 minute delay to add or change options.</b>"
      } elseif($mode -eq "QueueError"){
        $MailSubject = "1 Click Demo Provisioning failed validation for $($datavar.pocname)";
        $body += "<h2>1 Click Demo Provisioning failed validation for $($datavar.pocname)</h2>";
        $body += "<b>This item needs to be manually corrected.</b>"
        $body += "<b>Please read the error below:.</b><br>"
        foreach ($line in $validation){
          $body += "$line <br>"
        }
      } elseif($mode -eq "SingleUser"){
        $MailSubject = "1 Click Demo Provisioning Single Threaded mode active, request $($datavar.pocname) queued";
        $body += "<h2>1 Click Demo Provisioning is queued for $($datavar.pocname)</h2>";
        $body += "<b>The item will be submitted for auto queue once validated.</b>"
        $body += "<b>There are other provisioning instances running that have locked multithreaded execution.</b>"
        $body += "<b>You will be notified once it starts.</b>"   
      } else {
        $MailSubject = "1 Click Demo Provisioning Finished for $($datavar.pocname)";
        $body += "<h2>1 Click Demo Provisioning Finished for $($datavar.pocname)</h2>";
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

