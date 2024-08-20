Function Get-CPMUser {
    <#
.Synopsis
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
    [CmdletBinding()]
    param ()
    Begin {

    }

    Process {
        Write-LogMessage -Type verbose -msg "Getting list of CPMs"
        [string[]]$CPMList = (Get-SystemHealth -CPM).ComponentUserName
        Write-LogMessage -Type verbose -msg "Retrieved list of CPMS Succesfully: $($CPMList -Join ", ")"
        Return $CPMList
    }
}