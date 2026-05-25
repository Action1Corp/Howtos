# Action1 Public Repository Material
# Subject to TERMS_OF_USE.md (https://github.com/Action1Corp/PSAction1/blob/main/TERMS_OF_USE.md)
# Provided AS IS
# Use at your own risk
# Review and test before production deployment
# © Action1 Corporation

function delete-remotefile {
    PROCESS {
        $file = "\\$_\c$\install.exe"
        if (test-path $file) {
            echo "$_ install.exe exists"
            Remove-Item $file -force
            echo "$_ install.exe file deleted"
        }
    }
}
Get-Content C:\Scripts\Active_Computers.txt | delete-remotefile
