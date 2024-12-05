<#
.SYNOPSIS
Sets the account link for a specified account in the PVWA.

.DESCRIPTION
The Set-Account function links an account to an extra password in the PVWA. It supports multiple parameter sets to specify the extra password either by its type or by its index.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The authentication token for the PVWA.

.PARAMETER AccountID
The ID of the account to link.

.PARAMETER extraPass
The type of extra password to link (Logon, Enable, Reconcile).

.PARAMETER extraPassIndex
The index of the extra password to link.

.PARAMETER extraPassSafe
The safe where the extra password is stored.

.PARAMETER extraPassObject
The name of the extra password object.

.PARAMETER extraPassFolder
The folder where the extra password object is stored. Defaults to "Root".

.EXAMPLE
Set-Account -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12345" -extraPass Logon -extraPassSafe "Safe1" -extraPassObject "Object1"

.LINK
https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/WebServices/Implementing%20the%20REST%20API.htm
#>

enum extraPass {
    Logon       = 1
    Enable      = 2
    Reconcile   = 3
}

function Set-Account {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL", SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,

        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LogonToken,

        [Alias('ID')]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$AccountID,

        [Parameter(ParameterSetName = 'extraPass',Mandatory,ValueFromPipelineByPropertyName)]
        [extraPass]$extraPass,

        [Parameter(ParameterSetName = 'extraPasswordIndex',Mandatory,ValueFromPipelineByPropertyName)]
        [int]$extraPassIndex,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$extraPassSafe,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$extraPassObject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$extraPassFolder = "Root"
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountIDLink = "$BaseURL/Accounts/{0}/LinkAccount/"
    }

    Process {

        if ($PSCmdlet.ShouldProcess($AccountID, 'Set-AccountLink')) {

            $extraPassBody = @{
                safe = $extraPassSafe
                extraPasswordIndex =  $(if (-not [string]::IsNullOrEmpty($extraPass)) {$extraPass} else {$extraPassIndex})
                name =  $extraPassObject
                folder = $extraPassFolder
                }

            $URL = $AccountIDLink -f $AccountID
            $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $LogonToken -Body $extraPassBody  -ContentType 'application/json'
            Write-LogMessage -type Verbose -MSG "Set account `"$safeName`" successfully"
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of AccountID `"$AccountID`" due to confirmation being denied"
        }

    }
}
