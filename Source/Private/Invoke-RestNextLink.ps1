<#
.SYNOPSIS
Invokes a REST API call and handles pagination if necessary.

.DESCRIPTION
The Invoke-RestNextLink function sends a REST API request using the specified HTTP method and URI.
It supports pagination by following the 'NextLink' property in the response. If pagination is disabled,
it returns only the initial set of results.

.PARAMETER Command
Specifies the HTTP method to use for the REST API call. Valid values are 'GET', 'POST', 'DELETE', 'PATCH', and 'PUT'.

.PARAMETER URI
Specifies the URI for the REST API call. This parameter is mandatory and cannot be null or empty.

.PARAMETER Header
Specifies the headers to include in the REST API call. This parameter is optional.

.PARAMETER ContentType
Specifies the content type for the REST API call. The default value is 'application/json'.

.PARAMETER ErrAction
Specifies the action to take if an error occurs during the REST API call. Valid values are 'Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', and 'Suspend'. The default value is 'Continue'.

.RETURNS
Returns an array of PSCustomObject containing the results of the REST API call.

.EXAMPLE
Invoke-RestNextLink -Command GET -URI "https://api.example.com/resource" -Header $header

This example sends a GET request to the specified URI with the provided headers and handles pagination if necessary.

.NOTES
This function uses the Invoke-Rest function to send the REST API request and handles pagination by following the 'NextLink' property in the response.
#>
Function Invoke-RestNextLink {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Method')]
        [ValidateSet('GET', 'POST', 'DELETE', 'PATCH', 'PUT')]
        [String]$Command,

        [Alias('PCloudURL', 'IdentityURL', 'URL')]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$URI,

        [Alias('LogonToken', 'Headers')]
        [Parameter(Mandatory = $false)]
        $Header,

        [Parameter(Mandatory = $false)]
        [String]$ContentType = 'application/json',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', 'Suspend')]
        [String]$ErrAction = 'Continue'
    )

    $restResponse = Invoke-Rest -Uri $URI -Method $Command -Headers $Header -ContentType $ContentType -ErrorAction $ErrAction
    [PSCustomObject[]]$resultList = $restResponse.value

    if (-not [string]::IsNullOrEmpty($restResponse.NextLink)) {
        if ($DoNotPage) {
            Write-LogMessage -Type Verbose -MSG "A total of $($resultList.Count) results found, but paging is disabled. Returning only $($resultList.Count) results"
        } else {
            do {
                Write-LogMessage -Type Verbose -MSG "NextLink found, getting next page"
                $restResponse = Invoke-Rest -Uri "$PVWAURL/$($restResponse.NextLink)" -Method GET -Headers $logonToken -ContentType 'application/json'
                $resultList += $restResponse.value
            } until ([string]::IsNullOrEmpty($restResponse.NextLink))
        }
    } else {
        Write-LogMessage -Type Verbose -MSG "Found $($resultList.Count) results"
    }

    return $resultList
}
