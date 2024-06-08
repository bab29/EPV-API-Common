function Remove-IdentityUser {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [Switch]$Force,
        [Alias('url')]
        [string]
        $IdentityURL,
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
        Set-Globals
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
