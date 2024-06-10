    <#
.Synopsis
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
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
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        Write-LogMessage -type Verbose -MSG "Starting removal of users from role named `"$roleName`""
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        $rolesResult = Get-IdentityRole @PSBoundParameters -IDOnly
        IF (0 -eq $rolesResult.count) {
            Write-LogMessage -type Error -MSG 'No roles Found'
            Return
        }
        elseif (2 -le $rolesResult.Count) {
            Write-LogMessage -type Error -MSG 'Multiple roles found, please enter a uqniue role name and try again'
            Return
        }
    }
    process {
        if ($PSCmdlet.ShouldProcess($user, "Remove-IdentityRoleFromUser $roleName")) {
            $addUserToRole = [PSCustomObject]@{
                Users = [PSCustomObject]@{
                    Delete = $User
                }
                Name  = $($rolesResult)
            }
            Try {
                $result = Invoke-RestMethod -Uri "$IdentityURL/Roles/UpdateRole" -Method POST -Headers $header -ContentType 'application/json' -Body $($addUserToRole | ConvertTo-Json -Depth 99)
                If ([bool]$result.success) {
                    If (1 -eq $user.Count) {
                        Write-LogMessage -type Info -MSG "Role `"$roleName`" removed from user `"$user`""
                    }
                    Else {
                        Write-LogMessage -type Info -MSG "Role `"$roleName`" removed from all users"
                    }
                }
                else {
                    If (1 -eq $user.Count) {
                        Write-LogMessage -type Error -MSG "Error removing `"$roleName`" from user `"$user`": $($response.Message)"
                    }
                    Else {
                        Write-LogMessage -type Error -MSG "Error removing `"$roleName`" from users: $($response.Message)"
                    }
                }
            }
            Catch {
                Write-LogMessage -type Error -MSG "Error while trying to remove users from `"$roleName`" : $PSItem "
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping removal of user $user from role  `"$roleName`" due to confimation being denied"
        }
    }
}