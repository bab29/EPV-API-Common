function Export-SafeMember {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $CSVPath = ".\SafeMemberExport.csv",
        [switch]
        $Force,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SafeMember]
        $SafeMember,
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
        $SafeMemberCount = 0
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
                If ($PSitem.SafeName -in $SafesToRemove) {
                    Write-LogMessage -type Verbose -msg "Safe `"$($PSitem.SafeName)`" is a system safe, skipping"
                    return
                }
            }
            Write-LogMessage -type Verbose -msg "Working with safe `"$($PSitem.Safename)`" and safe member `"$($PSitem.memberName)`""
            $item = [pscustomobject]@{
                "Safe Name"                                  = $PSitem.safeName
                "Member Name"                                = $PSitem.memberName
                "Member Type"                                = $PSitem.memberType
                "Use Accounts"                               = $PSitem.Permissions.useAccounts
                "Retrieve Accounts"                          = $PSitem.Permissions.retrieveAccounts
                "Add Accounts"                               = $PSitem.Permissions.addAccounts
                "Update Account Properties"                  = $PSitem.Permissions.updateAccountProperties
                "Update Account Content"                     = $PSitem.Permissions.updateAccountContent
                "Initiate CPM Account Management Operations" = $PSitem.Permissions.initiateCPMAccountManagementOperations
                "Specify Next Account Content"               = $PSitem.Permissions.specifyNextAccountContent
                "Rename Account"                             = $PSitem.Permissions.renameAccounts
                "Delete Account"                             = $PSitem.Permissions.deleteAccounts
                "Unlock Account"                             = $PSitem.Permissions.unlockAccounts
                "Manage Safe"                                = $PSitem.Permissions.manageSafe
                "View Safe Members"                          = $PSitem.Permissions.viewSafeMembers
                "Manage Safe Members"                        = $PSitem.Permissions.manageSafeMembers
                "View Audit Log"                             = $PSitem.Permissions.viewAuditLog
                "Backup Safe"                                = $PSitem.Permissions.backupSafe
                "Level 1 Confirmer"                          = $PSitem.Permissions.requestsAuthorizationLevel1
                "Level 2 Confirmer"                          = $PSitem.Permissions.requestsAuthorizationLevel2
                "Access Safe Without Confirmation"           = $PSitem.Permissions.accessWithoutConfirmation
                "Move Accounts / Folders"                    = $PSitem.Permissions.moveAccountsAndFolders
                "Create Folders"                             = $PSitem.Permissions.createFolders
                "Delete Folders"                             = $PSitem.Permissions.deleteFolders

            }

            Write-LogMessage -type Verbose -msg "Adding safe `"$($PSitem.Safename)`" and safe member `"$($PSitem.memberName)`" to CSV `"$CSVPath`""
            $item | Export-Csv -Append $CSVPath
            $SafeMemberCount += 1
        }
        Catch {
            Write-LogMessage -type Error -msg $PSitem
        }
    }
    End {
        Write-LogMessage -type Info -msg "Exported $SafeMemberCount safe members succesfully"
        Write-LogMessage -Type Verbose -msg "Completed succesfully, returning exit code 0"
        Exit 0
    }
}