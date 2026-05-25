# List All Missing Windows Updates.ps1

# Action1 Public Repository Material
# Subject to TERMS_OF_USE.md (https://github.com/Action1Corp/PSAction1/blob/main/TERMS_OF_USE.md)
# Provided AS IS
# Use at your own risk
# Review and test before production deployment
# © Action1 Corporation

function Get-MissingUpdates {
<#
.SYNOPSIS
Gets missing Windows security updates for one or more computers by using Microsoft Baseline Security Analyzer.

.DESCRIPTION
The Get-MissingUpdates function runs the Microsoft Baseline Security Analyzer command-line tool,
mbsacli.exe, against a target computer and reads the generated MBSA XML report.

It returns one custom PowerShell object for each missing Windows security update found in the report.

The function looks for mbsacli.exe under the 32-bit Program Files path, which is the default install
location for Microsoft Baseline Security Analyzer 2.

The function requires MBSA to be installed on the computer where the function is executed.

.PARAMETER ComputerName
Specifies the name of the computer to scan.

This parameter accepts input from the pipeline and by property name.

.EXAMPLE
Get-MissingUpdates -ComputerName SERVER01

Scans SERVER01 for missing Windows security updates and returns the missing update details.

.EXAMPLE
'SERVER01', 'SERVER02', 'SERVER03' | Get-MissingUpdates

Scans multiple computers from pipeline input.

.EXAMPLE
Get-Content .\servers.txt | Get-MissingUpdates

Scans each computer name listed in servers.txt.

.EXAMPLE
[pscustomobject]@{ ComputerName = 'SERVER01' } | Get-MissingUpdates

Uses pipeline input by property name.

.INPUTS
System.String

You can pipe computer names to this function.

.OUTPUTS
System.Management.Automation.PSCustomObject

Returns one object for each missing update detected by MBSA.

.NOTES
Requires:
- Windows PowerShell 5.1
- Microsoft Baseline Security Analyzer 2
- mbsacli.exe
- Appropriate network access and permissions to scan the target computer

The generated MBSA report is read from:

$env:USERPROFILE\SecurityScans

This function removes only likely existing MBSA report files for the current target computer before
running a new scan.

.LINK
Get-Help about_Comment_Based_Help
#>

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('CN', 'DNSHostName', 'HostName')]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    begin {
        function Get-32BitProgramFilesPath {
            $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')

            if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
                return $programFilesX86
            }

            return $env:ProgramFiles
        }

        $UpdateSeverityLabels = @{
            '0' = 'Other'
            '1' = 'Low'
            '2' = 'Moderate'
            '3' = 'Important'
            '4' = 'Critical'
        }

        $ExeFilePath = Join-Path `
            -Path (Get-32BitProgramFilesPath) `
            -ChildPath 'Microsoft Baseline Security Analyzer 2\mbsacli.exe'

        $ScanRoot = Join-Path `
            -Path $env:USERPROFILE `
            -ChildPath 'SecurityScans'
    }

    process {
        try {
            if (-not (Test-Path -LiteralPath $ExeFilePath -PathType Leaf)) {
                throw "MBSA command-line tool was not found: $ExeFilePath"
            }

            if (-not (Test-Path -LiteralPath $ScanRoot -PathType Container)) {
                New-Item -Path $ScanRoot -ItemType Directory -Force | Out-Null
            }

            $ShortComputerName = ($ComputerName -split '\.')[0]

            $ReportCandidates = @(
                Join-Path -Path $ScanRoot -ChildPath ('{0}.mbsa' -f $ComputerName)
                Join-Path -Path $ScanRoot -ChildPath ('{0}.mbsa' -f $ShortComputerName)
            ) | Select-Object -Unique

            foreach ($ReportCandidate in $ReportCandidates) {
                Remove-Item `
                    -LiteralPath $ReportCandidate `
                    -Force `
                    -ErrorAction SilentlyContinue
            }

            $ScanStarted = Get-Date

            $MbsaOutput = & $ExeFilePath /target $ComputerName /wi /nvc /o '%C%' 2>&1

            if ($LASTEXITCODE -ne 0) {
                $MbsaOutputText = ($MbsaOutput | Out-String).Trim()

                if ($MbsaOutputText) {
                    throw "mbsacli.exe returned exit code $LASTEXITCODE. Output: $MbsaOutputText"
                }

                throw "mbsacli.exe returned exit code $LASTEXITCODE."
            }

            $ReportPath = $ReportCandidates |
                Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
                Select-Object -First 1

            if (-not $ReportPath) {
                $NewestReport = Get-ChildItem `
                    -LiteralPath $ScanRoot `
                    -Filter '*.mbsa' `
                    -ErrorAction SilentlyContinue |
                    Where-Object {
                        -not $_.PSIsContainer -and
                        $_.LastWriteTime -ge $ScanStarted.AddSeconds(-5)
                    } |
                    Sort-Object -Property LastWriteTime -Descending |
                    Select-Object -First 1

                if ($NewestReport) {
                    $ReportPath = $NewestReport.FullName
                }
            }

            if (-not $ReportPath) {
                throw "MBSA completed, but no .mbsa report was found in '$ScanRoot' for '$ComputerName'."
            }

            [xml]$ScanResults = Get-Content `
                -LiteralPath $ReportPath `
                -Raw `
                -ErrorAction Stop

            $MissingUpdates = $ScanResults.SelectNodes(
                "//Check[@Name='Windows Security Updates']/Detail/UpdateData[@IsInstalled='false']"
            )

            foreach ($Update in $MissingUpdates) {
                $OutputObject = [ordered]@{
                    ComputerName = $ComputerName
                    ReportPath   = $ReportPath
                }

                foreach ($Attribute in $Update.Attributes) {
                    $Name = $Attribute.Name
                    $Value = $Attribute.Value

                    if ($Name -eq 'Severity' -and $UpdateSeverityLabels.ContainsKey($Value)) {
                        $Value = $UpdateSeverityLabels[$Value]
                    }

                    $OutputObject[$Name] = $Value
                }

                foreach ($ChildNode in $Update.ChildNodes) {
                    if (
                        $ChildNode.NodeType -eq [System.Xml.XmlNodeType]::Element -and
                        -not $OutputObject.Contains($ChildNode.Name)
                    ) {
                        $OutputObject[$ChildNode.Name] = $ChildNode.InnerText
                    }
                }

                [pscustomobject]$OutputObject
            }
        }
        catch {
            $LineNumber = $_.InvocationInfo.ScriptLineNumber

            Write-Error -Message (
                "Get-MissingUpdates failed for '{0}': {1} Line: {2}" -f `
                    $ComputerName,
                    $_.Exception.Message,
                    $LineNumber
            )
        }
    }
}