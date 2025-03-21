<#
.SYNOPSIS
Retrieves account information from the PVWA API.

.DESCRIPTION
The Get-Account function retrieves account information from the PVWA API based on various parameters such as AccountID, Search, Filter, and SavedFilter. It supports multiple parameter sets to allow for flexible querying.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The authentication token used for API requests.

.PARAMETER AccountID
The ID of the account to retrieve.

.PARAMETER AccountLink
Switch to include account links in the response.

.PARAMETER AccountLinkObject
Switch to include account link objects in the response.

.PARAMETER AllAccounts
Switch to retrieve all accounts.

.PARAMETER Search
Search term to filter accounts.

.PARAMETER SearchType
Type of search to perform.

.PARAMETER Filter
Filter to apply to the account query.

.PARAMETER SavedFilter
Predefined filter to apply to the account query. Valid values are:
- Regular
- Recently
- New
- Link
- Deleted
- PolicyFailures
- AccessedByUsers
- ModifiedByUsers
- ModifiedByCPM
- DisabledPasswordByUser
- DisabledPasswordByCPM
- ScheduledForChange
- ScheduledForVerify
- ScheduledForReconcile
- SuccessfullyReconciled
- FailedChange
- FailedVerify
- FailedReconcile
- LockedOrNew
- Locked

.PARAMETER Offset
Offset for pagination.

.PARAMETER Limit
Limit for pagination.

.PARAMETER DoNotPage
Switch to disable pagination.

.PARAMETER Sort
Sort order for the results. Valid values are "asc" and "desc".

.EXAMPLE
Get-Account -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12345"

.EXAMPLE
Get-Account -PVWAURL "https://pvwa.example.com" -LogonToken $token -Search "admin" -SearchType "contains"

.NOTES
This function requires the PVWA URL and a valid logon token to authenticate API requests.

#>

function Get-Account {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL")]
    param (
        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory)]
        $LogonToken,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]$AccountID,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [switch]$AccountLink,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [switch]$AccountLinkObject,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [switch]$AllAccounts,

        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]$Search,

        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]$SearchType,

        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'filter', ValueFromPipelineByPropertyName)]
        [string]$Filter,

        [Parameter(ParameterSetName = 'savedfilter', ValueFromPipelineByPropertyName)]
        [string]
        [ValidateSet("Regular", "Recently", "New", "Link", "Deleted", "PolicyFailures",
            "AccessedByUsers", "ModifiedByUsers", "ModifiedByCPM", "DisabledPasswordByUser",
            "DisabledPasswordByCPM", "ScheduledForChange", "ScheduledForVerify",
            "ScheduledForReconcile", "SuccessfullyReconciled", "FailedChange",
            "FailedVerify", "FailedReconcile", "LockedOrNew", "Locked"
        )]
        $SavedFilter,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]$Offset = $null,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]$Limit,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [switch]$DoNotPage,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [AllowEmptyString]
        [ValidateSet("asc", "desc")]
        $Sort
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountUrl = "$BaseURL/Accounts/?"
        $AccountIDURL = "$BaseURL/Accounts/{0}/?"
    }

    Process {
        $AccountIDExists = -not [string]::IsNullOrEmpty($AccountID)
        $SavedFilterExists = -not [string]::IsNullOrEmpty($SavedFilter)
        $SearchExists = -not [string]::IsNullOrEmpty($Search)
        $FilterExists = -not [string]::IsNullOrEmpty($Filter)

        if ($AccountIDExists) {
            [account]$Account = Get-AccountViaID
            If ($AccountLink -or $AccountLinkObject) {
                $Account.LinkedAccounts = Get-AccountLink -AccountID $AccountID -accountObject:$AccountLinkObject
            }
            Return $Account
        }
        else {
            if (-not ($AccountIDExists -or $FilterExists -or $SavedFilterExists -or $SearchExists)) {
                Write-LogMessage -type Verbose -MSG "No Account ID, Filter, SavedFilter, or Search provided, returning all accounts"
            }
            Get-AccountViaQuery
        }
    }
}

function Get-AccountViaID {
    $URL = $AccountIDURL -f $AccountID
    Write-LogMessage -type Verbose -MSG "Getting account with ID of `"$AccountID`""
    $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $LogonToken -ContentType 'application/json'
    return [account]$restResponse
}

function Get-AccountViaQuery {
    Write-LogMessage -type Verbose -MSG "Getting list of accounts"
    $URL = $AccountUrl
    Add-BaseQueryParameter -URL ([ref]$URL)
    Add-AccountQueryParameter -URL ([ref]$URL)
    [Account[]]$resultList = Invoke-RestNextLink -Uri $URL -Method GET -Headers $LogonToken -ContentType 'application/json'
    return $resultList
}

function Add-AccountQueryParameter {
    param (
        [ref]$URL
    )
    Write-LogMessage -type Verbose -MSG "Adding Query Parameters"
    if (-not [string]::IsNullOrEmpty($Search)) {
        $URL.Value += "&search=$Search"
        Write-LogMessage -type Verbose -MSG "Applying a search of `"$Search`""
    }
    if (-not [string]::IsNullOrEmpty($SearchType)) {
        $URL.Value += "&searchType=$SearchType"
        Write-LogMessage -type Verbose -MSG "Applying a search type of `"$SearchType`""
    }
    if (-not [string]::IsNullOrEmpty($SavedFilter)) {
        $URL.Value += "&savedfilter=$SavedFilter"
        Write-LogMessage -type Verbose -MSG "Applying a savedfilter of `"$SavedFilter`""
    }
    if (-not [string]::IsNullOrEmpty($Filter)) {
        $URL.Value += "&filter=$Filter"
        Write-LogMessage -type Verbose -MSG "Applying a filter of `"$Filter`""
    }
    Write-LogMessage -type Verbose -MSG "New URL: $URL"
}
