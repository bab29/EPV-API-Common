<#
.SYNOPSIS
    Retrieves the system health status from the specified PVWA URL.

.DESCRIPTION
    The Get-SystemHealth function retrieves the health status of various components from the specified PVWA URL.
    It supports multiple parameter sets to get detailed health information for specific components or a summary of all components.

.PARAMETER PVWAURL
    The URL of the PVWA instance from which to retrieve the system health status.

.PARAMETER LogonToken
    The logon token used for authentication when making the API request.

.PARAMETER Summary
    Switch parameter to retrieve a summary of the system health status.

.PARAMETER CPM
    Switch parameter to retrieve the health status of the CPM component.

.PARAMETER PVWA
    Switch parameter to retrieve the health status of the PVWA component.

.PARAMETER PSM
    Switch parameter to retrieve the health status of the PSM component.

.PARAMETER PSMP
    Switch parameter to retrieve the health status of the PSMP component.

.PARAMETER PTA
    Switch parameter to retrieve the health status of the PTA component.

.PARAMETER AIM
    Switch parameter to retrieve the health status of the AIM component.

.EXAMPLE
    Get-SystemHealth -PVWAURL "https://example.com" -LogonToken $token -Summary

    Retrieves a summary of the system health status from the specified PVWA URL.

.EXAMPLE
    Get-SystemHealth -PVWAURL "https://example.com" -LogonToken $token -CPM

    Retrieves the health status of the CPM component from the specified PVWA URL.

.NOTES
    Author: Your Name
    Date: Today's Date
#>

Function Get-SystemHealth {
    [CmdletBinding(DefaultParameterSetName = 'Summary')]
    Param
    (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(ParameterSetName = "Summary")]
        [switch] $Summary,

        [Parameter(ParameterSetName = "CPM")]
        [switch] $CPM,

        [Parameter(ParameterSetName = "PVWA")]
        [switch] $PVWA,

        [Parameter(ParameterSetName = "PSM")]
        [switch] $PSM,

        [Parameter(ParameterSetName = "PSMP")]
        [switch] $PSMP,

        [Parameter(ParameterSetName = "PTA")]
        [switch] $PTA,

        [Parameter(ParameterSetName = "AIM")]
        [switch] $AIM
    )

    Begin {
        Write-LogMessage -Type Verbose -msg "Getting System Health"
    }

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            'PVWA' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/PVWA/"
            }
            'PSM' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/SessionManagement/"
            }
            'PSMP' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/SessionManagement/"
            }
            'CPM' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/CPM/"
            }
            'PTA' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/PTA/"
            }
            'AIM' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/AIM/"
            }
            Default {
                $URL = "$PVWAURL/api/ComponentsMonitoringSummary/"
                return (Invoke-Rest -Command GET -Uri $URL -header $LogonToken).Components
            }
        }

        Try {
            $result = (Invoke-Rest -Command GET -Uri $URL -header $LogonToken).ComponentsDetails
        Write-LogMessage -Type Verbose -msg "Found $($result.ComponentsDetails.Count) $($PSCmdlet.ParameterSetName)"
            return $result
        } Catch {
            Write-LogMessage -Type Error -msg "Error Returned: $_"
        }
    }
}
