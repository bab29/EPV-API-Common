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
    process {
        Write-LogMessage -Type Verbose -MSG "Adding `"$User`" to role `"$RoleName`""
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
                Name = $rolesResult
            }
            try {
                if ($PSCmdlet.ShouldProcess($User, 'Add-IdentityRoleToUser')) {
                    Write-LogMessage -Type Verbose -MSG "Adding `"$RoleName`" to user `"$User`""
                    $result = Invoke-Rest -Uri "$IdentityURL/Roles/UpdateRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body $($addUserToRole | ConvertTo-Json -Depth 99)
                    if ($result.success) {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -Type Info -MSG "Role `"$RoleName`" added to user `"$User`""
                        }
                        else {
                            Write-LogMessage -Type Info -MSG "Role `"$RoleName`" added to all users"
                        }
                    }
                    else {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -Type Error -MSG "Error adding `"$RoleName`" to user `"$User`": $($response.Message)"
                        }
                        else {
                            Write-LogMessage -Type Error -MSG "Error adding `"$RoleName`" to users: $($response.Message)"
                        }
                    }
                }
                else {
                    Write-LogMessage -Type Warning -MSG "Skipping addition of role `"$RoleName`" to user `"$User`" due to confirmation being denied"
                }
            }
            catch {
                Write-LogMessage -Type Error -MSG "Error while trying to add users to `"$RoleName`": $PSItem"
            }
        }
    }
}
