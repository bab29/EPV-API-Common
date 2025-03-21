Using Module .\Classes\Base.psm1
Using Module .\Classes\Safe.psm1
Using Module .\Classes\SafeMember.psm1
Using Module .\Classes\Account.psm1
#Region '.\Private\Get-CallerPreference.ps1' -1

function Get-CallerPreference {
  <#
.Synopsis
    Retrieves and sets caller preference variables.
  .DESCRIPTION
    The Get-CallerPreference function retrieves specific preference variables from the caller's session state and sets them in the current session state or a specified session state.
    It ensures that the preference variables such as ErrorActionPreference, VerbosePreference, and DebugPreference are correctly set based on the caller's context.
  .EXAMPLE
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    This example retrieves the caller preference variables from the current session state and sets them accordingly.
  .EXAMPLE
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $CustomSessionState
    This example retrieves the caller preference variables from the current session state and sets them in a custom session state.
  .INPUTS
    [System.Management.Automation.PSScriptCmdlet]
      The cmdlet from which to retrieve the caller preference variables.
    [System.Management.Automation.SessionState]
      The session state where the preference variables will be set.
  .OUTPUTS
    None
  .NOTES
    This function is useful for ensuring that preference variables are consistently set across different session states.
  .COMPONENT
    EPV-API-Common
  .ROLE
    Utility
  .FUNCTIONALITY
    Preference Management
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
    $Cmdlet,
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.SessionState]
    $SessionState
  )

  $vars = @{
    'ErrorView'             = $null
    'ErrorActionPreference' = 'ErrorAction'
    'VerbosePreference'     = 'Verbose'
    'DebugPreference'       = 'Debug'
  }

  foreach ($entry in $vars.GetEnumerator()) {
    if ([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) {
      $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
      if ($null -ne $variable) {
        if ($SessionState -eq $ExecutionContext.SessionState) {
          Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
        } else {
          $SessionState.PSVariable.Set($variable.Name, $variable.Value)
        }
      }
    }
  }
}
#EndRegion '.\Private\Get-CallerPreference.ps1' 60
#Region '.\Private\Get-OnPremHeader.ps1' -1

Function Get-OnPremHeader {
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
        )
}
#EndRegion '.\Private\Get-OnPremHeader.ps1' 28
#Region '.\Private\Invoke-Rest.ps1' -1

<#
.SYNOPSIS
    Invokes a REST API call with the specified parameters.

.DESCRIPTION
    The Invoke-Rest function is designed to make REST API calls using various HTTP methods such as GET, POST, DELETE, PATCH, and PUT.
    It supports custom headers, request bodies, and content types. The function also includes error handling and logging mechanisms.

.PARAMETER Command
    Specifies the HTTP method to use for the REST API call.
    Valid values are 'GET', 'POST', 'DELETE', 'PATCH', and 'PUT'. This parameter is mandatory.

.PARAMETER URI
    Specifies the URI of the REST API endpoint. This parameter is mandatory.

.PARAMETER Header
    Specifies the headers to include in the REST API call. This parameter is optional.

.PARAMETER Body
    Specifies the body content to include in the REST API call. This parameter is optional.

.PARAMETER ContentType
    Specifies the content type of the request body. The default value is 'application/json'. This parameter is optional.

.PARAMETER ErrAction
    Specifies the action to take if an error occurs.
    Valid values are 'Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', and 'Suspend'. The default value is 'Continue'. This parameter is optional.

.EXAMPLE
    Invoke-Rest -Command GET -URI "https://api.example.com/data" -Header @{Authorization = "Bearer token"}

    This example makes a GET request to the specified URI with an authorization header.

.EXAMPLE
    Invoke-Rest -Command POST -URI "https://api.example.com/data" -Body '{"name":"value"}' -ContentType "application/json"

    This example makes a POST request to the specified URI with a JSON body.

.NOTES
    This function includes extensive logging for debugging purposes. It logs the entry and exit points, as well as detailed information about the request and response.
#>

Function Invoke-Rest {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = "Function", Justification = 'Used in deep debugging')]
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
        Write-LogMessage -type Verbose -MSG 'Entering Invoke-Rest'
        $restResponse = ''

        try {
            Write-LogMessage -type Verbose -MSG "Invoke-RestMethod -Uri $URI -Method $Command -Header $($Header | ConvertTo-Json -Compress -Depth 9) -ContentType $ContentType -TimeoutSec 2700"

            if ([string]::IsNullOrEmpty($Body)) {
                $restResponse = Invoke-RestMethod -Uri $URI -Method $Command -Header $Header -ContentType $ContentType -TimeoutSec 2700 -ErrorAction $ErrAction
            }
            else {
                Write-LogMessage -type Verbose -MSG "Body Found: `n$Body"
                $restResponse = Invoke-RestMethod -Uri $URI -Method $Command -Body $Body -Header $Header -ContentType $ContentType -TimeoutSec 2700 -ErrorAction $ErrAction
            }
        }
        catch [System.Net.WebException] {
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCaught WebException"
            if ($ErrAction -match ('\bContinue\b|\bInquire\b|\bStop\b|\bSuspend\b')) {
                Write-LogMessage -type Error -MSG "Error Message: $PSItem"
                Write-LogMessage -type Error -MSG "Exception Message: $($PSItem.Exception.Message)"
                Write-LogMessage -type Error -MSG "Status Code: $($PSItem.Exception.Response.StatusCode.value__)"
                Write-LogMessage -type Error -MSG "Status Description: $($PSItem.Exception.Response.StatusDescription)"
                $restResponse = $null
                Throw
                Else {
                    Throw $PSItem
                }
            }
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCaught HttpResponseException"
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCommand:`t$Command`tURI:  $URI"
            If (-not [string]::IsNullOrEmpty($Body)) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tBody:`t $Body"
            }
            $Details = ($PSItem.ErrorDetails.Message | ConvertFrom-Json)
            If ('SFWS0007' -eq $Details.ErrorCode) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`t$($Details.ErrorMessage)"
                Throw $PSItem
            }
            elseif ('ITATS127E' -eq $Details.ErrorCode) {
                Write-LogMessage -type Error -MSG 'Was able to connect to the PVWA successfully, but the account was locked'
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`t$($Details.ErrorMessage)"
                Throw [System.Management.Automation.RuntimeException] 'Account Locked'
            }
            elseif ('PASWS013E' -eq $Details.ErrorCode) {
                Write-LogMessage -type Error -MSG "$($Details.ErrorMessage)" -Header -Footer
            }
            elseif ('SFWS0002' -eq $Details.ErrorCode) {
                Write-LogMessage -type Warning -MSG "$($Details.ErrorMessage)"
                Throw "$($Details.ErrorMessage)"
            }
            If ('SFWS0012' -eq $Details.ErrorCode) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`t$($Details.ErrorMessage)"
                Throw $PSItem
            }
            elseif (!($errorDetails.ErrorCode -in $global:SkipErrorCode)) {
                Write-LogMessage -type Error -MSG 'Was able to connect to the PVWA successfully, but the command resulted in an error'
                Write-LogMessage -type Error -MSG "Returned ErrorCode: $($errorDetails.ErrorCode)"
                Write-LogMessage -type Error -MSG "Returned ErrorMessage: $($errorDetails.ErrorMessage)"
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tExiting Invoke-Rest"
                Throw $PSItem
            }
            Else {
                Write-LogMessage -type Error -MSG "Error in running '$Command' on '$URI', $($PSItem.Exception)"
                Throw $(New-Object System.Exception ("Invoke-Rest: Error in running $Command on '$URI'", $PSItem.Exception))
            }
        }
        catch {
            Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tCaught Exception"
            If ($ErrAction -ne "SilentlyContinue") {
                Write-LogMessage -type Error -MSG "Error in running $Command on '$URI', $PSItem.Exception"
                Write-LogMessage -type Error -MSG "Error Message: $PSItem"
            }
            else {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tError in running $Command on '$URI', $PSItem.Exception"
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tError Message: $PSItem"
            }
            Throw $(New-Object System.Exception ("Error in running $Command on '$URI'", $PSItem.Exception))
        }

        if ($URI -match 'Password/Retrieve') {
            Write-LogMessage -type Verbose -MSG 'Invoke-Rest:`tInvoke-REST Response: ***********'
        }
        else {
            if ($global:SuperVerbose) {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST Response Type: $($restResponse.GetType().Name)"
                $type = $restResponse.GetType().Name
                if ('String' -ne $type) {
                    Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST ConvertTo-Json Response: $($restResponse | ConvertTo-Json -Depth 9 -Compress)"
                }
                else {
                    Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST Response: $restResponse"
                }
            }
            else {
                Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tInvoke-REST Response: $restResponse"
            }
        }
        Write-LogMessage -type Verbose -MSG "Invoke-Rest:`tExiting Invoke-Rest"
        return $restResponse
    }
}
#EndRegion '.\Private\Invoke-Rest.ps1' 175
#Region '.\Private\Invoke-RestNextLink.ps1' -1

<#
.SYNOPSIS
Invokes a REST API call and handles pagination if necessary.

.DESCRIPTION
The Invoke-RestNextLink function sends a REST API request using the specified HTTP method and URI.
It supports pagination by following the 'NextLink' property in the response. If pagination is disabled,
it returns only the initial set of results.

.PARAMETER Command
Specifies the HTTP method to use for the REST API call. Valid values are 'GET', 'POST', 'DELETE', 'PATCH', and 'PUT'.

.PARAMETER URI
Specifies the URI for the REST API call. This parameter is mandatory and cannot be null or empty.

.PARAMETER Header
Specifies the headers to include in the REST API call. This parameter is optional.

.PARAMETER ContentType
Specifies the content type for the REST API call. The default value is 'application/json'.

.PARAMETER ErrAction
Specifies the action to take if an error occurs during the REST API call. Valid values are 'Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', and 'Suspend'. The default value is 'Continue'.

.RETURNS
Returns an array of PSCustomObject containing the results of the REST API call.

.EXAMPLE
Invoke-RestNextLink -Command GET -URI "https://api.example.com/resource" -Header $header

This example sends a GET request to the specified URI with the provided headers and handles pagination if necessary.

.NOTES
This function uses the Invoke-Rest function to send the REST API request and handles pagination by following the 'NextLink' property in the response.
#>
Function Invoke-RestNextLink {
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
        [String]$ContentType = 'application/json',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Continue', 'Ignore', 'Inquire', 'SilentlyContinue', 'Stop', 'Suspend')]
        [String]$ErrAction = 'Continue'
    )

    $restResponse = Invoke-Rest -Uri $URI -Method $Command -Headers $Header -ContentType $ContentType -ErrorAction $ErrAction
    [PSCustomObject[]]$resultList = $restResponse.value

    if (-not [string]::IsNullOrEmpty($restResponse.NextLink)) {
        if ($DoNotPage) {
            Write-LogMessage -Type Verbose -MSG "A total of $($resultList.Count) results found, but paging is disabled. Returning only $($resultList.Count) results"
        } else {
            do {
                Write-LogMessage -Type Verbose -MSG "NextLink found, getting next page"
                $restResponse = Invoke-Rest -Uri "$PVWAURL/$($restResponse.NextLink)" -Method GET -Headers $logonToken -ContentType 'application/json'
                $resultList += $restResponse.value
            } until ([string]::IsNullOrEmpty($restResponse.NextLink))
        }
    } else {
        Write-LogMessage -Type Verbose -MSG "Found $($resultList.Count) results"
    }

    return $resultList
}
#EndRegion '.\Private\Invoke-RestNextLink.ps1' 80
#Region '.\Private\Load-Modules.ps1' -1

# Load the Base module
#Using Module .\Classes\Base.psm1

# Load the Safe module
#Using Module .\Classes\Safe.psm1

# Load the SafeMember module
#Using Module .\Classes\SafeMember.psm1

# Load the Account module
#Using Module .\Classes\Account.psm1
#EndRegion '.\Private\Load-Modules.ps1' 12
#Region '.\Public\Identity\Directory\Get-DirectoryService.ps1' -1

<#
.Synopsis
    Get Identity Directories
.DESCRIPTION
    Get Identity Directories
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
function Get-DirectoryService {
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
        [Alias('DirID', 'DirectoryUUID')]
        [String[]]
        $DirectoryServiceUuid,
        [Parameter(ValueFromPipeline)]
        [string]
        $directoryName,
        [Parameter(ValueFromPipeline)]
        [string]
        $directoryService,
        [switch]
        $UuidOnly
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        if ($DirectoryServiceUuid) {
            Write-LogMessage -type Verbose -MSG "Directory UUID Provided. Setting Search Directory to `"$DirectoryServiceUuid`""
            [PSCustomObject[]]$DirID = $DirectoryServiceUuid
        } elseif ($directoryName) {
            Write-LogMessage -type Verbose -MSG "Directory name provided. Searching for directory with the name of `"$directoryName`""
            $dirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json'
            if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories with the name of `"$directoryName`""
                if ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryName*" } | Select-Object -ExpandProperty directoryServiceUuid
                } else {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryName*" }
                }
            }
        } elseif ($directoryService) {
            Write-LogMessage -type Verbose -MSG "Directory service provided. Searching for directory with the name of `"$directoryService`""
            $dirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json'
            if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories with the service type of `"$directoryService`""
                if ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryService*" } | Select-Object -ExpandProperty directoryServiceUuid
                } else {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.DisplayName -like "*$directoryService*" }
                }
            }
        } else {
            Write-LogMessage -type Verbose -MSG 'No directory parameters passed. Gathering all directories, except federated'
            $dirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $logonToken -ContentType 'application/json'
            if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
                Write-LogMessage -type Verbose -MSG "Found $($dirResult.result.Count) directories"
                if ($UuidOnly) {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row | Select-Object -ExpandProperty directoryServiceUuid
                } else {
                    [PSCustomObject[]]$DirID = $dirResult.result.Results.Row
                }
            }
        }
        return $DirID
    }
}
#EndRegion '.\Public\Identity\Directory\Get-DirectoryService.ps1' 94
#Region '.\Public\Identity\Role\Add-IdentityRoleToUser.ps1' -1

<#
.SYNOPSIS
Adds a specified identity role to one or more users.

.DESCRIPTION
The Add-IdentityRoleToUser function assigns a specified role to one or more users by making a REST API call to update the role. It supports ShouldProcess for confirmation prompts and logs detailed messages about the operation.

.PARAMETER RoleName
The name of the role to be added to the users. This parameter is mandatory and accepts pipeline input.

.PARAMETER IdentityURL
The base URL of the identity service. This parameter is mandatory.

.PARAMETER LogonToken
The authentication token required to log on to the identity service. This parameter is mandatory.

.PARAMETER User
An array of user identifiers to which the role will be added. This parameter is mandatory and accepts pipeline input.

.EXAMPLE
PS> Add-IdentityRoleToUser -RoleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token -User "user1"

Adds the "Admin" role to the user "user1".

.EXAMPLE
PS> "user1", "user2" | Add-IdentityRoleToUser -RoleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token

Adds the "Admin" role to the users "user1" and "user2".

.NOTES
This function requires the Write-LogMessage and Invoke-Rest functions to be defined in the session.
#>
function Add-IdentityRoleToUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('role')]
        [ValidateNotNullOrEmpty()]
        [string]
        $RoleName,
        [Parameter(Mandatory)]
        [Alias('url')]
        [ValidateNotNullOrEmpty()]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        [ValidateNotNullOrEmpty()]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Users', 'Member')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $User
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -MSG "Adding `"$User`" to role `"$RoleName`""
        $rolesResult = Get-IdentityRole @PSBoundParameters -IDOnly

        if ($rolesResult.Count -eq 0) {
            Throw "Role `"$RoleName`" not found"
        }
        elseif ($rolesResult.Count -ge 2) {
            Throw "Multiple roles found, please enter a unique role name and try again"
        }
        else {
            $addUserToRole = [PSCustomObject]@{
                Users = [PSCustomObject]@{
                    Add = $User
                }
                Name  = $rolesResult
            }
            try {
                if ($PSCmdlet.ShouldProcess($User, 'Add-IdentityRoleToUser')) {
                    Write-LogMessage -type Verbose -MSG "Adding `"$RoleName`" to user `"$User`""
                    $result = Invoke-Rest -Uri "$IdentityURL/Roles/UpdateRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body $($addUserToRole | ConvertTo-Json -Depth 99)
                    if ($result.success) {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Info -MSG "Role `"$RoleName`" added to user `"$User`""
                        }
                        else {
                            Write-LogMessage -type Info -MSG "Role `"$RoleName`" added to all users"
                        }
                    }
                    else {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Error -MSG "Error adding `"$RoleName`" to user `"$User`": $($result.Message)"
                        }
                        else {
                            Write-LogMessage -type Error -MSG "Error adding `"$RoleName`" to users: $($result.Message)"
                        }
                    }
                }
                else {
                    Write-LogMessage -type Warning -MSG "Skipping addition of role `"$RoleName`" to user `"$User`" due to confirmation being denied"
                }
            }
            catch {
                Write-LogMessage -type Error -MSG "Error while trying to add users to `"$RoleName`": $_"
            }
        }
    }
}
#EndRegion '.\Public\Identity\Role\Add-IdentityRoleToUser.ps1' 109
#Region '.\Public\Identity\Role\Get-IdentityGroup.ps1' -1

<#
.SYNOPSIS
Retrieves identity group information from a specified identity URL.

.DESCRIPTION
The Get-IdentityGroup function retrieves information about identity groups from a specified identity URL.
It supports retrieving all groups or a specific group by name. The function can also return only the ID of the group if specified.

.PARAMETER IdentityURL
The URL of the identity service to query.

.PARAMETER LogonToken
The logon token used for authentication with the identity service.

.PARAMETER GroupName
The name of the group to retrieve information for. This parameter is mandatory when using the "GroupName" parameter set.

.PARAMETER IDOnly
A switch to specify if only the ID of the group should be returned.

.PARAMETER AllGroups
A switch to specify if all groups should be retrieved. This parameter is mandatory when using the "AllGroups" parameter set.

.EXAMPLE
Get-IdentityGroup -IdentityURL "https://identity.example.com" -LogonToken $token -GroupName "Admins"

This example retrieves information about the "Admins" group from the specified identity URL.

.EXAMPLE
Get-IdentityGroup -IdentityURL "https://identity.example.com" -LogonToken $token -AllGroups

This example retrieves information about all groups from the specified identity URL.

.NOTES
The function uses Invoke-Rest to query the identity service and requires appropriate permissions to access the service.
#>

function Get-IdentityGroup {
    [CmdletBinding(DefaultParameterSetName = "GroupName")]
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
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "GroupName")]
        [Alias('Group')]
        [string]
        $GroupName,
        [switch]
        $IDOnly,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "AllGroups")]
        [switch]
        $AllGroups
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        if ($AllGroups) {
            Write-LogMessage -type Verbose -Message "Attempting to locate all groups"
            $Groups = [PSCustomObject]@{
                '_or' = [PSCustomObject]@{
                    'DisplayName' = [PSCustomObject]@{
                        '_like' = ""
                    }
                },
                [PSCustomObject]@{
                    'SystemName' = [PSCustomObject]@{
                        '_like' = [PSCustomObject]@{
                            value      = ""
                            ignoreCase = 'true'
                        }
                    }
                }
            }
        }
        else {
            Write-LogMessage -type Verbose -Message "Attempting to locate Identity Group named `"$GroupName`""
            $Group = $GroupName.Trim()
            $Groups = [PSCustomObject]@{
                '_or' = [PSCustomObject]@{
                    'DisplayName' = [PSCustomObject]@{
                        '_like' = $Group
                    }
                },
                [PSCustomObject]@{
                    'SystemName' = [PSCustomObject]@{
                        '_like' = [PSCustomObject]@{
                            value      = $Group
                            ignoreCase = 'true'
                        }
                    }
                }
            }
        }

        $GroupQuery = [PSCustomObject]@{
            'group' = "$($Groups | ConvertTo-Json -Depth 99 -Compress)"
            'Args'  = [PSCustomObject]@{
                'PageNumber' = 1
                'PageSize'   = 100000
                'Limit'      = 100000
                'SortBy'     = ''
                'Caching'    = -1
            }
        }

        Write-LogMessage -type Verbose -Message "Gathering Directories"
        $DirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $LogonToken -ContentType 'application/json'

        if ($DirResult.Success -and $DirResult.result.Count -ne 0) {
            Write-LogMessage -type Verbose -Message "Located $($DirResult.result.Count) Directories"
            Write-LogMessage -type Verbose -Message "Directory results: $($DirResult.result.Results.Row | ConvertTo-Json -Depth 99)"
            [string[]]$DirID = $DirResult.result.Results.Row | Where-Object { $_.Service -eq 'ADProxy' } | Select-Object -ExpandProperty directoryServiceUuid
            $GroupQuery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force
        }

        Write-LogMessage -type Verbose -Message "Body set to : `"$($GroupQuery | ConvertTo-Json -Depth 99)`""
        $Result = Invoke-Rest -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($GroupQuery | ConvertTo-Json -Depth 99)
        Write-LogMessage -type Verbose -Message "Result set to : `"$($Result | ConvertTo-Json -Depth 99)`""

        if (!$Result.Success) {
            Write-LogMessage -type Error -Message $Result.Message
            return
        }

        if ($Result.Result.Groups.Results.FullCount -eq 0) {
            Write-LogMessage -type Warning -Message 'No Group found'
            return
        }
        else {
            if ($IDOnly) {
                Write-LogMessage -type Verbose -Message "Returning ID of Group `"$GroupName`""
                return $Result.Result.Group.Results.row.InternalName
            }
            else {
                Write-LogMessage -type Verbose -Message "Returning all information about Group `"$GroupName`""
                return $Result.Result.Group.Results.row
            }
        }
    }
}
#EndRegion '.\Public\Identity\Role\Get-IdentityGroup.ps1' 148
#Region '.\Public\Identity\Role\Get-IdentityRole.ps1' -1

<#
.SYNOPSIS
Retrieves identity roles from the specified identity URL.

.DESCRIPTION
The Get-IdentityRole function retrieves identity roles from a specified identity URL. It supports retrieving a specific role by name or all roles. The function can return either the full role information or just the role ID.

.PARAMETER IdentityURL
The URL of the identity service.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER roleName
The name of the role to retrieve. This parameter is mandatory when using the "RoleName" parameter set.

.PARAMETER IDOnly
A switch to indicate if only the role ID should be returned.

.PARAMETER AllRoles
A switch to indicate if all roles should be retrieved. This parameter is mandatory when using the "AllRoles" parameter set.

.EXAMPLE
Get-IdentityRole -IdentityURL "https://identity.example.com" -LogonToken $token -roleName "Admin"
Retrieves the role information for the role named "Admin".

.EXAMPLE
Get-IdentityRole -IdentityURL "https://identity.example.com" -LogonToken $token -AllRoles
Retrieves all roles from the identity service.

.NOTES
The function uses REST API calls to interact with the identity service.
#>

function Get-IdentityRole {
    [CmdletBinding(DefaultParameterSetName = "RoleName")]
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
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "roleName")]
        [Alias('role')]
        [string]
        $roleName,
        [switch]
        $IDOnly,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "AllRoles")]
        [switch]
        $AllRoles
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }

    Process {
        if ($AllRoles) {
            $query = [PSCustomObject]@{ script = "SELECT Role.Name, Role.ID FROM Role" }
            $result = Invoke-Rest -Uri "$IdentityURL/Redrock/Query" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($query | ConvertTo-Json -Depth 99)
            return $result.result.results.Row  |Select-Object -Property Name, ID
        }

        Write-LogMessage -type Verbose -MSG "Attempting to locate Identity Role named `"$roleName`""
        $roles = [PSCustomObject]@{
            '_or' = [PSCustomObject]@{
                '_ID' = [PSCustomObject]@{ '_like' = $roleName }
            },
            [PSCustomObject]@{
                'Name' = [PSCustomObject]@{
                    '_like' = [PSCustomObject]@{
                        value      = $roleName
                        ignoreCase = 'true'
                    }
                }
            }
        }

        $rolequery = [PSCustomObject]@{
            'roles' = ($roles | ConvertTo-Json -Depth 99 -Compress)
            'Args'  = [PSCustomObject]@{
                'PageNumber' = 1
                'PageSize'   = 100000
                'Limit'      = 100000
                'SortBy'     = ''
                'Caching'    = -1
            }
        }

        Write-LogMessage -type Verbose -MSG "Gathering Directories"
        $dirResult = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryServices" -Method Get -Headers $LogonToken -ContentType 'application/json'

        if ($dirResult.Success -and $dirResult.result.Count -ne 0) {
            Write-LogMessage -type Verbose -MSG "Located $($dirResult.result.Count) Directories"
            Write-LogMessage -type Verbose -MSG "Directory results: $($dirResult.result.Results.Row)"
            [string[]]$DirID = $dirResult.result.Results.Row | Where-Object { $_.Service -eq 'CDS' } | Select-Object -ExpandProperty directoryServiceUuid
            $rolequery | Add-Member -Type NoteProperty -Name 'directoryServices' -Value $DirID -Force
        }

        $result = Invoke-Rest -Uri "$IdentityURL/UserMgmt/DirectoryServiceQuery" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($rolequery | ConvertTo-Json -Depth 99)

        if (!$result.Success) {
            Write-LogMessage -type Error -MSG $result.Message
            return
        }

        if ($result.Result.roles.Results.Count -eq 0) {
            Write-LogMessage -type Warning -MSG 'No role found'
            return
        }
        else {
            if ($IDOnly) {
                Write-LogMessage -type Verbose -MSG "Returning ID of role `"$roleName`""
                return $result.Result.roles.Results.Row._ID
            }
            else {
                Write-LogMessage -type Verbose -MSG "Returning all information about role `"$roleName`""
                return $result.Result.roles.Results.Row
            }
        }
    }
}
#EndRegion '.\Public\Identity\Role\Get-IdentityRole.ps1' 128
#Region '.\Public\Identity\Role\Get-IdentityRoleInDir.ps1' -1

<#
.SYNOPSIS
Retrieves identity roles and rights from a specified directory.

.DESCRIPTION
The Get-IdentityRoleInDir function sends a POST request to the specified IdentityURL to retrieve roles and rights for a given directory. The function requires an identity URL, a logon token, and a directory identifier.

.PARAMETER IdentityURL
The URL of the identity service endpoint.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER Directory
The unique identifier of the directory service.

.EXAMPLE
PS> Get-IdentityRoleInDir -IdentityURL "https://example.com" -LogonToken $token -Directory "12345"
This example retrieves the roles and rights for the directory with the identifier "12345" from the specified identity service URL.

.NOTES
The function removes the CatchAll parameter from the bound parameters before processing the request.
#>
function Get-IdentityRoleInDir {
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('DirectoryServiceUuid', '_ID')]
        [string]
        $Directory
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        $result = Invoke-Rest -Uri "$IdentityURL/Core/GetDirectoryRolesAndRights?path=$Directory" -Method POST -Headers $LogonToken -ContentType 'application/json'
        return $result.result.Results.Row
    }
}
#EndRegion '.\Public\Identity\Role\Get-IdentityRoleInDir.ps1' 49
#Region '.\Public\Identity\Role\Get-IdentityRoleMember.ps1' -1

<#
.SYNOPSIS
Retrieves members of a specified identity role.

.DESCRIPTION
The Get-IdentityRoleMember function sends a POST request to the specified Identity URL to retrieve members of a role identified by its UUID. The function requires a logon token for authentication.

.PARAMETER IdentityURL
The base URL of the identity service.

.PARAMETER LogonToken
The authentication token required to access the identity service.

.PARAMETER UUID
The unique identifier of the role whose members are to be retrieved.

.EXAMPLE
PS> Get-IdentityRoleMember -IdentityURL "https://identity.example.com" -LogonToken $token -UUID "12345"

.NOTES
The function removes any additional parameters passed to it using the CatchAll parameter.
#>
function Get-IdentityRoleMember {
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
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('role', '_ID', "ID")]
        [string]
        $UUID
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    process {
        $result = Invoke-Rest -Uri "$IdentityURL/Roles/GetRoleMembers?name=$UUID" -Method POST -Headers $logonToken -ContentType 'application/json'
        If (-not [string]::IsNullOrEmpty($result.result.Results.Row)) {
            $result.result.Results.Row | Add-Member -MemberType NoteProperty -Name "RoleUUID" -Value $UUID
            Return $result.result.Results.Row
        }

    }
}
#EndRegion '.\Public\Identity\Role\Get-IdentityRoleMember.ps1' 52
#Region '.\Public\Identity\Role\New-IdentityRole.ps1' -1

<#
.SYNOPSIS
Creates a new identity role.

.DESCRIPTION
The `New-IdentityRole` function creates a new identity role with specified parameters such as role name, role type, users, roles, and groups. It sends a POST request to the specified Identity URL to store the role.

.PARAMETER IdentityURL
The URL of the identity service where the role will be created.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER roleName
The name of the role to be created.

.PARAMETER Description
A description of the role.

.PARAMETER RoleType
The type of the role. Valid values are 'PrincipalList', 'Script', and 'Everybody'. Default is 'PrincipalList'.

.PARAMETER Users
An array of users to be added to the role.

.PARAMETER Roles
An array of roles to be added to the role.

.PARAMETER Groups
An array of groups to be added to the role.

.EXAMPLE
PS> New-IdentityRole -IdentityURL "https://identity.example.com" -LogonToken $token -roleName "Admin" -Description "Administrator role" -RoleType "PrincipalList" -Users "user1", "user2"

Creates a new role named "Admin" with the specified users.

.NOTES
The function supports ShouldProcess for safety and confirmation prompts.
#>
function New-IdentityRole {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
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
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $roleName,
        [Alias('desc')]
        [string]
        $Description,
        [ValidateSet('PrincipalList', 'Script', 'Everybody')]
        [string]
        $RoleType = 'PrincipalList',
        [Alias('User')]
        [string[]]
        $Users,
        [Alias('Role')]
        [string[]]
        $Roles,
        [Alias('Group')]
        [string[]]
        $Groups
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -MSG "Creating new Role named `"$roleName`""
        $body = [PSCustomObject]@{
            Name     = $roleName
            RoleType = $RoleType
        }
        if ($Users) {
            Write-LogMessage -type Verbose -MSG "Adding users `"$Users`" to new Role named `"$roleName`""
            $body | Add-Member -MemberType NoteProperty -Name Users -Value $Users
        }
        if ($Roles) {
            Write-LogMessage -type Verbose -MSG "Adding roles `"$Roles`" to new Role named `"$roleName`""
            $body | Add-Member -MemberType NoteProperty -Name Roles -Value $Roles
        }
        if ($Groups) {
            Write-LogMessage -type Verbose -MSG "Adding groups `"$Groups`" to new Role named `"$roleName`""
            $body | Add-Member -MemberType NoteProperty -Name Groups -Value $Groups
        }
        if ($PSCmdlet.ShouldProcess($roleName, 'New-IdentityRole')) {
            Write-LogMessage -type Verbose -MSG "Creating role named `"$roleName`""
            $result = Invoke-Rest -Uri "$IdentityURL/Roles/StoreRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99)
            if (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
                return
            }
            else {
                Write-LogMessage -type Info -MSG "New Role named `"$roleName`" created"
                return $result.Result._RowKey
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping addition of role `"$roleName`" due to confirmation being denied"
        }
    }
}
#EndRegion '.\Public\Identity\Role\New-IdentityRole.ps1' 112
#Region '.\Public\Identity\Role\Remove-IdentityRole.ps1' -1

<#
.SYNOPSIS
Removes an identity role from the system.

.DESCRIPTION
The Remove-IdentityRole function removes a specified identity role from the system.
It supports confirmation prompts and can be forced to bypass confirmation.
The function logs messages at various stages of execution.

.PARAMETER Force
A switch to force the removal without confirmation.

.PARAMETER IdentityURL
The URL of the identity service.

.PARAMETER LogonToken
The logon token for authentication.

.PARAMETER Role
The name of the role to be removed.

.EXAMPLE
Remove-IdentityRole -IdentityURL "https://example.com" -LogonToken $token -Role "Admin"

This command removes the "Admin" role from the identity service at "https://example.com".

.EXAMPLE
Remove-IdentityRole -IdentityURL "https://example.com" -LogonToken $token -Role "Admin" -Force

This command forcefully removes the "Admin" role from the identity service at "https://example.com" without confirmation.

.NOTES
The function logs messages at various stages of execution, including warnings and errors.
#>

function Remove-IdentityRole {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]
        $Force,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]
        $Role
    )
    begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
    }
    process {
        Write-LogMessage -type Verbose -MSG "Removing role named `"$Role`""
        try {
            $RoleID = Get-IdentityRole -LogonToken $LogonToken -roleName "$Role" -IdentityURL $IdentityURL -IDOnly
            if ([string]::IsNullOrEmpty($RoleID)) {
                Write-LogMessage -type Warning -MSG "Role named `"$Role`" not found"
                return
            }
        }
        catch {
            Write-LogMessage -type Error -MSG $_
            return
        }
        $body = [PSCustomObject]@{ Name = $RoleID }
        if ($PSCmdlet.ShouldProcess($Role, 'Remove-IdentityRole')) {
            $result = Invoke-Rest -Uri "$IdentityURL/SaasManage/DeleteRole/" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99)
            if (!$result.Success) {
                Write-LogMessage -type Error -MSG $result.Message
            }
            else {
                Write-LogMessage -type Warning -MSG "Role named `"$Role`" successfully deleted"
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping removal of role `"$Role`" due to confirmation being denied"
        }
    }
}
#EndRegion '.\Public\Identity\Role\Remove-IdentityRole.ps1' 89
#Region '.\Public\Identity\Role\Remove-IdentityRoleFromUser.ps1' -1

<#
.SYNOPSIS
Removes a specified role from one or more users.

.DESCRIPTION
The Remove-IdentityRoleFromUser function removes a specified role from one or more users in an identity management system.
It supports pipeline input and can be forced to bypass confirmation prompts.

.PARAMETER roleName
The name of the role to be removed from the users.

.PARAMETER IdentityURL
The URL of the identity management system.

.PARAMETER LogonToken
The authentication token required to log on to the identity management system.

.PARAMETER User
An array of users from whom the role will be removed.

.PARAMETER Force
A switch to bypass confirmation prompts.

.INPUTS
System.String
System.String[]

.OUTPUTS
None

.EXAMPLE
PS> Remove-IdentityRoleFromUser -roleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token -User "user1"

Removes the "Admin" role from "user1".

.EXAMPLE
PS> "user1", "user2" | Remove-IdentityRoleFromUser -roleName "Admin" -IdentityURL "https://identity.example.com" -LogonToken $token

Removes the "Admin" role from "user1" and "user2".

.NOTES
This function requires the Write-LogMessage and Get-IdentityRole functions to be defined in the session.
#>

function Remove-IdentityRoleFromUser {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('role')]
        [string]
        $roleName,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Users')]
        [string[]]
        $User
    )
    begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        Write-LogMessage -type Verbose -MSG "Starting removal of users from role named `"$roleName`""
        $rolesResult = Get-IdentityRole @PSBoundParameters -IDOnly
        if ($rolesResult.Count -eq 0) {
            Write-LogMessage -type Error -MSG 'No roles Found'
            return
        }
        elseif ($rolesResult.Count -ge 2) {
            Write-LogMessage -type Error -MSG 'Multiple roles found, please enter a unique role name and try again'
            return
        }
    }
    process {
        foreach ($user in $User) {
            if ($PSCmdlet.ShouldProcess($user, "Remove-IdentityRoleFromUser $roleName")) {
                $removeUserFromRole = [PSCustomObject]@{
                    Users = [PSCustomObject]@{
                        Delete = $User
                    }
                    Name  = $($rolesResult)
                }
                try {
                    $result = Invoke-Rest -Uri "$IdentityURL/Roles/UpdateRole" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($removeUserFromRole | ConvertTo-Json -Depth 99)
                    if ($result.success) {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Info -MSG "Role `"$roleName`" removed from user `"$user`""
                        }
                        else {
                            Write-LogMessage -type Info -MSG "Role `"$roleName`" removed from all users"
                        }
                    }
                    else {
                        if ($User.Count -eq 1) {
                            Write-LogMessage -type Error -MSG "Error removing `"$roleName`" from user `"$user`": $($result.Message)"
                        }
                        else {
                            Write-LogMessage -type Error -MSG "Error removing `"$roleName`" from users: $($result.Message)"
                        }
                    }
                }
                catch {
                    Write-LogMessage -type Error -MSG "Error while trying to remove users from `"$roleName`": $_"
                }
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of user $user from role `"$roleName`" due to confirmation being denied"
            }
        }
    }
}
#EndRegion '.\Public\Identity\Role\Remove-IdentityRoleFromUser.ps1' 125
#Region '.\Public\Identity\User\Get-IdentityUser.ps1' -1

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
#EndRegion '.\Public\Identity\User\Get-IdentityUser.ps1' 215
#Region '.\Public\Identity\User\Remove-IdentityUser.ps1' -1

<#
.SYNOPSIS
Removes identity users from the system.

.DESCRIPTION
The Remove-IdentityUser function removes identity users from the system based on the provided parameters.
It supports confirmation prompts and can process input from the pipeline.

.PARAMETER Force
A switch to force the removal without confirmation.

.PARAMETER IdentityURL
The URL of the identity service.

.PARAMETER LogonToken
The logon token for authentication.

.PARAMETER User
The username of the identity user to be removed. This parameter can be provided from the pipeline by property name.

.PARAMETER mail
The email of the identity user to be removed. This parameter can be provided from the pipeline by property name.

.EXAMPLE
Remove-IdentityUser -IdentityURL "https://identity.example.com" -LogonToken $token -User "jdoe"

.EXAMPLE
Remove-IdentityUser -IdentityURL "https://identity.example.com" -LogonToken $token -mail "jdoe@example.com"

.NOTES
This function requires the Write-LogMessage and Invoke-Rest functions to be defined elsewhere in the script or module.
#>

function Remove-IdentityUser {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url')]
        [string]
        $IdentityURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $User,
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('email')]
        [string]
        $mail
    )

    begin {
        if ($Force) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        $userList = @()
        $userNames = @()
    }

    process {
        $userID = Get-IdentityUser @PSBoundParameters
        if ([string]::IsNullOrEmpty($userID)) {
            if ([string]::IsNullOrEmpty($User) -and [string]::IsNullOrEmpty($mail)) {
                Write-LogMessage -type Warning -MSG 'Username or mail not provided'
                return
            }
            elseif (![string]::IsNullOrEmpty($User)) {
                Write-LogMessage -type Warning -MSG "User `"$User`" not found"
                return
            }
            elseif (![string]::IsNullOrEmpty($mail)) {
                Write-LogMessage -type Warning -MSG "Mail `"$mail`" not found"
                return
            }
            else {
                Write-LogMessage -type Warning -MSG "User `"$User`" or mail `"$mail`" not found"
                return
            }
        }

        Write-LogMessage -type Info -MSG "A total of $($userID.Count) user accounts found"
        $userID | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.SystemName, 'Remove-IdentityUser')) {
                $userNames += [string]$_.SystemName
                $userList += [string]$_.InternalName
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of Identity User `"$User`" due to confirmation being denied"
            }
        }
    }

    end {
        try {
            if ($userList.Count -eq 0) {
                Write-LogMessage -type Warning -MSG 'No accounts found to delete'
                return
            }

            $UserJson = [pscustomobject]@{ Users = $userList }
            $result = Invoke-Rest -Uri "$IdentityURL/UserMgmt/RemoveUsers" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($UserJson | ConvertTo-Json -Depth 99)

            if ($result.success) {
                if ($result.Result.Exceptions.User.Count -ne 0) {
                    Write-LogMessage -type Error -MSG 'Users failed to remove, no logs given'
                }
                else {
                    Write-LogMessage -type Info -MSG "The following Users removed successfully:`n$userNames"
                }
            }
        }
        catch {
            Write-LogMessage -type Error -MSG "Error removing users:`n$_"
        }
    }
}
#EndRegion '.\Public\Identity\User\Remove-IdentityUser.ps1' 123
#Region '.\Public\PAS\Account\AccountGroups\Add-AccountGroup.ps1' -1

#TODO
#EndRegion '.\Public\PAS\Account\AccountGroups\Add-AccountGroup.ps1' 2
#Region '.\Public\PAS\Account\AccountGroups\Add-AccountGroupMember.ps1' -1

#TODO
#EndRegion '.\Public\PAS\Account\AccountGroups\Add-AccountGroupMember.ps1' 2
#Region '.\Public\PAS\Account\AccountGroups\Get-AccountGroup.ps1' -1

#TODO
#EndRegion '.\Public\PAS\Account\AccountGroups\Get-AccountGroup.ps1' 2
#Region '.\Public\PAS\Account\AccountGroups\Get-AccountGroupMember.ps1' -1

#TODO
#EndRegion '.\Public\PAS\Account\AccountGroups\Get-AccountGroupMember.ps1' 2
#Region '.\Public\PAS\Account\AccountGroups\Remove-AccountGroup.ps1' -1

#TODO
#EndRegion '.\Public\PAS\Account\AccountGroups\Remove-AccountGroup.ps1' 2
#Region '.\Public\PAS\Account\Add-Account.ps1' -1



<#
.SYNOPSIS
Adds account in the PVWA system.

.DESCRIPTION
The Add-Account function connects to the PVWA API to add or update an account.
It requires the PVWA URL and a logon token for authentication. The function
supports ShouldProcess for confirmation prompts.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The logon token used for authentication with the PVWA API.

.EXAMPLE
Add-Account -PVWAURL "https://pvwa.example.com" -LogonToken "your-logon-token"

.NOTES
This function is part of the EPV-API-Common module and is used to manage accounts
in the PVWA system. The function currently has a TODO to complete the account
update process.

#>
function Add-Account {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL", SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,

        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LogonToken

    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountUrl = "$BaseURL/Accounts/?"
        $AccountIDURL = "$BaseURL/Accounts/{0}/?"
    }

    Process {

        if ($PSCmdlet.ShouldProcess($AccountID, 'Set-Account')) {
            Write-LogMessage -type Verbose -MSG "Getting AccountID `"$AccountID`""
            $Account = Get-Account -PVWAURL $PVWAURL -LogonToken $LogonToken -AccountID $AccountID
            #TODO Complete function so accounts get updated
            Write-LogMessage -type Verbose -MSG "Set account `"$safeName`" successfully"
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of AccountID `"$AccountID`" due to confirmation being denied"
        }

    }
}
#EndRegion '.\Public\PAS\Account\Add-Account.ps1' 64
#Region '.\Public\PAS\Account\Get-Account.ps1' -1

<#
.SYNOPSIS
Retrieves account information from the PVWA API.

.DESCRIPTION
The Get-Account function retrieves account information from the PVWA API based on various parameters such as AccountID, Search, Filter, and SavedFilter. It supports multiple parameter sets to allow for flexible querying.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The authentication token used for API requests.

.PARAMETER AccountID
The ID of the account to retrieve.

.PARAMETER AccountLink
Switch to include account links in the response.

.PARAMETER AccountLinkObject
Switch to include account link objects in the response.

.PARAMETER AllAccounts
Switch to retrieve all accounts.

.PARAMETER Search
Search term to filter accounts.

.PARAMETER SearchType
Type of search to perform.

.PARAMETER Filter
Filter to apply to the account query.

.PARAMETER SavedFilter
Predefined filter to apply to the account query. Valid values are:
- Regular
- Recently
- New
- Link
- Deleted
- PolicyFailures
- AccessedByUsers
- ModifiedByUsers
- ModifiedByCPM
- DisabledPasswordByUser
- DisabledPasswordByCPM
- ScheduledForChange
- ScheduledForVerify
- ScheduledForReconcile
- SuccessfullyReconciled
- FailedChange
- FailedVerify
- FailedReconcile
- LockedOrNew
- Locked

.PARAMETER Offset
Offset for pagination.

.PARAMETER Limit
Limit for pagination.

.PARAMETER DoNotPage
Switch to disable pagination.

.PARAMETER Sort
Sort order for the results. Valid values are "asc" and "desc".

.EXAMPLE
Get-Account -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12345"

.EXAMPLE
Get-Account -PVWAURL "https://pvwa.example.com" -LogonToken $token -Search "admin" -SearchType "contains"

.NOTES
This function requires the PVWA URL and a valid logon token to authenticate API requests.

#>

function Get-Account {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL")]
    param (
        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory)]
        $LogonToken,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [string]$AccountID,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [switch]$AccountLink,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [switch]$AccountLinkObject,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [switch]$AllAccounts,

        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]$Search,

        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]$SearchType,

        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'filter', ValueFromPipelineByPropertyName)]
        [string]$Filter,

        [Parameter(ParameterSetName = 'savedfilter', ValueFromPipelineByPropertyName)]
        [string]
        [ValidateSet("Regular", "Recently", "New", "Link", "Deleted", "PolicyFailures",
            "AccessedByUsers", "ModifiedByUsers", "ModifiedByCPM", "DisabledPasswordByUser",
            "DisabledPasswordByCPM", "ScheduledForChange", "ScheduledForVerify",
            "ScheduledForReconcile", "SuccessfullyReconciled", "FailedChange",
            "FailedVerify", "FailedReconcile", "LockedOrNew", "Locked"
        )]
        $SavedFilter,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]$Offset = $null,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]$Limit,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [switch]$DoNotPage,

        [Parameter(ParameterSetName = 'AllAccounts')]
        [Parameter(ParameterSetName = 'filter')]
        [Parameter(ParameterSetName = 'savedfilter')]
        [Parameter(ParameterSetName = 'Search')]
        [AllowEmptyString]
        [ValidateSet("asc", "desc")]
        $Sort
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountUrl = "$BaseURL/Accounts/?"
        $AccountIDURL = "$BaseURL/Accounts/{0}/?"
    }

    Process {
        $AccountIDExists = -not [string]::IsNullOrEmpty($AccountID)
        $SavedFilterExists = -not [string]::IsNullOrEmpty($SavedFilter)
        $SearchExists = -not [string]::IsNullOrEmpty($Search)
        $FilterExists = -not [string]::IsNullOrEmpty($Filter)

        if ($AccountIDExists) {
            [account]$Account = Get-AccountViaID
            If ($AccountLink -or $AccountLinkObject) {
                $Account.LinkedAccounts = Get-AccountLink -AccountID $AccountID -accountObject:$AccountLinkObject
            }
            Return $Account
        }
        else {
            if (-not ($AccountIDExists -or $FilterExists -or $SavedFilterExists -or $SearchExists)) {
                Write-LogMessage -type Verbose -MSG "No Account ID, Filter, SavedFilter, or Search provided, returning all accounts"
            }
            Get-AccountViaQuery
        }
    }
}

function Get-AccountViaID {
    $URL = $AccountIDURL -f $AccountID
    Write-LogMessage -type Verbose -MSG "Getting account with ID of `"$AccountID`""
    $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $LogonToken -ContentType 'application/json'
    return [account]$restResponse
}

function Get-AccountViaQuery {
    Write-LogMessage -type Verbose -MSG "Getting list of accounts"
    $URL = $AccountUrl
    Add-BaseQueryParameter -URL ([ref]$URL)
    Add-AccountQueryParameter -URL ([ref]$URL)
    [Account[]]$resultList = Invoke-RestNextLink -Uri $URL -Method GET -Headers $LogonToken -ContentType 'application/json'
    return $resultList
}

function Add-AccountQueryParameter {
    param (
        [ref]$URL
    )
    Write-LogMessage -type Verbose -MSG "Adding Query Parameters"
    if (-not [string]::IsNullOrEmpty($Search)) {
        $URL.Value += "&search=$Search"
        Write-LogMessage -type Verbose -MSG "Applying a search of `"$Search`""
    }
    if (-not [string]::IsNullOrEmpty($SearchType)) {
        $URL.Value += "&searchType=$SearchType"
        Write-LogMessage -type Verbose -MSG "Applying a search type of `"$SearchType`""
    }
    if (-not [string]::IsNullOrEmpty($SavedFilter)) {
        $URL.Value += "&savedfilter=$SavedFilter"
        Write-LogMessage -type Verbose -MSG "Applying a savedfilter of `"$SavedFilter`""
    }
    if (-not [string]::IsNullOrEmpty($Filter)) {
        $URL.Value += "&filter=$Filter"
        Write-LogMessage -type Verbose -MSG "Applying a filter of `"$Filter`""
    }
    Write-LogMessage -type Verbose -MSG "New URL: $URL"
}
#EndRegion '.\Public\PAS\Account\Get-Account.ps1' 219
#Region '.\Public\PAS\Account\Get-AccountLink.ps1' -1

<#
.SYNOPSIS
Retrieves linked accounts for a specified account from the PVWA API.

.DESCRIPTION
The Get-AccountLink function retrieves linked accounts for a specified account ID from the PVWA API. It supports retrieving the linked accounts as account objects if the -accountObject switch is specified.

.PARAMETER PVWAURL
The base URL of the PVWA API. This parameter is mandatory.

.PARAMETER LogonToken
The authentication token required to access the PVWA API. This parameter is mandatory.

.PARAMETER AccountID
The ID of the account for which linked accounts are to be retrieved. This parameter is mandatory when using the 'AccountID' parameter set.

.PARAMETER accountObject
A switch parameter that, when specified, retrieves the linked accounts as account objects.

.EXAMPLE
PS> Get-AccountLink -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12_45"

Retrieves the linked accounts for the account with ID "12_45".

.EXAMPLE
PS> Get-AccountLink -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12345" -accountObject

Retrieves the linked accounts for the account with ID "12345" and returns them as account objects.

.NOTES
This function requires the Write-LogMessage and Invoke-Rest functions to be defined in the session.
#>
function Get-AccountLink {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL")]
    param (
        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory)]
        $LogonToken,

        [Parameter(ParameterSetName = 'AccountID', ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias("id")]
        [string]$AccountID,

        [Parameter()]
        [switch]$accountObject
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountIDLink = "$BaseURL/ExtendedAccounts/{0}/LinkedAccounts"
    }

    Process {
        $URL = $AccountIDLink -f $AccountID
        Write-LogMessage -type Verbose -MSG "Getting account links with ID of `"$AccountID`""
        $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $LogonToken -ContentType 'application/json'
        If ($accountObject) {
            $restResponse.LinkedAccounts | ForEach-Object {
                IF (-not [string]::IsNullOrEmpty($PSitem.AccountID)) {
                    $PSItem | Add-Member -Name "AccountObject" -MemberType NoteProperty -Value $($PSitem | Get-Account)
                }
            }
        }
        Return $restResponse
    }
}
#EndRegion '.\Public\PAS\Account\Get-AccountLink.ps1' 72
#Region '.\Public\PAS\Account\Set-Account.ps1' -1

#TODO Run Co-Pilot doc generator
Function Set-Account {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL", SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,

        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LogonToken,

        [Alias('ID')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$AccountID,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Property,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Value

    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountUrl = "$BaseURL/Accounts/?"
        $AccountIDURL = "$BaseURL/Accounts/{0}/?"
    }

    Process {

        if ($PSCmdlet.ShouldProcess($AccountID, 'Set-Account')) {
            Write-LogMessage -type Verbose -MSG "Getting AccountID `"$AccountID`""
            $Account = Get-Account -PVWAURL $PVWAURL -LogonToken $LogonToken -AccountID $AccountID
            #TODO Complete function so accounts get updated
            Write-LogMessage -type Verbose -MSG "Set account `"$safeName`" successfully"
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of AccountID `"$AccountID`" due to confirmation being denied"
        }

    }
}
#EndRegion '.\Public\PAS\Account\Set-Account.ps1' 49
#Region '.\Public\PAS\Account\Set-AccountLink.ps1' -1

<#
.SYNOPSIS
Sets the account link for a specified account in the PVWA.

.DESCRIPTION
The Set-Account function links an account to an extra password in the PVWA. It supports multiple parameter sets to specify the extra password either by its type or by its index.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The authentication token for the PVWA.

.PARAMETER AccountID
The ID of the account to link.

.PARAMETER extraPass
The type of extra password to link (Logon, Enable, Reconcile).

.PARAMETER extraPassIndex
The index of the extra password to link.

.PARAMETER extraPassSafe
The safe where the extra password is stored.

.PARAMETER extraPassObject
The name of the extra password object.

.PARAMETER extraPassFolder
The folder where the extra password object is stored. Defaults to "Root".

.EXAMPLE
Set-Account -PVWAURL "https://pvwa.example.com" -LogonToken $token -AccountID "12345" -extraPass Logon -extraPassSafe "Safe1" -extraPassObject "Object1"

.LINK
https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/WebServices/Implementing%20the%20REST%20API.htm
#>

enum extraPass {
    Logon       = 1
    Enable      = 2
    Reconcile   = 3
}

function Set-Account {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL", SupportsShouldProcess = $true)]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,

        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LogonToken,

        [Alias('ID')]
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$AccountID,

        [Parameter(ParameterSetName = 'extraPass',Mandatory,ValueFromPipelineByPropertyName)]
        [extraPass]$extraPass,

        [Parameter(ParameterSetName = 'extraPasswordIndex',Mandatory,ValueFromPipelineByPropertyName)]
        [int]$extraPassIndex,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$extraPassSafe,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [string]$extraPassObject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$extraPassFolder = "Root"
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $AccountIDLink = "$BaseURL/Accounts/{0}/LinkAccount/"
    }

    Process {

        if ($PSCmdlet.ShouldProcess($AccountID, 'Set-AccountLink')) {

            $extraPassBody = @{
                safe = $extraPassSafe
                extraPasswordIndex =  $(if (-not [string]::IsNullOrEmpty($extraPass)) {$extraPass} else {$extraPassIndex})
                name =  $extraPassObject
                folder = $extraPassFolder
                }

            $URL = $AccountIDLink -f $AccountID
            $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $LogonToken -Body $extraPassBody  -ContentType 'application/json'
            Write-LogMessage -type Verbose -MSG "Set account `"$safeName`" successfully"
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of AccountID `"$AccountID`" due to confirmation being denied"
        }

    }
}
#EndRegion '.\Public\PAS\Account\Set-AccountLink.ps1' 106
#Region '.\Public\PAS\Safe\Export-Safe.ps1' -1

<#
.SYNOPSIS
Exports information about safes to a CSV file.

.DESCRIPTION
The Export-Safe function exports details about safes to a specified CSV file. It includes options to force overwrite the file, include account details, and include additional safe details. The function can also exclude system safes from the export.

.PARAMETER CSVPath
The path to the CSV file where the safe information will be exported. Default is ".\SafeExport.csv".

.PARAMETER Force
If specified, forces the overwrite of the existing CSV file.

.PARAMETER Safe
The safe object to be exported. This parameter is mandatory and accepts input from the pipeline.

.PARAMETER IncludeAccounts
If specified, includes account details in the export.

.PARAMETER IncludeDetails
If specified, includes additional details about the safe in the export.

.PARAMETER includeSystemSafes
If specified, includes system safes in the export. This parameter is hidden from the user.

.PARAMETER CPMUser
An array of CPM user names. This parameter is hidden from the user.

.EXAMPLE
Export-Safe -CSVPath "C:\Exports\SafeExport.csv" -Force -Safe $safe -IncludeAccounts -IncludeDetails

This example exports the details of the specified safe to "C:\Exports\SafeExport.csv", including account details and additional safe details, and forces the overwrite of the existing file.

.NOTES
The function logs messages at various stages of execution and handles errors gracefully. It exits with code 80 if the CSV file already exists and the Force switch is not specified.

#>

function Export-Safe {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $CSVPath = ".\SafeExport.csv",
        [switch] $Force,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Safe] $Safe,
        [switch] $IncludeAccounts,
        [switch] $IncludeDetails,
        [Parameter(DontShow)]
        [switch] $includeSystemSafes,
        [Parameter(DontShow)]
        [string[]] $CPMUser
    )
    begin {
        [String[]]$SafesToRemove = @(
            'System', 'Pictures', 'VaultInternal', 'Notification Engine', 'SharedAuth_Internal', 'PVWAUserPrefs',
            'PVWAConfig', 'PVWAReports', 'PVWATaskDefinitions', 'PVWAPrivateUserPrefs', 'PVWAPublicData', 'PVWATicketingSystem',
            'AccountsFeed', 'PSM', 'xRay', 'PIMSuRecordings', 'xRay_Config', 'AccountsFeedADAccounts', 'AccountsFeedDiscoveryLogs',
            'PSMSessions', 'PSMLiveSessions', 'PSMUniversalConnectors', 'PSMNotifications', 'PSMUnmanagedSessionAccounts',
            'PSMRecordings', 'PSMPADBridgeConf', 'PSMPADBUserProfile', 'PSMPADBridgeCustom', 'PSMPConf', 'PSMPLiveSessions',
            'AppProviderConf', 'PasswordManagerTemp', 'PasswordManager_Pending', 'PasswordManagerShared', 'SCIM Config', 'TelemetryConfig'
        )
        [string[]]$cpmSafes = @()
        $CPMUser | ForEach-Object {
            $cpmSafes += "$($_)"
            $cpmSafes += "$($_)_Accounts"
            $cpmSafes += "$($_)_ADInternal"
            $cpmSafes += "$($_)_Info"
            $cpmSafes += "$($_)_workspace"
        }
        $SafesToRemove += $cpmSafes
        $SafeCount = 0
        if (Test-Path $CSVPath) {
            try {
                Write-LogMessage -type Debug -MSG "The file '$CSVPath' already exists. Checking for Force switch"
                if ($Force) {
                    Remove-Item $CSVPath
                    Write-LogMessage -type Debug -MSG "The file '$CSVPath' was removed."
                } else {
                    Write-LogMessage -type Debug -MSG "The file '$CSVPath' already exists and the switch 'Force' was not passed."
                    Write-LogMessage -type Error -MSG "The file '$CSVPath' already exists."
                }
            } catch {
                Write-LogMessage -type ErrorThrow -MSG "Error while trying to remove '$CSVPath'"
            }
        }
    }
    process {
        try {
            if (-not $includeSystemSafes) {
                if ($safe.SafeName -in $SafesToRemove) {
                    Write-LogMessage -type Debug -MSG "Safe '$($Safe.SafeName)' is a system safe, skipping"
                    return
                }
            }
            Write-LogMessage -type Verbose -MSG "Working with safe '$($Safe.Safename)'"
            $item = [pscustomobject]@{
                "Safe Name"        = $Safe.Safename
                "Description"      = $Safe.Description
                "Managing CPM"     = $Safe.managingCPM
                "Retention Policy" = $(if ([string]::IsNullOrEmpty($Safe.numberOfVersionsRetention)) { "$($Safe.numberOfDaysRetention) days" } else { "$($Safe.numberOfVersionsRetention) versions" })
                "Creation Date"    = ([datetime]'1/1/1970').ToLocalTime().AddSeconds($Safe.creationTime)
                "Last Modified"    = ([datetime]'1/1/1970').ToLocalTime().AddMicroseconds($Safe.lastModificationTime)
            }
            if ($IncludeDetails) {
                Write-LogMessage -type Debug -MSG "Including Details"
                $item | Add-Member -MemberType NoteProperty -Name "OLAC Enabled" -Value $safe.OLAC
                $item | Add-Member -MemberType NoteProperty -Name "Auto Purge Enabled" -Value $safe.autoPurgeEnabled
                $item | Add-Member -MemberType NoteProperty -Name "Safe ID" -Value $safe.safeNumber
                $item | Add-Member -MemberType NoteProperty -Name "Safe URL" -Value $safe.safeUrlId
                $item | Add-Member -MemberType NoteProperty -Name "Creator Name" -Value $Safe.Creator.Name
                $item | Add-Member -MemberType NoteProperty -Name "Creator ID" -Value $Safe.Creator.id
                $item | Add-Member -MemberType NoteProperty -Name "Location" -Value $safe.Location
                $item | Add-Member -MemberType NoteProperty -Name "Membership Expired" -Value $safe.isExpiredMember
            }
            if ($IncludeAccounts) {
                Write-LogMessage -type Debug -MSG "Including Accounts"
                $item | Add-Member -MemberType NoteProperty -Name "Accounts" -Value $($Safe.accounts.Name -join ", ")
            }
            Write-LogMessage -type Debug -MSG "Adding safe '$($Safe.Safename)' to CSV '$CSVPath'"
            $item | Export-Csv -Append $CSVPath -NoTypeInformation
            $SafeCount += 1
        } catch {
            Write-LogMessage -type Error -MSG $_
        }
    }
    end {
        Write-LogMessage -type Info -MSG "Exported $SafeCount safes successfully"
        Write-LogMessage -type Debug -MSG "Completed successfully"
    }
}
#EndRegion '.\Public\PAS\Safe\Export-Safe.ps1' 132
#Region '.\Public\PAS\Safe\Get-Safe.ps1' -1

<#
.SYNOPSIS
    Retrieves information about safes from the PVWA API.

.DESCRIPTION
    The Get-Safe function retrieves information about safes from the PVWA API. It supports multiple parameter sets to allow retrieval by Safe ID, Platform ID, or general queries. The function can also return all safes if no specific parameters are provided.

.PARAMETER PVWAURL
    The URL of the PVWA instance.

.PARAMETER LogonToken
    The logon token for authentication.

.PARAMETER SafeUrlId
    The ID of the safe to retrieve.

.PARAMETER SafeName
    The name of the safe to retrieve.

.PARAMETER PlatformID
    The ID of the platform to retrieve safes for.

.PARAMETER AllSafes
    Switch to retrieve all safes.

.PARAMETER ExtendedDetails
    Switch to include extended details in the results.

.PARAMETER includeAccounts
    Switch to include accounts in the results.

.PARAMETER useCache
    Switch to use cached results.

.PARAMETER Search
    A search string to filter the results.

.PARAMETER offset
    The offset for pagination.

.PARAMETER limit
    The limit for pagination.

.PARAMETER DoNotPage
    Switch to disable pagination.

.PARAMETER sort
    The sort order for the results. Valid values are "asc" and "desc".

.EXAMPLE
    Get-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeUrlId "12345"
    Retrieves the safe with ID 12345.

.EXAMPLE
    Get-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -AllSafes
    Retrieves all safes.

.EXAMPLE
    Get-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "MySafe" -PlatformID "Platform1"
    Retrieves the safe named "MySafe" for platform "Platform1".

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
#>
function Get-Safe {
    [CmdletBinding(DefaultParameterSetName = "PVWAURL")]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,

        [Alias('url', 'PCloudURL')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]
        $PVWAURL,

        [Alias('header')]
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LogonToken,

        [Parameter(ParameterSetName = 'SafeID', ValueFromPipelineByPropertyName)]
        [Alias('SafeID')]
        [string]
        $SafeUrlId,

        [Parameter(ParameterSetName = 'PlatformID', ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,

        [Parameter(ParameterSetName = 'PlatformID', ValueFromPipelineByPropertyName)]
        [string]
        $PlatformID,

        [Parameter(ParameterSetName = 'AllSafes')]
        [switch]
        $AllSafes,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'PVWAURL')]
        [switch]
        $ExtendedDetails,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeID')]
        [Parameter(ParameterSetName = 'PVWAURL')]
        [switch]
        $includeAccounts,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'SafeID')]
        [switch]
        $useCache,

        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]
        $Search,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $offset = $null,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $limit,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [switch]
        $DoNotPage,

        [Parameter(ParameterSetName = 'AllSafes')]
        [Parameter(ParameterSetName = 'Search')]
        [AllowEmptyString]
        [ValidateSet("asc", "desc")]
        $sort
    )

    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        $BaseURL = "$PVWAURL/API/"
        $SafeURL = "$BaseURL/Safes/?"
        $SafeIDURL = "$BaseURL/Safes/{0}/?"
        $PlatformIDURL = "$BaseURL/Platforms/{0}/Safes/{1}/?"
    }

    Process {
        $SafeUrlIdExists = -not [string]::IsNullOrEmpty($SafeUrlId)
        $SafeNameExists = -not [string]::IsNullOrEmpty($SafeName)
        $PlatformIDExists = -not [string]::IsNullOrEmpty($PlatformID)

        if ($SafeUrlIdExists) {
            Get-SafeViaID
        }
        elseif ($PlatformIDExists) {
            Get-SafeViaPlatformID
        }
        else {
            if (-not ($SafeNameExists -or $PlatformIDExists -or $SafeUrlIdExists)) {
                Write-LogMessage -type Debug -MSG "No Safe Name, Safe ID, or Platform ID provided, returning all safes"
            }
            Get-SafeViaQuery
        }
    }
}

function Get-SafeViaID {
    $URL = $SafeIDURL -f $SafeUrlId
    Write-LogMessage -type Debug -MSG "Getting safe with ID of `"$SafeUrlId`""
    Add-BaseQueryParameter -URL ([ref]$URL)
    $restResponse = Invoke-Rest -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
    return [safe]$restResponse
}

function Get-SafeViaPlatformID {
    if ($SafeNameExists) {
        Write-LogMessage -type Debug -MSG "Searching for a safe with the name of `"$SafeName`" and a platformID of `"$PlatformID`""
        $URL = $PlatformIDURL -f $PlatformID, $SafeName
    }
    else {
        Write-LogMessage -type Debug -MSG "Getting a list of safes available to platformID `"$PlatformID`""
        $URL = $PlatformIDURL -f $PlatformID
    }
    [PSCustomObject[]]$resultList = Invoke-RestNextLink -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
    return [safe[]]$resultList
}

function Get-SafeViaQuery {
    Write-LogMessage -type Debug -MSG "Getting list of safes"
    $URL = $SafeURL
    Add-BaseQueryParameter -URL ([ref]$URL)
    Add-SafeQueryParameter -URL ([ref]$URL)
    [PSCustomObject[]]$resultList = Invoke-RestNextLink -Uri $URL -Method GET -Headers $logonToken -ContentType 'application/json'
    return [safe[]]$resultList
}

function Add-SafeQueryParameter {
    param (
        [ref]$URL
    )
    Write-LogMessage -type Debug -MSG "Adding Query Parameters"
    if ($includeAccounts) {
        $URL.Value += "&includeAccounts=true"
        Write-LogMessage -type Debug -MSG "Including accounts in results"
    }
    if ($ExtendedDetails) {
        $URL.Value += "&extendedDetails=true"
        Write-LogMessage -type Debug -MSG "Including extended details"
    }
    if (-not [string]::IsNullOrEmpty($Search)) {
        $URL.Value += "&search=$Search"
        Write-LogMessage -type Debug -MSG "Applying a search of `"$Search`""
    }
    Write-LogMessage -type Debug -MSG "New URL: $($URL.ToString())"
}
#EndRegion '.\Public\PAS\Safe\Get-Safe.ps1' 218
#Region '.\Public\PAS\Safe\New-Safe.ps1' -1

<#
.SYNOPSIS
Creates a new safe in the specified PVWA instance.

.DESCRIPTION
The New-Safe function creates a new safe in the specified PVWA instance using the provided parameters.
It supports ShouldProcess for confirmation prompts and logs the process.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The logon token for authentication.

.PARAMETER safeName
The name of the safe to be created.

.PARAMETER description
The description of the safe.

.PARAMETER location
The location of the safe.

.PARAMETER olacEnabled
Switch to enable or disable OLAC (Object Level Access Control).

.PARAMETER managingCPM
The name of the managing CPM (Central Policy Manager).

.PARAMETER numberOfVersionsRetention
The number of versions to retain.

.PARAMETER numberOfDaysRetention
The number of days to retain versions.

.PARAMETER AutoPurgeEnabled
Switch to enable or disable automatic purging.

.EXAMPLE
PS> New-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -safeName "NewSafe" -description "This is a new safe" -location "Root" -olacEnabled -managingCPM "CPM1" -numberOfVersionsRetention "5" -numberOfDaysRetention "30" -AutoPurgeEnabled

This command creates a new safe named "NewSafe" in the specified PVWA instance with the given parameters.

.NOTES
This function requires the 'Invoke-Rest' and 'Write-LogMessage' functions to be defined in the session.
#>

function New-Safe {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $safeName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $description,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $location,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $olacEnabled,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $managingCPM,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $numberOfVersionsRetention,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $numberOfDaysRetention,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $AutoPurgeEnabled,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $UpdateOnDuplicate
    )

    Begin {
        $SafeURL = "$PVWAURL/API/Safes/"
    }

    Process {
        $body = @{
            safeName                  = $safeName
            description               = $description
            location                  = $location
            managingCPM               = $managingCPM
            numberOfVersionsRetention = $numberOfVersionsRetention
            numberOfDaysRetention     = $numberOfDaysRetention
            AutoPurgeEnabled          = $AutoPurgeEnabled.IsPresent
            olacEnabled               = $olacEnabled.IsPresent
        }

        if ($PSCmdlet.ShouldProcess($safeName, 'New-Safe')) {
            Write-LogMessage -type Debug -MSG "Adding safe `"$safeName`""
            Try {
                Invoke-Rest -Uri $SafeURL -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99) -ErrAction SilentlyContinue
                Write-LogMessage -type Debug -MSG "Added safe `"$safeName`" successfully"
            }
            Catch {
                If ($($PSItem.ErrorDetails.Message |ConvertFrom-Json).ErrorCode -eq "SFWS0002") {
                    IF ($UpdateOnDuplicate) {
                        Write-LogMessage -type Debug -MSG "Safe `"$safeName`" does not exist, creating instead"
                        $updateParams = @{
                            PVWAURL                  = $PVWAURL
                            LogonToken               = $LogonToken
                            safeName                 = $safeName
                            description              = $description
                            location                 = $location
                            olacEnabled              = $olacEnabled
                            managingCPM              = $managingCPM
                            numberOfVersionsRetention = $numberOfVersionsRetention
                            numberOfDaysRetention    = $numberOfDaysRetention
                            Confirm                  = $false
                        }
                        Set-Safe @updateParams
                    }
                    Else {
                        Write-LogMessage -type Warning -MSG "Safe `"$safeName`" already exists, skipping creation"
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to add safe `"$safeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping creation of safe `"$safeName`" due to confirmation being denied"
        }
    }
}
#EndRegion '.\Public\PAS\Safe\New-Safe.ps1' 142
#Region '.\Public\PAS\Safe\Set-Safe.ps1' -1

<#
.SYNOPSIS
Updates the properties of an existing safe in the PVWA.

.DESCRIPTION
The Set-Safe function updates the properties of an existing safe in the PVWA (Password Vault Web Access).
It allows you to modify the safe's description, location, managing CPM, number of versions retention,
number of days retention, and OLAC (Object Level Access Control) status.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The authentication token required to log on to the PVWA.

.PARAMETER safeName
The name of the safe to be updated.

.PARAMETER description
The new description for the safe.

.PARAMETER location
The new location for the safe.

.PARAMETER olacEnabled
A switch parameter to enable or disable OLAC for the safe.

.PARAMETER managingCPM
The name of the CPM (Central Policy Manager) managing the safe.

.PARAMETER numberOfVersionsRetention
The number of versions to retain for the safe.

.PARAMETER numberOfDaysRetention
The number of days to retain the safe.

.EXAMPLE
Set-Safe -PVWAURL "https://pvwa.example.com" -LogonToken $token -safeName "FinanceSafe" -description "Updated description" -location "New York" -olacEnabled -managingCPM "CPM1" -numberOfVersionsRetention "5" -numberOfDaysRetention "30"

This example updates the safe named "FinanceSafe" with a new description, location, and other properties.

.NOTES
This function requires the PVWA URL and a valid logon token for authentication.
The function supports ShouldProcess for confirmation before making changes.
#>
function
Set-Safe {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $safeName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $description,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $location,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $olacEnabled,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $managingCPM,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $numberOfVersionsRetention,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $numberOfDaysRetention,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch] $CreateOnMissing
    )
    Begin {
        $SafeURL = "$PVWAURL/API/Safes/{0}/"
    }
    Process {
        $body = @{
            safeName                  = $safeName
            description               = $description
            location                  = $location
            managingCPM               = $managingCPM
            numberOfVersionsRetention = $numberOfVersionsRetention
            numberOfDaysRetention     = $numberOfDaysRetention
        }

        if ($olacEnabled) {
            $body.Add("olacEnabled", "true")
        }

        if ($PSCmdlet.ShouldProcess($safeName, 'Set-Safe')) {
            Write-LogMessage -type Debug -MSG "Updating safe `"$safeName`""
            Try {
                Invoke-Rest -Command PUT -URI ($SafeURL -f $safeName) -Header $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99) -ErrAction SilentlyContinue
                Write-LogMessage -type Debug -MSG "Updated safe `"$safeName`" successfully"
            }
            Catch {
                If (($PSItem.ErrorDetails.Message |ConvertFrom-Json).ErrorCode -eq 'SFWS0007') {
                    IF ($CreateOnMissing) {
                        Write-LogMessage -type Debug -MSG "Safe `"$safeName`" not found, creating instead"
                        New-Safe -PVWAURL $PVWAURL -LogonToken $LogonToken -safeName $safeName -description $description -location $location -olacEnabled:$olacEnabled -managingCPM $managingCPM -numberOfVersionsRetention $numberOfVersionsRetention -numberOfDaysRetention $numberOfDaysRetention -Confirm:$false
                    }
                    Else {
                        Write-LogMessage -type ErrorThrow -MSG "Safe `"$safeName`" not found."
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to add safe `"$safeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of safe `"$safeName`" due to confirmation being denied"
        }
    }
}
#EndRegion '.\Public\PAS\Safe\Set-Safe.ps1' 126
#Region '.\Public\PAS\SafeMember\Add-SafeMember.ps1' -1

<#
.SYNOPSIS
    Adds a member to a specified safe in the PVWA.

.DESCRIPTION
    The Add-SafeMember function adds a member to a specified safe in the PVWA with various permissions.
    This function supports ShouldProcess for safety and confirmation prompts.

.PARAMETER PVWAURL
    The URL of the PVWA instance.

.PARAMETER LogonToken
    The logon token for authentication.

.PARAMETER SafeName
    The name of the safe to which the member will be added.

.PARAMETER memberName
    The name of the member to be added to the safe.

.PARAMETER searchIn
    The search scope for the member.

.PARAMETER MemberType
    The type of the member (User, Group, Role).

.PARAMETER membershipExpirationDate
    The expiration date of the membership.

.PARAMETER useAccounts
    Permission to use accounts.

.PARAMETER retrieveAccounts
    Permission to retrieve accounts.

.PARAMETER listAccounts
    Permission to list accounts.

.PARAMETER addAccounts
    Permission to add accounts.

.PARAMETER updateAccountContent
    Permission to update account content.

.PARAMETER updateAccountProperties
    Permission to update account properties.

.PARAMETER initiateCPMAccountManagementOperations
    Permission to initiate CPM account management operations.

.PARAMETER specifyNextAccountContent
    Permission to specify next account content.

.PARAMETER renameAccounts
    Permission to rename accounts.

.PARAMETER deleteAccounts
    Permission to delete accounts.

.PARAMETER unlockAccounts
    Permission to unlock accounts.

.PARAMETER manageSafe
    Permission to manage the safe.

.PARAMETER manageSafeMembers
    Permission to manage safe members.

.PARAMETER backupSafe
    Permission to backup the safe.

.PARAMETER viewAuditLog
    Permission to view the audit log.

.PARAMETER viewSafeMembers
    Permission to view safe members.

.PARAMETER accessWithoutConfirmation
    Permission to access without confirmation.

.PARAMETER createFolders
    Permission to create folders.

.PARAMETER deleteFolders
    Permission to delete folders.

.PARAMETER moveAccountsAndFolders
    Permission to move accounts and folders.

.PARAMETER requestsAuthorizationLevel1
    Permission for requests authorization level 1.

.PARAMETER requestsAuthorizationLevel2
    Permission for requests authorization level 2.

.EXAMPLE
    Add-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "Finance" -memberName "JohnDoe" -MemberType "User" -useAccounts $true

.NOTES
    This function requires the PVWA URL and a valid logon token for authentication.
#>

function Add-SafeMember {
    [CmdletBinding(DefaultParameterSetName = "memberName", SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string] $SafeName,

        [Parameter(ParameterSetName = 'memberObject', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('SafeMember')]
        [string] $memberObject,

        [Parameter(ParameterSetName = 'memberName', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string] $memberName,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [string] $searchIn,

        [ValidateSet('User', 'Group', 'Role')]
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [string] $MemberType,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [int] $membershipExpirationDate,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $useAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $retrieveAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $listAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $addAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $updateAccountContent,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $updateAccountProperties,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $initiateCPMAccountManagementOperations,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $specifyNextAccountContent,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $renameAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $deleteAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $unlockAccounts,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $manageSafe,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $manageSafeMembers,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $backupSafe,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $viewAuditLog,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $viewSafeMembers,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $accessWithoutConfirmation,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $createFolders,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $deleteFolders,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $moveAccountsAndFolders,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $requestsAuthorizationLevel1,

        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $requestsAuthorizationLevel2,

        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$UpdateOnDuplicate
    )

    Begin {
        $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/"
    }

    Process {
        IF ($PsCmdlet.ParameterSetName -eq 'memberName') {

            $permissions = [SafePerms]@{
                useAccounts                            = $useAccounts
                retrieveAccounts                       = $retrieveAccounts
                listAccounts                           = $listAccounts
                addAccounts                            = $addAccounts
                updateAccountContent                   = $updateAccountContent
                updateAccountProperties                = $updateAccountProperties
                initiateCPMAccountManagementOperations = $initiateCPMAccountManagementOperations
                specifyNextAccountContent              = $specifyNextAccountContent
                renameAccounts                         = $renameAccounts
                deleteAccounts                         = $deleteAccounts
                unlockAccounts                         = $unlockAccounts
                manageSafe                             = $manageSafe
                manageSafeMembers                      = $manageSafeMembers
                backupSafe                             = $backupSafe
                viewAuditLog                           = $viewAuditLog
                viewSafeMembers                        = $viewSafeMembers
                accessWithoutConfirmation              = $accessWithoutConfirmation
                createFolders                          = $createFolders
                deleteFolders                          = $deleteFolders
                moveAccountsAndFolders                 = $moveAccountsAndFolders
                requestsAuthorizationLevel1            = $requestsAuthorizationLevel1
                requestsAuthorizationLevel2            = $requestsAuthorizationLevel2
            }

            $body = [SafeMember]@{
                memberName               = $memberName
                searchIn                 = $searchIn
                membershipExpirationDate = $membershipExpirationDate
                MemberType               = $MemberType
                Permissions              = $permissions
            }
        }
        elseif ($PsCmdlet.ParameterSetName -eq 'memberObject') {
            $memberName = $memberObject.memberName
            $body = $memberObject
        }

        if ($PSCmdlet.ShouldProcess($memberName, 'Add-SafeMember')) {
            Try {
                Write-LogMessage -type Verbose -MSG "Adding owner `"$memberName`" to safe `"$SafeName`""
                Invoke-Rest -Uri $SafeMemberURL -Method POST -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99) -ErrAction SilentlyContinue
                Write-LogMessage -type Verbose -MSG "Added owner `"$memberName`" to safe `"$SafeName`" successfully"
            }
            Catch {
                If ($($PSItem.ErrorDetails.Message | ConvertFrom-Json).ErrorCode -eq "SFWS0012") {
                    IF ($UpdateOnDuplicate) {
                        Write-LogMessage -type Verbose -MSG "Owner `"$memberName`" on `"$SafeName`" already exist, updating instead"
                        $SetParams = @{
                            PVWAURL                                = $PVWAURL
                            LogonToken                             = $LogonToken
                            SafeName                               = $SafeName
                            memberName                             = $memberName
                            MemberType                             = $MemberType
                            searchIn                               = $searchIn
                            membershipExpirationDate               = $membershipExpirationDate
                            useAccounts                            = $useAccounts
                            retrieveAccounts                       = $retrieveAccounts
                            listAccounts                           = $listAccounts
                            addAccounts                            = $addAccounts
                            updateAccountContent                   = $updateAccountContent
                            updateAccountProperties                = $updateAccountProperties
                            initiateCPMAccountManagementOperations = $initiateCPMAccountManagementOperations
                            specifyNextAccountContent              = $specifyNextAccountContent
                            renameAccounts                         = $renameAccounts
                            deleteAccounts                         = $deleteAccounts
                            unlockAccounts                         = $unlockAccounts
                            manageSafe                             = $manageSafe
                            manageSafeMembers                      = $manageSafeMembers
                            backupSafe                             = $backupSafe
                            viewAuditLog                           = $viewAuditLog
                            viewSafeMembers                        = $viewSafeMembers
                            accessWithoutConfirmation              = $accessWithoutConfirmation
                            createFolders                          = $createFolders
                            deleteFolders                          = $deleteFolders
                            moveAccountsAndFolders                 = $moveAccountsAndFolders
                            requestsAuthorizationLevel1            = $requestsAuthorizationLevel1
                            requestsAuthorizationLevel2            = $requestsAuthorizationLevel2
                        }
                        Set-SafeMember @SetParams
                    }
                    Else {
                        Write-LogMessage -type Warning -MSG "Owner `"$memberName`" on `"$SafeName`"  already exists, skipping creation"
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to add Owner `"$memberName`" on `"$SafeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping addition of owner `"$memberName`" to safe `"$SafeName`""
        }
    }
}
#EndRegion '.\Public\PAS\SafeMember\Add-SafeMember.ps1' 310
#Region '.\Public\PAS\SafeMember\Export-SafeMember.ps1' -1

<#
.SYNOPSIS
Exports safe member information to a CSV file.

.DESCRIPTION
The Export-SafeMember function exports information about safe members to a specified CSV file.
It allows filtering out system safes and includes options to force overwrite the CSV file if it already exists.

.PARAMETER CSVPath
Specifies the path to the CSV file where the safe member information will be exported.
Defaults to ".\SafeMemberExport.csv".

.PARAMETER Force
If specified, forces the overwrite of the CSV file if it already exists.

.PARAMETER SafeMember
Specifies the safe member object to be exported. This parameter is mandatory and accepts input from the pipeline.

.PARAMETER includeSystemSafes
If specified, includes system safes in the export. This parameter is hidden from the help documentation.

.PARAMETER CPMUser
Specifies an array of CPM user names. This parameter is hidden from the help documentation.

.EXAMPLE
Export-SafeMember -CSVPath "C:\Exports\SafeMembers.csv" -SafeMember $safeMember

This example exports the safe member information to "C:\Exports\SafeMembers.csv".

.EXAMPLE
$safeMembers | Export-SafeMember -CSVPath "C:\Exports\SafeMembers.csv" -Force

This example exports the safe member information from the pipeline to "C:\Exports\SafeMembers.csv",
forcing the overwrite of the file if it already exists.

.NOTES
The function logs verbose messages about its operations and handles errors gracefully.
#>
function Export-SafeMember {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $CSVPath = ".\SafeMemberExport.csv",
        [switch]
        $Force,
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [SafeMember]
        $SafeMember,
        # Parameter help description
        [Parameter(DontShow)]
        [switch]
        $includeSystemSafes,
        # Parameter help description
        [Parameter(DontShow)]
        [string[]]
        $CPMUser
    )
    begin {
        [String[]]$SafesToRemove = @('System', 'Pictures', 'VaultInternal', 'Notification Engine', 'SharedAuth_Internal', 'PVWAUserPrefs',
            'PVWAConfig', 'PVWAReports', 'PVWATaskDefinitions', 'PVWAPrivateUserPrefs', 'PVWAPublicData', 'PVWATicketingSystem',
            'AccountsFeed', 'PSM', 'xRay', 'PIMSuRecordings', 'xRay_Config', 'AccountsFeedADAccounts', 'AccountsFeedDiscoveryLogs', 'PSMSessions', 'PSMLiveSessions', 'PSMUniversalConnectors',
            'PSMNotifications', 'PSMUnmanagedSessionAccounts', 'PSMRecordings', 'PSMPADBridgeConf', 'PSMPADBUserProfile', 'PSMPADBridgeCustom', 'PSMPConf', 'PSMPLiveSessions'
            'AppProviderConf', 'PasswordManagerTemp', 'PasswordManager_Pending', 'PasswordManagerShared', 'SCIM Config', 'TelemetryConfig')
        [string[]]$cpmSafes = @()
        $CPMUser | ForEach-Object {
            $cpmSafes += "$($PSitem)"
            $cpmSafes += "$($PSitem)_Accounts"
            $cpmSafes += "$($PSitem)_ADInternal"
            $cpmSafes += "$($PSitem)_Info"
            $cpmSafes += "$($PSitem)_workspace"
        }
        $SafesToRemove += $cpmSafes
        $SafeMemberCount = 0
        if (Test-Path $CSVPath) {
            Try {
                Write-LogMessage -type Verbose -MSG "The file `'$CSVPath`' already exists. Checking for Force switch"
                If ($Force) {
                    Remove-Item $CSVPath
                    Write-LogMessage -type Verbose -MSG "The file `'$CSVPath`' was removed."
                }
                else {
                    Write-LogMessage -type Verbose -MSG "The file `'$CSVPath`' already exists and the switch `"Force`" was not passed."
                    Write-LogMessage -type Error -MSG "The file `'$CSVPath`' already exists."
                    Exit 80
                }
            }
            catch {
                Write-LogMessage -type ErrorThrow -MSG "Error while trying to remove`'$CSVPath`'"
            }
        }
    }
    Process {

        Try {
            IF (-not $includeSystemSafes) {
                If ($PSitem.SafeName -in $SafesToRemove) {
                    Write-LogMessage -type Verbose -MSG "Safe `"$($PSitem.SafeName)`" is a system safe, skipping"
                    return
                }
            }
            Write-LogMessage -type Verbose -MSG "Working with safe `"$($PSitem.Safename)`" and safe member `"$($PSitem.memberName)`""
            $item = [pscustomobject]@{
                "Safe Name"                                  = $PSitem.safeName
                "Member Name"                                = $PSitem.memberName
                "Member Type"                                = $PSitem.memberType
                "Use Accounts"                               = $PSitem.Permissions.useAccounts
                "Retrieve Accounts"                          = $PSitem.Permissions.retrieveAccounts
                "Add Accounts"                               = $PSitem.Permissions.addAccounts
                "Update Account Properties"                  = $PSitem.Permissions.updateAccountProperties
                "Update Account Content"                     = $PSitem.Permissions.updateAccountContent
                "Initiate CPM Account Management Operations" = $PSitem.Permissions.initiateCPMAccountManagementOperations
                "Specify Next Account Content"               = $PSitem.Permissions.specifyNextAccountContent
                "Rename Account"                             = $PSitem.Permissions.renameAccounts
                "Delete Account"                             = $PSitem.Permissions.deleteAccounts
                "Unlock Account"                             = $PSitem.Permissions.unlockAccounts
                "Manage Safe"                                = $PSitem.Permissions.manageSafe
                "View Safe Members"                          = $PSitem.Permissions.viewSafeMembers
                "Manage Safe Members"                        = $PSitem.Permissions.manageSafeMembers
                "View Audit Log"                             = $PSitem.Permissions.viewAuditLog
                "Backup Safe"                                = $PSitem.Permissions.backupSafe
                "Level 1 Confirmer"                          = $PSitem.Permissions.requestsAuthorizationLevel1
                "Level 2 Confirmer"                          = $PSitem.Permissions.requestsAuthorizationLevel2
                "Access Safe Without Confirmation"           = $PSitem.Permissions.accessWithoutConfirmation
                "Move Accounts / Folders"                    = $PSitem.Permissions.moveAccountsAndFolders
                "Create Folders"                             = $PSitem.Permissions.createFolders
                "Delete Folders"                             = $PSitem.Permissions.deleteFolders

            }

            Write-LogMessage -type Verbose -MSG "Adding safe `"$($PSitem.Safename)`" and safe member `"$($PSitem.memberName)`" to CSV `"$CSVPath`""
            $item | Export-Csv -Append $CSVPath
            $SafeMemberCount += 1
        }
        Catch {
            Write-LogMessage -type Error -MSG $PSitem
        }
    }
    End {
        Write-LogMessage -type Info -MSG "Exported $SafeMemberCount safe members succesfully"
        Write-LogMessage -type Verbose -MSG "Completed successfully"
    }
}
#EndRegion '.\Public\PAS\SafeMember\Export-SafeMember.ps1' 144
#Region '.\Public\PAS\SafeMember\Get-SafeMember.ps1' -1

<#
.SYNOPSIS
    Retrieves safe member information from the PVWA API.

.DESCRIPTION
    The Get-SafeMember function retrieves information about members of a specified safe from the PVWA API.
    It supports various parameter sets to filter and search for specific members or member types.

.PARAMETER PVWAURL
    The URL of the PVWA instance.

.PARAMETER LogonToken
    The logon token for authenticating with the PVWA API.

.PARAMETER SafeName
    The name of the safe to retrieve members from.

.PARAMETER memberName
    The name of the member to retrieve information for. This parameter is mandatory when using the 'memberName' parameter set.

.PARAMETER useCache
    A switch to indicate whether to use cached data. This parameter is only valid with the 'memberName' parameter set.

.PARAMETER Search
    A search string to filter members by name. This parameter is only valid with the 'Search' parameter set.

.PARAMETER memberType
    The type of member to filter by. Valid values are "User" and "Group". This parameter is only valid with the 'Search' parameter set.

.PARAMETER membershipExpired
    A filter to include only members with expired memberships. Valid values are "True" and "False". This parameter is only valid with the 'Search' parameter set.

.PARAMETER includePredefinedUsers
    A filter to include predefined users. Valid values are "True" and "False". This parameter is only valid with the 'Search' parameter set.

.PARAMETER offset
    The offset for pagination. This parameter is only valid with the 'Search' parameter set.

.PARAMETER limit
    The limit for pagination. This parameter is only valid with the 'Search' parameter set.

.PARAMETER DoNotPage
    A switch to disable pagination. This parameter is only valid with the 'Search' parameter set.

.PARAMETER sort
    The sort order for the results. Valid values are "asc" and "desc". This parameter is only valid with the 'Search' parameter set.

.PARAMETER permissions
    A switch to include permissions in the output.

.EXAMPLE
    Get-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "Finance"

    Retrieves all members of the "Finance" safe.

.EXAMPLE
    Get-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "Finance" -memberName "JohnDoe"

    Retrieves information about the member "JohnDoe" in the "Finance" safe.
#>

function Get-SafeMember {
    [CmdletBinding(DefaultParameterSetName = "SafeName")]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]
        $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string]
        $SafeName,
        [Parameter(Mandatory, ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string]
        $memberName,
        [Parameter(ParameterSetName = 'memberName')]
        [switch]
        $useCache,
        [Parameter(ParameterSetName = 'Search', ValueFromPipelineByPropertyName)]
        [string]
        $Search,
        [Parameter(ParameterSetName = 'Search')]
        [ValidateSet("User", "Group")]
        [string]
        $memberType,
        [Parameter(ParameterSetName = 'Search')]
        [ValidateSet("True", "False")]
        [string]
        $membershipExpired,
        [Parameter(ParameterSetName = 'Search')]
        [ValidateSet("True", "False")]
        [string]
        $includePredefinedUsers,
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $offset = $null,
        [Parameter(ParameterSetName = 'Search')]
        [Nullable[int]]
        $limit,
        [Parameter(ParameterSetName = 'Search')]
        [switch]
        $DoNotPage,
        [Parameter(ParameterSetName = 'Search')]
        [AllowEmptyString]
        [ValidateSet("asc", "desc")]
        $sort,
        [switch]
        $permissions
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        if ([string]::IsNullOrEmpty($SafeName)) {
            Write-LogMessage -type Error -MSG "No Safe Name provided"
            return
        }

        if (-not [string]::IsNullOrEmpty($memberName)) {
            $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/$memberName/"
            Write-LogMessage -type Verbose -MSG "Getting memberName permissions for safe $SafeName"
            return Invoke-Rest -Uri $SafeMemberURL -Method GET -Headers $logonToken -ContentType 'application/json'
        }
        else {
            $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/?"
            Write-LogMessage -type Verbose -MSG "Getting owners permissions for safe $SafeName"
            $filterList = @()

            if (-not [string]::IsNullOrEmpty($memberType)) {
                $filterList += "memberType eq $memberType"
            }
            if (-not [string]::IsNullOrEmpty($membershipExpired)) {
                $filterList += "membershipExpired eq $membershipExpired"
            }
            if (-not [string]::IsNullOrEmpty($includePredefinedUsers)) {
                $filterList += "includePredefinedUsers eq $includePredefinedUsers"
            }
            if ($filterList.Count -gt 0) {
                $filter = $filterList -join " AND "
                $SafeMemberURL += "filter=$filter"
                Write-LogMessage -type Verbose -MSG "Applying a filter of $filter"
            }
            if (-not [string]::IsNullOrEmpty($Search)) {
                $SafeMemberURL += "&search=$Search"
                Write-LogMessage -type Verbose -MSG "Applying a search of $Search"
            }
            if (-not [string]::IsNullOrEmpty($offset)) {
                $SafeMemberURL += "&offset=$offset"
                Write-LogMessage -type Verbose -MSG "Applying an offset of $offset"
            }
            if (-not [string]::IsNullOrEmpty($limit)) {
                $SafeMemberURL += "&limit=$limit"
                Write-LogMessage -type Verbose -MSG "Applying a limit of $limit"
            }
            if (-not [string]::IsNullOrEmpty($sort)) {
                $SafeMemberURL += "&sort=$sort"
                Write-LogMessage -type Verbose -MSG "Applying a sort of $sort"
            }
            if ($DoNotPage) {
                Write-LogMessage -type Verbose -MSG "Paging is disabled."
            }

            $restResponse = Invoke-Rest -Uri $SafeMemberURL -Method GET -Headers $logonToken -ContentType 'application/json'
            [SafeMember[]]$memberList = $restResponse.value

            if (-not [string]::IsNullOrEmpty($restResponse.NextLink)) {
                if ($DoNotPage) {
                    Write-LogMessage -type Verbose -MSG "A total of $($memberList.Count) members found, but paging is disabled. Returning only $($memberList.Count) members"
                }
                else {
                    do {
                        Write-LogMessage -type Verbose -MSG "NextLink found, getting next page"
                        $restResponse = Invoke-Rest -Uri "$PVWAURL/$($restResponse.NextLink)" -Method GET -Headers $logonToken -ContentType 'application/json'
                        $memberList += $restResponse.value
                    } until ([string]::IsNullOrEmpty($restResponse.NextLink))
                }
            }
            else {
                Write-LogMessage -type Verbose -MSG "Found $($memberList.Count) members"
            }

            return [SafeMember[]]$memberList
        }
    }
}
#EndRegion '.\Public\PAS\SafeMember\Get-SafeMember.ps1' 192
#Region '.\Public\PAS\SafeMember\Remove-SafeMember.ps1' -1

<#
.SYNOPSIS
Removes a member from a specified safe in the PVWA.

.DESCRIPTION
The Remove-SafeMember function removes a specified member from a safe in the PVWA (Privileged Vault Web Access).
It supports confirmation prompts and logging of actions.

.PARAMETER PVWAURL
The URL of the PVWA instance.

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER SafeName
The name of the safe from which the member will be removed.

.PARAMETER memberName
The name of the member to be removed from the safe.

.EXAMPLE
Remove-SafeMember -PVWAURL "https://pvwa.example.com" -LogonToken $token -SafeName "FinanceSafe" -memberName "JohnDoe"

This command removes the member "JohnDoe" from the safe "FinanceSafe" in the specified PVWA instance.

.NOTES
- This function supports ShouldProcess for safety.
- The ConfirmImpact is set to High, so confirmation is required by default.
- The function logs actions and warnings using Write-LogMessage.
#>
function Remove-SafeMember {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
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
        $memberName
    )

    Begin {
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
    }

    Process {
        $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/$memberName/"
        if ($PSCmdlet.ShouldProcess($memberName, 'Remove-SafeMember')) {
            Write-LogMessage -type Verbose -MSG "Removing member `$memberName` from safe `$SafeName`""
            Invoke-Rest -Uri $SafeMemberURL -Method DELETE -Headers $LogonToken -ContentType 'application/json'
        } else {
            Write-LogMessage -type Warning -MSG "Skipping removal of member `$memberName` from safe `$SafeName` due to confirmation being denied"
        }
    }
}
#EndRegion '.\Public\PAS\SafeMember\Remove-SafeMember.ps1' 74
#Region '.\Public\PAS\SafeMember\Set-SafeMember.ps1' -1

#TODO Run Co-Pilot doc generator
function Set-SafeMember {
    [CmdletBinding(DefaultParameterSetName = "memberName", SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Safe')]
        [string] $SafeName,
        [Parameter(ParameterSetName = 'memberObject', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('SafeMember')]
        [string] $memberObject,
        [Parameter(ParameterSetName = 'memberName', Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('User')]
        [string] $memberName,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [string] $searchIn,
        [ValidateSet('User', 'Group', 'Role')]
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [string] $MemberType,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [AllowNull()]
        [int] $membershipExpirationDate,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $useAccounts,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $retrieveAccounts,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $listAccounts,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $addAccounts,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $updateAccountContent,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $updateAccountProperties,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $initiateCPMAccountManagementOperations,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $specifyNextAccountContent,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $renameAccounts,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $deleteAccounts,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $unlockAccounts,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $manageSafe,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $manageSafeMembers,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $backupSafe,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $viewAuditLog,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $viewSafeMembers,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $accessWithoutConfirmation,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $createFolders,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $deleteFolders,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $moveAccountsAndFolders,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $requestsAuthorizationLevel1,
        [Parameter(ParameterSetName = 'memberName', ValueFromPipelineByPropertyName)]
        [bool] $requestsAuthorizationLevel2,
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$CreateOnMissing
    )
    Begin {
        $SafeMemberURL = "$PVWAURL/API/Safes/$SafeName/Members/{0}/"
    }
    Process {
        IF ($PsCmdlet.ParameterSetName -eq 'memberName') {
            $permissions = [SafePerms]@{
                useAccounts                            = $useAccounts
                retrieveAccounts                       = $retrieveAccounts
                listAccounts                           = $listAccounts
                addAccounts                            = $addAccounts
                updateAccountContent                   = $updateAccountContent
                updateAccountProperties                = $updateAccountProperties
                initiateCPMAccountManagementOperations = $initiateCPMAccountManagementOperations
                specifyNextAccountContent              = $specifyNextAccountContent
                renameAccounts                         = $renameAccounts
                deleteAccounts                         = $deleteAccounts
                unlockAccounts                         = $unlockAccounts
                manageSafe                             = $manageSafe
                manageSafeMembers                      = $manageSafeMembers
                backupSafe                             = $backupSafe
                viewAuditLog                           = $viewAuditLog
                viewSafeMembers                        = $viewSafeMembers
                accessWithoutConfirmation              = $accessWithoutConfirmation
                createFolders                          = $createFolders
                deleteFolders                          = $deleteFolders
                moveAccountsAndFolders                 = $moveAccountsAndFolders
                requestsAuthorizationLevel1            = $requestsAuthorizationLevel1
                requestsAuthorizationLevel2            = $requestsAuthorizationLevel2
            }
            $body = [SafeMember]@{
                memberName               = $memberName
                searchIn                 = $searchIn
                membershipExpirationDate = $membershipExpirationDate
                MemberType               = $MemberType
                Permissions              = $permissions
            }
        }
        elseif ($PsCmdlet.ParameterSetName -eq 'memberObject') {
            $memberName = $memberObject.memberName
            $body = $memberObject
        }
        if ($PSCmdlet.ShouldProcess($memberName, 'Set-SafeMember')) {
            Try {
                Write-LogMessage -type Verbose -MSG "Updating owner `"$memberName`" to safe `"$SafeName`""
                $URL = $SafeMemberURL -f $memberName
                Invoke-Rest -Uri $URL -Method PUT -Headers $LogonToken -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 99)
                Write-LogMessage -type Verbose -MSG "Updated owner `"$memberName`" to safe `"$SafeName`" successfully"
            }
            Catch {
                If ($($PSItem.ErrorDetails.Message | ConvertFrom-Json).ErrorCode -eq "SFWS0012") {
                    IF ($CreateOnMissing) {
                        Write-LogMessage -type Verbose -MSG "Owner `"$memberName`" on `"$SafeName`" doesn't exist, adding instead"
                        $splatParams = @{
                            PVWAURL                                = $PVWAURL
                            LogonToken                             = $LogonToken
                            SafeName                               = $SafeName
                            memberName                             = $memberName
                            memberType                             = $MemberType
                            membershipExpirationDate               = $membershipExpirationDate
                            useAccounts                            = $useAccounts
                            retrieveAccounts                       = $retrieveAccounts
                            listAccounts                           = $listAccounts
                            addAccounts                            = $addAccounts
                            updateAccountContent                   = $updateAccountContent
                            updateAccountProperties                = $updateAccountProperties
                            initiateCPMAccountManagementOperations = $initiateCPMAccountManagementOperations
                            specifyNextAccountContent              = $specifyNextAccountContent
                            renameAccounts                         = $renameAccounts
                            deleteAccounts                         = $deleteAccounts
                            unlockAccounts                         = $unlockAccounts
                            manageSafe                             = $manageSafe
                            manageSafeMembers                      = $manageSafeMembers
                            backupSafe                             = $backupSafe
                            viewAuditLog                           = $viewAuditLog
                            viewSafeMembers                        = $viewSafeMembers
                            accessWithoutConfirmation              = $accessWithoutConfirmation
                            createFolders                          = $createFolders
                            deleteFolders                          = $deleteFolders
                            moveAccountsAndFolders                 = $moveAccountsAndFolders
                            requestsAuthorizationLevel1            = $requestsAuthorizationLevel1
                            requestsAuthorizationLevel2            = $requestsAuthorizationLevel2
                        }
                        Add-SafeMember @splatParams
                    }
                    Else {
                        Write-LogMessage -type Warning -MSG "Owner `"$memberName`" on `"$SafeName`" does not exist, unable to set"
                    }
                }
                else {
                    Write-LogMessage -type Error -MSG "Failed to update Owner `"$memberName`" on `"$SafeName`" due to an error: $PSitem"
                    return
                }
            }
        }
        else {
            Write-LogMessage -type Warning -MSG "Skipping update of owner `"$memberName`" to safe `"$SafeName`""
        }
    }
}
#EndRegion '.\Public\PAS\SafeMember\Set-SafeMember.ps1' 174
#Region '.\Public\PAS\System Health\Get-CPMUser.ps1' -1

<#
.SYNOPSIS
Retrieves the list of Component User Names (CPMs) from the system health.

.DESCRIPTION
The Get-CPMUser function retrieves the list of Component User Names (CPMs) by calling the Get-SystemHealth cmdlet with the -CPM parameter. It logs the process of retrieving the list and returns the list of CPMs.

.PARAMETERS
None

.OUTPUTS
System.String[]
Returns an array of strings containing the Component User Names (CPMs).

.EXAMPLES
Example 1:
PS> Get-CPMUser
This example retrieves and returns the list of Component User Names (CPMs).
#>
function Get-CPMUser {
    [CmdletBinding()]
    param ()

    process {
        Write-LogMessage -type verbose -MSG "Getting list of CPMs"
        [string[]]$CPMList = (Get-SystemHealth -CPM).ComponentUserName
        Write-LogMessage -type verbose -MSG "Retrieved list of CPMs successfully: $($CPMList -join ', ')"
        return $CPMList
    }
}
#EndRegion '.\Public\PAS\System Health\Get-CPMUser.ps1' 31
#Region '.\Public\PAS\System Health\Get-SystemHealth.ps1' -1

<#
.SYNOPSIS
    Retrieves the system health status from the specified PVWA URL.

.DESCRIPTION
    The Get-SystemHealth function retrieves the health status of various components from the specified PVWA URL.
    It supports multiple parameter sets to get detailed health information for specific components or a summary of all components.

.PARAMETER PVWAURL
    The URL of the PVWA instance from which to retrieve the system health status.

.PARAMETER LogonToken
    The logon token used for authentication when making the API request.

.PARAMETER Summary
    Switch parameter to retrieve a summary of the system health status.

.PARAMETER CPM
    Switch parameter to retrieve the health status of the CPM component.

.PARAMETER PVWA
    Switch parameter to retrieve the health status of the PVWA component.

.PARAMETER PSM
    Switch parameter to retrieve the health status of the PSM component.

.PARAMETER PSMP
    Switch parameter to retrieve the health status of the PSMP component.

.PARAMETER PTA
    Switch parameter to retrieve the health status of the PTA component.

.PARAMETER AIM
    Switch parameter to retrieve the health status of the AIM component.

.EXAMPLE
    Get-SystemHealth -PVWAURL "https://example.com" -LogonToken $token -Summary

    Retrieves a summary of the system health status from the specified PVWA URL.

.EXAMPLE
    Get-SystemHealth -PVWAURL "https://example.com" -LogonToken $token -CPM

    Retrieves the health status of the CPM component from the specified PVWA URL.

.NOTES
    Author: Your Name
    Date: Today's Date
#>

Function Get-SystemHealth {
    [CmdletBinding(DefaultParameterSetName = 'Summary')]
    Param
    (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string] $PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [Parameter(ParameterSetName = "Summary")]
        [switch] $Summary,

        [Parameter(ParameterSetName = "CPM")]
        [switch] $CPM,

        [Parameter(ParameterSetName = "PVWA")]
        [switch] $PVWA,

        [Parameter(ParameterSetName = "PSM")]
        [switch] $PSM,

        [Parameter(ParameterSetName = "PSMP")]
        [switch] $PSMP,

        [Parameter(ParameterSetName = "PTA")]
        [switch] $PTA,

        [Parameter(ParameterSetName = "AIM")]
        [switch] $AIM
    )

    Begin {
        Write-LogMessage -Type Verbose -msg "Getting System Health"
    }

    Process {
        switch ($PSCmdlet.ParameterSetName) {
            'PVWA' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/PVWA/"
            }
            'PSM' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/SessionManagement/"
            }
            'PSMP' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/SessionManagement/"
            }
            'CPM' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/CPM/"
            }
            'PTA' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/PTA/"
            }
            'AIM' {
                $URL = "$PVWAURL/api/ComponentsMonitoringDetails/AIM/"
            }
            Default {
                $URL = "$PVWAURL/api/ComponentsMonitoringSummary/"
                return (Invoke-Rest -Command GET -Uri $URL -header $LogonToken).Components
            }
        }

        Try {
            $result = (Invoke-Rest -Command GET -Uri $URL -header $LogonToken).ComponentsDetails
        Write-LogMessage -Type Verbose -msg "Found $($result.ComponentsDetails.Count) $($PSCmdlet.ParameterSetName)"
            return $result
        } Catch {
            Write-LogMessage -Type Error -msg "Error Returned: $_"
        }
    }
}
#EndRegion '.\Public\PAS\System Health\Get-SystemHealth.ps1' 124
#Region '.\Public\PAS\User\Add-TestVaultUser.ps1' -1

<#
.SYNOPSIS
Creates a test vault user in the specified PVWA instance.

.DESCRIPTION
The Add-TestVaultUser function creates a test vault user with a predefined initial password and sets the user as disabled.
It requires the PVWA URL, a logon token, and the username of the user to be created.

.PARAMETER PVWAURL
The URL of the PVWA instance where the user will be created. This parameter is mandatory.

.PARAMETER LogonToken
The logon token used for authentication. This parameter is mandatory.

.PARAMETER User
The username of the test vault user to be created. This parameter is mandatory and can be provided via pipeline.

.PARAMETER Force
A switch parameter that can be used to force the operation. This parameter is optional.

.EXAMPLE
Add-TestVaultUser -PVWAURL "https://pvwa.example.com" -LogonToken $token -User "TestUser"

This example creates a test vault user named "TestUser" in the specified PVWA instance using the provided logon token.

.NOTES
The function logs verbose messages for the creation process and catches any errors that occur during the creation of the test vault user.
#>

function Add-TestVaultUser {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]$PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Member')]
        [string]$User
    )
    Begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
    }
    Process {
        Write-LogMessage -type Verbose -Message "Creating Test Vault User named `"$User`""
        $body = @{
            UserName        = $User
            InitialPassword = 'asdljhdsaldjl#@!321sadAS3144dcswafd'
            Disabled        = $true
        } | ConvertTo-Json -Depth 3
        $URL_AddVaultUser = "$PVWAURL/API/Users/"
        Try {
            Invoke-Rest -Command POST -Uri $URL_AddVaultUser -Header $LogonToken -Body $body
            Write-LogMessage -type Verbose -Message "Successfully created test vault user named `"$User`""
        }
        catch {
            Write-LogMessage -type Error -Message "Error creating Test Vault User named `"$User`""
        }
    }
}
#EndRegion '.\Public\PAS\User\Add-TestVaultUser.ps1' 66
#Region '.\Public\PAS\User\Get-VaultUser.ps1' -1

<#
.SYNOPSIS
    Retrieves all vault users from the specified PVWA URL.

.DESCRIPTION
    The Get-VaultUser function retrieves all vault users from the specified PVWA URL.
    It supports optional parameters to include extended details and component user information.

.PARAMETER PVWAURL
    The URL of the PVWA (Password Vault Web Access) API endpoint.

.PARAMETER LogonToken
    The logon token used for authentication with the PVWA API.

.PARAMETER componentUser
    A switch parameter to include component user information in the response.

.PARAMETER ExtendedDetails
    A switch parameter to include extended details in the response.

.EXAMPLE
    PS> Get-VaultUser -PVWAURL "https://pvwa.example.com" -LogonToken $token

.NOTES
    The function uses the Invoke-Rest function to send a GET request to the PVWA API endpoint.
    Ensure that the Invoke-Rest function is defined and available in the scope where this function is called.
#>

Function Get-VaultUser {
    Param
    (
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]$PVWAURL,

        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,

        [switch]$componentUser,
        [switch]$ExtendedDetails
    )

    Begin {
        # No need to handle $CatchAll as it's not used
    }

    Process {
        Write-LogMessage -type Verbose -MSG 'Getting all vault users'
        Write-LogMessage -type Verbose -MSG "ExtendedDetails=$ExtendedDetails"
        Write-LogMessage -type Verbose -MSG "componentUser=$componentUser"

        $URL_Users = "$PVWAURL/api/Users?ExtendedDetails=$($ExtendedDetails)&componentUser=$($componentUser)"
        return Invoke-Rest -Command GET -Uri $URL_Users -header $LogonToken
    }
}
#EndRegion '.\Public\PAS\User\Get-VaultUser.ps1' 57
#Region '.\Public\PAS\User\Remove-VaultUser.ps1' -1

<#
.SYNOPSIS
Removes a specified user from the vault.

.DESCRIPTION
The Remove-VaultUser function removes a specified user from the vault using the provided PVWA URL and logon token.
It supports confirmation prompts and can force removal without confirmation if specified.

.PARAMETER PVWAURL
The URL of the PVWA (Password Vault Web Access).

.PARAMETER LogonToken
The logon token used for authentication.

.PARAMETER User
The username of the vault user to be removed.

.PARAMETER Force
A switch to force the removal without confirmation.

.EXAMPLE
Remove-VaultUser -PVWAURL "https://vault.example.com" -LogonToken $token -User "jdoe"

.EXAMPLE
Remove-VaultUser -PVWAURL "https://vault.example.com" -LogonToken $token -User "jdoe" -Force

.NOTES
This function requires the Get-VaultUsers and Invoke-Rest functions to be defined elsewhere in the script or module.
#>

function Remove-VaultUser {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        [Switch]$Force,
        [Parameter(Mandatory)]
        [Alias('url', 'PCloudURL')]
        [string]$PVWAURL,
        [Parameter(Mandatory)]
        [Alias('header')]
        $LogonToken,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ValueFromPipeline)]
        [Alias('Member')]
        [string]$User
    )
    begin {
        $PSBoundParameters.Remove("CatchAll") | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        $vaultUsers = Get-VaultUsers -url $PVWAURL -logonToken $LogonToken
        $vaultUserHT = @{}
        $vaultUsers.users | ForEach-Object {
            try {
                $username = if ($_.username.Length -le 28) { $_.username } else { $_.username.Substring(0, 28) }
                Write-LogMessage -type verbose -MSG "Adding username `"$username`" with ID `"$($_.ID)`" to hashtable"
                $vaultUserHT[$username] = $_.ID
            }
            catch {
                Write-Error "Error on $item"
                Write-Error $_
            }
        }
    }
    process {
        Write-LogMessage -type Verbose -MSG "Removing Vault User named `"$User`""
        $ID = $vaultUserHT[$User]
        if ([string]::IsNullOrEmpty($ID)) {
            Write-LogMessage -type Error "No ID located for $User"
            return
        }
        else {
            Write-LogMessage -type Verbose -MSG "Vault ID for `"$User`" is `"$ID`""
            if ($PSCmdlet.ShouldProcess($User, 'Remove-VaultUser')) {
                Write-LogMessage -type verbose -MSG 'Confirmation to remove received, proceeding with removal'
                try {
                    $URL_DeleteVaultUser = "$PVWAURL/API/Users/$ID/"
                    Invoke-Rest -Command DELETE -Uri $URL_DeleteVaultUser -header $LogonToken
                    Write-LogMessage -type Info -MSG "Removed user with the name `"$User`" from the vault successfully"
                }
                catch {
                    Write-LogMessage -type Error -MSG 'Error removing Vault Users'
                    Write-LogMessage -type Error -MSG $_
                }
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of user `"$User`" due to confirmation being denied"
            }
        }
    }
}
#EndRegion '.\Public\PAS\User\Remove-VaultUser.ps1' 94
#Region '.\Public\Shared\Add-BaseQueryParameter.ps1' -1

<#
.SYNOPSIS
Adds base query parameters to a URL.

.DESCRIPTION
The Add-BaseQueryParameter function appends various query parameters to a given URL.
It supports parameters such as sort, offset, limit, and useCache. It also logs the
actions performed at each step.

.PARAMETER URL
[ref] The URL to which the query parameters will be added.

.PARAMETER sort
(Optional) The sort parameter to be appended to the URL.

.PARAMETER offset
(Optional) The offset parameter to be appended to the URL.

.PARAMETER limit
(Optional) The limit parameter to be appended to the URL.

.PARAMETER DoNotPage
(Optional) If specified, indicates that paging is disabled.

.PARAMETER useCache
(Optional) If specified, indicates that session cache should be used for results.

.EXAMPLE
$URL = [ref] "http://example.com/api/resource"
Add-BaseQueryParameter -URL $URL -sort "name" -offset 10 -limit 50 -useCache

This example adds the sort, offset, limit, and useCache parameters to the given URL.

.NOTES
This function requires the Write-LogMessage function to be defined for logging purposes.
#>
function Add-BaseQueryParameter {
    param (
        [ref]$URL,
        [string]$sort,
        [string]$offset,
        [string]$limit,
        [switch]$DoNotPage,
        [switch]$useCache
    )

    Write-LogMessage -type Verbose -MSG "Adding Base Query Parameters"

    if (-not [string]::IsNullOrEmpty($sort)) {
        $URL.Value += "&sort=$sort"
        Write-LogMessage -type Verbose -MSG "Applying a sort of `"$sort`""
    }

    if (-not [string]::IsNullOrEmpty($offset)) {
        $URL.Value += "&offset=$offset"
        Write-LogMessage -type Verbose -MSG "Applying an offset of `"$offset`""
    }

    if (-not [string]::IsNullOrEmpty($limit)) {
        $URL.Value += "&limit=$limit"
        Write-LogMessage -type Verbose -MSG "Applying a limit of `"$limit`""
    }

    if ($DoNotPage) {
        Write-LogMessage -type Verbose -MSG "Paging is disabled."
    }

    if ($useCache) {
        $URL.Value += "&useCache=true"
        Write-LogMessage -type Verbose -MSG "Using session cache for results"
    }

    Write-LogMessage -type Verbose -MSG "New URL: $($URL.Value)"
}
#EndRegion '.\Public\Shared\Add-BaseQueryParameter.ps1' 75
#Region '.\Public\Shared\New-Session.ps1' -1

<#
.SYNOPSIS
Creates a new session for connecting to CyberArk environments.

.DESCRIPTION
The New-Session function establishes a new session for connecting to CyberArk environments, including PVWA and Privileged Cloud. It supports multiple parameter sets for different connection scenarios and handles credentials securely.

.PARAMETER Username
Specifies the username to connect with as a string. This parameter is used in the 'PVWAURL', 'PCloudSubdomain', and 'PCloudURL' parameter sets.

.PARAMETER Password
Specifies the password to connect with, stored as a SecureString. This parameter is used in the 'PVWAURL', 'PCloudSubdomain', and 'PCloudURL' parameter sets.

.PARAMETER Creds
Specifies the credentials stored as PSCredentials. This parameter is used in the 'PVWAURL', 'PCloudSubdomain', and 'PCloudURL' parameter sets.

.PARAMETER PVWAURL
Specifies the URL to the PVWA. This parameter is mandatory in the 'PVWAURL' parameter set.

.PARAMETER PCloudURL
Specifies the URL to the Privileged Cloud. This parameter is mandatory in the 'PCloudURL' parameter set.

.PARAMETER PCloudSubdomain
Specifies the subdomain for the Privileged Cloud. This parameter is mandatory in the 'PCloudSubdomain' parameter set.

.PARAMETER IdentityURL
Specifies the URL for CyberArk Identity. This parameter is used in the 'PCloudURL' and 'PCloudSubdomain' parameter sets.

.PARAMETER OAuthCreds
Specifies the OAuth credentials stored as PSCredentials. This parameter is used in the 'PCloudURL' and 'PCloudSubdomain' parameter sets.

.PARAMETER LogFile
Specifies the log file name. The default value is ".\Log.Log".

.EXAMPLE
New-Session -Username "admin" -Password (ConvertTo-SecureString "password" -AsPlainText -Force) -PVWAURL "https://pvwa.example.com"

.EXAMPLE
New-Session -Creds (Get-Credential) -PCloudURL "https://cloud.example.com" -IdentityURL "https://identity.example.com"

.NOTES
This function sets default parameter values for subsequent commands in the session, including logon tokens and URLs.
#>

function New-Session {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Used to create a new session')]
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Alias("IdentityUserName", "PVWAUsername")]
        [string] $Username,

        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [securestring] $Password,

        [Parameter(ParameterSetName = 'PVWAURL')]
        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("PVWACreds", "IdentityCreds")]
        [pscredential] $Creds,

        [Parameter(ParameterSetName = 'PVWAURL', Mandatory)]
        [string] $PVWAURL,

        [Parameter(ParameterSetName = 'PCloudURL', Mandatory)]
        [string] $PCloudURL,

        [Parameter(ParameterSetName = 'PCloudSubdomain', Mandatory)]
        [string] $PCloudSubdomain,

        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [Alias("IdentityTenantURL")]
        [string] $IdentityURL,

        [Parameter(ParameterSetName = 'PCloudURL')]
        [Parameter(ParameterSetName = 'PCloudSubdomain')]
        [pscredential] $OAuthCreds,

        [string] $LogFile = ".\Log.Log"
    )

    begin {
        $PSDefaultParameterValues["*:LogFile"] = $LogFile

        function Get-PCLoudLogonHeader {
            param (
                [Parameter(ValueFromRemainingArguments, DontShow)] $CatchAll,
                [Alias("IdentityURL")] [string] $IdentityTenantURL,
                [Alias("Username")] [string] $IdentityUserName,
                [Alias("Creds")] [pscredential] $UPCreds,
                [pscredential] $OAuthCreds
            )
            $PSBoundParameters.Remove("CatchAll") | Out-Null
            return Get-IdentityHeader @PSBoundParameters
        }

        function Get-OnPremLogonHeader {
            param (
                [Parameter(ValueFromRemainingArguments, DontShow)] $CatchAll,
                [string] $PVWAURL,
                [string] $Username,
                [Alias("Creds")] [pscredential] $PVWACreds
            )
            $PSBoundParameters.Remove("CatchAll") | Out-Null
            return Get-IdentityHeader @PSBoundParameters
        }

        if ($Password) {
            $PSBoundParameters["Creds"] = [pscredential]::new($Username, $Password)
            $null = $PSBoundParameters.Remove("Username")
            $null = $PSBoundParameters.Remove("Password")
        }

        try {
            switch ($PSCmdlet.ParameterSetName) {
                'PCloudSubdomain' {
                    $logonToken = Get-PCLoudLogonHeader @PSBoundParameters
                    $PSDefaultParameterValues["*:LogonToken"] = $logonToken
                    $PSDefaultParameterValues["*:PVWAURL"] = "https://$PCloudSubdomain.privilegecloud.cyberark.cloud/PasswordVault/"
                    $PSDefaultParameterValues["*:IdentityURL"] = $IdentityURL
                }
                'PCloudURL' {
                    $logonToken = Get-PCLoudLogonHeader @PSBoundParameters
                    $PSDefaultParameterValues["*:LogonToken"] = $logonToken
                    $PSDefaultParameterValues["*:PVWAURL"] = $PCloudURL
                    $PSDefaultParameterValues["*:IdentityURL"] = $IdentityURL
                }
                'PVWAURL' {
                    $PSDefaultParameterValues["*:LogonToken"] = Get-OnPremLogonHeader @PSBoundParameters
                    $PSDefaultParameterValues["*:PVWAURL"] = $PVWAURL
                }
            }
        }
        catch {
            Write-LogMessage -type Error -MSG "Unable to establish a connection to CyberArk"
            return
        }

        Set-Variable -Name PSDefaultParameterValues -Scope 2 -Value $PSDefaultParameterValues

        try {
            [string[]] $CPMUser = Get-CPMUser
            $PSDefaultParameterValues["*:CPMUser"] = $CPMUser
            Set-Variable -Name PSDefaultParameterValues -Scope 2 -Value $PSDefaultParameterValues
        }
        catch {
            Write-LogMessage -type Warning -MSG "Unable to retrieve list of CPMs, the connection was made with a restricted user and not all commands may work"
        }
    }
}
#EndRegion '.\Public\Shared\New-Session.ps1' 156
#Region '.\Public\Shared\Write-LogMessage - orginal.ps1' -1

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

# Original version of the Write-LogMessage function
Function Write-LogMessage-OLD {
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
#EndRegion '.\Public\Shared\Write-LogMessage - orginal.ps1' 170
#Region '.\Public\Shared\Write-LogMessage.ps1' -1

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
#EndRegion '.\Public\Shared\Write-LogMessage.ps1' 232

