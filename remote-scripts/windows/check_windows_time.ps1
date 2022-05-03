$w32tm = w32tm /stripchart /computer:ntp01.cwserverfarm.local /samples:1 /dataonly

$w32tm | % { $_ -match "^[0-9]{2}:[0-9]{2}:[0-9]{2}, ([\-+][0-9]+\.[0-9]+)s$" } | Out-Null

$string = [Double]::Parse($matches[1])

$offset = [Math]::abs([Double]::Parse($string))

$warning = 1.5

$critical = 3

if (((Get-WmiObject Win32_OperatingSystem).Caption).StartsWith("Microsoft Windows Server 2008 R2")) {

    $warning *= 2;

}

if($offset -gt $warning){
    Write-Host "WARNING - Offset is greater than $warning seconds. | 'Offset'=$($string)s;$($warning);$($critical);0;";
    Exit 1;
}

if($offset -gt $critical){
    Write-Host "CRITICAL - Offset is greater than $critical seconds. | 'Offset'=$($string)s;$($warning);$($critical);0;";
    Exit 2;
}

Write-Host "OK | 'Offset'=$($string)s;$($warning);$($critical);0;"


