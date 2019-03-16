Function Get-IncommingueueItem{
  param(
    [string] $queuepath,
    [string] $modulepath,
    [string] $AutoQueueTimer,
    [string] $ready,
    [string] $Incoming,
    [string] $manual
    )
  ## Version 2.0
  $item = $null
  write-host "$(get-date -format "hh:mm:ss") | INFO  | Terminating leftover outlook."
  get-process outlook | stop-process -ea:0
  write-host "$(get-date -format "hh:mm:ss") | INFO  | Applying Outlook Settings."
  reg import "C:\HostedPocProvisioningService\Binaries\Outlook.reg"
  write-host "$(get-date -format "hh:mm:ss") | INFO  | Starting outlook."
  Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null 
  $olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type] 
  write-host "$(get-date -format "hh:mm:ss") | INFO  | Assemblies set, starting COM." 
  $outlook = new-object -comobject outlook.application 
  $namespace = $outlook.GetNameSpace("MAPI") 
  write-host "$(get-date -format "hh:mm:ss") | INFO  | COMS started, locating folders."
  $folders = $namespace.Folders.item(2).folders
  $folder = $folders | where {$_.FolderPath -eq "\\michell.grauwmans@nutanix.com\Foundation"}
  write-host "$(get-date -format "hh:mm:ss") | INFO  | Mailbox loaded checking items."
  $PCmode                = "3 Node" ### TODO 
  $item = $folder.items | select -first 1
  if ($item){
    write-host "$(get-date -format "hh:mm:ss") | INFO  | We found 1 item to process."
    $DemoLab = 1
    $EnableFlow = 1
    $DemoXenDeskT = 1
    $InstallEra = 1
    $DemoExchange = 1
    $InstallKarbon = 1
    $DemoIISXPlay = 1
    $InstallFiles = 1
    $slackbot = 0
    $SetupSSP = 1
    $Move = 1
    $debug = 1
    $pcmode = 3
    $Body = $item.body
    $Body = $Body -split "\n"
    $Sender = $item.SENDERname
    $email = $item.SenderEmailAddress
    if ($email -match "="){
      $email = ($item.sender.GetExchangeUser()).primarysmtpaddress
    }
    $separator = @(': ')
    $PECreds = ($Body | where {$_ -match "^Prism UI Credentials"}).replace('Prism UI Credentials: ', '')
    $PEAdmin = $PECreds.split("/")[0]
    $PEPass  = $PECreds.split("/")[1] -replace ("`r",'')
    $VPNUser = ($Body | where {$_ -match ".*VPN User Accounts: (.*),"}) -replace ".*VPN User Accounts: (.*),.*", '$1'
    $VPNPass = ($Body | where {$_ -match ".*VPN User Password: (.*)`r|`n"}) -replace ".*VPN User Password: (.*)`r|`n", '$1'
    $VPNURL = ((($Body | where {$_ -match "^Server URL: (.*)`r|`n"}) -replace "^Server URL: (.*)`r|`n", '$1') -split (" "))[0]
    $InfraSubnetmask = ($Body | where {$_ -match "^Subnet Mask:"}).replace('Subnet Mask: ', '') -replace ("`r",'')
    $InfraGateway = ($Body | where {$_ -match "^Gateway:"}).replace('Gateway: ', '') -replace ("`r",'')
    $DNSServer = ($Body | where {$_ -match "^Nameserver IP"}).replace('Nameserver IP: ', '') -replace ("`r",'')
    $nw1vlan = 0 
    $nw2vlan = ($Body | where {$_ -match "^Secondary VLAN"}).replace('Secondary VLAN: ', '') -replace ("`r",'')
    $nw2subnet =  ($Body | where {$_ -match "^Secondary Subnet"}).replace('Secondary Subnet: ', '') -replace ("`r",'')
    $nw2gw = ($Body | where {$_ -match "^Secondary Gateway"}).replace('Secondary Gateway: ', '') -replace ("`r",'')
    $nw2dhcp =  ($Body | where {$_ -match "^Secondary IP Range"}).replace('Secondary IP Range: ', '') -replace ("`r",'')
    $nw2dhcpstart = ($nw2dhcp -split ("-"))[0]
    if ($body -match "cluster RTP-"){
      $POCname = (($Body | where {$_ -match "^Your Reservation Information for"}) -replace('Your Reservation Information for.*RTP-POC', 'RTP-POC')) -replace (" \(.*",'')
    } elseif ($body -match "cluster PHX-")  {
      $POCname = (($Body | where {$_ -match "^Your Reservation Information for"}) -replace('Your Reservation Information for.*PHX-POC', 'PHX-POC')) -replace (" \(.*",'')
    } else {
      $POCname = (($Body | where {$_ -match "^Your Reservation Information for"}) -replace('Your Reservation Information for.*POC', 'POC')) -replace (" \(.*",'')
    }
    $Model = (($Body | where {$_ -match "^Your Reservation Information for"}) -replace ('Your Reservation Information for.*\((.*)\).*', '$1')) 
    [string]$PEClusterIP = ($Body | where {$_ -match "^Cluster IP: https"}).split("/")[2].split(":")[0];
    [int]$debug = 0;

    $Params = $body | select -first 15
    foreach ($line in $params){
      if ($line -match "^Debug:[0-9]"){
        $debug = $line -replace("^Debug:([0-9]).*", '$1')
      } 
      if ($line -match "^pcmode:[0-9]"){
        $pcmode = $line -replace("^pcmode:([0-9]).*", '$1')
      } 
      if ($line -match "^queue:manual"){
        $queue = "manual"
      } 
      if ($line -match "^karbon:[0-9]"){
        $InstallKarbon = $line -replace("^karbon:([0-9]).*", '$1')
      }
      if ($line -match "^era:[0-9]"){
        $InstallEra = $line -replace("^era:([0-9]).*", '$1')
      }
      if ($line -match "^exchange:[0-9]"){
        $DemoExchange = $line -replace("^exchange:([0-9]).*", '$1')
      }
      if ($line -match "^files:[0-9]"){
        $InstallFiles = $line -replace("^files:([0-9]).*", '$1')
      }
      if ($line -match "^flow:[0-9]"){
        $EnableFlow = $line -replace("^flow:([0-9]).*", '$1')
      }
      if ($line -match "^ssp:[0-9]"){
        $SetupSSP = $line -replace("^ssp:([0-9]).*", '$1')
      }
      if ($line -match "^iis:[0-9]"){
        $DemoIISXPlay = $lin -replace("^iis:([0-9]).*", '$1')
      }
      if ($line -match "^xd:[0-9]"){
        $DemoXenDeskT = $line -replace("^xd:([0-9]).*", '$1')
      }
      if ($line -match "^lab:[0-9]"){
        $DemoLab = $line -replace("^lab:([0-9]).*", '$1')
      }
      if ($line -match "^slackbot:[0-9]"){
        $slackbot = $line -replace("^slackbot:([0-9]).*", '$1')
      }
      if ($line -match "^move:[0-9]"){
        $move = $line -replace("^move:([0-9]).*", '$1')
      }
      if ($line -match "^pcversion:"){
        $DemoLab = $line.split(":")[1];
      } else {
        $PCVersion = "Latest"
      }

    }


    $HYPERvISOR = $body | where { $_ -match "Hypervisor Version:"};
    $HYPERvISOR = ($HYPERvISOR -split(": "))[1];
    if ($hypervisor -match "AHV"){;
      $hypervisor = $hypervisor -replace (".*\((.*)\)", 'AHV $1');
      $hypervisor = $hypervisor -replace ("`r",'');
    };
    $aos = $body | where { $_ -match "AOS Version:"};
    $aos = ($aos -split(": "))[1];
    $aos = $aos -replace ("`r",'');
    if ($aos -eq $null -or $aos.length -lt 3){;
      $aos = "GPU Node";
    };

    $nw1vlan = 0
    $Region = "US"
    $Ver = "AOS"
    $date = get-date;
    $Guid = [guid]::newguid();
    $Object = New-Object PSObject;
    $Object | add-member Noteproperty DateCreated         $date;
    $Object | add-member Noteproperty PEClusterIP         $PEClusterIP;
    $Object | add-member Noteproperty SenderName          $Sender;
    $Object | add-member Noteproperty SenderEMail         $email;
    $Object | add-member Noteproperty PEAdmin             $PEAdmin;
    $Object | add-member Noteproperty PEPass              $PEPass;
    $Object | add-member Noteproperty debug               $debug;
    $Object | add-member Noteproperty AOSVersion          $aos;
    $Object | add-member Noteproperty PCVersion           $PCVersion;
    $Object | add-member Noteproperty Hypervisor          $hypervisor;
    $Object | add-member Noteproperty InfraSubnetmask     $InfraSubnetmask;
    $Object | add-member Noteproperty InfraGateway        $InfraGateway;
    $Object | add-member Noteproperty DNSServer           $DNSServer;
    $object | add-member Noteproperty POCname             $POCname;
    $object | add-member Noteproperty PCmode              $PCmode;
    $object | add-member Noteproperty AutoQueueTimer      $AutoQueueTimer;
    $object | add-member Noteproperty SystemModel         $Model;
    $object | add-member Noteproperty Nw1Vlan             $nw1vlan;
    $object | add-member Noteproperty Nw2DHCPStart        $nw2dhcpstart;
    $object | add-member Noteproperty Nw2Vlan             $nw2vlan;
    $object | add-member Noteproperty Nw2subnet           $nw2subnet;
    $object | add-member Noteproperty Nw2gw               $nw2gw;
    $object | add-member Noteproperty Location            $Region;
    $object | add-member Noteproperty VersionMethod       $ver;    
    $object | add-member Noteproperty VPNUser             $VPNUser;
    $object | add-member Noteproperty VPNPass             $VPNPass;
    $object | add-member Noteproperty VPNURL              $VPNURL;
    $object | add-member Noteproperty SetupSSP            $SetupSSP;
    $object | add-member Noteproperty DemoLab             $DemoLab;
    $object | add-member Noteproperty EnableFlow          $EnableFlow;
    $object | add-member Noteproperty DemoXenDeskT        $DemoXenDeskT;
    $object | add-member Noteproperty InstallEra          $InstallEra;
    $object | add-member Noteproperty InstallMove         $move
    $object | add-member Noteproperty DemoExchange        $DemoExchange;
    $object | add-member Noteproperty InstallKarbon       $InstallKarbon;
    $object | add-member Noteproperty DemoIISXPlay        $DemoIISXPlay;
    $object | add-member Noteproperty InstallFiles        $InstallFiles;
    $object | add-member Noteproperty slackbot            $slackbot;
    $object | add-member Noteproperty move                $move;
    $object | add-member Noteproperty UUID                $Guid.Guid;
    $item.delete()
    if ($queue -eq "Manual"){
      $object | export-csv "$($queuepath)\$($Manual)\$($POCname)-$($Guid.Guid).queue"
    } else {
      $object | export-csv "$($queuepath)\$($Incoming)\$($POCname)-$($Guid.Guid).queue"
    }
    sleep 5
    $outlook.quit()
    return $object 
  };
};