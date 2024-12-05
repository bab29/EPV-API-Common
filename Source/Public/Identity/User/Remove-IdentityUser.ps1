<#
.SYNOPSIS
Removes identity users from the system.

.DESCRIPTION
The Remove-IdentityUser function removes identity users from the system based on the provided parameters.
It supports confirmation prompts and can process input from the pipeline.

.PARAMETER Force
A switch to force the removal without confirmation.

.PARAMETER IdentityURL
The URL of the identity service.

.PARAMETER LogonToken
The logon token for authentication.

.PARAMETER User
The username of the identity user to be removed. This parameter can be provided from the pipeline by property name.

.PARAMETER mail
The email of the identity user to be removed. This parameter can be provided from the pipeline by property name.

.EXAMPLE
Remove-IdentityUser -IdentityURL "https://identity.example.com" -LogonToken $token -User "jdoe"

.EXAMPLE
Remove-IdentityUser -IdentityURL "https://identity.example.com" -LogonToken $token -mail "jdoe@example.com"

.NOTES
This function requires the Write-LogMessage and Invoke-Rest functions to be defined elsewhere in the script or module.
#>

function Remove-IdentityUser {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $User,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('email')]
        [string]
        $mail
    )

    begin {
        if ($Force) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        $userList = @()
        $userNames = @()
    }

    process {
        $userID = Get-IdentityUser @PSBoundParameters
        if ([string]::IsNullOrEmpty($userID)) {
            if ([string]::IsNullOrEmpty($User) -and [string]::IsNullOrEmpty($mail)) {
                Write-LogMessage -type Warning -MSG 'Username or mail not provided'
                return
            }
            elseif (![string]::IsNullOrEmpty($User)) {
                Write-LogMessage -type Warning -MSG "User `"$User`" not found"
                return
            }
            elseif (![string]::IsNullOrEmpty($mail)) {
                Write-LogMessage -type Warning -MSG "Mail `"$mail`" not found"
                return
            }
            else {
                Write-LogMessage -type Warning -MSG "User `"$User`" or mail `"$mail`" not found"
                return
            }
        }

        Write-LogMessage -type Info -MSG "A total of $($userID.Count) user accounts found"
        $userID | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.SystemName, 'Remove-IdentityUser')) {
                $userNames += [string]$_.SystemName
                $userList += [string]$_.InternalName
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of Identity User `"$User`" due to confirmation being denied"
            }
        }
    }

    end {
        try {
            if ($userList.Count -eq 0) {
                Write-LogMessage -type Warning -MSG 'No accounts found to delete'
                return
            }

            $UserJson = [pscustomobject]@{ Users = $userList }
            $result = Invoke-Rest -Uri "$IdentityURL/UserMgmt/RemoveUsers" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($UserJson | ConvertTo-Json -Depth 99)

            if ($result.success) {
                if ($result.Result.Exceptions.User.Count -ne 0) {
                    Write-LogMessage -type Error -MSG 'Users failed to remove, no logs given'
                }
                else {
                    Write-LogMessage -type Info -MSG "The following Users removed successfully:`n$userNames"
                }
            }
        }
        catch {
            Write-LogMessage -type Error -MSG "Error removing users:`n$_"
        }
    }
}
