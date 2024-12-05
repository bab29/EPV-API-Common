<#
.SYNOPSIS
Retrieves identity user information from a specified identity URL.

.DESCRIPTION
The Get-IdentityUser function retrieves user information from an identity service. It supports various parameters to filter the search, including UUID, name, display name, email, and internal name. The function can return either detailed information or just the user IDs based on the provided switches.

.PARAMETER IdentityURL
The URL of the identity service to query.

.PARAMETER LogonToken
The logon token used for authentication with the identity service.

.PARAMETER IDOnly
A switch to return only the user IDs.

.PARAMETER DirectoryServiceUuid
The UUID(s) of the directory service(s) to query.

.PARAMETER directoryName
The name of the directory to query.

.PARAMETER directoryService
The directory service to query.

.PARAMETER name
The name of the user to search for.

.PARAMETER DisplayName
The display name of the user to search for.

.PARAMETER mail
The email of the user to search for.

.PARAMETER InternalName
The internal name of the user to search for.

.PARAMETER UUID
The UUID of the user to search for.

.PARAMETER AllUsers
A switch to retrieve all users from the directory service.

.PARAMETER IncludeDetails
A switch to include detailed information about the users.

.EXAMPLE
Get-IdentityUser -IdentityURL "https://identity.example.com" -LogonToken $token -UUID "1234-5678-90ab-cdef"

.EXAMPLE
Get-IdentityUser -IdentityURL "https://identity.example.com" -LogonToken $token -name "jdoe" -IDOnly

.NOTES
Author: Your Name
Date: Today's Date
#>

function Get-IdentityUser {
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
        [string]
        $name,
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
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        [string[]]$DirID = Get-DirectoryService @PSBoundParameters -UuidOnly
        $count = (Get-Variable -Name users -Scope 1 -ErrorAction SilentlyContinue).value.Count
        $currentValue = 0
    }
    process {
        if ($count -ne 0) {
            $currentValue += 1
            $percent = ($currentValue / $count) * 100
            Write-Progress -Activity "Getting detailed user information" -Status "$currentValue out of $count" -PercentComplete $percent
        }
        if ($AllUsers) {
            Write-LogMessage -type Warning -MSG 'All Users switch passed, getting all users'
            $result = Invoke-Rest -Uri "$IdentityURL/CDirectoryService/GetUsers" -Method POST -Headers $logonToken -ContentType 'application/json'
            if (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
                return
            }
            elseif (![string]::IsNullOrEmpty($result.Result.Exceptions.User)) {
                Write-LogMessage -type Error -MSG $result.Result.Exceptions.User
                return
            }
            if ($result.Result.Results.Count -eq 0) {
                Write-LogMessage -type Warning -MSG 'No user found'
                return
            }
            else {
                if ($IDOnly) {
                    Write-LogMessage -type Verbose -MSG 'Returning ID of users'
                    return $result.Result.Results.Row.UUID
                }
                elseif ($IncludeDetails) {
                    Write-LogMessage -type Verbose -MSG 'Returning detailed information about users'
                    [PSCustomObject[]]$users = $result.Result.Results.Row | Select-Object -Property UUID
                    $ReturnedUsers = $users | Get-IdentityUser -DirectoryServiceUuid $DirID
                    return $ReturnedUsers
                }
                else {
                    Write-LogMessage -type Verbose -MSG 'Returning basic information about users'
                    [PSCustomObject[]]$users = $result.Result.Results.Row
                    return $users
                }
            }
        }
        [PSCustomObject[]]$userSearch = @()
        if (![string]::IsNullOrEmpty($UUID)) {
            Write-LogMessage -type Verbose -MSG "User UUID provided, adding `"$UUID`" to user search parameters"
            $userSearch += [PSCustomObject]@{_ID = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $UUID; ignoreCase = 'true' } } }
        }
        if (![string]::IsNullOrEmpty($name)) {
            Write-LogMessage -type Verbose -MSG "User Name provided, adding `"$name`" to user search parameters"
            $userSearch += [PSCustomObject]@{SystemName = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $name; ignoreCase = 'true' } } }
        }
        if (![string]::IsNullOrEmpty($DisplayName)) {
            Write-LogMessage -type Verbose -MSG "User Display Name provided, adding `"$DisplayName`" to user search parameters"
            $userSearch += [PSCustomObject]@{DisplayName = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $DisplayName; ignoreCase = 'true' } } }
        }
        if (![string]::IsNullOrEmpty($mail)) {
            Write-LogMessage -type Verbose -MSG "User Email provided, adding `"$mail`" to user search parameters"
            $userSearch += [PSCustomObject]@{Email = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $mail; ignoreCase = 'true' } } }
        }
        if (![string]::IsNullOrEmpty($InternalName)) {
            Write-LogMessage -type Verbose -MSG "User Internal Name provided, adding `"$InternalName`" to user search parameters"
            $userSearch += [PSCustomObject]@{InternalName = [PSCustomObject]@{'_like' = [PSCustomObject]@{value = $InternalName; ignoreCase = 'true' } } }
        }
        elseif ($userSearch.Count -eq 0) {
            Write-LogMessage -type ErrorThrow -MSG 'No search parameters found'
        }
        $user = $userSearch
        $userquery = [PSCustomObject]@{
            'user' = "$($user | ConvertTo-Json -Depth 99 -Compress)"
        }
        $userquery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force
        try {
            Write-LogMessage -type Verbose -MSG 'Starting search for user'
            $result = Invoke-Rest -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $logonToken -ContentType 'application/json' -Body ($userquery | ConvertTo-Json -Depth 99)
            if (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
                return
            }
            elseif (![string]::IsNullOrEmpty($result.Result.Exceptions.User)) {
                Write-LogMessage -type Error -MSG $result.Result.Exceptions.User
                return
            }
            if ($result.Result.User.Results.Count -eq 0) {
                Write-LogMessage -type Warning -MSG 'No user found'
                return
            }
            else {
                if ($IDOnly) {
                    Write-LogMessage -type Verbose -MSG 'Returning ID of user'
                    return $result.Result.User.Results.Row.InternalName
                }
                else {
                    Write-LogMessage -type Verbose -MSG 'Returning all information about user'
                    return $result.Result.User.Results.Row
                }
            }
        }
        catch {
            Write-LogMessage -type Error -MSG "Error Code : $($_.Exception.Message)"
        }
    }
    end {
        Write-Progress -Completed
    }
}
