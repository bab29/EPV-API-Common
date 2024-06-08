Function Get-VaultUsers {
    Param
    (
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Alias('header')]
        $LogonToken,
        [switch]$componentUser,
        [switch]$ExtendedDetails
    )
    Begin {
        Set-Globals
    }
    Process {
        Write-LogMessage -type Verbose -MSG 'Getting all vault users'
        Write-LogMessage -type Verbose -MSG "ExtendedDetails=$ExtendedDetails"
        Write-LogMessage -type Verbose -MSG "componentUser=$componentUser"
        $URL_Users = "$PVWAURL/api/Users?ExtendedDetails=$($ExtendedDetails)&componentUser=$($componentUser)"
        return Invoke-Rest -Command GET -Uri $URL_Users -header $logonToken
    }
}