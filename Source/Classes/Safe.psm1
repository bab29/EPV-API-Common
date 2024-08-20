
Class Safe {

    [string]$SafeName
    [String]$safeUrlId
    [String]$autoPurgeEnabled
    [string]$creationTime
    [pscustomobject]$creator
    [string]$description
    [string]$isExpiredMember
    [string]$lastModificationTime
    [string]$location
    [string]$managingCPM
    [string]$numberOfDaysRetention
    [string]$numberOfVersionsRetention
    [string]$olacEnabled
    [string]$safeNumber
    [pscustomobject]$accounts


    Report() {
        $this | Export-Csv -Path C:\GIT\EPV-API-Common\SafeClassSafe.csv -Append
    }

    Safe() {
    }

    Safe([pscustomobject]$PSCustom) {
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