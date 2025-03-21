#TODO Run Co-Pilot doc generator
Function Set-Account {
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$AccountID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Property,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Value

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
