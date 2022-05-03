$Date = (Get-Date).AddMinutes(-10)
$events = Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{ LogName='Application'; ProviderName="Application Error"; StartTime=$Date; Id='1000' } | Where-Object { $_.Message -like '*Faulting application name: w3wp.exe*' }
$count = ($events | Measure-Object).Count
if($count -gt 0){
    Write-Host "CRITICAL - w3wp event. | problem_count=$($count);0;0  "
    exit 2;
}

Write-Host "OK | problem_count=$($count);0;0  "
exit 0;


