function LIB-Connect-PSNutanix {
  param(
      [parameter(mandatory=$false)]$ClusterName,
      [parameter(mandatory=$false)]$NutanixClusterUsername,
      [parameter(mandatory=$false)]$NutanixClusterPassword
  )
  $count = 0
  if($ClusterName -and ($ClusterName -ne $($connection.server))){;
    try {
      Disconnect-NTNXCluster * -ea:0 
    } catch {
      write-log -message "Not Connected yet, no clean disconect required."
    }
    $NutanixCluster = $ClusterName;
    $SecurePassword = ConvertTo-SecureString $NutanixClusterPassword -asplaintext -force;
    do {
      $count++
      try{
        $connection = Connect-NutanixCluster -server $NutanixCluster -username $NutanixClusterUsername -password $SecurePassword -AcceptInvalidSSLCerts -ForcedConnection;
        if ($connection.IsConnected){;

          write-log -message "Connected to $($connection.server)";

        } else {;
          sleep 60;

          write-log -message "Failed to connect to $NutanixCluster" -sev "WARN"

          $SecurePassword = ConvertTo-SecureString $NutanixClusterPassword -asplaintext -force;
          $connection = Connect-NutanixCluster -server $NutanixCluster -username $NutanixClusterUsername -password $SecurePassword -AcceptInvalidSSLCerts -ForcedConnection;
        };
      } catch {

        write-log -message "Failed to connect to $NutanixCluster" -sev "WARN"
        
      }
    } until ($connection -or $count -gt 6) 
  };
};
Export-ModuleMember *