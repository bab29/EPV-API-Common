<#
.SYNOPSIS
    Retrieves all vault users from the specified PVWA URL.

.DESCRIPTION
    The Get-VaultUser function retrieves all vault users from the specified PVWA URL.
    It supports optional parameters to include extended details and component user information.

.PARAMETER PVWAURL
    The URL of the PVWA (Password Vault Web Access) API endpoint.

.PARAMETER LogonToken
    The logon token used for authentication with the PVWA API.

.PARAMETER componentUser
    A switch parameter to include component user information in the response.

.PARAMETER ExtendedDetails
    A switch parameter to include extended details in the response.

.EXAMPLE
    PS> Get-VaultUser -PVWAURL "https://pvwa.example.com" -LogonToken $token

.NOTES
    The function uses the Invoke-Rest function to send a GET request to the PVWA API endpoint.
    Ensure that the Invoke-Rest function is defined and available in the scope where this function is called.
#>

Function Get-VaultUser {
    Param
    (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]$PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [switch]$componentUser,
        [switch]$ExtendedDetails
    )

    Begin {
        # No need to handle $CatchAll as it's not used
    }

    Process {
        Write-LogMessage -type Verbose -MSG 'Getting all vault users'
        Write-LogMessage -type Verbose -MSG "ExtendedDetails=$ExtendedDetails"
        Write-LogMessage -type Verbose -MSG "componentUser=$componentUser"

        $URL_Users = "$PVWAURL/api/Users?ExtendedDetails=$($ExtendedDetails)&componentUser=$($componentUser)"
        return Invoke-Rest -Command GET -Uri $URL_Users -header $LogonToken
    }
}
