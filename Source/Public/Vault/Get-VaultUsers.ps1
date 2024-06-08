Function Get-VaultUsers {
    Param
    (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [switch]$componentUser,
        [switch]$ExtendedDetails
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -MSG 'Getting all vault users'
        Write-LogMessage -type Verbose -MSG "ExtendedDetails=$ExtendedDetails"
        Write-LogMessage -type Verbose -MSG "componentUser=$componentUser"
        $URL_Users = "$PVWAURL/api/Users?ExtendedDetails=$($ExtendedDetails)&componentUser=$($componentUser)"
        return Invoke-Rest -Command GET -Uri $URL_Users -header $logonToken
    }
}