<#
.SYNOPSIS
Creates a new safe in the specified PVWA instance.

.DESCRIPTION
The New-Safe function creates a new safe in the specified PVWA instance using the provided parameters.
It supports ShouldProcess for confirmation prompts and logs the process.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The logon token for authentication.

.PARAMETER safeName
The name of the safe to be created.

.PARAMETER description
The description of the safe.

.PARAMETER location
The location of the safe.

.PARAMETER olacEnabled
Switch to enable or disable OLAC (Object Level Access Control).

.PARAMETER managingCPM
The name of the managing CPM (Central Policy Manager).

.PARAMETER numberOfVersionsRetention
The number of versions to retain.

.PARAMETER numberOfDaysRetention
The number of days to retain versions.

.PARAMETER AutoPurgeEnabled
Switch to enable or disable automatic purging.

.EXAMPLE
PS> New-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -safeName "NewSafe" -description "This is a new safe" -location "Root" -olacEnabled -managingCPM "CPM1" -numberOfVersionsRetention "5" -numberOfDaysRetention "30" -AutoPurgeEnabled

This command creates a new safe named "NewSafe" in the specified PVWA instance with the given parameters.

.NOTES
This function requires the 'Invoke-Rest' and 'Write-LogMessage' functions to be defined in the session.
#>

function New-Safe {
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
        [switch] $AutoPurgeEnabled,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $UpdateOnDuplicate
    )

    Begin {
        $SafeURL = "$PVWAURL/API/Safes/"
    }

    Process {
        $body = @{
            safeName                  = $safeName
            description               = $description
            location                  = $location
            managingCPM               = $managingCPM
            numberOfVersionsRetention = $numberOfVersionsRetention
            numberOfDaysRetention     = $numberOfDaysRetention
            AutoPurgeEnabled          = $AutoPurgeEnabled.IsPresent
            olacEnabled               = $olacEnabled.IsPresent
        }

        if ($PSCmdlet.ShouldProcess($safeName, 'New-Safe')) {
            Write-LogMessage -type Verbose -MSG "Adding safe `"$safeName`""
            Try {
                Invoke-Rest -Uri $SafeURL -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99) -ErrAction SilentlyContinue
                Write-LogMessage -type Verbose -MSG "Added safe `"$safeName`" successfully"
            }
            Catch {
                If ($($PSItem.ErrorDetails.Message |ConvertFrom-Json).ErrorCode -eq "SFWS0002") {
                    IF ($UpdateOnDuplicate) {
                        Write-LogMessage -type Verbose -MSG "Safe `"$safeName`" does not exist, creating instead"
                        $updateParams = @{
                            PVWAURL                  = $PVWAURL
                            LogonToken               = $LogonToken
                            safeName                 = $safeName
                            description              = $description
                            location                 = $location
                            olacEnabled              = $olacEnabled
                            managingCPM              = $managingCPM
                            numberOfVersionsRetention = $numberOfVersionsRetention
                            numberOfDaysRetention    = $numberOfDaysRetention
                            Confirm                  = $false
                        }
                        Set-Safe @updateParams
                    }
                    Else {
                        Write-LogMessage -type Warning -MSG "Safe `"$safeName`" already exists, skipping creation"
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to add safe `"$safeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping creation of safe `"$safeName`" due to confirmation being denied"
        }
    }
}
