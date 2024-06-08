

function Get-CallerPreference
{
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
    'ErrorView' = $null
    'ErrorActionPreference' = 'ErrorAction'
  }
  foreach ($entry in $vars.GetEnumerator())
  {
    if ([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value))
    {
      $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
      if ($null -ne $variable)
      {
        if ($SessionState -eq $ExecutionContext.SessionState)
        {
          Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
        }
        else
        {
          $SessionState.PSVariable.Set($variable.Name, $variable.Value)
        }
      }
    }
  }
}