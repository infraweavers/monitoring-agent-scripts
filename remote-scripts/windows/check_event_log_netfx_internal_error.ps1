$Date = (Get-Date).AddMinutes(-10)
$events = Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{ LogName='Application'; ProviderName=".NET Runtime"; StartTime=$Date; Id='1023' }
$count = ($events | Measure-Object).Count
if($count -gt 0){
    Write-Host "CRITICAL - .NET Runtime event | problem_count=$($count);0;0  "
    exit 2;
}

Write-Host "OK | problem_count=$($count);0;0 "
exit 0;


