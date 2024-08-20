
Class SafeMember {
    [string]$safeUrlId
    [string]$safeName
    [string]$safeNumber
    [string]$memberId
    [string]$memberName
    [string]$memberType
    [string]$membershipExpirationDate
    [string]$isExpiredMembershipEnable
    [string]$isPredefinedUser
    [string]$isReadOnly
    [PSCustomObject]$permissions

    SafeMember() {
    }

    SafeMember([pscustomobject]$PSCustom) {
        $This.SetValues($PSCustom)
    }
    hidden [void] SetValues([pscustomobject]$PSCustom) {
        $This.ClearValues()
        foreach ($Property in $PSCustom.psobject.properties.name) {
            if ([bool]($this.PSobject.Properties.name.ToLower() -eq $Property.ToLower())) {
                $this.$Property = $PSCustom.$Property
            }
        }
    }
    hidden [void] ClearValues() {
        foreach ($Property in $This.psobject.properties.name) {
            Try {
                $this.$Property = $null
            }
            Catch [System.Management.Automation.SetValueInvocationException] {
                If ($PSitem -match 'System.DateTime') {
                    Try {
                        $this.$Property = [DateTime]::MinValue
                    }
                    catch {
                        $this.$Property = 0
                    }
                }
                elseIf ($PSitem -match 'System.Double') {
                    $this.$Property = 0
                }
                else {
                    Throw
                }
            }
        }
    }
}