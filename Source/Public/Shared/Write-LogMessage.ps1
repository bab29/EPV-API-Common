<#
.SYNOPSIS
    Writes a log message to the console and optionally to a log file with various formatting options.

.DESCRIPTION
    The Write-LogMessage function logs messages to the console with optional headers, subheaders, and footers.
    It also supports writing messages to a log file. The function can handle different message types such as
    Info, Warning, Error, Debug, Verbose, Success, LogOnly, and ErrorThrow. It also masks sensitive information
    like passwords in the messages.

.PARAMETER MSG
    The message to log. This parameter is mandatory and accepts pipeline input.

.PARAMETER Header
    Adds a header line before the message. This parameter is optional.

.PARAMETER SubHeader
    Adds a subheader line before the message. This parameter is optional.

.PARAMETER Footer
    Adds a footer line after the message. This parameter is optional.

.PARAMETER WriteLog
    Indicates whether to write the output to a log file. The default value is $true.

.PARAMETER type
    The type of the message to log. Valid values are 'Info', 'Warning', 'Error', 'Debug', 'Verbose', 'Success',
    'LogOnly', and 'ErrorThrow'. The default value is 'Info'.

.PARAMETER LogFile
    The log file to write to. If not provided and WriteLog is $true, a temporary log file named 'Log.Log' will be created.

.EXAMPLE
    Write-LogMessage -MSG "This is an info message" -type Info

    Logs an info message to the console and the default log file.

.EXAMPLE
    "This is a warning message" | Write-LogMessage -type Warning

    Logs a warning message to the console and the default log file using pipeline input.

.EXAMPLE
    Write-LogMessage -MSG "This is an error message" -type Error -LogFile "C:\Logs\error.log"

    Logs an error message to the console and to the specified log file.

.NOTES
    The function masks sensitive information like passwords in the messages to prevent accidental exposure.
#>

Function Write-LogMessage {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Scope = "Function" , Justification = 'Want to go to console and allow for colors')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String]$MSG,

        [Parameter(Mandatory = $false)]
        [Switch]$Header,

        [Parameter(Mandatory = $false)]
        [Switch]$SubHeader,

        [Parameter(Mandatory = $false)]
        [Switch]$Footer,

        [Parameter(Mandatory = $false)]
        [Bool]$WriteLog = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug', 'Verbose', 'Success', 'LogOnly', 'ErrorThrow')]
        [String]$type = 'Info',

        [Parameter(Mandatory = $false)]
        [String]$LogFile
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }

    process {
        Try {
            if ([string]::IsNullOrEmpty($LogFile) -and $WriteLog) {
                $LogFile = '.\Log.Log'
            }

            if ($Header -and $WriteLog) {
                '=======================================' | Out-File -Append -FilePath $LogFile
                Write-Host '=======================================' -ForegroundColor Magenta
            }
            elseif ($SubHeader -and $WriteLog) {
                '------------------------------------' | Out-File -Append -FilePath $LogFile
                Write-Host '------------------------------------' -ForegroundColor Magenta
            }

            if ([string]::IsNullOrEmpty($Msg)) {
                $Msg = 'N/A'
            }

            $msgToWrite = ''
            $Msg = $Msg.Replace('"secretType":"password"', '"secretType":"pass"')

            if ($Msg -match '((?:password|credentials|secret)\s{0,}["\:=]{1,}\s{0,}["]{0,})(?=([\w`~!@#$%^&*()-_\=\+\\\/|;:\.,\[\]{}]+))') {
                $Msg = $Msg.Replace($Matches[2], '****')
            }

            $Msg = $Msg.Replace('"secretType":"pass"', '"secretType":"password"')

            switch ($type) {
                { ($PSItem -eq 'Info') -or ($PSItem -eq 'LogOnly') } {
                    if ($PSItem -eq 'Info') {
                        Write-Host $MSG.ToString() -ForegroundColor $(if ($Header -or $SubHeader) { 'Magenta' } else { 'Gray' })
                    }
                    $msgToWrite = "[INFO]`t`t`t$Msg"
                    break
                }
                'Success' {
                    Write-Host $MSG.ToString() -ForegroundColor Green
                    $msgToWrite = "[SUCCESS]`t`t$Msg"
                    break
                }
                'Warning' {
                    Write-Host $MSG.ToString() -ForegroundColor Yellow
                    $msgToWrite = "[WARNING]`t$Msg"
                    break
                }
                'Error' {
                    Write-Host $MSG.ToString() -ForegroundColor Red
                    $msgToWrite = "[ERROR]`t`t$Msg"
                    break
                }
                'ErrorThrow' {
                    $msgToWrite = "[THROW]`t`t$Msg"
                    break
                }
                'Debug' {
                    if ($DebugPreference -ne 'SilentlyContinue' -or $VerbosePreference -ne 'SilentlyContinue') {
                        Write-Debug -Message $MSG
                        $msgToWrite = "[Debug]`t`t`t$Msg"
                    }
                    break
                }
                'Verbose' {
                    if ($VerbosePreference -ne 'SilentlyContinue') {
                        Write-Verbose -Message $MSG
                        $msgToWrite = "[VERBOSE]`t`t$Msg"
                    }
                    break
                }
            }

            if ($WriteLog -and $msgToWrite) {
                "[$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')]`t$msgToWrite" | Out-File -Append -FilePath $LogFile
            }

            if ($Footer -and $WriteLog) {
                '=======================================' | Out-File -Append -FilePath $LogFile
                Write-Host '=======================================' -ForegroundColor Magenta
            }
        }
        catch {
            Throw $(New-Object System.Exception ('Cannot write message'), $PSItem.Exception)
        }
    }
}
