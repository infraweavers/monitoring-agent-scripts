$perfdata = "";

netstat -a -n -t -P TCP | 
    Where-Object { $_ -match '^\s*TCP\s' } | 
    Foreach-Object { $line = ($_ -Split '\s+'); $socket = $line[2] -split ":"; $state = $line[4]; "$($state)_$($socket[0])" } | 
    Group-Object -NoElement | Sort-Object |
        Foreach-Object { 
            $perfdata += "$($_.Name)=$($_.Count)connections;0;0 "
        };

Write-Host "OK|$perfdata";
exit 0;


