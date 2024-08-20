function New-Safe {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory)]
        [string]
        $safeName,
        [Parameter(Mandatory)]
        [string]
        $description,
        [Parameter(Mandatory)]
        [string]
        $location,
        [Parameter(Mandatory, DontShow)]
        [switch]
        $olacEnabled,
        [Parameter(Mandatory)]
        [string]
        $managingCPM,
        [Parameter(Mandatory)]
        [string]
        $numberOfVersionsRetention,
        [Parameter(Mandatory)]
        [string]
        $numberOfDaysRetention,
        [Parameter(Mandatory, DontShow)]
        [switch]
        $AutoPurgeEnabled
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        $SafeURL = "$PVWAURL/API/Safes/"
    }
    process {

        $body = @{
            safeName                  = $safeName
            description               = $description
            location                  = $location
            managingCPM               = $managingCPM
            numberOfVersionsRetention = $_numberOfVersionsRetention
            numberOfDaysRetention     = $_numberOfDaysRetention
            AutoPurgeEnabled          = $AutoPurgeEnabled

        }
        If ([string]::IsNullOrEmpty($numberOfDaysRetention)) {
            $body.Add("numberOfVersionsRetention",$numberOfVersionsRetention)
        }
        else {
            $body.Add("numberOfDaysRetention",$numberOfDaysRetention)
        }
        IF ($olacEnabled) {
            $body.Add("olacEnabled","true")
        }
        IF ($AutoPurgeEnabled) {
            $body.Add("AutoPurgeEnabled","true")
        }
        if ($PSCmdlet.ShouldProcess($safeName, 'New-Safe')) {
            Write-LogMessage -type Verbose -MSG "Adding safe `"$SafeName`""
            Invoke-Rest -Uri $SafeURL -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($body | ConvertTo-Json -Depth 99)
            Write-LogMessage -type Verbose -MSG "Added safe `"$SafeName`" succesfully"
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping creation of safe `"$SafeName`" due to confimation being denied"
        }
    }
}