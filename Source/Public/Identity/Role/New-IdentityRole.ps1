function New-IdentityRole {
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
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }

    process {
        Write-LogMessage -type Verbose -MSG "Creatung new Role named `"$RoleName`""
        $body = [PSCustomObject]@{
            Name     = $RoleName
            RoleType = $RoleType
        }
        IF (![string]::IsNullOrEmpty($User)) {
            Write-LogMessage -type Verbose -MSG "Adding users `"$Users`" to new Role named `"$RoleName`""
            $body  | Add-Member -MemberType NoteProperty -Name Users -Value $Users
        }
        IF (![string]::IsNullOrEmpty($Roles)) {
            Write-LogMessage -type Verbose -MSG "Adding roles `"$Roles`" to new Role named `"$RoleName`""
            $body  | Add-Member -MemberType NoteProperty -Name Users -Value $Roles
        }
        IF (![string]::IsNullOrEmpty($Groups)) {
            Write-LogMessage -type Verbose -MSG "Adding groups `"$Groups`" to new Role named `"$RoleName`""
            $body  | Add-Member -MemberType NoteProperty -Name Users -Value $Groups
        }

        $result = Invoke-RestMethod -Uri "$IdentityURL/Roles/StoreRole" -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($body | ConvertTo-Json -Depth 99)
        IF (!$result.Success) {
            Write-LogMessage -type Error -MSG  $result.Message
            Return
        }
        else {
            Write-LogMessage -type info -MSG "New Role named `"$RoleName`" created"
            Return $result.Result._RowKey
        }
        
    }
}