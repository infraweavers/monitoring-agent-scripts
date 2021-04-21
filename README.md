[![License: MIT](https://img.shields.io/github/license/infraweavers/monitoring-agent-scripts)](https://mit-license.org/)

# monitoring-agent-scripts
A selection of scripts for use with [Monitoring Agent](https://github.com/infraweavers/monitoring-agent)

### **check_script_via_monitoring_agent.pl** by Example

To run the a script called `check_application-list.ps1` stored on the monitoring host against a monitored remote host...

...via the command line:

```
/check_script_via_monitoring-agent.pl --template=application_whitelist --host=HostToCheck --port=9000 --username="test" --password="secret" --executable='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' --script=/lib/monitoring-plugins/remote-scripts/check_application_list.ps1 -- -command -
```

...via Naemon (Command and Service Definitions):

```
define command {
                command_name                          check_script_via_monitoring_agent
                command_line                          $USER2$/check_script_via_monitoring-agent.pl --template=application_whitelist --host=$HOSTADDRESS$ --port=9000 --username="test" --password="secret" --executable='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' --script=$ARG2$ -- -command -
}

define service {
                service_description                   Application Whitelist
                check_command                         check_script_via_monitoring_agent!application_whitelist!/lib/monitoring-plugins/remote-scripts/check_application_list.ps1
                hostgroup_name                        myServers
                use                                   Generic_ServiceTemplate
}
```
