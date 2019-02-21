Function RPA-LCM-Inventory {
  Param (
    [string] $PCClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $iedelay = 10,
    [string] $mode,
    [string] $debug
  ) 
  do {
    $requestUri = "https://$($PCClusterIP):9440/console/#page/explore/settings/lcm_entity";
    $ie = new-object -ComObject "InternetExplorer.Application";
    if ($debug -ge 2){;
      $ie.silent = $false;
      $ie.visible = $true;
    } else {;
      $ie.silent = $true;
      $ie.visible = $False;      
    };
    if ($debug -ge 1){;

      write-host "Starting at $(get-date) ";
      write-log -message "IE Delay is set at $IEDelay seconds";
      write-log -message "Debug level is $debug";

    };
    $ie.navigate($requestUri);
    while($ie.Busy) { Start-Sleep -Milliseconds 100 };
    try {
      if ($ie.document.url -Match "invalidcert"){;

        write-log -message "Bypassing SSL Certificate Error Page";

        $sslbypass = $ie.Document.IHTMLDocument3_getElementsByTagName("a")  | where-object {$_.id -eq "overridelink"};
        $sslbypass.click();
      }
    } catch {
      while($ie.Busy){;
        Sleep -m 100;
      };
      $ie.quit();
      $ie = new-object -ComObject "InternetExplorer.Application";
      $requestUri = "https://$($PCClusterIP):9440/console/#page/explore/settings/lcm_entity";
      $ie.navigate($requestUri);
      sleep $IEDelay;
      if ($ie.document.url -Match "invalidcert"){;

        write-log -message "Bypassing SSL Certificate Error Page";

        $sslbypass = $ie.Document.IHTMLDocument3_getElementsByTagName("a") | where-object {$_.id -eq "overridelink"};
        $sslbypass.click();
      };
    };
    $LoginButton_ID     = "btnLogin";
    $PasswordField_ID   = "inputPassword";
    $UsenameField_ID    = "inputUsername";
    $doc = $ie.Document;
    sleep $IEDelay;
    try{
      $var = $doc.IHTMLDocument3_getElementsByTagName("Input")[2].outerhtml
    } catch { 
      write-log -message "No Input form was present when loading IE, Already logged in?"
    }
    while($ie.Busy){;
      Sleep -m 100;
    };
    sleep $IEDelay;    
    if (($var -notmatch "username" -AND $ie.document.IHTMLDocument2_body.outerhtml -notmatch "Manage Dashboards|OK, got it|Available Updates|Loading") -AND $ie.documenT.title -notMATCH "Nutanix|Prism Central"  ){
      $var = $null
      while($ie.Busy){;
        Sleep -m 100;
      };
      $ie.quit();
      if ($debug -ge 1){;
        $minutes = (30*$($count1)*$($IEDelay)) / 60

        write-log -message "PC Not ready"
        write-log -message "Looping $minutes Minutes"

      }
    }
    $count1++
    sleep $IEDelay;
    sleep $IEDelay;
  } until ((($var -match "username" -or $ie.document.IHTMLDocument2_body.outerhtml -match "Manage Dashboards|OK, got it|Available Updates|Loading") -AND $ie.documenT.title -MATCH "Nutanix|Prism Central") -or $count1 -ge 10 )  
  if ($count1 -ge 52){

    write-log -message "We failed loading the PC page after 26 minutes"

  }
  if ($ie.document.IHTMLDocument2_body.outerhtml -match "Manage Dashboards|OK, got it|Available Updates|Loading" -or $ie.document.IHTMLDocument2_body.outerhtml -match "Available Updates" ){
    if ($debug -ge 1){;

      write-log -message "We are already logged in"

    };
  };
  if ($ie.document.IHTMLDocument2_body.outerhtml -notmatch "Manage Dashboards|OK, got it|Available Updates|Loading" -and $ie.document.IHTMLDocument2_body.innerhtml -notmatch "company"){;
    $doc.IHTMLDocument3_getElementsByTagName("Input") | % {;
      if ($_.id -ne $null){;
        if ($_.id.Contains($LoginButton_ID)) { $Button = $_ };
        if ($_.id.Contains($PasswordField_ID)) { $webPassword = $_ };
        if ($_.id.Contains($UsenameField_ID)) { $webUsername = $_ };
      };
    };
    if ($webPassword) {;
      if ($debug -ge 1){;

        write-log -message "Site not logged in yet. Starting login procedure.";

        sleep $IEDelay;
        sleep $IEDelay;
  

        write-log -message "Trying Given creds";      
      };
      $webPassword.value = "$clpassword";
      $webUsername.value  = "$clusername";
      $Button.click();
      sleep $IEDelay;
      if ($ie.document.IHTMLDocument2_body.innerhtml -match "invalid username or password"){;
        if ($debug -ge 1){;

          write-log -message "Password Error." -sev "WARN" 

        };
      };
    };
  } else {;
    if ($debug -ge 1){;

      write-log -message "Site is already logged in";

    };
  };
  if ($debug -ge 1){;

    write-log -message "Moving Passed Login Page";

  }
  sleep $IEDelay;
  
  if ($ie.document.IHTMLDocument2_body.outerhtml -match "OK, got it"){;
    if ($debug -ge 1){;
      write-log -message "Bypassing Seach Helper";
    };
    $searchHelper = ($doc.IHTMLDocument3_getElementsByTagName("A") | where {  $_.outerhtml -match "OK, Got It"}).click()
  } else {
    if ($debug -ge 1){;
      write-log -message "Bypassing Seach Helper not required.";
    };    
  };
  
  if ($mode -eq "stage1"){
    $LCMTrigger =  0
    do {
      $LCMTrigger++

      write-log -message "Expanding Options dropdown and performing inventory.";
    
      try {
        ($doc.IHTMLDocument3_getElementsByTagName("Button") | where {$_.textContent -match "Options"}).click()
        while($ie.Busy){;
          Sleep -m 100;
        };
        sleep $IEDelay;
      
        write-log -message "Drop down selected";
        ($doc.IHTMLDocument3_getElementsByTagName("A") | where {$_.textContent -match "Perform"}).click()
        while($ie.Busy){;
          Sleep -m 100;
        };
        sleep $IEDelay;
        write-log -message "Inventory started.";
      } catch {
        write-log -message "There is no Options dropdown at this time, this is unexpected, retry.";
        do {
         $countoptions++
          try {
            $ie.quit();
            $ie = new-object -ComObject "InternetExplorer.Application";
            $requestUri = "https://$($PCClusterIP):9440/console/#page/explore/settings/lcm_entity";
            $ie.navigate($requestUri);
            sleep $IEDelay;
            ($doc.IHTMLDocument3_getElementsByTagName("Button") | where {$_.textContent -match "Options"}).click()
            while($ie.Busy){;
              Sleep -m 100;
            };
            sleep $IEDelay;
            $optionssuccess = 1
           ($doc.IHTMLDocument3_getElementsByTagName("A") | where {$_.textContent -match "Perform"}).click()
           while($ie.Busy){;
             Sleep -m 100;
           };
           sleep $IEDelay;
           } catch {
             write-log -message "There is still Options dropdown at this time, this is unexpected, retry.";         
           }
        } until ($optionssuccess -eq 1 -or $countoptions -eq 5)
      }
      $countwaitinventory = 0
    
      try {
    
        write-log -message "Auto updating LCM";
    
        ($doc.IHTMLDocument3_getElementById("lcm-auto-update-enabled")).checked = $true
        while($ie.Busy){;
          Sleep -m 100;
        };
        sleep $IEDelay;
    
        write-log -message "Submit for completion"; 
    
        ($doc.IHTMLDocument3_getElementsByTagName("Button") | where {$_.textContent -match "OK"}).click()
        while($ie.Busy){;
          Sleep -m 100;
        };
      } catch {
    
        write-log -message "Not my first time";
    
      }
      $countsearching = 0
      sleep 40
      do {
        $countsearching++
        try {
  
          write-log -message "Refreshing IE to check its LCM status";
          
          sleep $IEDelay;
          $ie.Refresh()
          sleep $IEDelay;
          while($ie.Busy){;
            Sleep -m 100;
          };
          sleep 20
          $var = ($ie.document.IHTMLDocument2_body.outerhtml | where { $_ -match "The LCM Inventory operation is in progress"})
          
          
  
          if ($var){
  
            write-log -message "LCM is updating";
            $LCMSearch = 1
  
          } else {
  
            write-log -message "I am not of this world.";
  
          }
  
        } catch {
          $ie.quit();
          $ie = new-object -ComObject "InternetExplorer.Application";
          $requestUri = "https://$($PCClusterIP):9440/console/#page/explore/settings/lcm_entity";
          $ie.navigate($requestUri);
          write-log -message "LCM Inventory is not running." -sev "WARN";    
        }
      } until (($LCMSearch -eq 1 -and $var) -or $countsearching -ge 5)
  
      $avail = "Searching"
    } until ($LCMSearch -eq 1 -or $LCMTrigger -eq 2)
  } else {
    do { 
      $countwaitinventory++ 
      sleep 50
      $ie.navigate($requestUri);
      while($ie.Busy){;
        Sleep -m 100;
      };
      sleep $IEDelay;
      $updates = $ie.document.IHTMLDocument2_body.innerhtml | Where { $_ -match "Available Updates" } 
    } until ($countwaitinventory -ge 3 -or $updates -match "Available Updates");
  
    if ($updates -match "Available Updates"){
      write-log -message "LCM Inventory done.";
    }
  
    write-log -message "Executing Prism Central LCM Updates";
  
    do{
      $countupdates++
      try {
  
        ($doc.IHTMLDocument3_getElementsByTagName("Button") | where {$_.textContent -match "Update All"}).click()
        while($ie.Busy){;
          Sleep -m 100;
        };
        
        sleep 20
        $nrofupdates = ($doc.IHTMLDocument3_getElementsByTagName("Button") | where {$_.textContent -match "Apply.*"}).textcontent
        $nrofupdates = $nrofupdates.split(" ")[1]
  
        write-log -message "We found $nrofupdates";
        write-log -message "Executing All Updates";
  
        $avail = "success"
        ($doc.IHTMLDocument3_getElementsByTagName("Button") | where {$_.textContent -match "Apply.*"}).click()
        sleep 20
  
      } catch {
        while($ie.Busy){;
          Sleep -m 100;
        };
        $ie.quit()
        $ie = new-object -ComObject "InternetExplorer.Application";
        $ie.navigate($requestUri);
        sleep 20
  
        write-log -message "There are no updates available.";
    
      }
    } until ($countupdates -ge 3 -or $avail -eq "Success" )
    
  }

  if ($debug -ge 1){
    write-log -message "Were done here.";
    write-host "Stopping at $(get-date) ";
  };
  if ($debug -ge 3){
    Write-Host "Please close IE manually.";
  } else {;
    while($ie.Busy){;
      Sleep -m 100;
    };
    $ie.quit();
  };
  if ($avail -eq "Success"){
    $status = "Success"

    write-log -message "All Done here, All Updates executed";
    write-log -message "Please pump me full of JSON.";

  } elseif ($avail -eq "Searching"){

    write-log -message "Ill be back!";  

  } else {
    $status = "Failed"
    write-log -message "Danger Will Robbinson." -sev "ERROR";
  }
  $resultobject =@{
    Result = $status
  };
  return $resultobject
};

Export-ModuleMember *