
function Remove-IdentityUser {
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
    ) begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
        if ($Force -and -not $Confirm) {
            Write-LogMessage -type Warning -MSG 'Confirmation prompt suppressed, proceeding with all removals'
            $ConfirmPreference = 'None'
        }
        [string[]]$userList = @()
        [string[]]$userNames = @()
    }
    process {
        $userID = Get-IdentityUser @PSBoundParameters
        IF ([string]::IsNullOrEmpty($userID)) {
            If ([string]::IsNullOrEmpty($user) -and [string]::IsNullOrEmpty($user)) {
                Write-LogMessage -type Warning -MSG 'Username or mail not provided'
                Return
            }
            elseif (![string]::IsNullOrEmpty($user) -and [string]::IsNullOrEmpty($user)) {
                Write-LogMessage -type Warning -MSG "User `"$user`" not found"
                Return
            }
            elseif ([string]::IsNullOrEmpty($user) -and ![string]::IsNullOrEmpty($user)) {
                Write-LogMessage -type Warning -MSG "Mail `"$mail`" Not Found"
                Return
            }
            else {
                Write-LogMessage -type Warning -MSG "User `"$user`" or mail `"$mail`" not found"
                Return
            }
        }
        Write-LogMessage -type Info -MSG "A total of $($userID.Count) user accounts found"
        $userID | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($PSItem.SystemName, 'Remove-IdentityUser')) {
                $userNames += [string]$($PSItem.SystemName)
                $userList += [string]$($PSItem.InternalName)
            }
            else {
                Write-LogMessage -type Warning -MSG "Skipping removal of Identity User `"$user`" due to confimation being denied"
            }
        }
    }
    end {
        Try {
            IF (0 -eq $userList.count) {
                Write-LogMessage -type Warning -MSG 'No accounts found to delete'
                Return
            }
            $UserJson = [pscustomobject]@{Users = $userList }
            $result = Invoke-Rest -Uri "$IdentityURL/UserMgmt/RemoveUsers" -Method POST -Headers $LogonToken -ContentType 'application/json' -Body $($UserJson | ConvertTo-Json -Depth 99)
            If ([bool]$result.success) {
                If (0 -ne $result.Result.Exceptions.User.count) {
                    Write-LogMessage -type Error -MSG 'Users failed to remove, no logs given'
                }
                else {
                    Write-LogMessage -type Info -MSG "The following Users removed succesfully:`n$usernames"
                }
            }
        }
        catch {
            Write-LogMessage -type Error -MSG "Error removing users:`n$PSitem"
        }
    }
}