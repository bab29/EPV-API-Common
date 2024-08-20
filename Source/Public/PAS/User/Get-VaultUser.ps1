<#
.SYNOPSIS
Gets users from vault
.DESCRIPTION
Get users from vault
${2:Long description}
.PARAMETER PVWAURL
${4:Parameter description}
.PARAMETER LogonToken
${5:Parameter description}
.PARAMETER componentUser
${6:Parameter description}
.PARAMETER ExtendedDetails
${7:Parameter description}
.EXAMPLE
${8:An example}
.NOTES
${9:General notes}
#>
Function Get-VaultUser {
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