<#
.SYNOPSIS
${1:Short description}
.DESCRIPTION
${2:Long description}
.PARAMETER CatchAll
${3:Parameter description}
.PARAMETER roleName
${4:Parameter description}
.PARAMETER IdentityURL
${5:Parameter description}
.PARAMETER LogonToken
${6:Parameter description}
.PARAMETER User
${7:Parameter description}
.EXAMPLE
${8:An example}
.NOTES
${9:General notes}
#>
function Add-IdentityRoleToUser {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
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
        [Alias('Users','Member')]
        [string[]]
        $User
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    process {
        Write-LogMessage -type Verbose -MSG "Adding `"$user`" to role `"$roleName`""
        $rolesResult = Get-IdentityRole @PSBoundParameters -IDOnly
        IF (0 -eq $rolesResult.count) {
            Write-LogMessage -type Error -MSG "Role `"$roleName`" not found"
            Return
        }
        elseif (2 -le $rolesResult.Count) {
            Write-LogMessage -type Error -MSG 'Multiple roles found, please enter a uqniue role name and try again'
            Return
        }
        else {
            $addUserToRole = [PSCustomObject]@{
                Users = [PSCustomObject]@{
                    Add = $User
                }
                Name  = $($rolesResult)
            }
            Try {
                $result = Invoke-Rest -Uri "$IdentityURL/Roles/UpdateRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body $($addUserToRole | ConvertTo-Json -Depth 99)
                If ([bool]$result.success) {
                    If (1 -eq $user.Count) {
                        Write-LogMessage -type Info -MSG "Role `"$roleName`" added to user `"$user`""
                    }
                    Else {
                        Write-LogMessage -type Info -MSG "Role `"$roleName`" added to all users"
                    }
                }
                else {
                    If (1 -eq $user.Count) {
                        Write-LogMessage -type Error -MSG  "Error adding `"$roleName`" to user `"$user`": $($response.Message)"
                    }
                    Else {
                        Write-LogMessage -type Error -MSG  "Error adding `"$roleName`" to users: $($response.Message)"
                    }
                }
            }
            Catch {
                Write-LogMessage -type Error -MSG  "Error while trying to add users to `"$roleName`" : $PSItem "
            }
        }
    }
}