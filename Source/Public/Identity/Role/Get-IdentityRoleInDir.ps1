<#
.SYNOPSIS
Retrieves identity roles and rights from a specified directory.

.DESCRIPTION
The Get-IdentityRoleInDir function sends a POST request to the specified IdentityURL to retrieve roles and rights for a given directory. The function requires an identity URL, a logon token, and a directory identifier.

.PARAMETER IdentityURL
The URL of the identity service endpoint.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER Directory
The unique identifier of the directory service.

.EXAMPLE
PS> Get-IdentityRoleInDir -IdentityURL "https://example.com" -LogonToken $token -Directory "12345"
This example retrieves the roles and rights for the directory with the identifier "12345" from the specified identity service URL.

.NOTES
The function removes the CatchAll parameter from the bound parameters before processing the request.
#>
function Get-IdentityRoleInDir {
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('DirectoryServiceUuid', '_ID')]
        [string]
        $Directory
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        $result = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryRolesAndRights?path=$Directory" -Method POST -Headers $LogonToken -ContentType 'application/json'
        return $result.result.Results.Row
    }
}
