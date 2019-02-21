Function LIB-Config-DetailedDataSet {
  param (
  	[string] $ClusterPE_IP,
  	[string] $POCNAME,
  	[string] $debug,
  	[string] $Sendername
  )
  $Nw1name            = "Automation-Network-01";
  $Nw2name            = "Automation-Network-02";
  $StoragePoolName    = "SP01";
  $ImagesContainerName= "Images";
  $DisksContainerName = "Default";
  $DC_ImageName       = "Windows 2012";
  $SysprepPassword    = "Maandag01";
  $SENAME             = "$Sendername";
  $SEROLE             = "Systems Engineer";
  $SECompany          = "Nutanix";
  $EnablePulse        = 0;
  $Filesversion       = "AutoDetect"
  $smtpSender         = "$($POCNAME)-cluster@nutanix.com"
  $smtpport           = "25"
  $smtpServer         = "mxb-002c1b01.gslb.pphosted.com"
  $Supportemail       = "Michell.Grauwmans@nutanix.com"

  [int]$startingIP = $ClusterPE_IP.split(".") | select -last 1;
  [Array]$mask = $ClusterPE_IP.split(".") | select -first 3;

  write-log -message "Deducting IPs";
  write-log -message "Generating names";

  $DataIPoctet = $startingIP + 1;
  $NLBIPOctet  = $startingIP + 2;
  $PCCLIPoctet = $startingIP + 3;
  $PCN1IPoctet = $startingIP + 4;
  $PCN2IPoctet = $startingIP + 5;
  $PCN3IPoctet = $startingIP + 6;
  $DC1IPoctet  = $startingIP + 8;
  $DC2IPoctet  = $startingIP + 9;
  $FS1IntIPoctetstart  = $startingIP + 10;
  $FS1IntIPoctetend    = $startingIP + 13;
  $FS1extIPoctetstart  = $startingIP + 14;
  $FS1extIPoctetend    = $startingIP + 16;
  $DHCPNW1Octetstart   = $startingIP + 17;
  $FS1_IntName = "FS1I-$($POCNAME)";
  $FS1_ExtName = "FS1E-$($POCNAME)";
  $PC1Name = "PC1-$($POCNAME)";
  $PC2Name = "PC2-$($POCNAME)";
  $PC3Name = "PC3-$($POCNAME)";
  $DC1Name = "DC1-$($POCNAME)";
  $DC2Name = "DC2-$($POCNAME)";
  $Domainname = "$($POCNAME).nutanix.local";
  [string]$DataIP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DataIPoctet
  [string]$PCCLIP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCCLIPoctet
  [string]$PCN1IP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCN1IPoctet
  [string]$PCN2IP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCN2IPoctet
  [string]$PCN3IP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCN3IPoctet
  [string]$DC1IP      = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DC1IPoctet
  [string]$DC2IP      = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DC2IPoctet
  [string]$FS1IntIPst = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1IntIPoctetstart
  [string]$FS1IntIPend= $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1IntIPoctetend
  [string]$FS1ExtIPst = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1extIPoctetstart
  [string]$FS1ExtIPend= $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1extIPoctetend 
  [string]$NW1DHCPStar= $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DHCPNW1Octetstart
  [string]$IISNLBIP   = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $NLBIPOctet
  $FS1IntRange  = "$FS1IntIPst $FS1IntIPend"
  $FS1ExtRange  = "$FS1ExtIPst $FS1ExtIPend"
  $Object = New-Object PSObject;
  $Object | add-member Noteproperty DataServicesIP      $DataIP;
  $Object | add-member Noteproperty PCClusterIP         $PCCLIP;
  $Object | add-member Noteproperty PCNode1IP           $PCN1IP;
  $Object | add-member Noteproperty PCnode2IP           $PCN2IP;
  $Object | add-member Noteproperty PCnode3IP           $PCN3IP;
  $Object | add-member Noteproperty PCNode1Name         $PC1Name;
  $Object | add-member Noteproperty PCNode2Name         $PC2Name;
  $Object | add-member Noteproperty PCNode3Name         $PC3Name;
  $Object | add-member Noteproperty DC1IP               $DC1IP;
  $Object | add-member Noteproperty DC2IP               $DC2IP;
  $Object | add-member Noteproperty DC1Name				      $DC1Name;
  $Object | add-member Noteproperty DC2Name				      $DC2Name;   
  $Object | add-member Noteproperty Domainname			    $Domainname;   
  $Object | add-member Noteproperty Nw1name             $Nw1name;
  $Object | add-member Noteproperty Nw2name             $Nw2name 
  $Object | add-member Noteproperty DC_ImageName        $DC_ImageName;
  $Object | add-member Noteproperty SysprepPassword     $SysprepPassword;
  $Object | add-member Noteproperty SENAME              $SENAME;
  $Object | add-member Noteproperty SEROLE              $SEROLE;
  $Object | add-member Noteproperty SECompany           $SECompany;
  $Object | add-member Noteproperty EnablePulse         $EnablePulse;
  $object | add-member Noteproperty Filesversion        $Filesversion;
  $object | add-member Noteproperty FS1_IntName         $FS1_IntName;
  $object | add-member Noteproperty FS1_ExtName         $FS1_ExtName;
  $Object | add-member Noteproperty FS1IntRange         $FS1IntRange;
  $object | add-member Noteproperty FS1ExtRange         $FS1ExtRange;
  $Object | add-member Noteproperty NW1DHCPStart        $NW1DHCPStar; 
  $Object | add-member Noteproperty StoragePoolName     $StoragePoolName;
  $object | add-member Noteproperty ImagesContainerName $ImagesContainerName;
  $Object | add-member Noteproperty DisksContainerName  $DisksContainerName;
  $Object | add-member Noteproperty smtpSender          $smtpSender  
  $object | add-member Noteproperty smtpport            $smtpport    
  $Object | add-member Noteproperty smtpServer          $smtpServer  
  $Object | add-member Noteproperty IISNLBIP            $IISNLBIP 
  $Object | add-member Noteproperty Supportemail        $Supportemail
  return $object
}
Export-ModuleMember *
