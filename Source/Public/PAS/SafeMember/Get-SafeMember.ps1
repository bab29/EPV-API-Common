<#
.SYNOPSIS
    Retrieves safe member information from the PVWA API.

.DESCRIPTION
    The Get-SafeMember function retrieves information about members of a specified safe from the PVWA API.
    It supports various parameter sets to filter and search for specific members or member types.

.PARAMETER PVWAURL
    The URL of the PVWA instance.

.PARAMETER LogonToken
    The logon token for authenticating with the PVWA API.

.PARAMETER SafeName
    The name of the safe to retrieve members from.

.PARAMETER memberName
    The name of the member to retrieve information for. This parameter is mandatory when using the 'memberName' parameter set.

.PARAMETER useCache
    A switch to indicate whether to use cached data. This parameter is only valid with the 'memberName' parameter set.

.PARAMETER Search
    A search string to filter members by name. This parameter is only valid with the 'Search' parameter set.

.PARAMETER memberType
    The type of member to filter by. Valid values are "User" and "Group". This parameter is only valid with the 'Search' parameter set.

.PARAMETER membershipExpired
    A filter to include only members with expired memberships. Valid values are "True" and "False". This parameter is only valid with the 'Search' parameter set.

.PARAMETER includePredefinedUsers
    A filter to include predefined users. Valid values are "True" and "False". This parameter is only valid with the 'Search' parameter set.

.PARAMETER offset
    The offset for pagination. This parameter is only valid with the 'Search' parameter set.

.PARAMETER limit
    The limit for pagination. This parameter is only valid with the 'Search' parameter set.

.PARAMETER DoNotPage
    A switch to disable pagination. This parameter is only valid with the 'Search' parameter set.

.PARAMETER sort
    The sort order for the results. Valid values are "asc" and "desc". This parameter is only valid with the 'Search' parameter set.

.PARAMETER permissions
    A switch to include permissions in the output.

.EXAMPLE
    Get-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "Finance"

    Retrieves all members of the "Finance" safe.

.EXAMPLE
    Get-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "Finance" -memberName "JohnDoe"

    Retrieves information about the member "JohnDoe" in the "Finance" safe.
#>

function Get-SafeMember {
    [CmdletBinding(DefaultParameterSetName = "SafeName")]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,
        [Parameter(Mandatory, ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string]
        $memberName,
        [Parameter(ParameterSetName = 'memberName')]
        [switch]
        $useCache,
        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]
        $Search,
        [Parameter(ParameterSetName = 'Search')]
        [ValidateSet("User", "Group")]
        [string]
        $memberType,
        [Parameter(ParameterSetName = 'Search')]
        [ValidateSet("True", "False")]
        [string]
        $membershipExpired,
        [Parameter(ParameterSetName = 'Search')]
        [ValidateSet("True", "False")]
        [string]
        $includePredefinedUsers,
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $offset = $null,
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $limit,
        [Parameter(ParameterSetName = 'Search')]
        [switch]
        $DoNotPage,
        [Parameter(ParameterSetName = 'Search')]
        [AllowEmptyString]
        [ValidateSet("asc", "desc")]
        $sort,
        [switch]
        $permissions
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        if ([string]::IsNullOrEmpty($SafeName)) {
            Write-LogMessage -type Error -MSG "No Safe Name provided"
            return
        }

        if (-not [string]::IsNullOrEmpty($memberName)) {
            $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/$memberName/"
            Write-LogMessage -type Verbose -MSG "Getting memberName permissions for safe $SafeName"
            return Invoke-Rest -Uri $SafeMemberURL -Method GET -Headers $logonToken -ContentType 'application/json'
        }
        else {
            $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/?"
            Write-LogMessage -type Verbose -MSG "Getting owners permissions for safe $SafeName"
            $filterList = @()

            if (-not [string]::IsNullOrEmpty($memberType)) {
                $filterList += "memberType eq $memberType"
            }
            if (-not [string]::IsNullOrEmpty($membershipExpired)) {
                $filterList += "membershipExpired eq $membershipExpired"
            }
            if (-not [string]::IsNullOrEmpty($includePredefinedUsers)) {
                $filterList += "includePredefinedUsers eq $includePredefinedUsers"
            }
            if ($filterList.Count -gt 0) {
                $filter = $filterList -join " AND "
                $SafeMemberURL += "filter=$filter"
                Write-LogMessage -type Verbose -MSG "Applying a filter of $filter"
            }
            if (-not [string]::IsNullOrEmpty($Search)) {
                $SafeMemberURL += "&search=$Search"
                Write-LogMessage -type Verbose -MSG "Applying a search of $Search"
            }
            if (-not [string]::IsNullOrEmpty($offset)) {
                $SafeMemberURL += "&offset=$offset"
                Write-LogMessage -type Verbose -MSG "Applying an offset of $offset"
            }
            if (-not [string]::IsNullOrEmpty($limit)) {
                $SafeMemberURL += "&limit=$limit"
                Write-LogMessage -type Verbose -MSG "Applying a limit of $limit"
            }
            if (-not [string]::IsNullOrEmpty($sort)) {
                $SafeMemberURL += "&sort=$sort"
                Write-LogMessage -type Verbose -MSG "Applying a sort of $sort"
            }
            if ($DoNotPage) {
                Write-LogMessage -type Verbose -MSG "Paging is disabled."
            }

            $restResponse = Invoke-Rest -Uri $SafeMemberURL -Method GET -Headers $logonToken -ContentType 'application/json'
            [SafeMember[]]$memberList = $restResponse.value

            if (-not [string]::IsNullOrEmpty($restResponse.NextLink)) {
                if ($DoNotPage) {
                    Write-LogMessage -type Verbose -MSG "A total of $($memberList.Count) members found, but paging is disabled. Returning only $($memberList.Count) members"
                }
                else {
                    do {
                        Write-LogMessage -type Verbose -MSG "NextLink found, getting next page"
                        $restResponse = Invoke-Rest -Uri "$PVWAURL/$($restResponse.NextLink)" -Method GET -Headers $logonToken -ContentType 'application/json'
                        $memberList += $restResponse.value
                    } until ([string]::IsNullOrEmpty($restResponse.NextLink))
                }
            }
            else {
                Write-LogMessage -type Verbose -MSG "Found $($memberList.Count) members"
            }

            return [SafeMember[]]$memberList
        }
    }
}
