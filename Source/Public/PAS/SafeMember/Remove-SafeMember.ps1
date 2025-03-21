<#
.SYNOPSIS
Removes a member from a specified safe in the PVWA.

.DESCRIPTION
The Remove-SafeMember function removes a specified member from a safe in the PVWA (Privileged Vault Web Access).
It supports confirmation prompts and logging of actions.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER SafeName
The name of the safe from which the member will be removed.

.PARAMETER memberName
The name of the member to be removed from the safe.

.EXAMPLE
Remove-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "FinanceSafe" -memberName "JohnDoe"

This command removes the member "JohnDoe" from the safe "FinanceSafe" in the specified PVWA instance.

.NOTES
- This function supports ShouldProcess for safety.
- The ConfirmImpact is set to High, so confirmation is required by default.
- The function logs actions and warnings using Write-LogMessage.
#>
function Remove-SafeMember {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string]
        $memberName
    )

    Begin {
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
    }

    Process {
        $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/$memberName/"
        if ($PSCmdlet.ShouldProcess($memberName, 'Remove-SafeMember')) {
            Write-LogMessage -type Verbose -MSG "Removing member `$memberName` from safe `$SafeName`""
            Invoke-Rest -Uri $SafeMemberURL -Method DELETE -Headers $LogonToken -ContentType 'application/json'
        } else {
            Write-LogMessage -type Warning -MSG "Skipping removal of member `$memberName` from safe `$SafeName` due to confirmation being denied"
        }
    }
}
