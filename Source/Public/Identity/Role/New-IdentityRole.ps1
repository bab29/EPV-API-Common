<#
.SYNOPSIS
Creates a new identity role.

.DESCRIPTION
The `New-IdentityRole` function creates a new identity role with specified parameters such as role name, role type, users, roles, and groups. It sends a POST request to the specified Identity URL to store the role.

.PARAMETER IdentityURL
The URL of the identity service where the role will be created.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER roleName
The name of the role to be created.

.PARAMETER Description
A description of the role.

.PARAMETER RoleType
The type of the role. Valid values are 'PrincipalList', 'Script', and 'Everybody'. Default is 'PrincipalList'.

.PARAMETER Users
An array of users to be added to the role.

.PARAMETER Roles
An array of roles to be added to the role.

.PARAMETER Groups
An array of groups to be added to the role.

.EXAMPLE
PS> New-IdentityRole -IdentityURL "https://identity.example.com" -LogonToken $token -roleName "Admin" -Description "Administrator role" -RoleType "PrincipalList" -Users "user1", "user2"

Creates a new role named "Admin" with the specified users.

.NOTES
The function supports ShouldProcess for safety and confirmation prompts.
#>
function New-IdentityRole {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
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
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $roleName,
        [Alias('desc')]
        [string]
        $Description,
        [ValidateSet('PrincipalList', 'Script', 'Everybody')]
        [string]
        $RoleType = 'PrincipalList',
        [Alias('User')]
        [string[]]
        $Users,
        [Alias('Role')]
        [string[]]
        $Roles,
        [Alias('Group')]
        [string[]]
        $Groups
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -MSG "Creating new Role named `"$roleName`""
        $body = [PSCustomObject]@{
            Name     = $roleName
            RoleType = $RoleType
        }
        if ($Users) {
            Write-LogMessage -type Verbose -MSG "Adding users `"$Users`" to new Role named `"$roleName`""
            $body | Add-Member -MemberType NoteProperty -Name Users -Value $Users
        }
        if ($Roles) {
            Write-LogMessage -type Verbose -MSG "Adding roles `"$Roles`" to new Role named `"$roleName`""
            $body | Add-Member -MemberType NoteProperty -Name Roles -Value $Roles
        }
        if ($Groups) {
            Write-LogMessage -type Verbose -MSG "Adding groups `"$Groups`" to new Role named `"$roleName`""
            $body | Add-Member -MemberType NoteProperty -Name Groups -Value $Groups
        }
        if ($PSCmdlet.ShouldProcess($roleName, 'New-IdentityRole')) {
            Write-LogMessage -type Verbose -MSG "Creating role named `"$roleName`""
            $result = Invoke-Rest -Uri "$IdentityURL/Roles/StoreRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99)
            if (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
                return
            }
            else {
                Write-LogMessage -type Info -MSG "New Role named `"$roleName`" created"
                return $result.Result._RowKey
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping addition of role `"$roleName`" due to confirmation being denied"
        }
    }
}
