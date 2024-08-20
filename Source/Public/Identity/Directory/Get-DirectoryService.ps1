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
        [Alias('DirID,DirectoryUUID')]
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
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    Process {
        IF (![string]::IsNullOrEmpty($DirectoryServiceUuid)) {
            Write-LogMessage -type Verbose -MSG "Directory UUID Provided. Setting Search Directory to `"$DirectoryServiceUuid`""
            [PSCustomObject[]]$DirID = $DirectoryServiceUuid
        }
        ElseIF (![string]::IsNullOrEmpty($directoryName)) {
            Write-LogMessage -type Verbose -MSG "Directory name provided. Searching for directory with the name of `"$directoryName`""
            $dirResult = $(Invoke-RestMethod -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json')
            If ($dirResult.Success -and 0 -ne $dirResult.result.Count) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories with the name of `"$directoryName`""
                IF ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.DisplayName -like "*$directoryName*" }).directoryServiceUuid
                }
                else {
                    [PSCustomObject[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.DisplayName -like "*$directoryName*" })
                }
            }
        }
        ElseIF (![string]::IsNullOrEmpty($directoryService)) {
            Write-LogMessage -type Verbose -MSG "Directory service provided. Searching for directory with the name of `"$directoryService`""
            $dirResult = $(Invoke-RestMethod -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json')
            If ($dirResult.Success -and 0 -ne $dirResult.result.Count) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories with the service type of `"$directoryService`""
                IF ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.DisplayName -like "*$directoryName*" }).directoryServiceUuid
                }
                else {
                    [PSCustomObject[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.DisplayName -like "*$directoryName*" })
                }
            }
        }
        else {
            Write-LogMessage -type Verbose -MSG 'No directory paramters passed. Gathering all directories, except federated'
            $dirResult = $(Invoke-RestMethod -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json')
            If ($dirResult.Success -and 0 -ne $dirResult.result.Count) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories"
                IF ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.DisplayName -like "*$directoryName*" }).directoryServiceUuid
                }
                else {
                    [PSCustomObject[]]$DirID = $($dirResult.result.Results.Row | Where-Object { $PSItem.DisplayName -like "*$directoryName*" })
                }
            }
        }
        return $DirID
    }
}