<#
.SYNOPSIS
Retrieves identity group information from a specified identity URL.

.DESCRIPTION
The Get-IdentityGroup function retrieves information about identity groups from a specified identity URL.
It supports retrieving all groups or a specific group by name. The function can also return only the ID of the group if specified.

.PARAMETER IdentityURL
The URL of the identity service to query.

.PARAMETER LogonToken
The logon token used for authentication with the identity service.

.PARAMETER GroupName
The name of the group to retrieve information for. This parameter is mandatory when using the "GroupName" parameter set.

.PARAMETER IDOnly
A switch to specify if only the ID of the group should be returned.

.PARAMETER AllGroups
A switch to specify if all groups should be retrieved. This parameter is mandatory when using the "AllGroups" parameter set.

.EXAMPLE
Get-IdentityGroup -IdentityURL "https://identity.example.com" -LogonToken $token -GroupName "Admins"

This example retrieves information about the "Admins" group from the specified identity URL.

.EXAMPLE
Get-IdentityGroup -IdentityURL "https://identity.example.com" -LogonToken $token -AllGroups

This example retrieves information about all groups from the specified identity URL.

.NOTES
The function uses Invoke-RestMethod to query the identity service and requires appropriate permissions to access the service.
#>

function Get-IdentityGroup {
    [CmdletBinding(DefaultParameterSetName = "GroupName")]
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
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "GroupName")]
        [Alias('Group')]
        [string]
        $GroupName,
        [switch]
        $IDOnly,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "AllGroups")]
        [switch]
        $AllGroups
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        if ($AllGroups) {
            Write-LogMessage -type Verbose -Message "Attempting to locate all groups"
            $Groups = [PSCustomObject]@{
                '_or' = [PSCustomObject]@{
                    'DisplayName' = [PSCustomObject]@{
                        '_like' = ""
                    }
                },
                [PSCustomObject]@{
                    'SystemName' = [PSCustomObject]@{
                        '_like' = [PSCustomObject]@{
                            value      = ""
                            ignoreCase = 'true'
                        }
                    }
                }
            }
        }
        else {
            Write-LogMessage -type Verbose -Message "Attempting to locate Identity Group named `"$GroupName`""
            $Group = $GroupName.Trim()
            $Groups = [PSCustomObject]@{
                '_or' = [PSCustomObject]@{
                    'DisplayName' = [PSCustomObject]@{
                        '_like' = $Group
                    }
                },
                [PSCustomObject]@{
                    'SystemName' = [PSCustomObject]@{
                        '_like' = [PSCustomObject]@{
                            value      = $Group
                            ignoreCase = 'true'
                        }
                    }
                }
            }
        }

        $GroupQuery = [PSCustomObject]@{
            'group' = "$($Groups | ConvertTo-Json -Depth 99 -Compress)"
            'Args'  = [PSCustomObject]@{
                'PageNumber' = 1
                'PageSize'   = 100000
                'Limit'      = 100000
                'SortBy'     = ''
                'Caching'    = -1
            }
        }

        Write-LogMessage -type Verbose -Message "Gathering Directories"
        $DirResult = Invoke-RestMethod -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $LogonToken -ContentType 'application/json'

        if ($DirResult.Success -and $DirResult.result.Count -ne 0) {
            Write-LogMessage -type Verbose -Message "Located $($DirResult.result.Count) Directories"
            Write-LogMessage -type Verbose -Message "Directory results: $($DirResult.result.Results.Row | ConvertTo-Json -Depth 99)"
            [string[]]$DirID = $DirResult.result.Results.Row | Where-Object { $_.Service -eq 'ADProxy' } | Select-Object -ExpandProperty directoryServiceUuid
            $GroupQuery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force
        }

        Write-LogMessage -type Verbose -Message "Body set to : `"$($GroupQuery | ConvertTo-Json -Depth 99)`""
        $Result = Invoke-RestMethod -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($GroupQuery | ConvertTo-Json -Depth 99)
        Write-LogMessage -type Verbose -Message "Result set to : `"$($Result | ConvertTo-Json -Depth 99)`""

        if (!$Result.Success) {
            Write-LogMessage -type Error -Message $Result.Message
            return
        }

        if ($Result.Result.Groups.Results.FullCount -eq 0) {
            Write-LogMessage -type Warning -Message 'No Group found'
            return
        }
        else {
            if ($IDOnly) {
                Write-LogMessage -type Verbose -Message "Returning ID of Group `"$GroupName`""
                return $Result.Result.Group.Results.row.InternalName
            }
            else {
                Write-LogMessage -type Verbose -Message "Returning all information about Group `"$GroupName`""
                return $Result.Result.Group.Results.row
            }
        }
    }
}
