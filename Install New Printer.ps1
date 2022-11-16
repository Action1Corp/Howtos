Add-PrinterPort -Name “IP_192.168.10.26” -PrinterHostAddress “192.168.10.26”

#Before adding a port, you’d better check if it already exists or otherwise:

$portName = “IP_192.168.10.26”

$checkPortExists = Get-Printerport -Name $portname -ErrorAction SilentlyContinue

if (-not $checkPortExists) {

    Add-PrinterPort -name $portName -PrinterHostAddress “192.168.10.26” 
}

#To add a new printer in your operating system and then publish it, i.e. grant the shared access to it, you need to run the following command:

Add-Printer -Name hp2050_Office1_Buh -DriverName “HP Deskjet 2050 J510 series Class Driver” -PortName IP_192.168.10.26
-Shared -ShareName “hp2050_1_BUh” –Published
