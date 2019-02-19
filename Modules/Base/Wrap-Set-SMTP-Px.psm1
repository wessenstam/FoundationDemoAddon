Function Wrap-Set-SMTP-Px{
   param (
    $datafixed,
    $datavar
   ) 
  

  $PCcluster = REST-Query-Cluster -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -targetIP $datafixed.PCClusterIP

  write-log -message "Using PC Cluster $($PCcluster.metadata.uuid)"
  write-log -message "Using Setting SMTP for $($PCcluster.metadata.uuid)"

  REST-Set-SMTP-Server-Px -cluuid $($PCcluster.metadata.uuid) -clpassword $datavar.pepass -clusername $datavar.peadmin -ClusterPx_IP $datafixed.PCClusterIP -datagen $datafixed

  $PEcluster = REST-Query-Cluster -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -targetIP $datavar.PEClusterIP

  write-log -message "Using Pe Cluster $($PCcluster.metadata.uuid)"
  write-log -message "Using Setting SMTP for $($PCcluster.metadata.uuid)"

  REST-Set-SMTP-Server-Px -cluuid $($PEcluster.metadata.uuid) -clpassword $datavar.pepass -clusername $datavar.peadmin -ClusterPx_IP $datafixed.PCClusterIP -datagen $datafixed


}
Export-ModuleMember *