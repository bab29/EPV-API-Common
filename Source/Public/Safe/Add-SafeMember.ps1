function Add-SafeMember {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url','PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [PSCustomObject]
        $body,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('perms')]
        [PSCustomObject]
        $permissions,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string]
        $memberName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $searchIn,
        [ValidateSet('User', 'Group', 'Role')]
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $MemberType,
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][int]
        $membershipExpirationDate,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $useAccounts,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $retrieveAccounts, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $listAccounts, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $addAccounts, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $updateAccountContent,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $updateAccountProperties, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $initiateCPMAccountManagementOperations, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $specifyNextAccountContent,
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $renameAccounts, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $deleteAccounts, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $unlockAccounts, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $manageSafe,
        [Parameter(ValueFromPipelineByPropertyName)] 
        [bool]
        $manageSafeMembers, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $backupSafe, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $viewAuditLog, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $viewSafeMembers, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $accessWithoutConfirmation, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $createFolders, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $deleteFolders, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $moveAccountsAndFolders, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $requestsAuthorizationLevel1, 
        [Parameter(ValueFromPipelineByPropertyName)]
        [bool]
        $requestsAuthorizationLevel2            
        
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        $SafeMemberURL = "$PVWAURL/API/Safes/{0}/Members/" -f $SafeName
        
    }
    process {
        $permissions = [pscustomobject]@{
            'useAccounts'                            = $useAccounts
            'retrieveAccounts'                       = $retrieveAccounts
            'listAccounts'                           = $listAccounts
            'addAccounts'                            = $addAccounts
            'updateAccountContent'                   = $updateAccountContent
            'updateAccountProperties'                = $updateAccountProperties
            'initiateCPMAccountManagementOperations' = $initiateCPMAccountManagementOperations
            'specifyNextAccountContent'              = $specifyNextAccountContent
            'renameAccounts'                         = $renameAccounts
            'deleteAccounts'                         = $deleteAccounts
            'unlockAccounts'                         = $unlockAccounts
            'manageSafe'                             = $manageSafe
            'manageSafeMembers'                      = $manageSafeMembers
            'backupSafe'                             = $backupSafe
            'viewAuditLog'                           = $viewAuditLog
            'viewSafeMembers'                        = $viewSafeMembers
            'accessWithoutConfirmation'              = $accessWithoutConfirmation
            'createFolders'                          = $createFolders
            'deleteFolders'                          = $deleteFolders
            'moveAccountsAndFolders'                 = $moveAccountsAndFolders
            'requestsAuthorizationLevel1'            = $requestsAuthorizationLevel1
            'requestsAuthorizationLevel2'            = $requestsAuthorizationLevel2
        }
        $body = [PSCustomObject]@{
            'memberName'               = $memberName
            'searchIn'                 = $searchIn
            'membershipExpirationDate' = $membershipExpirationDate
            'MemberType'               = $MemberType
            'Permissions'              = $permissions
        }
        Write-LogMessage -type Verbose -MSG "Adding owner `"memberName`" to safe `"$SafeName`"" 
        Invoke-Rest -Uri $SafeMemberURL -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($body | ConvertTo-Json -Depth 99)
    }

}