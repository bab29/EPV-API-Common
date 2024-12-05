<#
.SYNOPSIS
Creates a test vault user in the specified PVWA instance.

.DESCRIPTION
The Add-TestVaultUser function creates a test vault user with a predefined initial password and sets the user as disabled.
It requires the PVWA URL, a logon token, and the username of the user to be created.

.PARAMETER PVWAURL
The URL of the PVWA instance where the user will be created. This parameter is mandatory.

.PARAMETER LogonToken
The logon token used for authentication. This parameter is mandatory.

.PARAMETER User
The username of the test vault user to be created. This parameter is mandatory and can be provided via pipeline.

.PARAMETER Force
A switch parameter that can be used to force the operation. This parameter is optional.

.EXAMPLE
Add-TestVaultUser -PVWAURL "https://pvwa.example.com" -LogonToken $token -User "TestUser"

This example creates a test vault user named "TestUser" in the specified PVWA instance using the provided logon token.

.NOTES
The function logs verbose messages for the creation process and catches any errors that occur during the creation of the test vault user.
#>

function Add-TestVaultUser {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]$PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Member')]
        [string]$User
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -Message "Creating Test Vault User named `"$User`""
        $body = @{
            UserName        = $User
            InitialPassword = 'asdljhdsaldjl#@!321sadAS3144dcswafd'
            Disabled        = $true
        } | ConvertTo-Json -Depth 3
        $URL_AddVaultUser = "$PVWAURL/API/Users/"
        Try {
            Invoke-Rest -Command POST -Uri $URL_AddVaultUser -Header $LogonToken -Body $body
            Write-LogMessage -type Verbose -Message "Successfully created test vault user named `"$User`""
        }
        catch {
            Write-LogMessage -type Error -Message "Error creating Test Vault User named `"$User`""
        }
    }
}
