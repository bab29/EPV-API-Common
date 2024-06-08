function Get-IdentityRole {
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
        [Parameter(Mandatory, ValueFromPipeline)]
        [Alias('role')]
        [string]
        $roleName,
        [switch]
        $IDOnly
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    process {
        Write-LogMessage -type Verbose -MSG "Attempting to locate Identity Role named `"$roleName`""
        $role = $roleName
        $roles = [PSCustomObject]@{
            '_or' = [PSCustomObject]@{
                '_ID' = [PSCustomObject]@{
                    '_like' = $role 
                }
            },
            [PSCustomObject]@{
                'Name' = [PSCustomObject]@{
                    '_like' = [PSCustomObject]@{
                        value      = $role
                        ignoreCase = 'true'
                    }
                }
            }
        }
    
        $rolequery = [PSCustomObject]@{
            'roles' = "$($roles|ConvertTo-Json -Depth 99 -Compress)" 
            'Args'  = [PSCustomObject]@{
                'PageNumber' = 1; 
                'PageSize'   = 100000; 
                'Limit'      = 100000;
                'SortBy'     = '';
                'Caching'    = -1 
            } 
        }
        Write-LogMessage -type Verbose -MSG "Gathering Directories"
        $dirResult = $(Invoke-RestMethod -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json')
        If ($dirResult.Success -and 0 -ne $dirResult.result.Count) {
            Write-LogMessage -type Verbose -MSG "Located $($dirResult.result.Count) Directories"
            [string[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.Service -eq 'CDS' }).directoryServiceUuid
            $rolequery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force 
        }
        $result = Invoke-RestMethod -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($rolequery | ConvertTo-Json -Depth 99)
        IF (!$result.Success) {
            Write-LogMessage -type Error -MSG  $result.Message
            Return
        }
        IF (0 -eq $result.Result.roles.Results.Count) {
            Write-LogMessage -type Warning -MSG 'No role found'
            Return
        }
        Else {
            If ($IDOnly) {
                Write-LogMessage -type Verbose -MSG "Returning ID of role `"$rolename`"" 
                Return $result.Result.roles.Results.Row._ID
            }
            else {
                Write-LogMessage -type Verbose -MSG "Returning all informatin about role `"$rolename`"" 
                Return $result.Result.roles.Results.Row
            }
        }
    }
}