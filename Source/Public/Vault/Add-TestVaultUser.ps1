
function Add-TestVaultUser {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName,ValueFromPipeline)]
        [Alias('Member')]
        [string]
        $User
    ) 
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -MSG "Creating Test Vault User named `"$user`""
        $body = @{
            UserName        = $User
            InitialPassword = 'asdljhdsaldjl#@!321sadAS3144dcswafd'
            Disabled        = $true
        } | ConvertTo-Json -Depth 3

        $URL_AddVaultUser = "$PVWAURL/API/Users/"
        Try {
        Invoke-Rest -Command POST -Uri $URL_AddVaultUser -header $logonToken -Body $body
        Write-LogMessage -type Verbose -MSG "Succesfully created test vault user named `"$user`""
    } catch {
        Write-LogMessage -type Error -MSG "Error creating Test Vault User named `"$user`""
    }
}
}
