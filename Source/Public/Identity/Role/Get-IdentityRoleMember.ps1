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