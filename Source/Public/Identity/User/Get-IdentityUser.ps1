
function Get-IdentityUser {
    <#
.Synopsis
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [switch]
        $IDOnly,
        [Parameter(ValueFromPipeline)]
        [Alias('DirID,DirectoryUUID')]
        [String[]]
        $DirectoryServiceUuid,
        [Parameter(ValueFromPipeline)]
        [string]
        $directoryName,
        [Parameter(ValueFromPipeline)]
        [string]
        $directoryService,
        [Parameter(ValueFromPipeline)]
        [Alias('user', 'username')]
        [string]$name,
        [Parameter(ValueFromPipeline)]
        [string]
        $DisplayName,
        [Parameter(ValueFromPipeline)]
        [alias('email')]
        [string]
        $mail,
        [Parameter(ValueFromPipeline)]
        [Alias('ObjectGUID', 'GUID', 'UUID', 'UID', 'ExternalUuid')]
        [string]
        $id,
        [switch]
        $AllUsers
    )
    begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        [string[]]$DirID = Get-DirectoryService @PSBoundParameters -UuidOnly
    }
    process {
        [PSCustomObject[]]$userSearch = @()
        IF (![string]::IsNullOrEmpty($id)) {
            Write-LogMessage -type Verbose -MSG "User ID provided, adding `"$id`" to user search paramters"
            $userSearch += [PSCustomObject]@{_ID = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $id; ignoreCase = 'true' } } }
        }
        IF (![string]::IsNullOrEmpty($Name)) {
            Write-LogMessage -type Verbose -MSG "User Name provided, adding `"$name`" to user search paramters"
            $userSearch += [PSCustomObject]@{Name = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $Name; ignoreCase = 'true' } } }
        }
        IF (![string]::IsNullOrEmpty($DisplayName)) {
            Write-LogMessage -type Verbose -MSG "User Display Name provided, adding `"$DisplayName`" to user search paramters"
            $userSearch += [PSCustomObject]@{DisplayName = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $DisplayName; ignoreCase = 'true' } } }
        }
        IF (![string]::IsNullOrEmpty($mail)) {
            Write-LogMessage -type Verbose -MSG "User Email provided, adding `"$mail`" to user search paramters"
            $userSearch += [PSCustomObject]@{Email = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $mail; ignoreCase = 'true' } } }
        }
        IF ($AllUsers) {
            Write-LogMessage -type Warning -MSG 'All Users switch passed, getting all users'
        }
        elseif (0 -eq $userSearch.Count) {
            Write-LogMessage -type ErrorThrow -MSG 'No search paramters found'
        }
        $user = [PSCustomObject]@{'_or' = $userSearch; ObjectType = 'user' }
        $userquery = [PSCustomObject]@{
            'user' = "$($user|ConvertTo-Json -Depth 99 -Compress)"
            'Args' = [PSCustomObject]@{
                'PageNumber' = 1;
                'PageSize'   = 100000;
                'Limit'      = 100000;
                'SortBy'     = '';
                'Caching'    = -1
            }
        }
        $userquery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force
        Try {
            Write-LogMessage -type Verbose -MSG 'Starting search for user'
            $result = Invoke-Rest -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $logonToken -ContentType 'application/json' -Body $($userquery | ConvertTo-Json -Depth 99)
            IF (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
                Return
            }
            elseif (![string]::IsNullOrEmpty($result.Result.Exceptions.User)) {
                Write-LogMessage -type Error -MSG $result.Result.Exceptions.User
                Return
            }
            IF (0 -eq $result.Result.User.Results.Count) {
                Write-LogMessage -type Warning -MSG 'No user found'
                Return
            }
            Else {
                If ($IDOnly) {
                    Write-LogMessage -type Verbose -MSG 'Returning ID of user'
                    Return $result.Result.User.Results.Row.InternalName
                }
                else {
                    Write-LogMessage -type Verbose -MSG 'Returning all informatin about user'
                    Return $result.Result.User.Results.Row
                }
            }
        }
        Catch {
            Write-LogMessage -type Error -MSG "Error Code : $($PSitem.Exception.Message)"
        }
    }
}