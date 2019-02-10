Function SSH-Networking-Pe {
  Param (
    [string] $PEClusterIP,
    [string] $clpassword,
    [string] $clusername,
    [string] $domainname,
    [string] $nw1dhcpstart,
    [string] $nw1gateway,
    [string] $nw1Subnet,
    [string] $nw1vlan,
    [string] $nw1name,   
    [string] $nw2dhcpstart,
    [string] $DC1IP,
    [string] $DC2IP,
    [string] $nw2Subnet,
    [string] $nw2gateway,
    [string] $ne2name,
    [string] $nw2vlan,
    [string] $debug
  )
  #dependencies LIB-write-log, Posh-SSH, PE_ncli

  $count = 0 
  write-log -message "Building Credential for SSH session";
  $hide = Get-SSHTrustedHost | Remove-SSHTrustedHost
  $Securepass = ConvertTo-SecureString $clpassword -AsPlainText -Force;
  $credential = New-Object System.Management.Automation.PSCredential ($clusername, $Securepass);
  $session = New-SSHSession -ComputerName $PEClusterIP -Credential $credential -AcceptKey;
  $netbios = $domainname.split(".")[0]
  
  write-log -message "Setting up Network for for $PEClusterIP";

  do {;
    $count++
    try {;
      $session = New-SSHSession -ComputerName $PEClusterIP -Credential $credential -AcceptKey;
      
      write-log -message "Setting clean state"

      $Delete = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli -y net.delete Rx-Automation-Network" -EnsureConnection

      write-log -message "Checking Networks";
      
      $Existing = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli net.list" -EnsureConnection

      if ($Existing.output -match $nw1name){

        write-log -message "Network 1 exists";

        $nw1completed = $true

      } else {

        write-log -message "Network 1 Does not exist, creating.";
        write-log -message "Calculating data.";

        $prefix = Convert-IpAddressToMaskLength $nw1Subnet
        $ipconfig = "$($nw1gateway)/$($prefix)"
        $lastIP = Get-LastAddress -IPAddress $PEClusterIP -SubnetMask $nw1Subnet

        write-log -message "IPconfig value should be: $ipconfig"
        write-log -message "DHCP Start should be: $nw1dhcpstart"
        write-log -message "Network 1 VLAN will be $nw1vlan"
        write-log -message "Last IP will be $lastIP"
        write-log -message "Netbios Domain is $netbios"
        write-log -message "DNS 1 = $DC1ip"
        write-log -message "DNS 1 = $DC2ip"

        $result = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli net.create $nw1name vlan=$($nw1vlan) ip_config=$($ipconfig)" -EnsureConnection
        sleep 5
        $result = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli net.update_dhcp_dns $nw1name servers=$($DC1IP),$($DC2ip) domains=$($netbios)" -EnsureConnection
        sleep 5
        $result = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli net.add_dhcp_pool $nw1name start=$($nw1dhcpstart) end=$($lastIP)" -EnsureConnection

        write-log -message "Network 1 Created"

      }

      if ($Existing.output -match $nw2name -and $nw2vlan){

        write-log -message "Network 2 exists";

        $nw2completed = $true

      } elseif ($nw2vlan) {

        write-log -message "Network 2 Does not exist, and needs creating.";
        write-log -message "Calculating data.";

        $prefix = Convert-IpAddressToMaskLength $nw21Subnet
        $ipconfig = "$($nw2gateway)/$($prefix)"
        $lastIP = Get-LastAddress -IPAddress $nw2dhcpstart -SubnetMask $nw2Subnet

        write-log -message "IPconfig value should be: $ipconfig"
        write-log -message "DHCP Start should be: $nw2dhcpstart"
        write-log -message "Network 0 VLAN will be $nw2vlan"
        write-log -message "Last IP will be $lastIP"
        write-log -message "Netbios Domain is $netbios"

        $result = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli net.create $nw1name vlan=$($nw2vlan) ip_config=$($ipconfig)" -EnsureConnection
        $result = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli net.update_dhcp_dns $nw2name servers=$($DC1IP),$($DC2ip) domains=$($netbios)" -EnsureConnection
        $result = Invoke-SSHCommand -SSHSession $session -command "/usr/local/nutanix/bin/acli net.add_dhcp_pool $nw2name start=$($nw2dhcpstart) end=$($lastIP)"

      } else {

        write-log -message "Network 2 is not specified to be deployed";

        $nw2completed = $true
      }
      
    } catch {;
      $nw1completed = $false

      write-log -message "Error Creating networks, Retry" -sev "WARN";

      sleep 2
    };
  } until (($nw1completed -eq $true -and $nw2completed -eq $true) -or $count -ge 6)

 
  if ($nw1completed -eq $true){
    $status = "Success"

  } else {
    $status = "Failed"
  }
  $resultobject =@{
    Result = $status
    Output = $result.output
  }
  Try {
    write-log -message "Executing session cleanup"
    $clean = Remove-SSHSession -SSHSession $session
  } catch {}
  return $resultobject
};
Export-ModuleMember *