if((repadmin /showrepl * /csv | select-string -Pattern "^showrepl_COLUMNS" -NotMatch | select-string -Pattern ",0$" -NotMatch | Measure-Object).Count -gt 0){
    Write-Host "WARNING - replication errors being reported."
    exit 1;
}
Write-Host "OK"
exit 0;


