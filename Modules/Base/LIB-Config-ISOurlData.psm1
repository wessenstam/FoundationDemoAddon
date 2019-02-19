Function  LIB-Config-ISOurlData { 
  param (
    $region
  )

  if ($region -ne "EU"){
    $SQL2014ISO    = "https://mail.mmouse.nl/wwwdump/SQLServer2014SP3-FullSlipstream-x64-ENU.iso";
    $XENDESKTOP    = "http://10.21.250.221/images/ahv/techsummit/XD715.iso";
    $office2016    = "https://mail.mmouse.nl/wwwdump/SW_DVD5_Office_Professional_Plus_2016_64Bit_English_MLF_X20-42432.iso";
    $Windows2016ISO= "http://10.21.250.221/images/tech-enablement/Windows2016.iso";
    $KarbonCentOS  = "http://download.nutanix.com/karbon/0.8/acs-centos7.qcow2"
    $KarbonUbuntu  = "http://download.nutanix.com/karbon/0.8/acs-ubuntu1604.qcow2"
    $Windows2012   = "http://10.21.250.221/images/ahv/Windows2012.qcow2"
    $Windows10     = "http://10.21.250.221/images/ahv/Windows10.qcow2"
    $windows2016   = "http://10.21.250.221/images/tech-enablement/Windows2016.qcow2"
    $era           = "http://download.nutanix.com/era/1.0.1/ERA-Server-build-1.0.1-c879f4f17419ad34487fd1759c236e79cdd7c225.qcow2"
  } else {
    $SQL2014ISO    = "https://mail.mmouse.nl/wwwdump/SQLServer2014SP3-FullSlipstream-x64-ENU.iso";
    $XENDESKTOP    = "https://mail.mmouse.nl/wwwdump/XenApp_and_XenDesktop_7_15_3000.iso";
    $office2016    = "https://mail.mmouse.nl/wwwdump/SW_DVD5_Office_Professional_Plus_2016_64Bit_English_MLF_X20-42432.iso";
    $Windows2016ISO= "https://mail.mmouse.nl/wwwdump/Windows2016.iso";
    $KarbonCentOS  = "http://download.nutanix.com/karbon/0.8/acs-centos7.qcow2"
    $KarbonUbuntu  = "http://download.nutanix.com/karbon/0.8/acs-ubuntu1604.qcow2"
    $Windows2012   = "https://mail.mmouse.nl/wwwdump/Windows2012.qcow2"
    $Windows10     = "https://mail.mmouse.nl/wwwdump/Windows10.qcow2"
    $windows2016   = "https://mail.mmouse.nl/wwwdump/Windows2016.qcow2"
    $era           = "http://download.nutanix.com/era/1.0.1/ERA-Server-build-1.0.1-c879f4f17419ad34487fd1759c236e79cdd7c225.qcow2" 
  }
  $Object = New-Object PSObject;
  $Object | add-member Noteproperty Windows2016ISO      $Windows2016ISO; 
  $Object | add-member Noteproperty Windows2016         $Windows2016; 
  $Object | add-member Noteproperty 'Windows 2012'      $Windows2012;  
  $Object | add-member Noteproperty 'Windows 10'        $Windows10;     
  $Object | add-member Noteproperty SQL2014ISO          $SQL2014ISO;
  $Object | add-member Noteproperty XENDESKTOPISO       $XENDESKTOP;
  $Object | add-member Noteproperty office2016ISO       $office2016;
  $Object | add-member Noteproperty KarbonCentOS        $KarbonCentOS;
  $Object | add-member Noteproperty KarbonUbuntu        $KarbonUbuntu;
  $Object | add-member Noteproperty ERA                 $Era;
  return $object;
};