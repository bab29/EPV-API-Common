<#
.Synopsis
    Used to establish a connection to CyberArk
.DESCRIPTION
    Used to establish a connection to CyberArk
.COMPONENT
    CyberArk PVWA or CyberArk Identity
#>
function New-Session {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '' ,Justification = 'Used to create a new session')]
    [CmdletBinding()]
    param (
        # Username to connect to with as a String
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Alias("IdentityUserName", "PVWAUsername")]
        [string]
        $Username,
        # Password to connect with stored as a SecureString
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [securestring]
        $Password,
        # Credentials stored a PSCredentials
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("PVWACreds", "IdentityCreds")]
        [pscredential]
        $Creds,
        # URL to the PVWA
        [Parameter(ParameterSetName = 'PVWAURL', Mandatory)]
        [string]
        $PVWAURL,
        # URL to Prvilaged Cloud
        [Parameter(ParameterSetName = 'PCloudURL', Mandatory)]
        [string]
        $PCloudURL,
        # Subdomain for Prvilaged Cloud
        [Parameter(ParameterSetName = 'PCloudSubdomain', Mandatory)]
        [string]
        $PCloudSubdomain,
        # URL for CyberArk Identity
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("IdentityTenantURL")]
        [string]
        $IdentityURL,
        # OAuth credentails stored as PSCredentials
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [pscredential]
        $OAuthCreds,
        # Log file name
        [string]
        $LogFile = ".\Log.Log"
    )
    begin {
        $PSDefaultParameterValues["*:LogFile"] = $LogFile
        Function Get-PCLoudLogonHeader {
            param (
                [Parameter(ValueFromRemainingArguments, DontShow)]
                $CatchAll,
                [Alias("IdentityURL")]
                [string]
                $IdentityTenantURL,
                [Alias("Username")]
                [string]
                $IdentityUserName,
                [Alias("Creds")]
                [pscredential]
                $UPCreds,
                [pscredential]
                $OAuthCreds
            )
            $PSBoundParameters.Remove("CatchAll") | Out-Null
            return Get-IdentityHeader @PSBoundParameters
        }
        Function Get-OnPremLogonHeader {
            param (
                [Parameter(ValueFromRemainingArguments, DontShow)]
                $CatchAll,
                [string]
                $PVWAURL,
                [string]
                $Username,
                [Alias("Creds")]
                [pscredential]
                $PVWACreds
            )
            $PSBoundParameters.Remove("CatchAll")  | Out-Null
            return Get-IdentityHeader @PSBoundParameters
        }
        if (![string]::IsNullOrEmpty($password)) {
            $PSBoundParameters["creds"] = [pscredential]::new($userName , $password )
            $null = $PSBoundParameters.Remove("Username")
            $null = $PSBoundParameters.Remove("Password")
        }
        switch ($PSCmdlet.ParameterSetName) {
            'PCloudSubdomain' {
                $logonToken = Get-PCLoudLogonHeader @PSBoundParameters
                $PSDefaultParameterValues["*:LogonToken"] = $logonToken
                $PSDefaultParameterValues["*:PVWAURL"] = "https://$PCloudSubdomain.privilegecloud.cyberark.cloud/PasswordVault/"
                $PSDefaultParameterValues["*:IdentityURL"] = $IdentityURL
                break
            }
            'PCloudURL' {
                $logonToken = Get-PCLoudLogonHeader @PSBoundParameters
                $PSDefaultParameterValues["*:LogonToken"] = $logonToken
                $PSDefaultParameterValues["*:PVWAURL"] = $PCloudURL
                $PSDefaultParameterValues["*:IdentityURL"] = $IdentityURL
                break
            }
            'PVWAURL' {
                $PSDefaultParameterValues["*:LogonToken"] = Get-OnPremLogonHeader @PSBoundParameters
                $PSDefaultParameterValues["*:PVWAURL"] = $PVWAURL
                break
            }
        }

        Set-Variable -Name PSDefaultParameterValues -Scope 2 -Value $PSDefaultParameterValues
        Try {
            [string[]]$CPMUser = Get-CPMUser 
            $PSDefaultParameterValues["*:CPMUser"] = $CPMUser
            Set-Variable -Name PSDefaultParameterValues -Scope 2 -Value $PSDefaultParameterValues
        }
        catch {
            Write-LogMessage -type warning -msg "Unable to retrieve list of CPMs, the connection was made with a restricted user and not all commands may work"
        }
    }
}