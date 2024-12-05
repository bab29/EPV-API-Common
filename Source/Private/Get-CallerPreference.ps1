function Get-CallerPreference {
  <#
.Synopsis
    Retrieves and sets caller preference variables.
  .DESCRIPTION
    The Get-CallerPreference function retrieves specific preference variables from the caller's session state and sets them in the current session state or a specified session state.
    It ensures that the preference variables such as ErrorActionPreference, VerbosePreference, and DebugPreference are correctly set based on the caller's context.
  .EXAMPLE
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    This example retrieves the caller preference variables from the current session state and sets them accordingly.
  .EXAMPLE
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $CustomSessionState
    This example retrieves the caller preference variables from the current session state and sets them in a custom session state.
  .INPUTS
    [System.Management.Automation.PSScriptCmdlet]
      The cmdlet from which to retrieve the caller preference variables.
    [System.Management.Automation.SessionState]
      The session state where the preference variables will be set.
  .OUTPUTS
    None
  .NOTES
    This function is useful for ensuring that preference variables are consistently set across different session states.
  .COMPONENT
    EPV-API-Common
  .ROLE
    Utility
  .FUNCTIONALITY
    Preference Management
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
    $Cmdlet,
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.SessionState]
    $SessionState
  )

  $vars = @{
    'ErrorView'             = $null
    'ErrorActionPreference' = 'ErrorAction'
    'VerbosePreference'     = 'Verbose'
    'DebugPreference'       = 'Debug'
  }

  foreach ($entry in $vars.GetEnumerator()) {
    if ([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) {
      $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
      if ($null -ne $variable) {
        if ($SessionState -eq $ExecutionContext.SessionState) {
          Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
        } else {
          $SessionState.PSVariable.Set($variable.Name, $variable.Value)
        }
      }
    }
  }
}
