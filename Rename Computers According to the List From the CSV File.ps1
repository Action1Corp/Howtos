# Action1 Public Repository Material
# Subject to TERMS_OF_USE.md (https://github.com/Action1Corp/PSAction1/blob/main/TERMS_OF_USE.md)
# Provided AS IS
# Use at your own risk
# Review and test before production deployment
# © Action1 Corporation

$csvfile = "C:\temp\rename.csv";

Import-Csv $csvfile | foreach {

    $oldName = $_.OldName;
    
    $newName = $_.NewName;
    
    Write-Host "Renaming computer from: $oldName to: $newName";
    
    netdom renamecomputer $ oldName / newName: $ newName / userd: domain_name \ administrator_name / passwordd: domain_administrator_password / usero: local_administrator / passwordo: local_administrator_password_old_computer / reboot: time_in_seconds_to_auto_reboot;     
}
