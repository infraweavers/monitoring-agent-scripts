$Date = (Get-Date).AddMinutes(-10)
$events = Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{ LogName='Application'; ProviderName="Application Error"; StartTime=$Date; Id='11' }
$count = ($events | Measure-Object).Count
if($count -gt 0){
    Write-Host "CRITICAL - remote procedure call error. | problem_count=$($count);0;0  "
    exit 2;
}

Write-Host "OK | problem_count=$($count);0;0  "
exit 0;


