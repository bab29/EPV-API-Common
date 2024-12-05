<#
.SYNOPSIS
Removes a specified user from the vault.

.DESCRIPTION
The Remove-VaultUser function removes a specified user from the vault using the provided PVWA URL and logon token.
It supports confirmation prompts and can force removal without confirmation if specified.

.PARAMETER PVWAURL
The URL of the PVWA (Password Vault Web Access).

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER User
The username of the vault user to be removed.

.PARAMETER Force
A switch to force the removal without confirmation.

.EXAMPLE
Remove-VaultUser -PVWAURL "https://vault.example.com" -LogonToken $token -User "jdoe"

.EXAMPLE
Remove-VaultUser -PVWAURL "https://vault.example.com" -LogonToken $token -User "jdoe" -Force

.NOTES
This function requires the Get-VaultUsers and Invoke-Rest functions to be defined elsewhere in the script or module.
#>

function Remove-VaultUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
    begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        $vaultUsers = Get-VaultUsers -url $PVWAURL -logonToken $LogonToken
        $vaultUserHT = @{}
        $vaultUsers.users | ForEach-Object {
            try {
                $username = if ($_.username.Length -le 28) { $_.username } else { $_.username.Substring(0, 28) }
                Write-LogMessage -type verbose -MSG "Adding username `"$username`" with ID `"$($_.ID)`" to hashtable"
                $vaultUserHT[$username] = $_.ID
            }
            catch {
                Write-Error "Error on $item"
                Write-Error $_
            }
        }
    }
    process {
        Write-LogMessage -type Verbose -MSG "Removing Vault User named `"$User`""
        $ID = $vaultUserHT[$User]
        if ([string]::IsNullOrEmpty($ID)) {
            Write-LogMessage -type Error "No ID located for $User"
            return
        }
        else {
            Write-LogMessage -type Verbose -MSG "Vault ID for `"$User`" is `"$ID`""
            if ($PSCmdlet.ShouldProcess($User, 'Remove-VaultUser')) {
                Write-LogMessage -type verbose -MSG 'Confirmation to remove received, proceeding with removal'
                try {
                    $URL_DeleteVaultUser = "$PVWAURL/API/Users/$ID/"
                    Invoke-Rest -Command DELETE -Uri $URL_DeleteVaultUser -header $LogonToken
                    Write-LogMessage -type Info -MSG "Removed user with the name `"$User`" from the vault successfully"
                }
                catch {
                    Write-LogMessage -type Error -MSG 'Error removing Vault Users'
                    Write-LogMessage -type Error -MSG $_
                }
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of user `"$User`" due to confirmation being denied"
            }
        }
    }
}
