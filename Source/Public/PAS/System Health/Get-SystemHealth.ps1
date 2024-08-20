<#
.SYNOPSIS
Gets users from vault
.DESCRIPTION
Get users from vault
${2:Long description}
.PARAMETER PVWAURL
${4:Parameter description}
.PARAMETER LogonToken
${5:Parameter description}
.PARAMETER componentUser
${6:Parameter description}
.PARAMETER ExtendedDetails
${7:Parameter description}
.EXAMPLE
${8:An example}
.NOTES
${9:General notes}
#>
Function Get-SystemHealth {
    [CmdletBinding(DefaultParameterSetName = 'Summary')]
    Param
    (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        # Parameter help description
        [Parameter(ParameterSetName = "Summary")]
        [switch]
        $Summery,
        [Parameter(ParameterSetName = "CPM")]
        [switch]
        $CPM,
        [Parameter(ParameterSetName = "PVWA")]
        [switch]
        $PVWA,
        [Parameter(ParameterSetName = "PSM")]
        [switch]
        $PSM,
        [Parameter(ParameterSetName = "PSMP")]
        [switch]
        $PSMP,
        [Parameter(ParameterSetName = "PTA")]
        [switch]
        $PTA,
        [Parameter(ParameterSetName = "AIM")]
        [switch]
        $AIM

    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    Process {
        Write-LogMessage -Type Verbose -msg "Getting System Health"
        switch ($PSCmdlet.ParameterSetName) {

            'PVWA' {
                Write-LogMessage -Type Verbose -msg "$($PSCmdlet.ParameterSetName) selected, sending details"
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/PVWA/"
                Break
            }
            { 'PSM' -eq $PSitem -or 'PSMP' -eq $PSitem } {
                Write-LogMessage -Type Verbose -msg "$($PSCmdlet.ParameterSetName) selected, sending details"
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/SessionManagement/"
                Break
            }
            'CPM' {
                Write-LogMessage -Type Verbose -msg "$($PSCmdlet.ParameterSetName) selected, sending details"
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/CPM/"
                Break
            }
            'PTA' {
                Write-LogMessage -Type Verbose -msg "$($PSCmdlet.ParameterSetName) selected, sending details"
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/PTA/"
                Break
            }
            'AIM' {
                Write-LogMessage -Type Verbose -msg "$($PSCmdlet.ParameterSetName) selected, sending details"
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/AIM/"
                Break
            }
            Default {
                Write-LogMessage -Type Verbose -msg "No component selected, returning summery"
                $URL = "$PVWAURL/api/ComponentsMonitoringSummary/"
                return (Invoke-Rest -Command GET -Uri $URL -header $logonToken).Components
                Break
            }
        }
        Try {
        $result = (Invoke-Rest -Command GET -Uri $URL -header $logonToken).ComponentsDetails
        Write-LogMessage -Type Verbose -msg "Found $($result.ComponentsDetails.Count) $($PSCmdlet.ParameterSetName)"
        return    $result
        } Catch {
            Write-LogMessage -Type Error -msg "Error Returned: $PSItem"
        }
    }
}