<#
.SYNOPSIS
Retrieves linked accounts for a specified account from the PVWA API.

.DESCRIPTION
The Get-AccountLink function retrieves linked accounts for a specified account ID from the PVWA API. It supports retrieving the linked accounts as account objects if the -accountObject switch is specified.

.PARAMETER PVWAURL
The base URL of the PVWA API. This parameter is mandatory.

.PARAMETER LogonToken
The authentication token required to access the PVWA API. This parameter is mandatory.

.PARAMETER AccountID
The ID of the account for which linked accounts are to be retrieved. This parameter is mandatory when using the 'AccountID' parameter set.

.PARAMETER accountObject
A switch parameter that, when specified, retrieves the linked accounts as account objects.

.EXAMPLE
PS> Get-AccountLink -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12_45"

Retrieves the linked accounts for the account with ID "12_45".

.EXAMPLE
PS> Get-AccountLink -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12345" -accountObject

Retrieves the linked accounts for the account with ID "12345" and returns them as account objects.

.NOTES
This function requires the Write-LogMessage and Invoke-Rest functions to be defined in the session.
#>
function Get-AccountLink {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL")]
    param (
        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory)]
        $LogonToken,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias("id")]
        [string]$AccountID,

        [Parameter()]
        [switch]$accountObject
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountIDLink = "$BaseURL/ExtendedAccounts/{0}/LinkedAccounts"
    }

    Process {
        $URL = $AccountIDLink -f $AccountID
        Write-LogMessage -type Verbose -MSG "Getting account links with ID of `"$AccountID`""
        $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $LogonToken -ContentType 'application/json'
        If ($accountObject) {
            $restResponse.LinkedAccounts | ForEach-Object {
                IF (-not [string]::IsNullOrEmpty($PSitem.AccountID)) {
                    $PSItem | Add-Member -Name "AccountObject" -MemberType NoteProperty -Value $($PSitem | Get-Account)
                }
            }
        }
        Return $restResponse
    }
}
