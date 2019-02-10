Function Wrap-Create-SSP-Groups-Projects{
   param (
    $datafixed,
    $datavar
   ) 
  $Customers = "Customer-A","Customer-B","Customer-C","Customer-D","Customer-E","Customer-F";
  $grouptypes = "user-accounts-group","admin-accounts-group"
  $subnet = REST-Query-Subnet -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -networkname $datafixed.nw1name -debug $datavar.debug
  
  foreach ($customer in $customers){
    
    write-log -message "Creating Admin Group for $customer"
  
    try {
      $admingroup = REST-Create-UserGroup -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -grouptype "admin-accounts-group" -customer $customer -domainname $datafixed.Domainname -debug $datavar.debug
    } catch {

      write-log -message "Admin Group for $customer exists"

      $result = REST-Query-ADGroups -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin
      $admingroup = $result.entities | where {$_.spec.resources.directory_service_user_group.distinguished_name -match $customer -and $_.spec.resources.directory_service_user_group.distinguished_name -match "admin-accounts-group"}

    }

    write-log -message "Creating User Group for $customer"

    try { 
      $usergroup = REST-Create-UserGroup -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -grouptype "user-accounts-group" -customer $customer -domainname $datafixed.Domainname -debug $datavar.debug
    } catch{

      write-log -message "User Group for $customer exists"

      $result = REST-Query-ADGroups -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin
      $usergroup = $result.entities | where {$_.spec.resources.directory_service_user_group.distinguished_name -match $customer -and $_.spec.resources.directory_service_user_group.distinguished_name -match "user-accounts-group"}
    }
    write-log -message "Creating Project for $customer"
  
    $project = REST-Create-Project -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -UserGroupName $usergroup.metadata.name -UserGroupUUID $usergroup.metadata.uuid -clusername $datavar.peadmin -customer $customer -AdminGroupName $admingroup.metadata.name -AdminGroupUUID $admingroup.metadata.uuid -SubnetName $subnet.spec.name -subnetuuid $subnet.metadata.uuid 

    write-log -message "Project already exists for $customer" -sev "WARN"  

  }

  write-log -message "Updating Consumer Group Mappings"

}
Export-ModuleMember *