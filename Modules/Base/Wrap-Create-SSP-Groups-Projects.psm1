Function Wrap-Create-SSP-Groups-Projects{
   param (
    $datafixed,
    $datavar
   ) 
  
   $Customers = "Customer-A","Customer-B","Customer-C","Customer-D","Customer-E","Customer-F";
   
 
  $subnet = REST-Query-Subnet -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -networkname $datafixed.nw1name -debug $datavar.debug
  sleep 10
  $cluster = REST-Query-Cluster -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -targetIP $datafixed.PCClusterIP

  write-log -message "Using Cluster $($cluster.metadata.uuid)"
  write-log -message "Using Subnet $($subnet.metadata.uuid)"


  foreach ($customer in $customers){
    
    write-log -message "Creating Admin Group for $customer"
  
    try {
      $admingroup = REST-Create-UserGroup -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -grouptype "admin-accounts-group" -customer $customer -domainname $datafixed.Domainname -debug $datavar.debug
    } catch {

      write-log -message "Admin Group for $customer exists"

      $result = REST-Query-ADGroups -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin-debug $datavar.debug
      $admingroup = $result.entities | where {$_.spec.resources.directory_service_user_group.distinguished_name -match $customer -and $_.spec.resources.directory_service_user_group.distinguished_name -match "admin-accounts-group"}

    }

    write-log -message "Creating User Group for $customer"

    try { 
      $usergroup = REST-Create-UserGroup -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -grouptype "user-accounts-group" -customer $customer -domainname $datafixed.Domainname -debug $datavar.debug
    } catch{

      write-log -message "User Group for $customer exists"

      $result = REST-Query-ADGroups -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug
      $usergroup = $result.entities | where {$_.spec.resources.directory_service_user_group.distinguished_name -match $customer -and $_.spec.resources.directory_service_user_group.distinguished_name -match "user-accounts-group"}
    }

    write-log -message "Using Admingroup $($admingroup.metadata.uuid)"
    write-log -message "Using Usergroup $($usergroup.metadata.uuid)"

    try {
      $project = REST-Create-Project -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -UserGroupName $usergroup.metadata.name -UserGroupUUID $usergroup.metadata.uuid -clusername $datavar.peadmin -customer $customer -AdminGroupName $admingroup.metadata.name -AdminGroupUUID $admingroup.metadata.uuid -SubnetName $subnet.spec.name -subnetuuid $subnet.metadata.uuid -debug $datavar.debug
    } catch {

      $resultproject = REST-Query-Projects -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -debug $datavar.debug 
      $project = $resultproject.entities | where {$_.spec.name -match $customer}

      write-log -message "Project already exists for $customer.."

    }

    write-log -message "Project UUID is $($project.metadata.uuid)"
    write-log -message "Getting Role uuids"

    $consumer = REST-Query-Role-List -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -rolename "Consumer" -debug $datavar.debug
    sleep 10
    $ProjectAdmin = REST-Query-Role-List -ClusterPC_IP $datafixed.PCClusterIP -clpassword $datavar.pepass -clusername $datavar.peadmin -rolename "Project Admin" -debug $datavar.debug

    write-log -message "Using Consumer Role $($consumer.metadata.uuid)"
    write-log -message "Using ProjectAdmin Role $($ProjectAdmin.metadata.uuid)"
    write-log -message "Updating Project with ACP for $customer"

    try {
      $result = REST-Update-Project -ClusterPC_IP $datafixed.PCClusterIP -Projectspec $project.metadata.spec_version -customer $customer -clpassword $datavar.pepass -clusername $datavar.peadmin -usergroup $usergroup -admingroup $admingroup -consumer $consumer -ProjectAdmin $projectadmin -project $project -cluster $cluster -subnet $subnet -debug $datavar.debug
    
    } catch {
      write-host $project.metadata.spec_version
      [int]$projectspec = $project.metadata.spec_version + 1 
      
      write-log -message "Up on spec"
      
      $result = REST-Update-Project -ClusterPC_IP $datafixed.PCClusterIP -Projectspec $projectspec -customer $customer -clpassword $datavar.pepass -clusername $datavar.peadmin -usergroup $usergroup -admingroup $admingroup -consumer $consumer -ProjectAdmin $projectadmin -project $project -cluster $cluster -subnet $subnet -debug $datavar.debug
    }
    write-log -message "Done with SSP Projects for Customer $customer"
    write-log -message "Making sure API can keep up"
    SLEEP 60
  }


}
Export-ModuleMember *