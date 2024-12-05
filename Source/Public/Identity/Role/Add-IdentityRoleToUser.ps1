<#
.SYNOPSIS
Adds a specified identity role to one or more users.

.DESCRIPTION
The Add-IdentityRoleToUser function assigns a specified role to one or more users by making a REST API call to update the role. It supports ShouldProcess for confirmation prompts and logs detailed messages about the operation.

.PARAMETER RoleName
The name of the role to be added to the users. This parameter is mandatory and accepts pipeline input.

.PARAMETER IdentityURL
The base URL of the identity service. This parameter is mandatory.

.PARAMETER LogonToken
The authentication token required to log on to the identity service. This parameter is mandatory.

.PARAMETER User
An array of user identifiers to which the role will be added. This parameter is mandatory and accepts pipeline input.

.EXAMPLE
PS> Add-IdentityRoleToUser -RoleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token -User "user1"

Adds the "Admin" role to the user "user1".

.EXAMPLE
PS> "user1", "user2" | Add-IdentityRoleToUser -RoleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token

Adds the "Admin" role to the users "user1" and "user2".

.NOTES
This function requires the Write-LogMessage and Invoke-Rest functions to be defined in the session.
#>
function Add-IdentityRoleToUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('role')]
        [ValidateNotNullOrEmpty()]
        [string]
        $RoleName,
        [Parameter(Mandatory)]
        [Alias('url')]
        [ValidateNotNullOrEmpty()]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        [ValidateNotNullOrEmpty()]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Users', 'Member')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $User
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -MSG "Adding `"$User`" to role `"$RoleName`""
        $rolesResult = Get-IdentityRole @PSBoundParameters -IDOnly

        if ($rolesResult.Count -eq 0) {
            Throw "Role `"$RoleName`" not found"
        }
        elseif ($rolesResult.Count -ge 2) {
            Throw "Multiple roles found, please enter a unique role name and try again"
        }
        else {
            $addUserToRole = [PSCustomObject]@{
                Users = [PSCustomObject]@{
                    Add = $User
                }
                Name  = $rolesResult
            }
            try {
                if ($PSCmdlet.ShouldProcess($User, 'Add-IdentityRoleToUser')) {
                    Write-LogMessage -type Verbose -MSG "Adding `"$RoleName`" to user `"$User`""
                    $result = Invoke-Rest -Uri "$IdentityURL/Roles/UpdateRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body $($addUserToRole | ConvertTo-Json -Depth 99)
                    if ($result.success) {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Info -MSG "Role `"$RoleName`" added to user `"$User`""
                        }
                        else {
                            Write-LogMessage -type Info -MSG "Role `"$RoleName`" added to all users"
                        }
                    }
                    else {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Error -MSG "Error adding `"$RoleName`" to user `"$User`": $($result.Message)"
                        }
                        else {
                            Write-LogMessage -type Error -MSG "Error adding `"$RoleName`" to users: $($result.Message)"
                        }
                    }
                }
                else {
                    Write-LogMessage -type Warning -MSG "Skipping addition of role `"$RoleName`" to user `"$User`" due to confirmation being denied"
                }
            }
            catch {
                Write-LogMessage -type Error -MSG "Error while trying to add users to `"$RoleName`": $_"
            }
        }
    }
}
