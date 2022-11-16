# List of accounts whose profiles cannot be deleted

$ExcludedUsers = ”Public”, ”zenoss”, ”svc”, ”user_1”, ”user_2”

$LocalProfiles = Get-WMIObject -class Win32_UserProfile | Where { (!$_.Special) -and (!$_.Loaded) -and ($_.ConvertToDateTime($_.LastUseTime) -lt (Get-Date).AddDays(-60)) }

foreach ($LocalProfile in $LocalProfiles) {

    if (!($ExcludedUsers -like $LocalProfile.LocalPath.Replace(“C:\Users\”, ””))) {

        $LocalProfile | Remove-WmiObject

        Write-host $LocalProfile.LocalPath, “profile deleted” -ForegroundColor Magenta

    }

}
