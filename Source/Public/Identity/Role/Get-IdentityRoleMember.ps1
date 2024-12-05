<#
.SYNOPSIS
Retrieves members of a specified identity role.

.DESCRIPTION
The Get-IdentityRoleMember function sends a POST request to the specified Identity URL to retrieve members of a role identified by its UUID. The function requires a logon token for authentication.

.PARAMETER IdentityURL
The base URL of the identity service.

.PARAMETER LogonToken
The authentication token required to access the identity service.

.PARAMETER UUID
The unique identifier of the role whose members are to be retrieved.

.EXAMPLE
PS> Get-IdentityRoleMember -IdentityURL "https://identity.example.com" -LogonToken $token -UUID "12345"

.NOTES
The function removes any additional parameters passed to it using the CatchAll parameter.
#>
function Get-IdentityRoleMember {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('role', '_ID', "ID")]
        [string]
        $UUID
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    process {
        $result = Invoke-RestMethod -Uri "$IdentityURL/Roles/GetRoleMembers?name=$UUID" -Method POST -Headers $logonToken -ContentType 'application/json'
        If (-not [string]::IsNullOrEmpty($result.result.Results.Row)) {
            $result.result.Results.Row | Add-Member -MemberType NoteProperty -Name "RoleUUID" -Value $UUID
            Return $result.result.Results.Row
        }

    }
}
