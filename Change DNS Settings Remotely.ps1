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
