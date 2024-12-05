#TODO Run Co-Pilot doc generator
function Set-SafeMember {
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
        [switch]$CreateOnMissing
    )
    Begin {
        $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/{0}/"
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
        if ($PSCmdlet.ShouldProcess($memberName, 'Set-SafeMember')) {
            Try {
                Write-LogMessage -type Verbose -MSG "Updating owner `"$memberName`" to safe `"$SafeName`""
                $URL = $SafeMemberURL -f $memberName
                Invoke-Rest -Uri $URL -Method PUT -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99)
                Write-LogMessage -type Verbose -MSG "Updated owner `"$memberName`" to safe `"$SafeName`" successfully"
            }
            Catch {
                If ($($PSItem.ErrorDetails.Message | ConvertFrom-Json).ErrorCode -eq "SFWS0012") {
                    IF ($CreateOnMissing) {
                        Write-LogMessage -type Verbose -MSG "Owner `"$memberName`" on `"$SafeName`" doesn't exist, adding instead"
                        $splatParams = @{
                            PVWAURL                                = $PVWAURL
                            LogonToken                             = $LogonToken
                            SafeName                               = $SafeName
                            memberName                             = $memberName
                            memberType                             = $MemberType
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
                        Add-SafeMember @splatParams
                    }
                    Else {
                        Write-LogMessage -type Warning -MSG "Owner `"$memberName`" on `"$SafeName`" does not exist, unable to set"
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to update Owner `"$memberName`" on `"$SafeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of owner `"$memberName`" to safe `"$SafeName`""
        }
    }
}
