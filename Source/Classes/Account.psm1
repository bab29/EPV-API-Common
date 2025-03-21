Using Module .\Base.psm1

Class RemoteMachinesAccess : Base {
    [string]$remoteMachinesAccess
    [bool]$accessRestrictedToRemoteMachines
    hidden[string[]]$_remoteMachines
    

    RemoteMachinesAccess([pscustomobject]$PSCustom) {
        $this.ReplaceGetSetRemoteMachine()
        $this.SetValues($PSCustom)
    }
    RemoteMachinesAccess() {
        $this.ReplaceGetSetRemoteMachine()
    }

    hidden [void] SetValues([pscustomobject]$PSCustom) {
        $this.ClearValues()
        foreach ($Property in $PSCustom.psobject.properties.name) {
            if ($this.PSobject.Properties.name -contains $Property) {
                If ("remoteMachines" -eq $Property) {
                    $this.$Property = $PSCustom.$Property.Split(";")
                } else {
                    $this.$Property = $PSCustom.$Property
                }
            } else {
                Write-Error "Property $Property with type $($Property.GetType().Name) not found in $($this.GetType().Name) "
            }
        }
    }
    hidden [void] ReplaceGetSetRemoteMachine() {
        $this | Add-Member -Name remoteMachines -MemberType ScriptProperty -Value {
            return $this._remoteMachines -join ";"
        } -SecondValue {
            param($value)
            $this._remoteMachines = $value
        }
    }
}


Class secretManagement : Base {
    [bool]$automaticManagementEnabled
    [string]$status
    [string]$lastModifiedTime
    [string]$lastReconciledTime
    [string]$lastVerifiedTime
    [string]$manualManagementReason

    secretManagement([pscustomobject]$PSCustom) : Base([pscustomobject]$PSCustom) {}
}
Class Account : Base {
    [string]$id
    [string]$name
    [string]$address
    [string]$username
    [string]$platformId
    [string]$safeName
    [string]$secretType
    hidden [string]$secret
    [PSCustomObject]$platformAccountProperties
    [secretManagement]$secretManagement
    [RemoteMachinesAccess]$remoteMachinesAccess
    [string]$createdTime
    [string]$CategoryModificationTime
    [PSCustomObject]$LinkedAccounts

    Account() {}

    Account([pscustomobject]$PSCustom) : Base([pscustomobject]$PSCustom) {}

    hidden [void] SetValues([string]$Property, [string]$Value) {
        $this.$Property = $Value
        }
}
