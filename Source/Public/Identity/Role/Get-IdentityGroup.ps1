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
.Group
    The Group this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
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
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    process {
        if ($AllGroups) {

            [PSCustomObject]$query = @{
                script = "Select * from DSGroups"
            }

            $result = Invoke-RestMethod -Uri "$IdentityURL/Redrock/Query" -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($query | ConvertTo-Json -Depth 99)
            Return $result.result.results.Row
        }

        Write-LogMessage -type Verbose -MSG "Attempting to locate Identity Group named `"$GroupName`""
        $Group = $GroupName
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
        $Groupquery = [PSCustomObject]@{
            'group' = "$($Groups|ConvertTo-Json -Depth 99 -Compress)"
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
            Write-LogMessage   -type Verbose -MSG "Directory results: $($dirResult.result.Results.Row| ConvertTo-Json -Depth 99)"
            [string[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.Service -eq 'ADProxy' }).directoryServiceUuid
            $Groupquery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force
        }
        Write-LogMessage -type Verbose -MSG "Body set to : `"$($Groupquery|ConvertTo-Json -Depth 99)`""
        $result = Invoke-RestMethod -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($Groupquery | ConvertTo-Json -Depth 99)
        Write-LogMessage -type Verbose -MSG "Result set to : `"$($result|ConvertTo-Json -Depth 99)`""
        IF (!$result.Success) {
            Write-LogMessage -type Error -MSG $result.Message
            Return
        }
        IF (0 -eq $result.Result.Groups.Results.FullCount) {
            Write-LogMessage -type Warning -MSG 'No Group found'
            Return
        }
        Else {
            If ($IDOnly) {
                Write-LogMessage -type Verbose -MSG "Returning ID of Group `"$Groupname`""
                Return $result.Result.Group.Results.row.InternalName
            }
            else {
                Write-LogMessage -type Verbose -MSG "Returning all informatin about Group `"$Groupname`""
                Return $result.Result.Group.Results.row
            }
        }
    }
}