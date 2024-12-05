<#
.SYNOPSIS
Retrieves identity roles from the specified identity URL.

.DESCRIPTION
The Get-IdentityRole function retrieves identity roles from a specified identity URL. It supports retrieving a specific role by name or all roles. The function can return either the full role information or just the role ID.

.PARAMETER IdentityURL
The URL of the identity service.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER roleName
The name of the role to retrieve. This parameter is mandatory when using the "RoleName" parameter set.

.PARAMETER IDOnly
A switch to indicate if only the role ID should be returned.

.PARAMETER AllRoles
A switch to indicate if all roles should be retrieved. This parameter is mandatory when using the "AllRoles" parameter set.

.EXAMPLE
Get-IdentityRole -IdentityURL "https://identity.example.com" -LogonToken $token -roleName "Admin"
Retrieves the role information for the role named "Admin".

.EXAMPLE
Get-IdentityRole -IdentityURL "https://identity.example.com" -LogonToken $token -AllRoles
Retrieves all roles from the identity service.

.NOTES
The function uses REST API calls to interact with the identity service.
#>

function Get-IdentityRole {
    [CmdletBinding(DefaultParameterSetName = "RoleName")]
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
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "roleName")]
        [Alias('role')]
        [string]
        $roleName,
        [switch]
        $IDOnly,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "AllRoles")]
        [switch]
        $AllRoles
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }

    Process {
        if ($AllRoles) {
            $query = [PSCustomObject]@{ script = "SELECT Role.Name, Role.ID FROM Role" }
            $result = Invoke-RestMethod -Uri "$IdentityURL/Redrock/Query" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($query | ConvertTo-Json -Depth 99)
            return $result.result.results.Row
        }

        Write-LogMessage -type Verbose -MSG "Attempting to locate Identity Role named `"$roleName`""
        $roles = [PSCustomObject]@{
            '_or' = [PSCustomObject]@{
                '_ID' = [PSCustomObject]@{ '_like' = $roleName }
            },
            [PSCustomObject]@{
                'Name' = [PSCustomObject]@{
                    '_like' = [PSCustomObject]@{
                        value      = $roleName
                        ignoreCase = 'true'
                    }
                }
            }
        }

        $rolequery = [PSCustomObject]@{
            'roles' = ($roles | ConvertTo-Json -Depth 99 -Compress)
            'Args'  = [PSCustomObject]@{
                'PageNumber' = 1
                'PageSize'   = 100000
                'Limit'      = 100000
                'SortBy'     = ''
                'Caching'    = -1
            }
        }

        Write-LogMessage -type Verbose -MSG "Gathering Directories"
        $dirResult = Invoke-RestMethod -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $LogonToken -ContentType 'application/json'

        if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
            Write-LogMessage -type Verbose -MSG "Located $($dirResult.result.Count) Directories"
            Write-LogMessage -type Verbose -MSG "Directory results: $($dirResult.result.Results.Row)"
            $DirID = $dirResult.result.Results.Row | Where-Object { $_.Service -eq 'CDS' } | Select-Object -ExpandProperty directoryServiceUuid
            $rolequery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force
        }

        $result = Invoke-RestMethod -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($rolequery | ConvertTo-Json -Depth 99)

        if (!$result.Success) {
            Write-LogMessage -type Error -MSG $result.Message
            return
        }

        if ($result.Result.roles.Results.Count -eq 0) {
            Write-LogMessage -type Warning -MSG 'No role found'
            return
        }
        else {
            if ($IDOnly) {
                Write-LogMessage -type Verbose -MSG "Returning ID of role `"$roleName`""
                return $result.Result.roles.Results.Row._ID
            }
            else {
                Write-LogMessage -type Verbose -MSG "Returning all information about role `"$roleName`""
                return $result.Result.roles.Results.Row
            }
        }
    }
}
