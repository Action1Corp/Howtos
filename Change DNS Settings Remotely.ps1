# Action1 Public Repository Material
# Subject to TERMS_OF_USE.md (https://github.com/Action1Corp/PSAction1/blob/main/TERMS_OF_USE.md)
# Provided AS IS
# Use at your own risk
# Review and test before production deployment
# © Action1 Corporation

function Set-DnsServerIpAddress {

    param(
    
        [string] $ComputerName,
    
        [string] $NicName,
    
        [string] $IpAddresses
    
    )
    
    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) {
    
        Invoke-Command -ComputerName $ComputerName -ScriptBlock { param ($ComputerName, $NicName, $IpAddresses)
    
            write-host “Setting on $ComputerName on interface $NicName a new set of DNS Servers $IpAddresses”
    
            Set-DnsClientServerAddress -InterfaceAlias $NicName -ServerAddresses $IpAddresses
    
        } -ArgumentList $ComputerName, $NicName, $IpAddresses
    
    }
    else {
    
        write-host “Can't access $ComputerName. Computer is not online.”
    
    }     
    
}
