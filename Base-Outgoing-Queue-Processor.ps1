param (
  $prodmode = "0"
)

$logging               = "C:\HostedPocProvisioningService\Jobs\Prod"
$loggingdev            = "C:\HostedPocProvisioningService\Jobs\Dev"
$Archivelogingdir      = "C:\HostedPocProvisioningService\Jobs\Archive"
$ModuleDir             = "C:\HostedPocProvisioningService\Modules\base"
$daemons               = "C:\HostedPocProvisioningService\Daemons"
$Lockdir               = "C:\HostedPocProvisioningService\Lock"
$queuepath             = "C:\HostedPocProvisioningService\Queue"
$basedir               = "C:\HostedPocProvisioningService"
$BlueprintsPath        = "C:\HostedPocProvisioningService\BluePrints"
$ArchiveQueue          = "Archive"
$OutgoingQueue         = "Outgoing" 
$SingleModelck         = "$($Lockdir)\Single.lck"

### Loading assemblies
add-type @"
  using System.Net;
  using System.Security.Cryptography.X509Certificates;
  public class TrustAllCertsPolicy : ICertificatePolicy {
      public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate,
                                        WebRequest request, int certificateProblem) {
          return true;
      }
   }
"@
 
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12
if ( (Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue) -eq $null ) {
  Add-PsSnapin NutanixCmdletsPSSnapin -ErrorAction Stop
}
Get-SSHTrustedHost | Remove-SSHTrustedHost

### Import Modules

Import-Module "$($ModuleDir)\CMD-Add-PEtoPC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-AutoDetectVersions.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Create-FS.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Create-FSShares.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Join-Px-to-Win-Domain.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMDPSR-Create-VM.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Create-VM.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Set-DataServicesIP.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Set-SMTPServerSettings.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Upload-ISOImages.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\CMD-Wait-ImageUpload.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Config-DetailedDataSet.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Config-ISOurlData.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Connect-NutanixVPN.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Connect-PSNutanix.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Lib-Check-Thread.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-IPAddressMath.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Get-OutgoingQueueItem.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Lib-Generate-SSHKey.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Send-Confirmation.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Server-SysprepXML.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Spawn-Wrapper.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-REST-Tools.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Test-ClusterPrereq.psm1"  -DisableNameChecking;
Import-Module "$($ModuleDir)\LIB-Write-Log.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\PSR-Add-DomainController.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\PSR-Create-Domain.psm1" -DisableNameChecking; 
Import-Module "$($ModuleDir)\PSR-ERA-ConfigureMSSQL.psm1" -DisableNameChecking; 
Import-Module "$($ModuleDir)\PSR-Generate-DomainContent.psm1" -DisableNameChecking; 
Import-Module "$($ModuleDir)\PSR-Join-Domain.psm1" -DisableNameChecking; 
Import-Module "$($ModuleDir)\REST-Enable-Calm-PE.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-Enable-Flow-PE.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-Enable-Karbon-PC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-ERA-ResetPass.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-Finalize-Px.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-Image-Import-PC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-Install-PC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-LCM-Inventory-Px.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\REST-WorkShopConfig-Px.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\RPA-LCM-Inventory.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-Manage-SoftwarePE.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-Unlock-XPlay.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-ResetPass-Px.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-RoleMapping-Px.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-Networking-Pe.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-Startup-Oracle.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-Oracle-InsertDemo.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\SSH-Storage-Pe.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-PC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Create-SSP-Groups-Projects.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Import-XPlay-Demo.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-Era-Base.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-Era-MSSQL.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-Era-Oracle.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-Splunk.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-HashiCorpVault.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-3TierWin.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Post-PC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Install-Second-DC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Update-PC-REST.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Create-ADForest-PC.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Create-KarbonCluster.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Slack-Log.psm1" -DisableNameChecking;
Import-Module "$($ModuleDir)\Wrap-Import-Move-Demo.psm1" -DisableNameChecking;


#-----End Loader-----

$exit = 0 
$exitcount = 0
$daemonID = ([guid]::newguid()).guid

### Cleanup just at daemon start.
$items = get-item "$($daemons)\*.thread" | where {$_.lastwritetime -lt (Get-Date).addminutes(-10)}
if ($items){
  try {
    Remove-item $items -force
  } catch {
  }
}


### Loop until there is work for you, then you die.
do {
  $alive = $null
  $singleusermode = (get-item $SingleModelck -ea:0).lastwritetime | where {$_ -ge (get-date).addminutes(-90)}
  if (!$singleusermode){
    $datavar = LIB-Get-OutgoingQueueItem -queuepath $queuepath -archive $ArchiveQueue -outgoing $OutgoingQueue -debug -prodmode $prodmode
  }
  $Incoming,
  $Archive
  $exitcount++
  if ($datavar){
    if ($datavar.debug -le 1){
      $logfile= "$($logging)\$($datavar.pocname)-$($datavar.UUID).log"
    } else {
      $logfile  = "$($loggingdev)\$($datavar.pocname)-$($datavar.UUID).log"
    }
    
    $lockfile = "$($Lockdir)\$($datavar.pocname)-base.lck"
    start-transcript -path $logfile
    ### Sysprep
    $ServerSysprepfile = LIB-Server-SysprepXML -Password $datavar.PEPass

    

    ### ISO Dirs
    $ISOurlData1 = LIB-Config-ISOurlData -region $datavar.Location
    $ISOurlData2 = LIB-Config-ISOurlData -region "Backup"

    ### Full Data Set
    $data = LIB-Config-DetailedDataSet -datavar $datavar -basedir $basedir
    $data.syspreppassword = $datavar.PEPass


    
    write-log -message "Working with Dynamic dataset:" -sev "CHAPTER"
    
    $datavar | fl
    
    write-log -message "Working with Generated dataset:" -sev "CHAPTER"
    
    $data | fl
   

    if ($datavar.slackbot -ge 1){

      write-log -message "Launching Slackbot" -sev "CHAPTER"

      $LauchCommand = 'Wrap-Slack-Log -datagen $datagen -datavar $datavar -basepath $basedir -ParentLogfile ' + "`"$logfile`""
      Lib-Spawn-Wrapper -Type "Slack" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Slack-Log.psm1" -LauchCommand $LauchCommand -debug $datavar.debug
    }

    write-log -message "Thread Started" -sev "CHAPTER"
    write-log -message "You are being served by Daemon ID $daemonID";
    write-log -message "Processing queue item ID $($datavar.UUID)";

    sleep 5     
    if ((get-item $lockfile -ea:0).lastwritetime -ge (get-date).addminutes(-90)){
      write-log -message "$($datavar.pocname) is still locked, what are you doing. Not accepting dual items in the queue, purging."
      LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $data -datavar $datavar -mode "Locked" -debug $datavar.debug -logfile $logfile
      stop-transcript
      break
    } else {
      write "Locked" | out-file $lockfile
    }

    write-log -message "Testing VPN Requirement" -sev "CHAPTER"

    $alive = LIB-Test-ClusterPrereq -PEClusterIP $datavar.PEClusterIP
    ### Try to build VPN if not reachable
    if ($alive.Result -eq "Failed"){;

      write-log -message "Cluster not reachable, entering single user mode to start VPN based provisioning.";
      write-log -message "Single User mode required, draining..."

      write "Locked" | out-file $SingleModelck
      
      do {
        $Active = (Get-item C:\HostedPocProvisioningService\Jobs\Active\*.log -ea:0) | where {$_.lastwritetime -gt (get-date).addminutes(-3) -and $_.fullname -ne $logfile} 
        if ($active) {

          write-log -message "Draining queue prior proceding in single user mode."
          write-log -message "Currently $($active.count) threads running, waiting."

        } else {

          write-log -message "Queue is drained, single user mode activated."

        }
        sleep 60 
      } until (!$Active)

      write-log -message "Starting VPN" -sev "CHAPTER"

      LIB-Connect-NutanixVPN -VPNUser $datavar.VPNUser -VPNPass $datavar.vpnpass -VPNURL $datavar.vpnurl -mode "start"
  
      $alive = LIB-Test-ClusterPrereq -PEClusterIP $datavar.PEClusterIP
    };
    if ($alive.Result -eq "Success"){

      LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $data -datavar $datavar -mode "start" -debug $datavar.debug

      write-log -message "Starting Foundation Addon" -sev "CHAPTER"

      write-log -message "Reset PE Password" -sev "CHAPTER"

      $status = SSH-ResetPass-Px -PxClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -debug $datavar.debug -mode "PE"
      Lib-Check-Thread -status $status.result -stage "Reset PE Password" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug

      if ($datavar.AOSVersion -eq "AutoDetect"){

        write-log -message "Autodetecting versions" -sev "CHAPTER"

        $result = CMD-AutoDetectVersions -peadmin $datavar.PEAdmin -pepass $datavar.PEPass -PEClusterIP $datavar.PEClusterIP
        $datavar.AOSVersion = $result.AOSVersion
        $datavar.SystemModel = $result.SystemModel
      } 

      write-log -message "Downloading Prism Element Addon Software SSH ncli" -sev "CHAPTER"
      
      $result = SSH-Manage-SoftwarePE -ClusterPE_IP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -PCversion $datavar.PCVersion -filesversion $data.FilesVErsion -debug $datavar.debug -MODEL $datavar.SystemModel -wait 0
      Lib-Check-Thread -status $Status.result -stage "Downloading Prism Element Addon Software SSH ncli" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug
      $datavar.PCVersion = $result.PCVersion -split ("`n") | select -last 1
      $data.filesversion = $result.filesversion -split ("`n") | select -last 1

      write-log -message "Setting up Networking" -sev "CHAPTER"

      $status = SSH-Networking-Pe -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -Domainname $data.domainname -nw1dhcpstart $data.NW1DHCPStart -nw1gateway $datavar.InfraGateway -nw1subnet $datavar.InfraSubnetmask -nw1vlan $datavar.nw1vlan -nw1name $data.nw1name -nw2name $data.nw2name -nw2dhcpstart $datavar.nw2dhcpstart -nw2vlan $datavar.nw2vlan -nw2subnet $datavar.nw2subnet -nw2gateway $datavar.nw2gw -DC1IP $data.DC1IP -DC2IP $data.DC2IP
      Lib-Check-Thread -status $status.result -stage "Setting up Networking" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug

      write-log -message "Setting up Storage" -sev "CHAPTER"

      $status = SSH-Storage-Pe -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -StoragePoolName $data.StoragePoolName -KarbonContainername $data.KarbonContainername -DisksContainerName $data.DisksContainerName -ImagesContainerName $data.ImagesContainerName -ERAContainerName $data.ERAContainerName
      Lib-Check-Thread -status $status.result -stage "Setting up Storage" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug

      write-log -message "Uploading ISO Images" -sev "CHAPTER"
      
      $STATUS = CMD-Upload-ISOImages -ISOurlDataPrimair $ISOurlData1 -ISOurlDataBackup $ISOurlData2 -debug $datavar.debug -peadmin $datavar.PEAdmin -pepass $datavar.PEPass -PEClusterIP $datavar.PEClusterIP -ContainerName $data.ImagesContainerName -dcimage $data.DC_ImageName
      Lib-Check-Thread -status $status.result -stage "Uploading ISO Images" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug

      write-log -message "Prism Element Prep (REST)" -sev "CHAPTER"
      
      $Status = REST-Finalize-Px -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -ClusterPx_IP $datavar.PEClusterIP -debug $datavar.debug -sename $data.sename -serole $data.serole -SECompany $data.SECompany -EnablePulse $data.EnablePulse
      Lib-Check-Thread -status $Status.result -stage "Prism Element Prep (REST)" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug

      write-log -message "Running Prism Central Installer wrapper for Stage 1" -sev "CHAPTER"

      Wrap-Install-PC -datafixed $data -datavar $datavar -stage "1" -logfile $logfile
      sleep 30

      write-log -message "Checking Images Disk upload status" -sev "CHAPTER"

      $image = CMD-Wait-ImageUpload -imagename $data.DC_ImageName -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -region $datavar.location
      if ($image -match "Error"){
        stop-transcript
        LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $data -datavar $datavar -mode "FailedImages" -debug $datavar.debug
        break
      } 

      write-log -message "Creating First DC VM" -sev "CHAPTER"

      $VM1 = CMDPSR-Create-VM -mode "FixedIP" -DisksContainerName $data.DiskContainerName -Subnetmask $datavar.InfraSubnetmask -Sysprepfile $ServerSysprepfile -Networkname $data.Nw1Name -VMname $data.DC1Name -ImageName $data.DC_ImageName -cpu 4 -ram 4096 -VMip $data.DC1IP -VMgw $datavar.InfraGateway -DNSServer1 $data.DC1IP -DNSServer2 $data.DC2IP -SysprepPassword $data.SysprepPassword -debug $datavar.debug -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass

      write-log -message "Spawning Create Forest" -sev "CHAPTER"

      $LauchCommand = 'Wrap-Create-ADForest-PC -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile'
      Lib-Spawn-Wrapper -Type "Forest" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Create-ADForest-PC.psm1" -LauchCommand $LauchCommand -debug $datavar.debug
      sleep 10

      write-log -message "Set External Data Services IP" -sev "CHAPTER"

      CMD-Set-DataservicesIP -DataServicesIP $data.DataServicesIP -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass

      if ($datavar.DemoXenDeskT -eq 1 -or $datavar.InstallFiles -eq 1){
        if ($datavar.SystemModel -notmatch "^SX"){

          write-log -message "Setting up Files" -sev "CHAPTER"

          CMD-Create-FS -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -network $networkUUID -SysprepPassword $data.SysprepPassword -Networkname $data.Nw1Name -PocName $datavar.POCname -domainname $data.Domainname -DNSServer1 $data.DC1IP -DNSServer2 $data.DC2IP -debug $datavar.debug -gateway $datavar.InfraGateway -subnetmask $datavar.InfraSubnetmask -fsiprangeint $data.FS1IntRange -fsiprangeext $data.FS1ExtRange -fsnameInt $data.FS1_IntName -fsnameext $data.FS1_ExtName
          
        } else {

          write-log -message "Files is not supported on SX models."

        }
      }
      if ($datavar.InstallEra -eq 1){

        write-log -message "Spawning ERA Install" -sev "CHAPTER"

        $LauchCommand = 'sleep 60;Wrap-Install-Era-Base -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -basedir $basedir'
        Lib-Spawn-Wrapper -Type "ERA_Base" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Install-Era-Base.psm1" -LauchCommand $LauchCommand -debug $datavar.debug

      } 
      if ($datavar.DemoLab -eq 1){
 
        write-log -message "Installing Workshop Lab Settings Prism Element" -sev "CHAPTER"
       
        REST-WorkShopConfig-Px -ClusterPx_IP $datavar.PEClusterIP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -POCName $datavar.POCname -VERSION $datavar.PCVersion -Mode "PE"

      } 
      write-log -message "Uploading ISO Images" -sev "CHAPTER"

      $STATUS = CMD-Upload-ISOImages -ISOurlDataPrimair $ISOurlData1 -ISOurlDataBackup $ISOurlData2 -debug $datavar.debug -peadmin $datavar.PEAdmin -pepass $datavar.PEPass -PEClusterIP $datavar.PEClusterIP -ContainerName $data.ImagesContainerName -dcimage $data.DC_ImageName
      Lib-Check-Thread -status $status.result -stage "Uploading ISO Images" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug

      write-log -message "Running PC Installer Wrapper for Stage 2" -sev "CHAPTER"

      Wrap-Install-PC -datafixed $data -datavar $datavar -stage "2" -logfile $logfile

      write-log -message "Running Full LCM Prism Central Updates (REST)" -sev "CHAPTER"

      Wrap-Update-PC-REST -datagen $data -datavar $datavar -logfile $logfile

      write-log -message "Running PC Installer Wrapper for Post Install" -sev "CHAPTER"

      $LauchCommand = 'Wrap-Post-PC -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile'
      Lib-Spawn-Wrapper -Type "PostPC" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Post-PC.psm1" -LauchCommand $LauchCommand -debug $datavar.debug
      sleep 10

      write-log -message "Setting up Calm" -sev "CHAPTER"

      REST-Enable-Calm -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $data.PCClusterIP -debug $datavar.debug

      if ($datavar.DemoLab -eq 1){
 
        write-log -message "Installing Workshop Lab Settings Prism Central" -sev "CHAPTER"
       
        REST-WorkShopConfig-Px -ClusterPx_IP $data.PCClusterIP -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -POCName $datavar.POCname -VERSION $datavar.PCVersion -Mode "PC"

      } 
      if ($datavar.DemoXenDeskT -eq 1 -or $datavar.InstallFiles -eq 1){
        if ($datavar.SystemModel -notmatch "^SX"){

          write-log -message "Setting up shares" -sev "CHAPTER"

          CMD-Create-FSShares -PEClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -domainname $data.Domainname -debug $datavar.debug -syspreppassword $data.SysprepPassword
        } else {

          write-log -message "Files is not supported on SX models."

        }
      } 
      if ($datavar.DemoXenDeskT -eq 1){

        write-log -message "Installing XenDesktop Demo" -sev "CHAPTER"
        write-log -message "Not implemented"    
      
      }

      if ($datavar.InstallMove -eq 1){

        write-log -message "Installing Move" -sev "CHAPTER"
        $LauchCommand = 'Wrap-Import-Move-Demo -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -BlueprintsPath ' + $BlueprintsPath
        Lib-Spawn-Wrapper -Type "Move" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Import-Move-Demo.psm1" -LauchCommand $LauchCommand -debug $datavar.debug
        sleep 10
        write-log -message "Spawning Karbon Cluster" -sev "CHAPTER"
        
      }

      if ($datavar.InstallKarbon -eq 1){

        write-log -message "Installing Karbon" -sev "CHAPTER"
        $LauchCommand = 'Wrap-Create-KarbonCluster -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -BlueprintsPath ' + $BlueprintsPath
        Lib-Spawn-Wrapper -Type "Karbon" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Create-KarbonCluster.psm1" -LauchCommand $LauchCommand -debug $datavar.debug
        sleep 10
        write-log -message "Spawning Karbon Cluster" -sev "CHAPTER"
        
      }

      if ($datavar.DemoIISXPlay -eq 1){

        write-log -message "Installing XPlay IIS CPU Scaling" -sev "CHAPTER"
        
        $demo = Wrap-Import-XPlay-Demo -datagen $data -datavar $datavar -BlueprintsPath $BlueprintsPath -basedir $basedir -debug $datavar.debug

      }
      if ($datavar.InstallSplunk -eq 1){

        write-log -message "Spawning Splunk Install" -sev "CHAPTER"

        $LauchCommand = 'Wrap-Install-Splunk -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -basedir $basedir -BlueprintsPath ' + $BlueprintsPath
        Lib-Spawn-Wrapper -Type "Splunk" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Install-Splunk.psm1" -LauchCommand $LauchCommand -debug $datavar.debug

      } 
      if ($datavar.InstallHashiVault -eq 1){

        write-log -message "Spawning HashiCorpVault Install" -sev "CHAPTER"

        $LauchCommand = 'Wrap-Install-HashiCorpVault -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -basedir $basedir -BlueprintsPath ' + $BlueprintsPath
        Lib-Spawn-Wrapper -Type "HashiCorpVault" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Install-3TierWin.psm1" -LauchCommand $LauchCommand -debug $datavar.debug

      } 
      if ($datavar.Install3TierWin -eq 1){

        write-log -message "Spawning 3TierWin Install" -sev "CHAPTER"

        $LauchCommand = 'Wrap-Install-3TierWin -datagen $datagen -datavar $datavar -ServerSysprepfile $ServerSysprepfile -basedir $basedir -BlueprintsPath ' + $BlueprintsPath
        Lib-Spawn-Wrapper -Type "3TierWin" -datavar $datavar -datagen $data -parentuuid "$($datavar.UUID)" -sysprepfile $sysprepfile -ModuleDir $ModuleDir -basedir $basedir -ProdMode $ProdMode -psm1file "$($ModuleDir)\Wrap-Install-3TierWin.psm1" -LauchCommand $LauchCommand -debug $datavar.debug

      } 
      write-log -message "Getting results from spawned demos" -sev "CHAPTER"

      Lib-Get-Wrapper-Results -datavar $datavar -datagen $data -ModuleDir $ModuleDir -parentuuid "$($datavar.UUID)" -basedir $basedir -debug $datavar.debug

      write-log -message "Checking uploaded ISO Images" -sev "CHAPTER"
      
      $STATUS = CMD-Upload-ISOImages -ISOurlDataPrimair $ISOurlData1 -ISOurlDataBackup $ISOurlData2 -debug $datavar.debug -peadmin $datavar.PEAdmin -pepass $datavar.PEPass -PEClusterIP $datavar.PEClusterIP -ContainerName $data.ImagesContainerName -dcimage $data.DC_ImageName
      Lib-Check-Thread -status $status.result -stage "Uploading ISO Images" -lockfile $lockfile -SingleModelck $SingleModelck -SenderEMail $datavar.SenderEMail -logfile $logfile -debug $datavar.debug
      
      write-log -message "Fire LCM Inventory for PE" -sev "CHAPTER"

      REST-LCM-Perform-Inventory -datavar $datavar -datagen $data -mode "PE"
      LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $data -datavar $datavar -mode "end" -debug $datavar.debug -logfile $logfile
  
      write-log -message "Done" -sev "CHAPTER"

    } else {

      write-log -message "Danger Will Robinson, Cannot connect, even with VPN attempt." -sev "ERROR"

      LIB-Send-Confirmation -reciever $datavar.SenderEMail -datagen $data -datavar $datavar -mode "FailedVPN" -debug $datavar.debug -logfile $logfile
    }
    stop-transcript
    $exit = 1
    try {
      Remove-item $lockfile
      Remove-item $SingleModelck -ea:0
      Connect-NutanixVPN -VPNUser $datavar.VPNUser -VPNPass $datavar.vpnpass -VPNURL $datavar.vpnurl -mode "stop"
    }catch {}
  } else {
    write-log -message "No Files in queue or queue not in multi usermode, Production mode is $prodmode V2"
    write "Empty Daemon sleeping" | out-file "$($daemons)\$($daemonID).thread"
  };
  sleep 110
} until ($exit -eq 1 -or $exitcount -ge 350 )


