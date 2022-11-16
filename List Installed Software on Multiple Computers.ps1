#computers from a text file: 
Get-Content -Path c:\computers.txt | ForEach-Object { Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_Product -Computer $_ }

#computers from AD domain: 
Get-ADComputer -Filter { OperatingSystem -Like ‘Windows 10*’ } | ForEach-Object { Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_Product -Computer $_.Name }
