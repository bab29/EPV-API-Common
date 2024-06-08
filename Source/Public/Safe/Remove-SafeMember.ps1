function Remove-SafeMember {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url','PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string]
        $memberName
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
    }
    process {
        $SafeMemberURL = "$PVWAURL/API/Safes/{0}/Members/{1}/" -f $SafeName, $memberName
        if ($PSCmdlet.ShouldProcess($PSItem.SystemName, 'Remove-SafeMember')) {
            Write-LogMessage -type Verbose -MSG "Removing owner `"memberName`" from safe `"$SafeName`"" 
            Invoke-Rest -Uri $SafeMemberURL -Method DELETE -Headers $logonToken -ContentType 'application/json'
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping removal of owner `"$memberName`" from safe  `"$SafeName`" due to confimation being denied" 
        }

    }

}