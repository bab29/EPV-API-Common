<#
.SYNOPSIS
Exports safe member information to a CSV file.

.DESCRIPTION
The Export-SafeMember function exports information about safe members to a specified CSV file.
It allows filtering out system safes and includes options to force overwrite the CSV file if it already exists.

.PARAMETER CSVPath
Specifies the path to the CSV file where the safe member information will be exported.
Defaults to ".\SafeMemberExport.csv".

.PARAMETER Force
If specified, forces the overwrite of the CSV file if it already exists.

.PARAMETER SafeMember
Specifies the safe member object to be exported. This parameter is mandatory and accepts input from the pipeline.

.PARAMETER includeSystemSafes
If specified, includes system safes in the export. This parameter is hidden from the help documentation.

.PARAMETER CPMUser
Specifies an array of CPM user names. This parameter is hidden from the help documentation.

.EXAMPLE
Export-SafeMember -CSVPath "C:\Exports\SafeMembers.csv" -SafeMember $safeMember

This example exports the safe member information to "C:\Exports\SafeMembers.csv".

.EXAMPLE
$safeMembers | Export-SafeMember -CSVPath "C:\Exports\SafeMembers.csv" -Force

This example exports the safe member information from the pipeline to "C:\Exports\SafeMembers.csv",
forcing the overwrite of the file if it already exists.

.NOTES
The function logs verbose messages about its operations and handles errors gracefully.
#>
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
                Write-LogMessage -type Verbose -MSG "The file `'$CSVPath`' already exists. Checking for Force switch"
                If ($Force) {
                    Remove-Item $CSVPath
                    Write-LogMessage -type Verbose -MSG "The file `'$CSVPath`' was removed."
                }
                else {
                    Write-LogMessage -type Verbose -MSG "The file `'$CSVPath`' already exists and the switch `"Force`" was not passed."
                    Write-LogMessage -type Error -MSG "The file `'$CSVPath`' already exists."
                    Exit 80
                }
            }
            catch {
                Write-LogMessage -type ErrorThrow -MSG "Error while trying to remove`'$CSVPath`'"
            }
        }
    }
    Process {

        Try {
            IF (-not $includeSystemSafes) {
                If ($PSitem.SafeName -in $SafesToRemove) {
                    Write-LogMessage -type Verbose -MSG "Safe `"$($PSitem.SafeName)`" is a system safe, skipping"
                    return
                }
            }
            Write-LogMessage -type Verbose -MSG "Working with safe `"$($PSitem.Safename)`" and safe member `"$($PSitem.memberName)`""
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

            Write-LogMessage -type Verbose -MSG "Adding safe `"$($PSitem.Safename)`" and safe member `"$($PSitem.memberName)`" to CSV `"$CSVPath`""
            $item | Export-Csv -Append $CSVPath
            $SafeMemberCount += 1
        }
        Catch {
            Write-LogMessage -type Error -MSG $PSitem
        }
    }
    End {
        Write-LogMessage -type Info -MSG "Exported $SafeMemberCount safe members succesfully"
        Write-LogMessage -type Verbose -MSG "Completed successfully"
    }
}
