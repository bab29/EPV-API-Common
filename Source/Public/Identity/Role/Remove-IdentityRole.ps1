<#
.SYNOPSIS
Removes an identity role from the system.

.DESCRIPTION
The Remove-IdentityRole function removes a specified identity role from the system.
It supports confirmation prompts and can be forced to bypass confirmation.
The function logs messages at various stages of execution.

.PARAMETER Force
A switch to force the removal without confirmation.

.PARAMETER IdentityURL
The URL of the identity service.

.PARAMETER LogonToken
The logon token for authentication.

.PARAMETER Role
The name of the role to be removed.

.EXAMPLE
Remove-IdentityRole -IdentityURL "https://example.com" -LogonToken $token -Role "Admin"

This command removes the "Admin" role from the identity service at "https://example.com".

.EXAMPLE
Remove-IdentityRole -IdentityURL "https://example.com" -LogonToken $token -Role "Admin" -Force

This command forcefully removes the "Admin" role from the identity service at "https://example.com" without confirmation.

.NOTES
The function logs messages at various stages of execution, including warnings and errors.
#>

function Remove-IdentityRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]
        $Force,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $Role
    )
    begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
    }
    process {
        Write-LogMessage -type Verbose -MSG "Removing role named `"$Role`""
        try {
            $RoleID = Get-IdentityRole -LogonToken $LogonToken -roleName "$Role" -IdentityURL $IdentityURL -IDOnly
            if ([string]::IsNullOrEmpty($RoleID)) {
                Write-LogMessage -type Warning -MSG "Role named `"$Role`" not found"
                return
            }
        }
        catch {
            Write-LogMessage -type Error -MSG $_
            return
        }
        $body = [PSCustomObject]@{ Name = $RoleID }
        if ($PSCmdlet.ShouldProcess($Role, 'Remove-IdentityRole')) {
            $result = Invoke-Rest -Uri "$IdentityURL/SaasManage/DeleteRole/" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99)
            if (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
            }
            else {
                Write-LogMessage -type Warning -MSG "Role named `"$Role`" successfully deleted"
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping removal of role `"$Role`" due to confirmation being denied"
        }
    }
}
