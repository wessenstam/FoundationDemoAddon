Function  LIB-Config-ISOurlData { 
  param (
    $region
  )

  if ($region -eq "EU"){
    $SQL2014ISO    = "xxxxxxxxx";
    $XENDESKTOP    = "xxxxxxxxx";
    $office2016    = "xxxxxxxxx";
    $Windows2016ISO= "xxxxxxxxx";
    $KarbonCentOS  = "xxxxxxxxx"
    $KarbonUbuntu  = "xxxxxxxxx"
    $CentOS        = "xxxxxxxxx"
    $Windows2012   = "xxxxxxxxx"
    $Windows10     = "xxxxxxxxx"
    $windows2016   = "xxxxxxxxx"
    $Move          = "xxxxxxxxx"
    $VirtIOISO     = "xxxxxxxxx"
    $XRAY          = "xxxxxxxxx"  
    $era           = "xxxxxxxxx"
    $sqlSERVER     = "xxxxxxxxx"
    $oracle1_0     = "xxxxxxxxx"
    $oracle1_1     = "xxxxxxxxx"
    $oracle1_2     = "xxxxxxxxx"

  } elseif ($region -eq "Backup"){
    #$SQL2014ISO    = "xxxxxxxxx";
    #$XENDESKTOP    = ""xxxxxxxxx";
    #$office2016    = "xxxxxxxxx";
    #$Windows2016ISO= "xxxxxxxxx";
    $KarbonCentOS  = "xxxxxxxxx"
    $CentOS        = "xxxxxxxxx"
    $KarbonUbuntu  = "xxxxxxxxx"
    $Windows2012   = "xxxxxxxxx"
    #$Windows10     = "xxxxxxxxx"
    #$windows2016   = "xxxxxxxxx"
    $Move          = "xxxxxxxxx"
    $VirtIOISO     = "xxxxxxxxx"
    $XRAY          = "xxxxxxxxx"
    $era           = "xxxxxxxxx"
    $sqlSERVER     = "xxxxxxxxx"
    $oracle1_0     = "xxxxxxxxx"
    $oracle1_1     = "xxxxxxxxx"
    $oracle1_2     = "xxxxxxxxx"  
  } elseif ($region -eq "Backup2"){
    $SQL2014ISO    = "xxxxxxxxx";
    $XENDESKTOP    = "xxxxxxxxx";
    $office2016    = "xxxxxxxxx";
    $Windows2016ISO= "xxxxxxxxx";
    $KarbonCentOS  = "xxxxxxxxx"
    $CentOS        = "xxxxxxxxx"
    $KarbonUbuntu  = "xxxxxxxxx"
    $Windows2012   = "xxxxxxxxx"
    $Windows10     = "xxxxxxxxx"
    $windows2016   = "xxxxxxxxx"
    $Move          = "xxxxxxxxx"
    $VirtIOISO     = "xxxxxxxxx"
    $XRAY          = "xxxxxxxxx"
    $era           = "xxxxxxxxx"
    $sqlSERVER     = "xxxxxxxxx" 
    $oracle1_0     = "xxxxxxxxx"
    $oracle1_1     = "xxxxxxxxx"
    $oracle1_2     = "xxxxxxxxx"  
  }else {
    $SQL2014ISO    = #"xxxxxxxxx";
    $XENDESKTOP    = "xxxxxxxxx";
    $office2016    = #"xxxxxxxxx";
    $Windows2016ISO= "xxxxxxxxx";
    $KarbonCentOS  = "xxxxxxxxx"
    $CentOS        = "xxxxxxxxx"
    $KarbonUbuntu  = "xxxxxxxxx"
    $Windows2012   = "xxxxxxxxx"
    $Windows10     = "xxxxxxxxx"
    $windows2016   = "xxxxxxxxx"
    $VirtIOISO     = "xxxxxxxxx"
    $Move          = "xxxxxxxxx"
    $XRAY          = "xxxxxxxxx"
    $era           = "xxxxxxxxx"
    $sqlSERVER     = "xxxxxxxxx"
    $oracle1_0     = "xxxxxxxxx"
    $oracle1_1     = "xxxxxxxxx"
    $oracle1_2     = "xxxxxxxxx" 
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
  $Object | add-member Noteproperty Oracle_1_0          $oracle1_0;
  $Object | add-member Noteproperty Oracle_1_1          $oracle1_1;
  $Object | add-member Noteproperty Oracle_1_2          $oracle1_2;
  return $object;
};