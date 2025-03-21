<#
.SYNOPSIS
    Adds a member to a specified safe in the PVWA.

.DESCRIPTION
    The Add-SafeMember function adds a member to a specified safe in the PVWA with various permissions.
    This function supports ShouldProcess for safety and confirmation prompts.

.PARAMETER PVWAURL
    The URL of the PVWA instance.

.PARAMETER LogonToken
    The logon token for authentication.

.PARAMETER SafeName
    The name of the safe to which the member will be added.

.PARAMETER memberName
    The name of the member to be added to the safe.

.PARAMETER searchIn
    The search scope for the member.

.PARAMETER MemberType
    The type of the member (User, Group, Role).

.PARAMETER membershipExpirationDate
    The expiration date of the membership.

.PARAMETER useAccounts
    Permission to use accounts.

.PARAMETER retrieveAccounts
    Permission to retrieve accounts.

.PARAMETER listAccounts
    Permission to list accounts.

.PARAMETER addAccounts
    Permission to add accounts.

.PARAMETER updateAccountContent
    Permission to update account content.

.PARAMETER updateAccountProperties
    Permission to update account properties.

.PARAMETER initiateCPMAccountManagementOperations
    Permission to initiate CPM account management operations.

.PARAMETER specifyNextAccountContent
    Permission to specify next account content.

.PARAMETER renameAccounts
    Permission to rename accounts.

.PARAMETER deleteAccounts
    Permission to delete accounts.

.PARAMETER unlockAccounts
    Permission to unlock accounts.

.PARAMETER manageSafe
    Permission to manage the safe.

.PARAMETER manageSafeMembers
    Permission to manage safe members.

.PARAMETER backupSafe
    Permission to backup the safe.

.PARAMETER viewAuditLog
    Permission to view the audit log.

.PARAMETER viewSafeMembers
    Permission to view safe members.

.PARAMETER accessWithoutConfirmation
    Permission to access without confirmation.

.PARAMETER createFolders
    Permission to create folders.

.PARAMETER deleteFolders
    Permission to delete folders.

.PARAMETER moveAccountsAndFolders
    Permission to move accounts and folders.

.PARAMETER requestsAuthorizationLevel1
    Permission for requests authorization level 1.

.PARAMETER requestsAuthorizationLevel2
    Permission for requests authorization level 2.

.EXAMPLE
    Add-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "Finance" -memberName "JohnDoe" -MemberType "User" -useAccounts $true

.NOTES
    This function requires the PVWA URL and a valid logon token for authentication.
#>

function Add-SafeMember {
    [CmdletBinding(DefaultParameterSetName = "memberName", SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string] $SafeName,

        [Parameter(ParameterSetName = 'memberObject', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('SafeMember')]
        [string] $memberObject,

        [Parameter(ParameterSetName = 'memberName', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string] $memberName,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [string] $searchIn,

        [ValidateSet('User', 'Group', 'Role')]
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [string] $MemberType,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [int] $membershipExpirationDate,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $useAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $retrieveAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $listAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $addAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $updateAccountContent,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $updateAccountProperties,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $initiateCPMAccountManagementOperations,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $specifyNextAccountContent,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $renameAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $deleteAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $unlockAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $manageSafe,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $manageSafeMembers,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $backupSafe,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $viewAuditLog,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $viewSafeMembers,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $accessWithoutConfirmation,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $createFolders,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $deleteFolders,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $moveAccountsAndFolders,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $requestsAuthorizationLevel1,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $requestsAuthorizationLevel2,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$UpdateOnDuplicate
    )

    Begin {
        $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/"
    }

    Process {
        IF ($PsCmdlet.ParameterSetName -eq 'memberName') {

            $permissions = [SafePerms]@{
                useAccounts                            = $useAccounts
                retrieveAccounts                       = $retrieveAccounts
                listAccounts                           = $listAccounts
                addAccounts                            = $addAccounts
                updateAccountContent                   = $updateAccountContent
                updateAccountProperties                = $updateAccountProperties
                initiateCPMAccountManagementOperations = $initiateCPMAccountManagementOperations
                specifyNextAccountContent              = $specifyNextAccountContent
                renameAccounts                         = $renameAccounts
                deleteAccounts                         = $deleteAccounts
                unlockAccounts                         = $unlockAccounts
                manageSafe                             = $manageSafe
                manageSafeMembers                      = $manageSafeMembers
                backupSafe                             = $backupSafe
                viewAuditLog                           = $viewAuditLog
                viewSafeMembers                        = $viewSafeMembers
                accessWithoutConfirmation              = $accessWithoutConfirmation
                createFolders                          = $createFolders
                deleteFolders                          = $deleteFolders
                moveAccountsAndFolders                 = $moveAccountsAndFolders
                requestsAuthorizationLevel1            = $requestsAuthorizationLevel1
                requestsAuthorizationLevel2            = $requestsAuthorizationLevel2
            }

            $body = [SafeMember]@{
                memberName               = $memberName
                searchIn                 = $searchIn
                membershipExpirationDate = $membershipExpirationDate
                MemberType               = $MemberType
                Permissions              = $permissions
            }
        }
        elseif ($PsCmdlet.ParameterSetName -eq 'memberObject') {
            $memberName = $memberObject.memberName
            $body = $memberObject
        }

        if ($PSCmdlet.ShouldProcess($memberName, 'Add-SafeMember')) {
            Try {
                Write-LogMessage -type Verbose -MSG "Adding owner `"$memberName`" to safe `"$SafeName`""
                Invoke-Rest -Uri $SafeMemberURL -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99) -ErrAction SilentlyContinue
                Write-LogMessage -type Verbose -MSG "Added owner `"$memberName`" to safe `"$SafeName`" successfully"
            }
            Catch {
                If ($($PSItem.ErrorDetails.Message | ConvertFrom-Json).ErrorCode -eq "SFWS0012") {
                    IF ($UpdateOnDuplicate) {
                        Write-LogMessage -type Verbose -MSG "Owner `"$memberName`" on `"$SafeName`" already exist, updating instead"
                        $SetParams = @{
                            PVWAURL                                = $PVWAURL
                            LogonToken                             = $LogonToken
                            SafeName                               = $SafeName
                            memberName                             = $memberName
                            MemberType                             = $MemberType
                            searchIn                               = $searchIn
                            membershipExpirationDate               = $membershipExpirationDate
                            useAccounts                            = $useAccounts
                            retrieveAccounts                       = $retrieveAccounts
                            listAccounts                           = $listAccounts
                            addAccounts                            = $addAccounts
                            updateAccountContent                   = $updateAccountContent
                            updateAccountProperties                = $updateAccountProperties
                            initiateCPMAccountManagementOperations = $initiateCPMAccountManagementOperations
                            specifyNextAccountContent              = $specifyNextAccountContent
                            renameAccounts                         = $renameAccounts
                            deleteAccounts                         = $deleteAccounts
                            unlockAccounts                         = $unlockAccounts
                            manageSafe                             = $manageSafe
                            manageSafeMembers                      = $manageSafeMembers
                            backupSafe                             = $backupSafe
                            viewAuditLog                           = $viewAuditLog
                            viewSafeMembers                        = $viewSafeMembers
                            accessWithoutConfirmation              = $accessWithoutConfirmation
                            createFolders                          = $createFolders
                            deleteFolders                          = $deleteFolders
                            moveAccountsAndFolders                 = $moveAccountsAndFolders
                            requestsAuthorizationLevel1            = $requestsAuthorizationLevel1
                            requestsAuthorizationLevel2            = $requestsAuthorizationLevel2
                        }
                        Set-SafeMember @SetParams
                    }
                    Else {
                        Write-LogMessage -type Warning -MSG "Owner `"$memberName`" on `"$SafeName`"  already exists, skipping creation"
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to add Owner `"$memberName`" on `"$SafeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping addition of owner `"$memberName`" to safe `"$SafeName`""
        }
    }
}
