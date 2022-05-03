$disks = Get-WmiObject -Class Win32_logicaldisk | Where-Object { $_.DriveType -eq 3 }
$output = "OK";
$outputCritical = "CRITICAL -";
$critical = $false;
$outputWarning = "WARNING -";
$warning = $false;

$perfdata = "" 

$disks | % { 
    
    $space = $_.FreeSpace/$_.Size;
    $perfdata += "'$($_.DeviceID)\ free'=$($space*100)%;10;5;0;100 "
    
    if($space -lt 0.05){
        $outputCritical += " $($_.DeviceID),";
        $critical = $true;
    }
    
    if($space -lt 0.1){
        $outputWarning += " $($_.DeviceID),";
        $warning = $true;
    }
}

if($critical){
    Write-Host "$outputCritical | $perfdata";
    exit 2;
}

if($warning){
    Write-Host "$outputWarning | $perfdata";
    exit 1;
}

Write-Host "$output | $perfdata"


