function Export-Safe {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $CSVPath = ".\SafeExport.csv",
        [switch]
        $Force,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Safe]
        $Safe,
        [switch]
        $IncludeAccounts,
        [switch]
        $IncludeDetails,
        # Parameter help description
        [Parameter(DontShow)]
        [switch]
        $includeSystemSafes,
        # Parameter help description
        [Parameter(DontShow)]
        [string[]]
        $CPMUser
    )
    begin {
        [String[]]$SafesToRemove = @('System', 'Pictures', 'VaultInternal', 'Notification Engine', 'SharedAuth_Internal', 'PVWAUserPrefs',
            'PVWAConfig', 'PVWAReports', 'PVWATaskDefinitions', 'PVWAPrivateUserPrefs', 'PVWAPublicData', 'PVWATicketingSystem',
            'AccountsFeed', 'PSM', 'xRay', 'PIMSuRecordings', 'xRay_Config', 'AccountsFeedADAccounts', 'AccountsFeedDiscoveryLogs', 'PSMSessions', 'PSMLiveSessions', 'PSMUniversalConnectors',
            'PSMNotifications', 'PSMUnmanagedSessionAccounts', 'PSMRecordings', 'PSMPADBridgeConf', 'PSMPADBUserProfile', 'PSMPADBridgeCustom', 'PSMPConf', 'PSMPLiveSessions'
            'AppProviderConf', 'PasswordManagerTemp', 'PasswordManager_Pending', 'PasswordManagerShared', 'SCIM Config', 'TelemetryConfig')
        [string[]]$cpmSafes = @()
        $CPMUser | ForEach-Object {
            $cpmSafes += "$($PSitem)"
            $cpmSafes += "$($PSitem)_Accounts"
            $cpmSafes += "$($PSitem)_ADInternal"
            $cpmSafes += "$($PSitem)_Info"
            $cpmSafes += "$($PSitem)_workspace"
        }
        $SafesToRemove += $cpmSafes
        $SafeCount = 0
        if (Test-Path $CSVPath) {
            Try {
                Write-LogMessage -type Verbose -msg "The file `'$CSVPath`' already exists. Checking for Force switch"
                If ($Force) {
                    Remove-Item $CSVPath
                    Write-LogMessage -type Verbose -msg "The file `'$CSVPath`' was removed."
                }
                else {
                    Write-LogMessage -type Verbose -msg "The file `'$CSVPath`' already exists and the switch `"Force`" was not passed. Exit with exit code 80"
                    Write-LogMessage -type Error -msg "The file `'$CSVPath`' already exists."
                    Exit 80
                }
            }
            catch {
                Write-LogMessage -type ErrorThrow -msg "Error while trying to remove`'$CSVPath`'"
            }
        }
    }
    Process {

        Try {
            IF (-not $includeSystemSafes) {
                If ($safe.SafeName -in $SafesToRemove) {
                    Write-LogMessage -type Verbose -msg "Safe `"$($Safe.SafeName)`" is a system safe, skipping"
                    return
                }
            }
            Write-LogMessage -type Verbose -msg "Working with safe `"$($Safe.Safename)`""
            $item = [pscustomobject]@{
                "Safe Name"        = $Safe.Safename
                "Description"      = $Safe.Description
                "Managing CPM"     = $Safe.managingCPM
                "Retention Policy" = $(if ([string]::IsNullOrEmpty($Safe.numberOfVersionsRetention)) { "$($Safe.numberOfDaysRetention) days" } else { "$($Safe.numberOfVersionsRetention) versions" })
                "Creation Date"    = ([datetime]'1/1/1970').ToLocalTime().AddSeconds($Safe.creationTime)
                "Last Modified"    = ([datetime]'1/1/1970').ToLocalTime().AddMicroseconds($Safe.lastModificationTime)
            }
            If ($IncludeDetails) {
                Write-LogMessage -type Verbose -msg "Including Details"
                $item | Add-Member -MemberType NoteProperty -Name "OLAC Enabled" -Value $safe.OLAC
                $item | Add-Member -MemberType NoteProperty -Name "Auto Purge Enabled" -Value $safe.autoPurgeEnabled
                $item | Add-Member -MemberType NoteProperty -Name "Safe ID" -Value $safe.safeNumber
                $item | Add-Member -MemberType NoteProperty -Name "Safe URL" -Value $safe.safeUrlId
                $item | Add-Member -MemberType NoteProperty -Name "Creator Name" -Value $Safe.Creator.Name
                $item | Add-Member -MemberType NoteProperty -Name "Creator ID" -Value $Safe.Creator.id
                $item | Add-Member -MemberType NoteProperty -Name "Location" -Value $safe.Location
                $item | Add-Member -MemberType NoteProperty -Name "Membership Expired" -Value $safe.isExpiredMember

            }
            If ($includeAccounts) {
                Write-LogMessage -type Verbose -msg "Including Accounts"
                $item.Accounts = $Safe.accounts.Name -join ", "
                $item | Add-Member -MemberType NoteProperty -Name "Accounts" -Value $($Safe.accounts.Name -join ", ")
            }
            Write-LogMessage -type Verbose -msg "Adding safe `"$($Safe.Safename)`" to CSV `"$CSVPath`""
            $item | Export-Csv -Append $CSVPath
            $SafeCount += 1
        }
        Catch {
            Write-LogMessage -type Error -msg $PSitem
        }
    }
    End {
        Write-LogMessage -type Info -msg "Exported $SafeCount safes succesfully"
        Write-LogMessage -Type Verbose -msg "Completed succesfully, returning exit code 0"
        Exit 0
    }
}