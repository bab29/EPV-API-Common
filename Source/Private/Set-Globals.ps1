function Set-Globals {
    [CmdletBinding()]
    param (
    )
    Begin {
        $SetGlobal = @("PVWAURL","logonToken","IdentityURL")
        $Parameters = (Get-Variable -Name MyInvocation -Scope 1).Value.MyCommand.Parameters
        $Parameters.Keys |Where-Object {$PSitem -in $SetGlobal}| ForEach-Object {
            IF ($Parameters[$PSItem].SwitchParameter) {
                Write-LogMessage -type Debug -MSG "The variable `"$PSItem`" has a type of `"Switch`", unable to get as global, skipping"
                Return
            }
            If (![string]::IsNullOrEmpty((Get-Variable -Name $PSItem -Scope 1).Value)) {
                New-Variable -Name $PSItem -Value (Get-Variable -Name $PSItem -Scope 1).Value -Scope Global -Force
                Return
            }
            Write-Host 'Supply values for the following parameters:'
            $Value = $(Read-Host -Prompt "$($PSItem)")
            IF (![string]::IsNullOrEmpty($Value)) {
                New-Variable -Name $PSItem -Value $Value -Scope Global -Force
                New-Variable -Name $PSItem -Value $Value -Scope 1 -Force
            }
            else {
                Throw "No value provided for $PSitem"
            }
        }
    }
}