<#
.SYNOPSIS
    Retrieves information about safes from the PVWA API.

.DESCRIPTION
    The Get-Safe function retrieves information about safes from the PVWA API. It supports multiple parameter sets to allow retrieval by Safe ID, Platform ID, or general queries. The function can also return all safes if no specific parameters are provided.

.PARAMETER PVWAURL
    The URL of the PVWA instance.

.PARAMETER LogonToken
    The logon token for authentication.

.PARAMETER SafeUrlId
    The ID of the safe to retrieve.

.PARAMETER SafeName
    The name of the safe to retrieve.

.PARAMETER PlatformID
    The ID of the platform to retrieve safes for.

.PARAMETER AllSafes
    Switch to retrieve all safes.

.PARAMETER ExtendedDetails
    Switch to include extended details in the results.

.PARAMETER includeAccounts
    Switch to include accounts in the results.

.PARAMETER useCache
    Switch to use cached results.

.PARAMETER Search
    A search string to filter the results.

.PARAMETER offset
    The offset for pagination.

.PARAMETER limit
    The limit for pagination.

.PARAMETER DoNotPage
    Switch to disable pagination.

.PARAMETER sort
    The sort order for the results. Valid values are "asc" and "desc".

.EXAMPLE
    Get-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeUrlId "12345"
    Retrieves the safe with ID 12345.

.EXAMPLE
    Get-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -AllSafes
    Retrieves all safes.

.EXAMPLE
    Get-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "MySafe" -PlatformID "Platform1"
    Retrieves the safe named "MySafe" for platform "Platform1".

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
#>
function Get-Safe {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL")]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,

        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LogonToken,

        [Parameter(ParameterSetName = 'SafeID', ValueFromPipelineByPropertyName)]
        [Alias('SafeID')]
        [string]
        $SafeUrlId,

        [Parameter(ParameterSetName = 'PlatformID', ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,

        [Parameter(ParameterSetName = 'PlatformID', ValueFromPipelineByPropertyName)]
        [string]
        $PlatformID,

        [Parameter(ParameterSetName = 'AllSafes')]
        [switch]
        $AllSafes,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'PVWAURL')]
        [switch]
        $ExtendedDetails,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeID')]
        [Parameter(ParameterSetName = 'PVWAURL')]
        [switch]
        $includeAccounts,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeID')]
        [switch]
        $useCache,

        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]
        $Search,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $offset = $null,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $limit,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [switch]
        $DoNotPage,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [AllowEmptyString]
        [ValidateSet("asc", "desc")]
        $sort
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $SafeURL = "$BaseURL/Safes/?"
        $SafeIDURL = "$BaseURL/Safes/{0}/?"
        $PlatformIDURL = "$BaseURL/Platforms/{0}/Safes/{1}/?"
    }

    Process {
        $SafeUrlIdExists = -not [string]::IsNullOrEmpty($SafeUrlId)
        $SafeNameExists = -not [string]::IsNullOrEmpty($SafeName)
        $PlatformIDExists = -not [string]::IsNullOrEmpty($PlatformID)

        if ($SafeUrlIdExists) {
            Get-SafeViaID
        }
        elseif ($PlatformIDExists) {
            Get-SafeViaPlatformID
        }
        else {
            if (-not ($SafeNameExists -or $PlatformIDExists -or $SafeUrlIdExists)) {
                Write-LogMessage -type Verbose -MSG "No Safe Name, Safe ID, or Platform ID provided, returning all safes"
            }
            Get-SafeViaQuery
        }
    }
}

function Get-SafeViaID {
    $URL = $SafeIDURL -f $SafeUrlId
    Write-LogMessage -type Verbose -MSG "Getting safe with ID of `"$SafeUrlId`""
    Add-BaseQueryParameter -URL ([ref]$URL)
    $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
    return [safe]$restResponse
}

function Get-SafeViaPlatformID {
    if ($SafeNameExists) {
        Write-LogMessage -type Verbose -MSG "Searching for a safe with the name of `"$SafeName`" and a platformID of `"$PlatformID`""
        $URL = $PlatformIDURL -f $PlatformID, $SafeName
    }
    else {
        Write-LogMessage -type Verbose -MSG "Getting a list of safes available to platformID `"$PlatformID`""
        $URL = $PlatformIDURL -f $PlatformID
    }
    [PSCustomObject[]]$resultList = Invoke-RestNextLink -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
    return [safe[]]$resultList
}

function Get-SafeViaQuery {
    Write-LogMessage -type Verbose -MSG "Getting list of safes"
    $URL = $SafeURL
    Add-BaseQueryParameter -URL ([ref]$URL)
    Add-SafeQueryParameter -URL ([ref]$URL)
    [PSCustomObject[]]$resultList = Invoke-RestNextLink -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
    return [safe[]]$resultList
}

function Add-SafeQueryParameter {
    param (
        [ref]$URL
    )
    Write-LogMessage -type Verbose -MSG "Adding Query Parameters"
    if ($includeAccounts) {
        $URL.Value += "&includeAccounts=true"
        Write-LogMessage -type Verbose -MSG "Including accounts in results"
    }
    if ($ExtendedDetails) {
        $URL.Value += "&extendedDetails=true"
        Write-LogMessage -type Verbose -MSG "Including extended details"
    }
    if (-not [string]::IsNullOrEmpty($Search)) {
        $URL.Value += "&search=$Search"
        Write-LogMessage -type Verbose -MSG "Applying a search of `"$Search`""
    }
    Write-LogMessage -type Verbose -MSG "New URL: $URL"
}
