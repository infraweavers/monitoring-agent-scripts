$Date = (Get-Date).AddMinutes(-10)
$events = Get-WinEvent -ErrorAction SilentlyContinue -FilterHashtable @{ LogName='Application'; ProviderName="Application Error"; StartTime=$Date } | Where-Object { $_.Message -like '*0xc00000fd*' }
$count = ($events | Measure-Object).Count
if($count -gt 0){
    Write-Host "CRITICAL - stack overflow event. | problem_count=$($count);0;0  "
    exit 2;
}

Write-Host "OK | problem_count=$($count);0;0  "
exit 0;


