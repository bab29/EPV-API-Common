<#
.SYNOPSIS
Removes a specified role from one or more users.

.DESCRIPTION
The Remove-IdentityRoleFromUser function removes a specified role from one or more users in an identity management system.
It supports pipeline input and can be forced to bypass confirmation prompts.

.PARAMETER roleName
The name of the role to be removed from the users.

.PARAMETER IdentityURL
The URL of the identity management system.

.PARAMETER LogonToken
The authentication token required to log on to the identity management system.

.PARAMETER User
An array of users from whom the role will be removed.

.PARAMETER Force
A switch to bypass confirmation prompts.

.INPUTS
System.String
System.String[]

.OUTPUTS
None

.EXAMPLE
PS> Remove-IdentityRoleFromUser -roleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token -User "user1"

Removes the "Admin" role from "user1".

.EXAMPLE
PS> "user1", "user2" | Remove-IdentityRoleFromUser -roleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token

Removes the "Admin" role from "user1" and "user2".

.NOTES
This function requires the Write-LogMessage and Get-IdentityRole functions to be defined in the session.
#>

function Remove-IdentityRoleFromUser {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('role')]
        [string]
        $roleName,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Users')]
        [string[]]
        $User
    )
    begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        Write-LogMessage -type Verbose -MSG "Starting removal of users from role named `"$roleName`""
        $rolesResult = Get-IdentityRole @PSBoundParameters -IDOnly
        if ($rolesResult.Count -eq 0) {
            Write-LogMessage -type Error -MSG 'No roles Found'
            return
        }
        elseif ($rolesResult.Count -ge 2) {
            Write-LogMessage -type Error -MSG 'Multiple roles found, please enter a unique role name and try again'
            return
        }
    }
    process {
        foreach ($user in $User) {
            if ($PSCmdlet.ShouldProcess($user, "Remove-IdentityRoleFromUser $roleName")) {
                $removeUserFromRole = [PSCustomObject]@{
                    Users = [PSCustomObject]@{
                        Delete = $User
                    }
                    Name  = $($rolesResult)
                }
                try {
                    $result = Invoke-Rest -Uri "$IdentityURL/Roles/UpdateRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($removeUserFromRole | ConvertTo-Json -Depth 99)
                    if ($result.success) {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Info -MSG "Role `"$roleName`" removed from user `"$user`""
                        }
                        else {
                            Write-LogMessage -type Info -MSG "Role `"$roleName`" removed from all users"
                        }
                    }
                    else {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Error -MSG "Error removing `"$roleName`" from user `"$user`": $($result.Message)"
                        }
                        else {
                            Write-LogMessage -type Error -MSG "Error removing `"$roleName`" from users: $($result.Message)"
                        }
                    }
                }
                catch {
                    Write-LogMessage -type Error -MSG "Error while trying to remove users from `"$roleName`": $_"
                }
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of user $user from role `"$roleName`" due to confirmation being denied"
            }
        }
    }
}
