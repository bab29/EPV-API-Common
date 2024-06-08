function Get-SafeMember {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Alias('url','PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string]
        $memberName,
        [switch]
        $AllUsers
    )
    Begin {
        Set-Globals
    }
    process {
        If ($AllUsers) {
            $SafeMemberURL = "$PVWAURL/API/Safes/{0}/Members/" -f $SafeName
            Write-LogMessage -type Verbose -MSG "Getting all owners permissions for safe `"$SafeName`"" 
        }
        else {
            $SafeMemberURL = "$PVWAURL/API/Safes/{0}/Members/{1}/" -f $SafeName, $memberName
            Write-LogMessage -type Verbose -MSG "Getting `"memberName`" permissions for safe `"$SafeName`"" 
        }
        
        Invoke-Rest -Uri $SafeMemberURL -Method GET -Headers $logonToken -ContentType 'application/json'
    }

}