<#
.SYNOPSIS
    Invokes a REST API call with the specified parameters.

.DESCRIPTION
    The Invoke-Rest function is designed to make REST API calls using various HTTP methods such as GET, POST, DELETE, PATCH, and PUT.
    It supports custom headers, request bodies, and content types. The function also includes error handling and logging mechanisms.

.PARAMETER Command
    Specifies the HTTP method to use for the REST API call.
    Valid values are 'GET', 'POST', 'DELETE', 'PATCH', and 'PUT'. This parameter is mandatory.

.PARAMETER URI
    Specifies the URI of the REST API endpoint. This parameter is mandatory.

.PARAMETER Header
    Specifies the headers to include in the REST API call. This parameter is optional.

.PARAMETER Body
    Specifies the body content to include in the REST API call. This parameter is optional.

.PARAMETER ContentType
    Specifies the content type of the request body. The default value is 'application/json'. This parameter is optional.

.PARAMETER ErrAction
    Specifies the action to take if an error occurs.
    Valid values are 'Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', and 'Suspend'. The default value is 'Continue'. This parameter is optional.

.EXAMPLE
    Invoke-Rest -Command GET -URI "https://api.example.com/data" -Header @{Authorization = "Bearer token"}

    This example makes a GET request to the specified URI with an authorization header.

.EXAMPLE
    Invoke-Rest -Command POST -URI "https://api.example.com/data" -Body '{"name":"value"}' -ContentType "application/json"

    This example makes a POST request to the specified URI with a JSON body.

.NOTES
    This function includes extensive logging for debugging purposes. It logs the entry and exit points, as well as detailed information about the request and response.
#>

Function Invoke-Rest {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = "Function", Justification = 'Used in deep debugging')]
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
        [String]$Body,

        [Parameter(Mandatory = $false)]
        [String]$ContentType = 'application/json',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', 'Suspend')]
        [String]$ErrAction = 'Continue'
    )

    Process {
        Write-LogMessage -type Verbose -MSG 'Entering Invoke-Rest'
        $restResponse = ''

        try {
            Write-LogMessage -type Verbose -MSG "Invoke-RestMethod -Uri $URI -Method $Command -Header $($Header | ConvertTo-Json -Compress -Depth 9) -ContentType $ContentType -TimeoutSec 2700"

            if ([string]::IsNullOrEmpty($Body)) {
                $restResponse = Invoke-RestMethod -Uri $URI -Method $Command -Header $Header -ContentType $ContentType -TimeoutSec 2700 -ErrorAction $ErrAction
            }
            else {
                Write-LogMessage -type Verbose -MSG "Body Found: `n$Body"
                $restResponse = Invoke-RestMethod -Uri $URI -Method $Command -Body $Body -Header $Header -ContentType $ContentType -TimeoutSec 2700 -ErrorAction $ErrAction
            }
        }
        catch [System.Net.WebException] {
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCaught WebException"
            if ($ErrAction -match ('\bContinue\b|\bInquire\b|\bStop\b|\bSuspend\b')) {
                Write-LogMessage -type Error -MSG "Error Message: $PSItem"
                Write-LogMessage -type Error -MSG "Exception Message: $($PSItem.Exception.Message)"
                Write-LogMessage -type Error -MSG "Status Code: $($PSItem.Exception.Response.StatusCode.value__)"
                Write-LogMessage -type Error -MSG "Status Description: $($PSItem.Exception.Response.StatusDescription)"
                $restResponse = $null
                Throw
                Else {
                    Throw $PSItem
                }
            }
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCaught HttpResponseException"
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCommand:`t$Command`tURI:  $URI"
            If (-not [string]::IsNullOrEmpty($Body)) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tBody:`t $Body"
            }
            $Details = ($PSItem.ErrorDetails.Message | ConvertFrom-Json)
            If ('SFWS0007' -eq $Details.ErrorCode) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`t$($Details.ErrorMessage)"
                Throw $PSItem
            }
            elseif ('ITATS127E' -eq $Details.ErrorCode) {
                Write-LogMessage -type Error -MSG 'Was able to connect to the PVWA successfully, but the account was locked'
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`t$($Details.ErrorMessage)"
                Throw [System.Management.Automation.RuntimeException] 'Account Locked'
            }
            elseif ('PASWS013E' -eq $Details.ErrorCode) {
                Write-LogMessage -type Error -MSG "$($Details.ErrorMessage)" -Header -Footer
                exit 5
            }
            elseif ('SFWS0002' -eq $Details.ErrorCode) {
                Write-LogMessage -type Warning -MSG "$($Details.ErrorMessage)"
                Throw "$($Details.ErrorMessage)"
            }
            If ('SFWS0012' -eq $Details.ErrorCode) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`t$($Details.ErrorMessage)"
                Throw $PSItem
            }
            elseif (!($errorDetails.ErrorCode -in $global:SkipErrorCode)) {
                Write-LogMessage -type Error -MSG 'Was able to connect to the PVWA successfully, but the command resulted in an error'
                Write-LogMessage -type Error -MSG "Returned ErrorCode: $($errorDetails.ErrorCode)"
                Write-LogMessage -type Error -MSG "Returned ErrorMessage: $($errorDetails.ErrorMessage)"
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tExiting Invoke-Rest"
                Throw $PSItem
            }
            Else {
                Write-LogMessage -type Error -MSG "Error in running '$Command' on '$URI', $($PSItem.Exception)"
                Throw $(New-Object System.Exception ("Invoke-Rest: Error in running $Command on '$URI'", $PSItem.Exception))
            }
        }
        catch {
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCaught Exception"
            If ($ErrAction -ne "SilentlyContinue") {
                Write-LogMessage -type Error -MSG "Error in running $Command on '$URI', $PSItem.Exception"
                Write-LogMessage -type Error -MSG "Error Message: $PSItem"
            }
            else {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tError in running $Command on '$URI', $PSItem.Exception"
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tError Message: $PSItem"
            }
            Throw $(New-Object System.Exception ("Error in running $Command on '$URI'", $PSItem.Exception))
        }

        if ($URI -match 'Password/Retrieve') {
            Write-LogMessage -type Verbose -MSG 'Invoke-Rest:`tInvoke-REST Response: ***********'
        }
        else {
            if ($global:SuperVerbose) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST Response Type: $($restResponse.GetType().Name)"
                $type = $restResponse.GetType().Name
                if ('String' -ne $type) {
                    Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST ConvertTo-Json Response: $($restResponse | ConvertTo-Json -Depth 9 -Compress)"
                }
                else {
                    Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST Response: $restResponse"
                }
            }
            else {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST Response: $restResponse"
            }
        }
        Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tExiting Invoke-Rest"
        return $restResponse
    }
}
