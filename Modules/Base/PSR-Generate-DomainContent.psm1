Function PSR-Generate-DomainContent {
  param (
    [string] $SysprepPassword,
    [string] $IP,
    [string] $Domainname,
    [string] $Sename,
    [string] $debug
  )
  $netbios = $Domainname.split(".")[0]

  write-log -message "Debug level is $debug";
  write-log -message "Building credential object.";

  $password = $SysprepPassword | ConvertTo-SecureString -asplaintext -force;
  $credential = New-Object System.Management.Automation.PsCredential("administrator",$password);
  $sesplit = ($Sename -split (" ")) -join (".")
  
  write-log -message "Populating AD content";
  write-log -message "5 Customers";
  write-log -message "5 Admins per customer";
  write-log -message "5 Service accounts per customer";
  write-log -message "3 Groups per customer";
  write-log -message "105 User accounts per customer"; 
  write-log -message "Groups Populated per customer";
  write-log -message "Admin $sesplit created as Domain and PC/PE Admin";
  write-log -message "Domain name is $Domainname"

  $connect = invoke-command -computername $ip -credential $credential { 
    $DomainParts = $Args[0].split(".");
    $Customers = "Customer-A","Customer-B","Customer-C"
    $OUs = "User-Accounts","Groups","Service-Accounts","Admin-Accounts","Resources","Disabled-Users";
    $users = "User-1","User-2","User-3","User-4","User-5";
    $ServiceAccounts = "ntnx-sql-svc","ntnx-xda-svc","ntnx-exc-svc","ntnx-bck-svc","ntnx-psr-svc","ntnx-ntx-svc";
    $adminaccounts = "adm-User-1","adm-User-2","adm-User-3","adm-User-4","adm-User-5";
    try {
      New-ADOrganizationalUnit -Name "Customers" -Path "DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])";
    } catch {
    };
    
    new-aduser -name $args[2] -AccountPassword $args[1] -PasswordNeverExpires $true -userPrincipalName "$($args[2])@$($args[0])" -EmailAddress "$($args[2])@$($args[0])" -Office "Hoofddorp" -ea:0 | out-null;
    add-ADGroupMember "Domain Admins" $args[2] -ea:0 | out-null;
    function Generate-Name {;
      $lastnames  = "Smith Johnson Williams Jones Brown Davis Miller Wilson Moore Taylor Anderson Thomas Jackson White Harris Martin Thompson Garcia Martinez Robinson Clark Wright Rodriguez Lopez Lewis Perez Hill Roberts Lee Scott Turner Walker Green Phillips Hall Adams Campbell Allen Baker Parker Young Gonzalez Evans Hernandez Nelson Edwards King Carter Collins";
      $firstnames = "James Christopher Ronald Mary Lisa Michelle John Daniel Anthony Patricia Nancy Laura Robert Paul Kevin Linda Karen Sarah Michael Mark Jason Barbara Betty Kimberly William Donald Jeff Elizabeth Helen Deborah David George Jennifer Sandra Richard Kenneth Maria Donna Charles Steven Susan Carol Joseph Edward Margaret Ruth Thomas Brian Dorothy Sharon";
      $first = $firstnames.split(" ");
      $Last = $lastnames.split(" ");
      $f = $first[ (Get-Random $first.count ) ];
      $l = $last[ (Get-Random $last.count) ];
      $full = $f+"."+$l;
      return $full;
    };
    Foreach ($customer in $customers){;
      $cusshort = $customer.split("-")[1]
      $count1 = 0;
      $count2 = 0;
      $names = $null;
      do {;
        [array]$names += Generate-name;
        $count1++;
      } until ($count1 -eq 1000);
      New-ADOrganizationalUnit -Name "$customer" -Path "OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])" -DisplayName "$customer Cloud";
      foreach ($ou in $ous){
        New-ADOrganizationalUnit -Name "$ou" -Path "OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])";
      }

      new-adgroup -groupscope 1 -name "$($customer)-Service-Accounts-Group" -path "OU=Groups,OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])" -ea:0 | out-null;
      new-adgroup -groupscope 1 -name "$($customer)-Admin-Accounts-Group" -path "OU=Groups,OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])" -ea:0 | out-null;
      new-adgroup -groupscope 1 -name "$($customer)-User-Accounts-Group" -path "OU=Groups,OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])" -ea:0 | out-null;

      foreach ($user in $users){;
        new-aduser -name "$($user)-$($cusshort)" -AccountPassword $args[1] -PasswordNeverExpires $true -userPrincipalName "$($Customer)-$($user)@$($args[0])" -EmailAddress "$($Customer)-$($user)@$($args[0])" -Office "Hoofddorp" -path "OU=User-Accounts,OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])" -ea:0 | out-null;
        add-ADGroupMember  "$($customer)-User-Accounts-Group" "$($user)-$($cusshort)" -ea:0 | out-null;
      };
      foreach ($user in $names){;
        $first = $user.split(".")[0];
        $last = $user.split(".")[1];
        try {;
          if ($count2 -le 100){;
            new-aduser -name "$user" -Surname $last -givenname $first -AccountPassword $args[1] -PasswordNeverExpires $true -userPrincipalName "$($user)@$($args[0])" -displayname "$first $last" -Office "Hoofddorp" -EmailAddress "$($user)@$($args[0])" -path "OU=User-Accounts,OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])";
            add-ADGroupMember  "$($customer)-User-Accounts-Group" "$user" -ea:0 | out-null;
            $count2 = $count2 + 1;
          };
        } catch {;
          $count2 = $count2 - 1;
        };
      };
      foreach ($serviceaccount in $ServiceAccounts){;
        new-aduser -name "$($serviceaccount)-$($cusshort)" -AccountPassword $args[1] -PasswordNeverExpires $true -userPrincipalName "$($serviceaccount)-$($cusshort)@$($args[0])" -path "OU=Service-Accounts,OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])";
        add-ADGroupMember  "$($customer)-Service-Accounts-Group" "$($serviceaccount)-$($cusshort)" -ea:0 | out-null;
      };
      foreach ($adminaccount in $adminaccounts){;
        new-aduser -name "$($adminaccount)-$($cusshort)" -AccountPassword $args[1] -PasswordNeverExpires $true -userPrincipalName "$($adminaccount)-$($cusshort)@$($args[0])" -path "OU=Admin-Accounts,OU=$($customer),OU=Customers,DC=$($($DomainParts)[0]),DC=$($($DomainParts)[1]),DC=$($($DomainParts)[2])"
        add-ADGroupMember "$($customer)-Admin-Accounts-Group" "$($adminaccount)-$($cusshort)" -ea:0 | out-null;
      };

    };
    Get-ADUser -filter * | Enable-ADAccount -ea:0
  } -args $domainname,$password,$sesplit

  write-log -message "We are all done here."
  
  $resultobject =@{
    Result = "Success"
  };
  return $resultobject
};
Export-ModuleMember *

