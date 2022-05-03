$nicStatus = Get-NetAdapter | ? { $_.Status -eq "Down" }

if($nicStatus.length -eq 0){
    $returnCode = 0
    $returnString = "OK"
}

if($nicStatus.length -gt 0){
    $returnCode = 2
    $returnString =  "CRITICAL - nics down"
}
 
Write-Host $returnString;
Exit $returnCode;

