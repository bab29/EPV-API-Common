
function Remove-IdentityRole {
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
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $Role
    )
    begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
    }
    process {
        Write-LogMessage -type Verbose -MSG "Removing role named `"$Role`""
        Try {
            $RoleID = $("$(Get-IdentityRole -Logontoken $header -roleName "$Role" -IdentityURL $IdentityURL -IDOnly)")
            IF ([string]::IsNullOrEmpty($RoleID)) {
                Write-LogMessage -type Warning -MSG "Role named `"$Role`" not found"
                Return
            }
        }
        Catch {
            Write-LogMessage -type Error -MSG $PSItem
            Return
        }
        $body = [PSCustomObject]@{
            Name = $RoleID
        }
        if ($PSCmdlet.ShouldProcess($Role, 'Remove-IdentityRole')) {
            $result = Invoke-RestMethod -Uri "$IdentityURL/SaasManage/DeleteRole/" -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($body | ConvertTo-Json -Depth 99)
            IF (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
                Return
            }
            else {
                Write-LogMessage -type Warning -MSG "Role named `"$Role`" succsefully deleted"
                Return
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping removal of role `"$Role`" due to confimation being denied"
        }
    }
}