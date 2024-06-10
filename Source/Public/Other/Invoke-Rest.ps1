<#
.SYNOPSIS
Invoke REST Method
.DESCRIPTION
Invoke REST Method
.PARAMETER Command
The REST Command method to run (GET, POST, PATCH, DELETE)
.PARAMETER URI
The URI to use as REST API
.PARAMETER Header
The Header as Dictionary object
.PARAMETER Body
The REST Body
.PARAMETER ErrAction
The Error Action to perform in case of error. By default "Continue"
#>
Function Invoke-Rest {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', Scope = "Function" , Justification = 'Used in deep debugging')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Method')]
        [ValidateSet('GET', 'POST', 'DELETE', 'PATCH', 'PUT')]
        [String]$Command,
        [Alias('PCloudURL', 'IdentityURL', 'URL')]
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$URI,
        [Alias('LogonToken', 'Headers')]
        [Parameter(Mandatory = $false)]
        $Header,
        [Parameter(Mandatory = $false)]
        [String]$Body,
        [Parameter(Mandatory = $false)]
        [String]$ContentType = 'application/json',
        [Parameter(Mandatory = $false)]
        [ValidateSet('Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', 'Suspend')]
        [String]$ErrAction = 'Continue'
    )
    Process {
        Write-LogMessage -Type Verbose -Msg 'Entering Invoke-Rest'
        $restResponse = ''
        try {
            Write-LogMessage -Type Verbose -Msg "Invoke-RestMethod -Uri $URI -Method $Command -Header $($Header |ConvertTo-Json -Compress -Depth 9) -ContentType $ContentType -TimeoutSec 2700"
            if ([string]::IsNullOrEmpty($Body)) {
                $restResponse = Invoke-RestMethod -Uri $URI -Method $Command -Header $Header -ContentType $ContentType -TimeoutSec 2700 -ErrorAction $ErrAction
            }
            else {
                Write-LogMessage -Type Verbose -Msg "Body Found: `n$body"
                $restResponse = Invoke-RestMethod -Uri $URI -Method $Command -Body $Body -Header $Header -ContentType $ContentType -TimeoutSec 2700 -ErrorAction $ErrAction
            }
        }
        catch [System.Net.WebException] {
            if ($ErrAction -match ('\bContinue\b|\bInquire\b|\bStop\b|\bSuspend\b')) {
                IF (![string]::IsNullOrEmpty($(($PSItem.ErrorDetails.Message | ConvertFrom-Json).ErrorCode))) {
                    If (($($PSItem.ErrorDetails.Message | ConvertFrom-Json).ErrorCode -eq 'ITATS127E')) {
                        Write-LogMessage -Type Error -Msg 'Was able to connect to the PVWA successfully, but the account was locked'
                        Write-LogMessage -Type Error -Msg "URI:  $URI"
                        Write-LogMessage -Type Verbose -Msg 'Exiting Invoke-Rest'
                        Throw [System.Management.Automation.RuntimeException] 'Account Locked'
                    }
                    ElseIf (!($($PSItem.ErrorDetails.Message | ConvertFrom-Json).ErrorCode -in $global:SkipErrorCode)) {
                        Write-LogMessage -Type Error -Msg 'Was able to connect to the PVWA successfully, but the command resulted in a error'
                        Write-LogMessage -Type Error -Msg "URI:  $URI"
                        Write-LogMessage -Type Error -Msg "Command:  $Command"
                        Write-LogMessage -Type Error -Msg "Body:  $Body"
                        Write-LogMessage -Type Error -Msg "Returned ErrorCode: $(($PSItem.ErrorDetails.Message|ConvertFrom-Json).ErrorCode)"
                        Write-LogMessage -Type Error -Msg "Returned ErrorMessage: $(($PSItem.ErrorDetails.Message|ConvertFrom-Json).ErrorMessage)"
                        Write-LogMessage -Type Verbose $PSItem
                    }
                }
                Else {
                    Write-LogMessage -Type Error -Msg "Error Message: $PSItem"
                    Write-LogMessage -Type Error -Msg "Exception Message: $($PSItem.Exception.Message)"
                    Write-LogMessage -Type Error -Msg "Status Code: $($PSItem.Exception.Response.StatusCode.value__)"
                    Write-LogMessage -Type Error -Msg "Status Description: $($PSItem.Exception.Response.StatusDescription)"
                    Write-LogMessage -Type Verbose $PSItem
                }
            }
            $restResponse = $null
        }
        catch {
            Write-LogMessage -Type Error -Msg "`tError Message: $PSItem"
            Write-LogMessage -Type Verbose $PSItem
            Write-LogMessage -Type Verbose -Msg 'Exiting Invoke-Rest'
            Throw $(New-Object System.Exception ("Invoke-Rest: Error in running $Command on '$URI'", $PSItem.Exception))
        }
        If ($URI -match 'Password/Retrieve') {
            Write-LogMessage -Type Verbose -Msg 'Invoke-REST Response: ***********'
        }
        else {
            If ($global:SuperVerbose) {
                Write-LogMessage -Type Verbose -Msg "Invoke-REST Response Type: $($restResponse.GetType().Name)"
                $type = $($restResponse.GetType().Name)
                IF (('String' -ne $type)) {
                    Write-LogMessage -Type Verbose -Msg "Invoke-REST ConvertTo-Json Response: $($restResponse |ConvertTo-Json -Depth 9 -Compress)"
                }
                else {
                    Write-LogMessage -Type Verbose -Msg "Invoke-REST Response: $($restResponse)"
                }
            }
            else {
                Write-LogMessage -Type Verbose -Msg "Invoke-REST Response: $($restResponse)"
            }
        }
        Write-LogMessage -Type Verbose -Msg 'Exiting Invoke-Rest'
        return $restResponse
    }
}