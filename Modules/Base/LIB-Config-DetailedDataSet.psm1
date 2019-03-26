Function LIB-Config-DetailedDataSet {
  param (
    [object] $datavar,
    [string] $basedir
  )
  $Nw1name            = "Automation-Network-01";
  $Nw2name            = "Automation-Network-02";
  $StoragePoolName    = "SP01";
  $ImagesContainerName= "Images";
  $DisksContainerName = "Default";
  $EraContainerName   = "ERA_01";
  $KarbonContainerName= "Karbon_01"
  $DC_ImageName       = "Windows 2012";
  $MoveImageName      = "Move";
  $oracle1_0Image     = "Oracle_1_0"
  $oracle1_1Image     = "Oracle_1_1"
  $oracle1_2Image     = "Oracle_1_2"
  $MSSQLImage         = "MSSQL-2016-VM"
  $ERA_ImageName      = "ERA";
  $SysprepPassword    = "Maandag01";
  $SENAME             = "$($datavar.Sendername)";
  $SEROLE             = "Systems Engineer";
  $SECompany          = "Nutanix";
  $EnablePulse        = 0;
  $Filesversion       = "AutoDetect"
  $smtpSender         = "$($datavar.POCname)-cluster@nutanix.com"
  $smtpport           = "25"
  $smtpServer         = "mxb-002c1b01.gslb.pphosted.com"
  $Supportemail       = "Michell.Grauwmans@nutanix.com"

  [int]$startingIP = $($datavar.PEClusterIP).split(".") | select -last 1;
  [Array]$mask = $($datavar.PEClusterIP).split(".") | select -first 3;

  $SSHKeys = Lib-Generate-SSHKey -datavar $datavar -basedir $basedir

  write-log -message "Deducting IPs";
  write-log -message "Generating names";

  $DataIPoctet = $startingIP + 1;
  $NLBIPOctet  = $startingIP + 2;
  $PCCLIPoctet = $startingIP + 3;
  $PCN1IPoctet = $startingIP + 4;
  $PCN2IPoctet = $startingIP + 5;
  $PCN3IPoctet = $startingIP + 6;
  $ERA1IPoctet = $startingIP + 7;
  $DC1IPoctet  = $startingIP + 8;
  $DC2IPoctet  = $startingIP + 9;
  $FS1IntIPoctetstart  = $startingIP + 10;
  $FS1IntIPoctetend    = $startingIP + 13;
  $FS1extIPoctetstart  = $startingIP + 14;
  $FS1extIPoctetend    = $startingIP + 16;
  $MSSQLIPoctet        = $startingIP + 17;
  $MOVEIPoctet         = $startingIP + 29;
  $DHCPNW1Octetstart   = $startingIP + 31;
  $OracleIPOctet       = $startingIP + 30;
  $Karbonoctetstart    = $startingIP + 18;
  $Karbonoctetend      = $startingIP + 28;
  $FS1_IntName = "FS1I-$($datavar.POCname)";
  $FS1_ExtName = "FS1E-$($datavar.POCname)";
  $PC1Name = "PC1-$($datavar.POCname)";
  $PC2Name = "PC2-$($datavar.POCname)";
  $PC3Name = "PC3-$($datavar.POCname)";
  $ERA1Name= "ERA1-$($datavar.POCname)";
  $MoveName= "Move1-$($datavar.POCname)";
  $MSSQL1  = "MSSQL1-$($datavar.POCname)";
  $SRVMaria= "Maria1-$($datavar.POCname)";
  $SRVOracl= "Oracle1-$($datavar.POCname)";
  $PostGres= "PostG1-$($datavar.POCname)";
  $DC1Name = "DC1-$($datavar.POCname)";
  $DC2Name = "DC2-$($datavar.POCname)";
  $Domainname = "$($datavar.POCname).nutanix.local";
  [string]$DataIP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DataIPoctet
  [string]$PCCLIP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCCLIPoctet
  [string]$PCN1IP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCN1IPoctet
  [string]$PCN2IP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCN2IPoctet
  [string]$PCN3IP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $PCN3IPoctet
  [string]$ERA1IP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $ERA1IPoctet
  [string]$moveIP     = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $MOVEIPoctet
  [string]$MSSQLIP    = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $MSSQLIPoctet
  [string]$OracleIP   = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $OracleIPOctet
  [string]$DC1IP      = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DC1IPoctet
  [string]$DC2IP      = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DC2IPoctet
  [string]$FS1IntIPst = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1IntIPoctetstart
  [string]$FS1IntIPend= $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1IntIPoctetend
  [string]$FS1ExtIPst = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1extIPoctetstart
  [string]$FS1ExtIPend= $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $FS1extIPoctetend
  [string]$KarbonStart= $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $Karbonoctetstart 
  [string]$KarbonEnd  = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $Karbonoctetend 
  [string]$NW1DHCPStar= $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $DHCPNW1Octetstart
  [string]$IISNLBIP   = $mask[0] + '.' + $mask[1] + '.' + $mask[2] + '.' + $NLBIPOctet
  $FS1IntRange  = "$FS1IntIPst $FS1IntIPend"
  $FS1ExtRange  = "$FS1ExtIPst $FS1ExtIPend"
  $karbonrange  = "$($KarbonStart)-$($KarbonEnd)"
  $Object = New-Object PSObject;
  $Object | add-member Noteproperty DataServicesIP      $DataIP;
  $Object | add-member Noteproperty PCClusterIP         $PCCLIP;
  $Object | add-member Noteproperty PCNode1IP           $PCN1IP;
  $Object | add-member Noteproperty PCnode2IP           $PCN2IP;
  $Object | add-member Noteproperty PCnode3IP           $PCN3IP;
  $Object | add-member Noteproperty PCNode1Name         $PC1Name;
  $Object | add-member Noteproperty PCNode2Name         $PC2Name;
  $Object | add-member Noteproperty PCNode3Name         $PC3Name;
  $Object | add-member Noteproperty ERA1Name            $ERA1Name;
  $Object | add-member Noteproperty ERA1IP              $ERA1IP;
  $Object | add-member Noteproperty DC1IP               $DC1IP;
  $Object | add-member Noteproperty DC2IP               $DC2IP;
  $Object | add-member Noteproperty DC1Name				      $DC1Name;
  $Object | add-member Noteproperty DC2Name				      $DC2Name;   
  $Object | add-member Noteproperty Domainname			    $Domainname;   
  $Object | add-member Noteproperty Nw1name             $Nw1name;
  $Object | add-member Noteproperty Nw2name             $Nw2name;
  $Object | add-member Noteproperty MoveIP              $moveIP;
  $Object | add-member Noteproperty Move_ImageName      $MoveImageName;
  $Object | add-member Noteproperty Move_VMName         $MoveName
  $Object | add-member Noteproperty DC_ImageName        $DC_ImageName;
  $Object | add-member Noteproperty ERA_ImageName       $ERA_ImageName;
  $Object | add-member Noteproperty ERA_MSSQLIP         $MSSQLIP;
  $Object | add-member Noteproperty ERA_MSSQLName       $MSSQL1;
  $Object | add-member Noteproperty ERA_MSSQLImage      $MSSQLImage;    
  $Object | add-member Noteproperty ERA_MariaName       $SRVMaria;
  $Object | add-member Noteproperty ERA_PostGName       $PostGres;
  $Object | add-member Noteproperty EraContainerName    $EraContainerName;
  $Object | add-member Noteproperty Oracle1_0Image      $oracle1_0Image  
  $Object | add-member Noteproperty Oracle1_1Image      $oracle1_1Image  
  $Object | add-member Noteproperty Oracle1_2Image      $oracle1_2Image 
  $Object | add-member Noteproperty OracleIP            $OracleIP
  $Object | add-member Noteproperty Oracle_VMName       $SRVOracl
  $Object | add-member Noteproperty KarbonContainerName $KarbonContainerName;
  $Object | add-member Noteproperty KarbonIPRange       $karbonrange;
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
  $Object | add-member Noteproperty PrivateKey          $SSHKeys.Private 
  $Object | add-member Noteproperty PublicKey           $SSHKeys.Public 
  return $object
}
Export-ModuleMember *
