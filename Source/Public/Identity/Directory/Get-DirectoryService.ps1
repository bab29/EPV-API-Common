<#
.Synopsis
    Get Identity Directories
.DESCRIPTION
    Get Identity Directories
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
function Get-DirectoryService {
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
        [switch]
        $IDOnly,
        [Parameter(ValueFromPipeline)]
        [Alias('DirID', 'DirectoryUUID')]
        [String[]]
        $DirectoryServiceUuid,
        [Parameter(ValueFromPipeline)]
        [string]
        $directoryName,
        [Parameter(ValueFromPipeline)]
        [string]
        $directoryService,
        [switch]
        $UuidOnly
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        if ($DirectoryServiceUuid) {
            Write-LogMessage -type Verbose -MSG "Directory UUID Provided. Setting Search Directory to `"$DirectoryServiceUuid`""
            [PSCustomObject[]]$DirID = $DirectoryServiceUuid
        } elseif ($directoryName) {
            Write-LogMessage -type Verbose -MSG "Directory name provided. Searching for directory with the name of `"$directoryName`""
            $dirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json'
            if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories with the name of `"$directoryName`""
                if ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryName*" } | Select-Object -ExpandProperty directoryServiceUuid
                } else {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryName*" }
                }
            }
        } elseif ($directoryService) {
            Write-LogMessage -type Verbose -MSG "Directory service provided. Searching for directory with the name of `"$directoryService`""
            $dirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json'
            if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories with the service type of `"$directoryService`""
                if ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryService*" } | Select-Object -ExpandProperty directoryServiceUuid
                } else {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryService*" }
                }
            }
        } else {
            Write-LogMessage -type Verbose -MSG 'No directory parameters passed. Gathering all directories, except federated'
            $dirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json'
            if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories"
                if ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Select-Object -ExpandProperty directoryServiceUuid
                } else {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row
                }
            }
        }
        return $DirID
    }
}
