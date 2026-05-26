# Action1 Public Repository Material
# Subject to TERMS_OF_USE.md (https://github.com/Action1Corp/PSAction1/blob/main/TERMS_OF_USE.md)
# Provided AS IS
# Use at your own risk
# Review and test before production deployment
# © Action1 Corporation

#computers from a text file: 
Get-Content -Path c:\computers.txt | ForEach-Object { Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_Product -Computer $_ }

#computers from AD domain: 
Get-ADComputer -Filter { OperatingSystem -Like ‘Windows 10*’ } | ForEach-Object { Get-WmiObject -Namespace ROOT\CIMV2 -Class Win32_Product -Computer $_.Name }
