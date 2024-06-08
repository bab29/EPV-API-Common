
# @FUNCTION@ ======================================================================================================================
# Name...........: Write-LogMessage
# Description....: Writes the message to log and screen
# Parameters.....: LogFile, MSG, (Switch)Header, (Switch)SubHeader, (Switch)Footer, Type
# Return Values..: None
# =================================================================================================================================

Function Write-LogMessage {
    <#
.SYNOPSIS
	Method to log a message on screen and in a log file
.DESCRIPTION
	Logging The input Message to the Screen and the Log File.
	The Message Type is presented in colours on the screen based on the type
.PARAMETER LogFile
	The Log File to write to. By default using the LOG_FILE_PATH
.PARAMETER MSG
	The message to log
.PARAMETER Header
	Adding a header line before the message
.PARAMETER SubHeader
	Adding a Sub header line before the message
.PARAMETER Footer
	Adding a footer line after the message
.PARAMETER Type
	The type of the message to log (Info, Warning, Error, Debug)
#>
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
        [String]$LogFile = $LOG_FILE_PATH
    )
    Try {
        If ([string]::IsNullOrEmpty($LogFile) -and $WriteLog) {
            # User wanted to write logs, but did not provide a log file - Create a temporary file
            $LogFile = '.\Log.Log'
        }
        If ($Header -and $WriteLog) {
            '=======================================' | Out-File -Append -FilePath $LogFile
            Write-Host '=======================================' -ForegroundColor Magenta
        }
        ElseIf ($SubHeader -and $WriteLog) {
            '------------------------------------' | Out-File -Append -FilePath $LogFile
            Write-Host '------------------------------------' -ForegroundColor Magenta
        }

        # Replace empty message with 'N/A'
        if ([string]::IsNullOrEmpty($Msg)) {
            $Msg = 'N/A'
        }
        $msgToWrite = ''

        # Change SecretType if password to prevent masking issues

        $Msg = $Msg.Replace('"secretType":"password"', '"secretType":"pass"')

        # Mask Passwords
        if ($Msg -match '((?:password|credentials|secret)\s{0,}["\:=]{1,}\s{0,}["]{0,})(?=([\w`~!@#$%^&*()-_\=\+\\\/|;:\.,\[\]{}]+))') {
            $Msg = $Msg.Replace($Matches[2], '****')
        }
        $Msg = $Msg.Replace('"secretType":"pass"', '"secretType":"password"')

        # Check the message type
        switch ($type) {
            { ($PSItem -eq 'Info') -or ($PSItem -eq 'LogOnly') } {
                If ($PSItem -eq 'Info') {
                    Write-Host $MSG.ToString() -ForegroundColor $(If ($Header -or $SubHeader) {
                            'Magenta'
                        }
                        Else {
                            'Gray'
                        })
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

                #Error will be thrown manually after use
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
                if ( $VerbosePreference -ne 'SilentlyContinue') {
                    Write-Verbose -Message $MSG
                    $msgToWrite = "[VERBOSE]`t`t$Msg"
                }
                break
            }
        }

        If ($WriteLog) {
            If (![string]::IsNullOrEmpty($msgToWrite)) {
                "[$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')]`t$msgToWrite" | Out-File -Append -FilePath $LogFile
            }
        }
        If ($Footer -and $WriteLog) {
            '=======================================' | Out-File -Append -FilePath $LogFile
            Write-Host '=======================================' -ForegroundColor Magenta
        }
    }
    catch {
        Throw $(New-Object System.Exception ('Cannot write message'), $PSItem.Exception)
    }
}
