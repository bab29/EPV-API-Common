<#
.SYNOPSIS
Creates a new session for connecting to CyberArk environments.

.DESCRIPTION
The New-Session function establishes a new session for connecting to CyberArk environments, including PVWA and Privileged Cloud. It supports multiple parameter sets for different connection scenarios and handles credentials securely.

.PARAMETER Username
Specifies the username to connect with as a string. This parameter is used in the 'PVWAURL', 'PCloudSubdomain', and 'PCloudURL' parameter sets.

.PARAMETER Password
Specifies the password to connect with, stored as a SecureString. This parameter is used in the 'PVWAURL', 'PCloudSubdomain', and 'PCloudURL' parameter sets.

.PARAMETER Creds
Specifies the credentials stored as PSCredentials. This parameter is used in the 'PVWAURL', 'PCloudSubdomain', and 'PCloudURL' parameter sets.

.PARAMETER PVWAURL
Specifies the URL to the PVWA. This parameter is mandatory in the 'PVWAURL' parameter set.

.PARAMETER PCloudURL
Specifies the URL to the Privileged Cloud. This parameter is mandatory in the 'PCloudURL' parameter set.

.PARAMETER PCloudSubdomain
Specifies the subdomain for the Privileged Cloud. This parameter is mandatory in the 'PCloudSubdomain' parameter set.

.PARAMETER IdentityURL
Specifies the URL for CyberArk Identity. This parameter is used in the 'PCloudURL' and 'PCloudSubdomain' parameter sets.

.PARAMETER OAuthCreds
Specifies the OAuth credentials stored as PSCredentials. This parameter is used in the 'PCloudURL' and 'PCloudSubdomain' parameter sets.

.PARAMETER LogFile
Specifies the log file name. The default value is ".\Log.Log".

.EXAMPLE
New-Session -Username "admin" -Password (ConvertTo-SecureString "password" -AsPlainText -Force) -PVWAURL "https://pvwa.example.com"

.EXAMPLE
New-Session -Creds (Get-Credential) -PCloudURL "https://cloud.example.com" -IdentityURL "https://identity.example.com"

.NOTES
This function sets default parameter values for subsequent commands in the session, including logon tokens and URLs.
#>

function New-Session {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Used to create a new session')]
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Alias("IdentityUserName", "PVWAUsername")]
        [string] $Username,

        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [securestring] $Password,

        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("PVWACreds", "IdentityCreds")]
        [pscredential] $Creds,

        [Parameter(ParameterSetName = 'PVWAURL', Mandatory)]
        [string] $PVWAURL,

        [Parameter(ParameterSetName = 'PCloudURL', Mandatory)]
        [string] $PCloudURL,

        [Parameter(ParameterSetName = 'PCloudSubdomain', Mandatory)]
        [string] $PCloudSubdomain,

        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("IdentityTenantURL")]
        [string] $IdentityURL,

        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [pscredential] $OAuthCreds,

        [string] $LogFile = ".\Log.Log"
    )

    begin {
        $PSDefaultParameterValues["*:LogFile"] = $LogFile

        function Get-PCLoudLogonHeader {
            param (
                [Parameter(ValueFromRemainingArguments, DontShow)] $CatchAll,
                [Alias("IdentityURL")] [string] $IdentityTenantURL,
                [Alias("Username")] [string] $IdentityUserName,
                [Alias("Creds")] [pscredential] $UPCreds,
                [pscredential] $OAuthCreds
            )
            $PSBoundParameters.Remove("CatchAll") | Out-Null
            return Get-IdentityHeader @PSBoundParameters
        }

        function Get-OnPremLogonHeader {
            param (
                [Parameter(ValueFromRemainingArguments, DontShow)] $CatchAll,
                [string] $PVWAURL,
                [string] $Username,
                [Alias("Creds")] [pscredential] $PVWACreds
            )
            $PSBoundParameters.Remove("CatchAll") | Out-Null
            return Get-IdentityHeader @PSBoundParameters
        }

        if ($Password) {
            $PSBoundParameters["Creds"] = [pscredential]::new($Username, $Password)
            $null = $PSBoundParameters.Remove("Username")
            $null = $PSBoundParameters.Remove("Password")
        }

        try {
            switch ($PSCmdlet.ParameterSetName) {
                'PCloudSubdomain' {
                    $logonToken = Get-PCLoudLogonHeader @PSBoundParameters
                    $PSDefaultParameterValues["*:LogonToken"] = $logonToken
                    $PSDefaultParameterValues["*:PVWAURL"] = "https://$PCloudSubdomain.privilegecloud.cyberark.cloud/PasswordVault/"
                    $PSDefaultParameterValues["*:IdentityURL"] = $IdentityURL
                }
                'PCloudURL' {
                    $logonToken = Get-PCLoudLogonHeader @PSBoundParameters
                    $PSDefaultParameterValues["*:LogonToken"] = $logonToken
                    $PSDefaultParameterValues["*:PVWAURL"] = $PCloudURL
                    $PSDefaultParameterValues["*:IdentityURL"] = $IdentityURL
                }
                'PVWAURL' {
                    $PSDefaultParameterValues["*:LogonToken"] = Get-OnPremLogonHeader @PSBoundParameters
                    $PSDefaultParameterValues["*:PVWAURL"] = $PVWAURL
                }
            }
        }
        catch {
            Write-LogMessage -type Error -MSG "Unable to establish a connection to CyberArk"
            return
        }

        Set-Variable -Name PSDefaultParameterValues -Scope 2 -Value $PSDefaultParameterValues

        try {
            [string[]] $CPMUser = Get-CPMUser
            $PSDefaultParameterValues["*:CPMUser"] = $CPMUser
            Set-Variable -Name PSDefaultParameterValues -Scope 2 -Value $PSDefaultParameterValues
        }
        catch {
            Write-LogMessage -type Warning -MSG "Unable to retrieve list of CPMs, the connection was made with a restricted user and not all commands may work"
        }
    }
}
