function Test-Mandatory {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('Identity')]
        [string]
        $IdentityURL,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('PVWA', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('header')]
        $LogonToken,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LogFile', 'Log_File')]
        [string]
        $LOG_FILE_PATH = '.\Log.Log'
    )
     process {

        $PSBoundParameters.Keys | ForEach-Object { 
            If ([string]::IsNullOrEmpty($PSBoundParameters[$PSItem])) {

            } 
        }
     }
}
