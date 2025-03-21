<#
.SYNOPSIS
Exports information about safes to a CSV file.

.DESCRIPTION
The Export-Safe function exports details about safes to a specified CSV file. It includes options to force overwrite the file, include account details, and include additional safe details. The function can also exclude system safes from the export.

.PARAMETER CSVPath
The path to the CSV file where the safe information will be exported. Default is ".\SafeExport.csv".

.PARAMETER Force
If specified, forces the overwrite of the existing CSV file.

.PARAMETER Safe
The safe object to be exported. This parameter is mandatory and accepts input from the pipeline.

.PARAMETER IncludeAccounts
If specified, includes account details in the export.

.PARAMETER IncludeDetails
If specified, includes additional details about the safe in the export.

.PARAMETER includeSystemSafes
If specified, includes system safes in the export. This parameter is hidden from the user.

.PARAMETER CPMUser
An array of CPM user names. This parameter is hidden from the user.

.EXAMPLE
Export-Safe -CSVPath "C:\Exports\SafeExport.csv" -Force -Safe $safe -IncludeAccounts -IncludeDetails

This example exports the details of the specified safe to "C:\Exports\SafeExport.csv", including account details and additional safe details, and forces the overwrite of the existing file.

.NOTES
The function logs messages at various stages of execution and handles errors gracefully. It exits with code 80 if the CSV file already exists and the Force switch is not specified.

#>

function Export-Safe {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $CSVPath = ".\SafeExport.csv",
        [switch] $Force,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Safe] $Safe,
        [switch] $IncludeAccounts,
        [switch] $IncludeDetails,
        [Parameter(DontShow)]
        [switch] $includeSystemSafes,
        [Parameter(DontShow)]
        [string[]] $CPMUser
    )
    begin {
        [String[]]$SafesToRemove = @(
            'System', 'Pictures', 'VaultInternal', 'Notification Engine', 'SharedAuth_Internal', 'PVWAUserPrefs',
            'PVWAConfig', 'PVWAReports', 'PVWATaskDefinitions', 'PVWAPrivateUserPrefs', 'PVWAPublicData', 'PVWATicketingSystem',
            'AccountsFeed', 'PSM', 'xRay', 'PIMSuRecordings', 'xRay_Config', 'AccountsFeedADAccounts', 'AccountsFeedDiscoveryLogs',
            'PSMSessions', 'PSMLiveSessions', 'PSMUniversalConnectors', 'PSMNotifications', 'PSMUnmanagedSessionAccounts',
            'PSMRecordings', 'PSMPADBridgeConf', 'PSMPADBUserProfile', 'PSMPADBridgeCustom', 'PSMPConf', 'PSMPLiveSessions',
            'AppProviderConf', 'PasswordManagerTemp', 'PasswordManager_Pending', 'PasswordManagerShared', 'SCIM Config', 'TelemetryConfig'
        )
        [string[]]$cpmSafes = @()
        $CPMUser | ForEach-Object {
            $cpmSafes += "$($_)"
            $cpmSafes += "$($_)_Accounts"
            $cpmSafes += "$($_)_ADInternal"
            $cpmSafes += "$($_)_Info"
            $cpmSafes += "$($_)_workspace"
        }
        $SafesToRemove += $cpmSafes
        $SafeCount = 0
        if (Test-Path $CSVPath) {
            try {
                Write-LogMessage -type Debug -MSG "The file '$CSVPath' already exists. Checking for Force switch"
                if ($Force) {
                    Remove-Item $CSVPath
                    Write-LogMessage -type Debug -MSG "The file '$CSVPath' was removed."
                } else {
                    Write-LogMessage -type Debug -MSG "The file '$CSVPath' already exists and the switch 'Force' was not passed."
                    Write-LogMessage -type Error -MSG "The file '$CSVPath' already exists."
                }
            } catch {
                Write-LogMessage -type ErrorThrow -MSG "Error while trying to remove '$CSVPath'"
            }
        }
    }
    process {
        try {
            if (-not $includeSystemSafes) {
                if ($safe.SafeName -in $SafesToRemove) {
                    Write-LogMessage -type Debug -MSG "Safe '$($Safe.SafeName)' is a system safe, skipping"
                    return
                }
            }
            Write-LogMessage -type Verbose -MSG "Working with safe '$($Safe.Safename)'"
            $item = [pscustomobject]@{
                "Safe Name"        = $Safe.Safename
                "Description"      = $Safe.Description
                "Managing CPM"     = $Safe.managingCPM
                "Retention Policy" = $(if ([string]::IsNullOrEmpty($Safe.numberOfVersionsRetention)) { "$($Safe.numberOfDaysRetention) days" } else { "$($Safe.numberOfVersionsRetention) versions" })
                "Creation Date"    = ([datetime]'1/1/1970').ToLocalTime().AddSeconds($Safe.creationTime)
                "Last Modified"    = ([datetime]'1/1/1970').ToLocalTime().AddMicroseconds($Safe.lastModificationTime)
            }
            if ($IncludeDetails) {
                Write-LogMessage -type Debug -MSG "Including Details"
                $item | Add-Member -MemberType NoteProperty -Name "OLAC Enabled" -Value $safe.OLAC
                $item | Add-Member -MemberType NoteProperty -Name "Auto Purge Enabled" -Value $safe.autoPurgeEnabled
                $item | Add-Member -MemberType NoteProperty -Name "Safe ID" -Value $safe.safeNumber
                $item | Add-Member -MemberType NoteProperty -Name "Safe URL" -Value $safe.safeUrlId
                $item | Add-Member -MemberType NoteProperty -Name "Creator Name" -Value $Safe.Creator.Name
                $item | Add-Member -MemberType NoteProperty -Name "Creator ID" -Value $Safe.Creator.id
                $item | Add-Member -MemberType NoteProperty -Name "Location" -Value $safe.Location
                $item | Add-Member -MemberType NoteProperty -Name "Membership Expired" -Value $safe.isExpiredMember
            }
            if ($IncludeAccounts) {
                Write-LogMessage -type Debug -MSG "Including Accounts"
                $item | Add-Member -MemberType NoteProperty -Name "Accounts" -Value $($Safe.accounts.Name -join ", ")
            }
            Write-LogMessage -type Debug -MSG "Adding safe '$($Safe.Safename)' to CSV '$CSVPath'"
            $item | Export-Csv -Append $CSVPath -NoTypeInformation
            $SafeCount += 1
        } catch {
            Write-LogMessage -type Error -MSG $_
        }
    }
    end {
        Write-LogMessage -type Info -MSG "Exported $SafeCount safes successfully"
        Write-LogMessage -type Debug -MSG "Completed successfully"
    }
}
