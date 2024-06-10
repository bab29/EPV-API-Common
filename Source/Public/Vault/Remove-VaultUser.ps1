<#
.SYNOPSIS
${1:Short description}
.DESCRIPTION
${2:Long description}
.PARAMETER CatchAll
${3:Parameter description}
.PARAMETER Force
${4:Parameter description}
.PARAMETER PVWAURL
${5:Parameter description}
.PARAMETER LogonToken
${6:Parameter description}
.PARAMETER User
${7:Parameter description}
.EXAMPLE
${8:An example}
.NOTES
${9:General notes}
#>
function Remove-VaultUser {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Member')]
        [string]
        $User
    )
    begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        $vaultUsers = Get-VaultUsers -url $PVWAURL -logonToken $LogonToken
        [hashtable]$vaultUserHT = @{}
        $null = $vaultUsers.users | ForEach-Object {
            Try {
                IF (28 -ge $PSitem.username.Length) {
                    Write-LogMessage -type verbose -MSG "Adding username `"$($PSitem.username)`" with ID `"$($PSItem.ID)`" to hashtable"
                    $vaultUserHT.Add($PSitem.username, $PSItem.id)
                }
                else {
                    Write-LogMessage -type verbose -MSG "Adding username `"$($PSitem.username.Substring(0,28))`" with ID `"$($PSItem.ID)`" to hashtable"
                    $vaultUserHT.Add($PSitem.username.Substring(0, 28), $PSItem.id)
                }
            }
            catch {
                Write-Error "Error on $item"
                Write-Error $PSItem
            }
        }
    }
    process {
        Write-LogMessage -type Verbose -MSG "Removing Vault User named `"$user`""
        $ID = $vaultUserHT[$user]
        If ([string]::IsNullOrEmpty($ID)) {
            Write-LogMessage -type Error "No ID located for $user"
            Return
        }
        else {
            Write-LogMessage -type Verbose -MSG "Vault ID for`"$user`" is `"$ID`""
            if ($PSCmdlet.ShouldProcess($user, 'Remove-VaultUser')) {
                Write-LogMessage -type verbose -MSG 'Confirmation to remove recieved, proceeding with removal'
                Try {
                    $URL_DeleteVaultUser = "$PVWAURL/API/Users/$($ID)/"
                    Invoke-Rest -Command DELETE -Uri $URL_DeleteVaultUser -header $logonToken
                    Write-LogMessage -type Info -MSG "Removed user with the name `"$user`" from the vault succesfully"
                }
                catch {
                    Write-LogMessage -type Error -MSG 'Error removing Vault Users'
                    Write-LogMessage -type Error -MSG $PSItem
                }
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of user `"$user`" due to confimation being denied"
            }
        }
    }
}