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
