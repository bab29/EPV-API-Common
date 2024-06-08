function Remove-IdentityRole {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Switch]$Force,
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Alias('url')]
        [string]
        $IdentityURL,
        [Alias('header')]
        $LogonToken,
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $Role
    )
    begin {
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        Set-Globals
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
                Return $true
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping removal of role `"$Role`" due to confimation being denied" 
        }
    }
}