function Update-Safe {
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
        $numberOfDaysRetention
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        $SafeURL = "$PVWAURL/API/Safes/{0}/"
    }
    process {

        $body = @{
            safeName = $safeName
        }
        If (-not [string]::IsNullOrEmpty($description)) {
            $body.Add("description", $description)
        }
        If (-not [string]::IsNullOrEmpty($location)) {
            $body.Add("location", $location)
        }
        If (-not [string]::IsNullOrEmpty($managingCPM)) {
            $body.Add("managingCPM", $managingCPM)
        }
        If (-not [string]::IsNullOrEmpty($numberOfDaysRetention)) {
            If (-not [string]::IsNullOrEmpty($numberOfDaysRetention)) {
                $body.Add("numberOfDaysRetention", $numberOfDaysRetention)
            }
        }
        else {
            $body.Add("numberOfDaysRetention", $numberOfDaysRetention)
        }
        IF ($olacEnabled) {
            $body.Add("olacEnabled", "true")
        }
        if ($PSCmdlet.ShouldProcess($safeName, 'Update-Safe')) {
            Write-LogMessage -type Verbose -MSG "Adding safe `"$SafeName`""
            Invoke-Rest -Uri $($SafeURL -f $safename) -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($body | ConvertTo-Json -Depth 99)
            Write-LogMessage -type Verbose -MSG "Added safe `"$SafeName`" succesfully"
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of safe `"$SafeName`" due to confimation being denied"
        }

    }
}