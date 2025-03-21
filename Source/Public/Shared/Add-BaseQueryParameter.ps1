<#
.SYNOPSIS
Adds base query parameters to a URL.

.DESCRIPTION
The Add-BaseQueryParameter function appends various query parameters to a given URL.
It supports parameters such as sort, offset, limit, and useCache. It also logs the
actions performed at each step.

.PARAMETER URL
[ref] The URL to which the query parameters will be added.

.PARAMETER sort
(Optional) The sort parameter to be appended to the URL.

.PARAMETER offset
(Optional) The offset parameter to be appended to the URL.

.PARAMETER limit
(Optional) The limit parameter to be appended to the URL.

.PARAMETER DoNotPage
(Optional) If specified, indicates that paging is disabled.

.PARAMETER useCache
(Optional) If specified, indicates that session cache should be used for results.

.EXAMPLE
$URL = [ref] "http://example.com/api/resource"
Add-BaseQueryParameter -URL $URL -sort "name" -offset 10 -limit 50 -useCache

This example adds the sort, offset, limit, and useCache parameters to the given URL.

.NOTES
This function requires the Write-LogMessage function to be defined for logging purposes.
#>
function Add-BaseQueryParameter {
    param (
        [ref]$URL,
        [string]$sort,
        [string]$offset,
        [string]$limit,
        [switch]$DoNotPage,
        [switch]$useCache
    )

    Write-LogMessage -type Verbose -MSG "Adding Base Query Parameters"

    if (-not [string]::IsNullOrEmpty($sort)) {
        $URL.Value += "&sort=$sort"
        Write-LogMessage -type Verbose -MSG "Applying a sort of `"$sort`""
    }

    if (-not [string]::IsNullOrEmpty($offset)) {
        $URL.Value += "&offset=$offset"
        Write-LogMessage -type Verbose -MSG "Applying an offset of `"$offset`""
    }

    if (-not [string]::IsNullOrEmpty($limit)) {
        $URL.Value += "&limit=$limit"
        Write-LogMessage -type Verbose -MSG "Applying a limit of `"$limit`""
    }

    if ($DoNotPage) {
        Write-LogMessage -type Verbose -MSG "Paging is disabled."
    }

    if ($useCache) {
        $URL.Value += "&useCache=true"
        Write-LogMessage -type Verbose -MSG "Using session cache for results"
    }

    Write-LogMessage -type Verbose -MSG "New URL: $($URL.Value)"
}
