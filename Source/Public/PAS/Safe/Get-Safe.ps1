function Get-Safe {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL")]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory)]
        [string]
        $PVWAURL,
        [Alias('header')]
        [Parameter(Mandatory)]
        $LogonToken,
        [Parameter(ParameterSetName = 'SafeID', ValueFromPipelineByPropertyName, ValueFromPipeline )]
        [Alias('SafeID')]
        [string]
        $SafeUrlId,
        [Parameter(ParameterSetName = 'PlatformID')]
        [Parameter(ParameterSetName = 'SafeName', ValueFromPipelineByPropertyName, ValueFromPipeline )]
        [Alias('Safe')]
        [string]
        $SafeName,
        [Parameter(ParameterSetName = 'PlatformID')]
        [string]
        $PlatformID,
        [Parameter(ParameterSetName = 'AllSafes')]
        [switch]
        $AllSafes,
        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeName')]
        [Parameter(ParameterSetName = 'PVWAURL')]
        [switch]
        $ExtendedDetails,
        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeID')]
        [Parameter(ParameterSetName = 'SafeName')]
        [Parameter(ParameterSetName = 'PVWAURL')]
        [switch]
        $includeAccounts,
        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeName')]
        [Parameter(ParameterSetName = 'SafeID')]
        [switch]
        $useCache,
        [Parameter(ParameterSetName = 'SafeName', ValueFromPipelineByPropertyName)]
        [string]
        $Search,
        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeName')]
        [Nullable[int]]
        $offset = $null,
        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeName')]
        [Nullable[int]]
        $limit,
        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeName')]
        [switch]
        $DoNotPage,
        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeName')]
        [AllowEmptyString]
        [ValidateSet("asc,desc")]
        $sort
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $SafeURL = "$BaseURL/Safes/?"
        $SafeIDURL = "$BaseURL/Safes/{0}/?"
        $PlatformIDURL = "$BaseURL/Platforms/{0}/Safes/{1}/?"
    }
    process {
        $SafeUrlIdExists = -not [string]::IsNullOrEmpty($SafeUrlId)
        $SafeNameExists = -not [string]::IsNullOrEmpty($SafeName)
        $PlatformIDExists = -not [string]::IsNullOrEmpty($PlatformID)
        IF (-not $($SafeNameExists -or $PlatformIDExists -or $SafeUrlIdExists)) {
            Write-LogMessage -type Verbose -Msg "No Safe Name, Safe ID, or Platform ID provided, returning all safes"
        }
        elseif ($SafeUrlIdExists) {
            $URL = $SafeIDURL -f $SafeUrlId
            Write-LogMessage -type Verbose -MSG "Gettting safe with ID of `"$SafeUrlId`""
            IF ($includeAccounts) {
                $URL = $URL + "&includeAccounts=true"
                Write-LogMessage -type Verbose -MSG "Including accounts in results"
            }
            IF ($useCache) {
                $URL = $URL + "&useCache=true"
                Write-LogMessage -type Verbose -MSG "Using session cache for results"
            }
            $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
            Return $restResponse
        }
        elseif ($PlatformIDExists) {
            If ($SafeNameExists) {
                Write-LogMessage -type Verbose -MSG "Searching for a safe with the name of `"$SafeName`" and a platformID of `"$PlatformID`""
                $URL = $PlatformIDURL -f $PlatformID, $SafeName
            }
            else {
                Write-LogMessage -type Verbose -MSG "Getting a list of safes available to platformID `"$PlatformID`""
                $URL = $PlatformIDURL -f $PlatformID
            }
            $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
            Return $restResponse
        }
        Write-LogMessage -type Verbose -MSG "Getting list of safes"
        $URL = $SafeURL
        IF (-not [string]::IsNullOrEmpty($Search)) {
            $URL = $URL + "&search=$search"
            Write-LogMessage -type Verbose -MSG "Applying a search of `"$search`""
        }
        IF (-not [string]::IsNullOrEmpty($offset)) {
            $URL = $URL + "&offset=$offset"
            Write-LogMessage -type Verbose -MSG "Applying a offset of `"$offset`""
        }
        IF (-not [string]::IsNullOrEmpty($limit)) {
            $URL = $URL + "&limit=$limit"
            Write-LogMessage -type Verbose -MSG "Applying a limit of `"$limit`""
        }
        IF (-not [string]::IsNullOrEmpty($sort)) {
            $URL = $URL + "&sort=$sort"
            Write-LogMessage -type Verbose -MSG "Applying a sort of `"$sort`""
        }
        IF ($includeAccounts) {
            $URL = $URL + "&includeAccounts=true"
            Write-LogMessage -type Verbose -MSG "Including accounts in results"
        }
        IF ($extendedDetails) {
            $URL = $URL + "&extendedDetails=true"
            Write-LogMessage -type Verbose -MSG "Including extended details"
        }
        If ($DoNotPage) {
            Write-LogMessage -type Verbose -MSG "Paging is disabled."
        }
        IF ($useCache) {
            $URL = $URL + "&useCache=true"
            Write-LogMessage -type Verbose -MSG "Using session cache for results"
        }
        $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
        [PSCustomObject[]]$resultList = $restResponse.value
        IF (-not [string]::IsNullOrEmpty($restResponse.NextLink)) {
            If ($DoNotPage) {
                Write-LogMessage -type Verbose -MSG "A total of $($resultList.Count) results found, but paging is disabled. Returning only $($resultList.count) results"
            }
            else {
                Do {
                    Write-LogMessage -type Verbose -MSG "NextLink found, getting next page"
                    $restResponse = Invoke-Rest -Uri "$PVWAURL/$($restResponse.NextLink)" -Method GET -Headers $logonToken -ContentType 'application/json'
                    $resultList += $restResponse.value
                }
                until ([string]::IsNullOrEmpty($($restResponse.NextLink)))
            }
        }
        else {
            Write-LogMessage -type Verbose -MSG "Found $($resultList.Count) results"
        }
        return [safe[]]$resultList
    }
}