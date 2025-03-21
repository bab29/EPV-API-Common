<#
.SYNOPSIS
Updates the properties of an existing safe in the PVWA.

.DESCRIPTION
The Set-Safe function updates the properties of an existing safe in the PVWA (Password Vault Web Access).
It allows you to modify the safe's description, location, managing CPM, number of versions retention,
number of days retention, and OLAC (Object Level Access Control) status.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The authentication token required to log on to the PVWA.

.PARAMETER safeName
The name of the safe to be updated.

.PARAMETER description
The new description for the safe.

.PARAMETER location
The new location for the safe.

.PARAMETER olacEnabled
A switch parameter to enable or disable OLAC for the safe.

.PARAMETER managingCPM
The name of the CPM (Central Policy Manager) managing the safe.

.PARAMETER numberOfVersionsRetention
The number of versions to retain for the safe.

.PARAMETER numberOfDaysRetention
The number of days to retain the safe.

.EXAMPLE
Set-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -safeName "FinanceSafe" -description "Updated description" -location "New York" -olacEnabled -managingCPM "CPM1" -numberOfVersionsRetention "5" -numberOfDaysRetention "30"

This example updates the safe named "FinanceSafe" with a new description, location, and other properties.

.NOTES
This function requires the PVWA URL and a valid logon token for authentication.
The function supports ShouldProcess for confirmation before making changes.
#>
function
Set-Safe {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $safeName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $description,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $location,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $olacEnabled,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $managingCPM,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $numberOfVersionsRetention,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $numberOfDaysRetention,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $CreateOnMissing
    )
    Begin {
        $SafeURL = "$PVWAURL/API/Safes/{0}/"
    }
    Process {
        $body = @{
            safeName                  = $safeName
            description               = $description
            location                  = $location
            managingCPM               = $managingCPM
            numberOfVersionsRetention = $numberOfVersionsRetention
            numberOfDaysRetention     = $numberOfDaysRetention
        }

        if ($olacEnabled) {
            $body.Add("olacEnabled", "true")
        }

        if ($PSCmdlet.ShouldProcess($safeName, 'Set-Safe')) {
            Write-LogMessage -type Debug -MSG "Updating safe `"$safeName`""
            Try {
                Invoke-Rest -Command PUT -URI ($SafeURL -f $safeName) -Header $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99) -ErrAction SilentlyContinue
                Write-LogMessage -type Debug -MSG "Updated safe `"$safeName`" successfully"
            }
            Catch {
                If (($PSItem.ErrorDetails.Message |ConvertFrom-Json).ErrorCode -eq 'SFWS0007') {
                    IF ($CreateOnMissing) {
                        Write-LogMessage -type Debug -MSG "Safe `"$safeName`" not found, creating instead"
                        New-Safe -PVWAURL $PVWAURL -LogonToken $LogonToken -safeName $safeName -description $description -location $location -olacEnabled:$olacEnabled -managingCPM $managingCPM -numberOfVersionsRetention $numberOfVersionsRetention -numberOfDaysRetention $numberOfDaysRetention -Confirm:$false
                    }
                    Else {
                        Write-LogMessage -type ErrorThrow -MSG "Safe `"$safeName`" not found."
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to add safe `"$safeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of safe `"$safeName`" due to confirmation being denied"
        }
    }
}
