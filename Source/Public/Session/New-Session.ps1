function New-Session {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Alias("IdentityUserName", "PVWAUsername")]
        [string]
        $Username,
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [securestring]
        $Password,
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("PVWACreds", "IdentityCreds")]
        [pscredential]
        $Creds,
        [Parameter(ParameterSetName = 'PVWAURL', Mandatory)]
        [string]
        $PVWAURL,
        [Parameter(ParameterSetName = 'PCloudURL', Mandatory)]
        [string]
        $PCloudURL,
        [Parameter(ParameterSetName = 'PCloudSubdomain', Mandatory)]
        [string]
        $PCloudSubdomain,
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("IdentityTenantURL")]
        [string]
        $IdentityURL,
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [pscredential]
        $OAuthCreds,
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
    }
}