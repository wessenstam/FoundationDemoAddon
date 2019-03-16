Function Wrap-Post-PC {
  param (
    [object] $datavar,
    [object] $datagen,
    $ServerSysprepfile

  )     
    write-log -message "Running LCM on both" -sev "CHAPTER"

    REST-LCM-Perform-Inventory -datavar $datavar -datagen $datagen -mode "PC"

    if ($datavar.EnableFlow -eq 1){

      write-log -message "Enable Flow (Option)" -sev "CHAPTER"
  
      REST-Enable-Flow -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $datagen.PCClusterIP -debug $datavar.debug
    
    } 
    write-log -message "Importing Images into Prism Central" -sev "CHAPTER"

    REST-Image-Import-PC -clpassword $datavar.PEPass -clusername $datavar.PEAdmin -PCClusterIP $datagen.PCClusterIP -debug $datavar.debug
    
    write-log -message "Join Prism Element to the AD Domain" -sev "CHAPTER"

    CMD-Join-PxtoADDomain -PEAdmin $datavar.PEAdmin -PEPass $datavar.PEPass -PxClusterIP $datavar.PEClusterIP -DC1_IPAddress $datagen.DC1IP -DC2_IPAddress $datagen.DC2IP -Domainname $datagen.Domainname -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug

    write-log -message "Join Prism Central to the AD Domain" -sev "CHAPTER"

    CMD-Join-PxtoADDomain -PEAdmin $datavar.PEAdmin -PEPass $datavar.PEPass -PxClusterIP $datagen.PCClusterIP -DC1_IPAddress $datagen.DC1IP -DC2_IPAddress $datagen.DC2IP -Domainname $datagen.Domainname -SysprepPassword $datagen.SysprepPassword -debug $datavar.debug

    if ($datavar.SetupSSP -eq 1){

      write-log -message "Configuring SSP Portal with AD content" -sev "CHAPTER"

      Wrap-Create-SSP-Groups-Projects -datafixed $datagen -datavar $datavar
  
    }

    write-log -message "Setting SMTP server for Prism Element" -sev "CHAPTER"
  
    CMD-Set-SMTPServerSettings -datagen $datagen -datavar $datavar -ip $datavar.PEClusterIP
  
    write-log -message "Setting SMTP server for Prism Central" -sev "CHAPTER"

    CMD-Set-SMTPServerSettings -datagen $datagen -datavar $datavar -ip $datagen.PCClusterIP

    write-log -message "Setting up RoleMapping for Prism Element" -sev "CHAPTER"

    SSh-RoleMapping-Px -PxClusterIP $datavar.PEClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -domainname $datagen.domainname -debug $datavar.debug

    write-log -message "Setting up RoleMapping for Prism Central" -sev "CHAPTER"

    SSh-RoleMapping-Px -PxClusterIP $datagen.PCClusterIP -clusername $datavar.PEAdmin -clpassword $datavar.PEPass -domainname $datagen.domainname -debug $datavar.debug
    


}