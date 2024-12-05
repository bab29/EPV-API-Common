

<#
.SYNOPSIS
Adds account in the PVWA system.

.DESCRIPTION
The Add-Account function connects to the PVWA API to add or update an account.
It requires the PVWA URL and a logon token for authentication. The function
supports ShouldProcess for confirmation prompts.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The logon token used for authentication with the PVWA API.

.EXAMPLE
Add-Account -PVWAURL "https://pvwa.example.com" -LogonToken "your-logon-token"

.NOTES
This function is part of the EPV-API-Common module and is used to manage accounts
in the PVWA system. The function currently has a TODO to complete the account
update process.

#>
function Add-Account {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL", SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,

        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LogonToken

    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountUrl = "$BaseURL/Accounts/?"
        $AccountIDURL = "$BaseURL/Accounts/{0}/?"
    }

    Process {

        if ($PSCmdlet.ShouldProcess($AccountID, 'Set-Account')) {
            Write-LogMessage -type Verbose -MSG "Getting AccountID `"$AccountID`""
            $Account = Get-Account -PVWAURL $PVWAURL -LogonToken $LogonToken -AccountID $AccountID
            #TODO Complete function so accounts get updated
            Write-LogMessage -type Verbose -MSG "Set account `"$safeName`" successfully"
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of AccountID `"$AccountID`" due to confirmation being denied"
        }

    }
}
