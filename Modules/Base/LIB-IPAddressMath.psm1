function Convert-IpAddressToMaskLength {
  Param(
    [string] $dottedIpAddressString
    )
  $result = 0; 
  # ensure we have a valid IP address
  [IPAddress] $ip = $dottedIpAddressString;
  $octets = $ip.IPAddressToString.Split('.');
  foreach($octet in $octets)
  {
    while(0 -ne $octet) 
    {
      $octet = ($octet -shl 1) -band [byte]::MaxValue
      $result++; 
    }
  }
  return $result;
}

function Get-LastAddress{
  param(
    $IPAddress,
    $SubnetMask
  )
  filter Convert-IP2Decimal{
      ([IPAddress][String]([IPAddress]$_)).Address
  }
  filter Convert-Decimal2IP{
    ([System.Net.IPAddress]$_).IPAddressToString 
  }
  [UInt32]$ip = $IPAddress | Convert-IP2Decimal
  [UInt32]$subnet = $SubnetMask | Convert-IP2Decimal
  [UInt32]$broadcast = $ip -band $subnet 
  $secondlast = $broadcast -bor -bnot $subnet | Convert-Decimal2IP
  $bc = $secondlast.tostring()
  [int]$Ending = ($bc.split(".") | select -last 1) -2
  [Array]$Prefix = $bc.split(".") | select -first 3;
  $EndingIP = [string]($Prefix -join(".")) + "." + $Ending
  return $endingIP
}
Export-ModuleMember *