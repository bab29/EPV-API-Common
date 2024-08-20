
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
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('DirID,DirectoryUUID')]
        [String[]]
        $DirectoryServiceUuid,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $directoryName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $directoryService,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('user', 'username', 'member', 'UserPrincipalName', 'SamAccountName')]
        [string]$name,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $DisplayName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [alias('email')]
        [string]
        $mail,
        [Parameter(ValueFromPipelineByPropertyName, DontShow)]
        [string]
        $InternalName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ObjectGUID', 'GUID', 'ID', 'UID')]
        [string]
        $UUID,
        [Parameter(ParameterSetName = 'AllUsers')]
        [switch]
        $AllUsers,
        [Parameter(ParameterSetName = 'AllUsers')]
        [switch]
        $IncludeDetails
    )
    begin {
        $PSBoundParameters.Remove("CatchAll") |  Out-Null
        [string[]]$DirID = Get-DirectoryService @PSBoundParameters -UuidOnly
        $count = (Get-Variable -Name users -Scope 1 -ErrorAction SilentlyContinue).value.Count
        $currentValue = 0
    }
    process {
        If (0 -ne $count) {
            $currentValue += 1
            $percent = $( $currentValue / $count) * 100
            Write-Progress -Activity "Getting detailed user infomation" -Status "$currentValue out of $count" -PercentComplete $percent
        }
        IF ($AllUsers) {
            Write-LogMessage -type Warning -MSG 'All Users switch passed, getting all users'
            $result = Invoke-Rest -Uri "$IdentityURL/CDirectoryService/GetUsers" -Method POST -Headers $logonToken -ContentType 'application/json'
            IF (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
                Return
            }
            elseif (![string]::IsNullOrEmpty($result.Result.Exceptions.User)) {
                Write-LogMessage -type Error -MSG $result.Result.Exceptions.User
                Return
            }
            IF (0 -eq $result.Result.Results.Count) {
                Write-LogMessage -type Warning -MSG 'No user found'
                Return
            }
            Else {
                If ($IDOnly) {
                    Write-LogMessage -type Verbose -MSG 'Returning ID of users'
                    Return $result.Result.Results.Row.UUID
                }
                elseIf ($IncludeDetails) {
                    Write-LogMessage -type Verbose -MSG 'Returning detailed information about users'
                    [PSCustomObject[]]$users = $result.Result.Results.Row | Select-Object -Property UUID
                    $ReturnedUsers = $users | Get-IdentityUser -DirectoryServiceUuid $DirID
                    Return $ReturnedUsers
                } else {
                    Write-LogMessage -type Verbose -MSG 'Returning basic information about users'
                    [PSCustomObject[]]$users = $result.Result.Results.Row
                    Return $ReturnedUsers
                }
            }
        }
        [PSCustomObject[]]$userSearch = @()
        IF (![string]::IsNullOrEmpty($UUID)) {
            Write-LogMessage -type Verbose -MSG "User UUID provided, adding `"$UUID`" to user search paramters"
            $userSearch += [PSCustomObject]@{_ID = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $UUID; ignoreCase = 'true' } } }
        }
        IF (![string]::IsNullOrEmpty($Name)) {
            Write-LogMessage -type Verbose -MSG "User Name provided, adding `"$name`" to user search paramters"
            $userSearch += [PSCustomObject]@{SystemName = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $Name; ignoreCase = 'true' } } }
        }
        IF (![string]::IsNullOrEmpty($DisplayName)) {
            Write-LogMessage -type Verbose -MSG "User Display Name provided, adding `"$DisplayName`" to user search paramters"
            $userSearch += [PSCustomObject]@{DisplayName = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $DisplayName; ignoreCase = 'true' } } }
        }
        IF (![string]::IsNullOrEmpty($mail)) {
            Write-LogMessage -type Verbose -MSG "User Email provided, adding `"$mail`" to user search paramters"
            $userSearch += [PSCustomObject]@{Email = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $mail; ignoreCase = 'true' } } }
        }
        IF (![string]::IsNullOrEmpty($InternalName)) {
            Write-LogMessage -type Verbose -MSG "User Internal Name provided, adding `"$InternalName`" to user search paramters"
            $userSearch += [PSCustomObject]@{InternalName = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $InternalName; ignoreCase = 'true' } } }
        }
        elseif (0 -eq $userSearch.Count) {
            Write-LogMessage -type ErrorThrow -MSG 'No search paramters found'
        }
        $user = $userSearch
        $userquery = [PSCustomObject]@{
            'user' = "$($user|ConvertTo-Json -Depth 99 -Compress)"
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
    end {
        Write-Progress -Completed
    }
}