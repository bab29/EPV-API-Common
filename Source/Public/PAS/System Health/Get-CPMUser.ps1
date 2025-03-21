<#
.SYNOPSIS
Retrieves the list of Component User Names (CPMs) from the system health.

.DESCRIPTION
The Get-CPMUser function retrieves the list of Component User Names (CPMs) by calling the Get-SystemHealth cmdlet with the -CPM parameter. It logs the process of retrieving the list and returns the list of CPMs.

.PARAMETERS
None

.OUTPUTS
System.String[]
Returns an array of strings containing the Component User Names (CPMs).

.EXAMPLES
Example 1:
PS> Get-CPMUser
This example retrieves and returns the list of Component User Names (CPMs).
#>
function Get-CPMUser {
    [CmdletBinding()]
    param ()

    process {
        Write-LogMessage -type verbose -MSG "Getting list of CPMs"
        [string[]]$CPMList = (Get-SystemHealth -CPM).ComponentUserName
        Write-LogMessage -type verbose -MSG "Retrieved list of CPMs successfully: $($CPMList -join ', ')"
        return $CPMList
    }
}
