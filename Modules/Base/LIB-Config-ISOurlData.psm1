Function  LIB-Config-ISOurlData { 
  param (
    $region
  )

  if ($region -eq "EU"){
    $SQL2014ISO    = 
    $XENDESKTOP    = 
    $office2016    = 
    $Windows2016ISO= 
    $KarbonCentOS  = 
    $KarbonUbuntu  = 
    $CentOS        = 
    $Windows2012   = 
    $Windows10     = 
    $windows2016   = 
    $Move          = 
    $VirtIOISO     = 
    $XRAY          = 
    $era           = 
    $sqlSERVER     = 

  } elseif ($region -eq "Backup"){
    #$SQL2014ISO    =
    #$XENDESKTOP    =
    #$office2016    =
    #$Windows2016ISO=
    $KarbonCentOS  = 
    $CentOS        = 
    $KarbonUbuntu  = 
    $Windows2012   = 
    #$Windows10     =
    #$windows2016   =
    $Move          = 
    $VirtIOISO     = 
    $XRAY          = 
    $era           = 
    $sqlSERVER     = 
  } elseif ($region -eq "Backup2"){
    $SQL2014ISO    = 
    $XENDESKTOP    = 
    $office2016    = 
    $Windows2016ISO= 
    $KarbonCentOS  = 
    $CentOS        = 
    $KarbonUbuntu  = 
    $Windows2012   = 
    $Windows10     = 
    $windows2016   = 
    $Move          = 
    $VirtIOISO     = 
    $XRAY          = 
    $era           = 
    $sqlSERVER     = 
  }else {
    $SQL2014ISO    = 
    $XENDESKTOP    = 
    $office2016    = 
    $Windows2016ISO= 
    $KarbonCentOS  = 
    $CentOS        = 
    $KarbonUbuntu  = 
    $Windows2012   = 
    $Windows10     = 
    $windows2016   = 
    $VirtIOISO     = 
    $Move          = 
    $XRAY          = 
    $era           = 
    $sqlSERVER     = 
  }
  $Object = New-Object PSObject;
  $Object | add-member Noteproperty Windows2016ISO      $Windows2016ISO; 
  $Object | add-member Noteproperty Windows2016         $Windows2016; 
  $Object | add-member Noteproperty 'Windows 2012'      $Windows2012;  
  $Object | add-member Noteproperty 'Windows 10'        $Windows10;     
  $Object | add-member Noteproperty SQL2014ISO          $SQL2014ISO;
  $Object | add-member Noteproperty XENDESKTOPISO       $XENDESKTOP;
  $Object | add-member Noteproperty office2016ISO       $office2016;
  $Object | add-member Noteproperty Move                $Move;
  $Object | add-member Noteproperty acs-centos          $KarbonCentOS;
  $Object | add-member Noteproperty acs-ubuntu          $KarbonUbuntu;
  $Object | add-member Noteproperty CentOS              $CentOs;
  $Object | add-member Noteproperty X-Ray               $xray;
  $Object | add-member Noteproperty ERA                 $Era;
  $Object | add-member Noteproperty 'MSSQL-2016-VM'     $sqlSERVER;
  return $object;
};