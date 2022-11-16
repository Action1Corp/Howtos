
Get-MissingUpdates -Computername YOURCOMPUTER

function Get-MissingUpdates {

    [CmdletBinding()]

    [OutputType([System.Management.Automation.PSCustomObject])]

    param (

        [Parameter(Mandatory,

            ValueFromPipeline,

            ValueFromPipelineByPropertyName)]

        [string]$ComputerName)

    begin {

        function Get-32BitProgramFilesPath {

            if ((Get-Architecture) -eq 'x64') {

                ${ env:ProgramFiles(x86) }

            }
            else {

                $env:ProgramFiles

            }

        }

        function Get-Architecture {

            if ([System.Environment]::Is64BitOperatingSystem) {

                'x64'

            }
            else {

                'x86'

            }

        }

        $Output = @{ }

    }

    process {

        try {

            ## Remove any previous reports

            Get-ChildItem вЂњ$($Env:USERPROFILE)\SecurityScans\*вЂќ -Recurse -ea 'SilentlyContinue' | Remove-Item -Force -Recurse

            ## Run the report to create the output XML

            $ExeFilePath = вЂњ$(Get-32BitProgramFilesPath)\Microsoft Baseline Security Analyzer 2\mbsacli.exeвЂќ

            if (!(Test-Path $ExeFilePath)) {

                throw вЂњ$ExeFilePath not foundвЂќ

            }

            & $ExeFilePath /target $ComputerName /wi /nvc /o %C% 2>&1> $null

            ## Convert the report to XML so I can use it

            [xml]$ScanResults = Get-Content вЂњ$($Env:USERPROFILE)\SecurityScans\$($Computername.Split('.')[0]).mbsaвЂќ

            $UpdateSeverityLabels = @{

                '0' = 'Other'

                '1' = 'Low'

                '2' = 'Moderate'

                '3' = 'Important'

                '4' = 'Critical'

            }

            $MissingUpdates = $ScanResults.SelectNodes(вЂњ//Check[@Name='Windows Security Updates']/Detail/UpdateData[@IsInstalled='false']вЂќ)

            foreach ($Update in $MissingUpdates) {

                $Ht = @{ }

                $Properties = $Update | Get-Member -Type Property

                foreach ($Prop in $Properties) {

                    $Value = ($Update | select -expandproperty $Prop.Name)

                    if ($Prop.Name -eq 'Severity') {

                        $Value = $UpdateSeverityLabels[$Value]

                    }

                    $Ht[$Prop.Name] = $Value

                }

                [pscustomobject]$Ht

            }

        }
        catch {

            Write-Error вЂњError: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)вЂќ

        }

    }

}
