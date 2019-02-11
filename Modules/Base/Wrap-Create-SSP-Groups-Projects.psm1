Function Wrap-Install-XPlay-IIS-Demo{
   param (
    $datafixed,
    $datavar
   ) 
 
   
 
  $subnet = REST-Query-Subnet -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -networkname $datafixed.nw1name -debug $datavar.debug
  $cluster = REST-Query-Clusters -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -targetIP $datafixed.PCClusterIP

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
    try {
      $project = REST-Create-Project -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -UserGroupName $usergroup.metadata.name -UserGroupUUID $usergroup.metadata.uuid -clusername $datavar.peadmin -customer $customer -AdminGroupName $admingroup.metadata.name -AdminGroupUUID $admingroup.metadata.uuid -SubnetName $subnet.spec.name -subnetuuid $subnet.metadata.uuid 
    } catch {

      write-log -message "Project already exists for $customer" -sev "WARN" 

    }

    write-log -message "Updating Project with ACP for $customer"
    $consumer = REST-Query-Role-List -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -rolename "Consumer"
    $ProjectAdmin = REST-Query-Role-List -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -rolename "Project Admin"
    $result = REST-Update-Project -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -usergroup $usergroup -admingroup $admingroup -consumer $consumer -ProjectAdmin $projectadmin -project $project -cluster $cluster -subnet $subnet


  }


}
Export-ModuleMember *