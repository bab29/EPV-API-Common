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
    The log file to write to. if not provided and WriteLog is $true, a temporary log file named 'Log.Log' will be created.

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
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = "Function" , Justification = 'In TODO list to remove')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [Alias('Message')]
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
        [String]$LogFile,
        [Parameter(Mandatory = $false)]
        [int]$pad = 20
    )

    begin {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    }
    process {
        try {
            if ([string]::IsNullOrEmpty($LogFile) -and $WriteLog) {
                $LogFile = '.\Log.Log'
            }
            $verboseFile = $($LogFile.replace('.log', '_Verbose.log'))
            if ($Header -and $WriteLog) {
                '=======================================' | Out-File -Append -FilePath $LogFile
                Write-Information - '======================================='
            }
            Elseif ($SubHeader -and $WriteLog) {
                '------------------------------------' | Out-File -Append -FilePath $LogFile
                Write-Output '------------------------------------'
            }
            $LogTime = "[$(Get-Date -Format 'yyyy-MM-dd hh:mm:ss')]`t"
            $msgToWrite += "$LogTime"
            $writeToFile = $true
            # Replace empty message with 'N/A'
            if ([string]::IsNullOrEmpty($Msg)) {
                $Msg = 'N/A'
            }
            # Added to prevent body messages from being masked
            $Msg = $Msg.Replace('"secretType":"password"', '"secretType":"pass"')
            # Mask Passwords
            if ($Msg -match '((?:"password"|"secret"|"NewCredentials")\s{0,}["\:=]{1,}\s{0,}["]{0,})(?=([\w!@#$%^&*()-\\\/]+))') {
                $Msg = $Msg.Replace($Matches[2], '****')
            }
            # Check the message type
            switch ($type) {
                'LogOnly' {
                    $msgToWrite = ''
                    $msgToWrite += "[INFO]`t`t$Msg"
                    break
                }
                'Info' {
                    $msgToWrite = ''
                    Write-Output $MSG.ToString()
                    $msgToWrite += "[INFO]`t`t$Msg"
                    break
                }
                'Warning' {
                    Write-Warning $MSG.ToString()
                    $msgToWrite += "[WARNING]`t$Msg"
                    if ($UseVerboseFile) {
                        $msgToWrite | Out-File -Append -FilePath $verboseFile
                    }
                    break
                }
                'Error' {
                    Write-Error $MSG.ToString()
                    $msgToWrite += "[ERROR]`t$Msg"
                    if ($UseVerboseFile) {
                        $msgToWrite | Out-File -Append -FilePath $verboseFile
                    }
                    break
                }
                'ErrorThrow' {
                    $msgToWrite = "[THROW]`t`t$Msg"
                    break
                }
                'Debug' {
                    if ($DebugPreference -ne 'SilentlyContinue' -or $VerbosePreference -ne 'SilentlyContinue' -or $UseVerboseFile) {
                        $msgToWrite += "[DEBUG]`t$Msg"
                    }
                    else {
                        $writeToFile = $False
                        break
                    }
                    if ($DebugPreference -ne 'SilentlyContinue' -or $VerbosePreference -ne 'SilentlyContinue') {
                        Write-Debug $MSG
                    }
                    if ($UseVerboseFile) {
                        $msgToWrite | Out-File -Append -FilePath $verboseFile
                    }
                }
                'Verbose' {
                    if ($VerbosePreference -ne 'SilentlyContinue' -or $UseVerboseFile) {
                        $arrMsg = $msg.split(":`t", 2)
                        if ($arrMsg.Count -gt 1) {
                            $msg = $arrMsg[0].PadRight($pad) + $arrMsg[1]
                        }
                        $msgToWrite += "[VERBOSE]`t$Msg"
                        #TODO Need to decide where to put IncludeCallStack
                        if ($global:IncludeCallStack) {
                            function Get-CallStack {
                                $stack = ''
                                $excludeItems = @('Write-LogMessage', 'Get-CallStack', '<ScriptBlock>')
                                Get-PSCallStack | ForEach-Object {
                                    if ($PSItem.Command -notin $excludeItems) {
                                        $command = $PSitem.Command
                                        #TODO Rewrite to get the script name from the script itself
                                        if ($command -eq $Global:scriptName) {
                                            $command = 'Base'
                                        }
                                        elseif ([string]::IsNullOrEmpty($command)) {
                                            $command = '**Blank**'
                                        }
                                        $Location = $PSItem.Location
                                        $stack = $stack + "$command $Location; "
                                    }
                                }
                                return $stack
                            }
                            $stack = Get-CallStack
                            $stackMsg = "CallStack:`t$stack"
                            $arrstackMsg = $stackMsg.split(":`t", 2)
                            if ($arrMsg.Count -gt 1) {
                                $stackMsg = $arrstackMsg[0].PadRight($pad) + $arrstackMsg[1].trim()
                            }
                            Write-Verbose $stackMsg
                            $msgToWrite += "`n$LogTime"
                            $msgToWrite += "[STACK]`t`t$stackMsg"
                        }
                        if ($VerbosePreference -ne 'SilentlyContinue') {
                            Write-Verbose $MSG
                            $writeToFile = $true
                        }
                        else {
                            $writeToFile = $False
                        }
                        if ($UseVerboseFile) {
                            $msgToWrite | Out-File -Append -FilePath $verboseFile
                        }
                    }
                    else {
                        $writeToFile = $False
                    }
                }
                'Success' {
                    Write-Output $MSG.ToString()
                    $msgToWrite += "[SUCCESS]`t$Msg"
                    break
                }
            }
            if ($writeToFile) {
                $msgToWrite | Out-File -Append -FilePath $LogFile
            }
            if ($Footer) {
                '=======================================' | Out-File -Append -FilePath $LogFile
                Write-Output '======================================='
            }
            If ($type -eq 'ErrorThrow') {
                Throw $MSG
            }
        }
        catch {
            IF ($type -eq 'ErrorThrow') {
                Throw $MSG
            }
            Throw $(New-Object System.Exception ('Cannot write message'), $PSItem.Exception)
        }
    }
}
