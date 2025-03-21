# Tests/Public/PAS/Safe/Get-Safe.Tests.ps1

# Import the module containing the functions to be tested
Import-Module EPV-API-Common
Import-Module -Name "$PSScriptRoot/../../../Source/Public/PAS/Safe/Get-Safe.ps1"

Describe 'Get-Safe' {
    Mock -CommandName 'Invoke-Rest' -MockWith {
        return [PSCustomObject]@{ Name = 'Safe1' }
    }
    Mock -CommandName 'Invoke-RestNextLink' -MockWith {
        return @(
            [PSCustomObject]@{ Name = 'Safe1' }
            [PSCustomObject]@{ Name = 'Safe2' }
        )
    }
    Mock -CommandName 'Write-LogMessage'

    It 'should call Get-SafeViaID when SafeUrlId is provided' {
        $PVWAURL = 'https://example.com'
        $LogonToken = 'dummyToken'
        $SafeUrlId = '12345'
        $result = Get-Safe -PVWAURL $PVWAURL -LogonToken $LogonToken -SafeUrlId $SafeUrlId

        Assert-MockCalled -CommandName 'Invoke-Rest' -Exactly 1 -Scope It -ParameterFilter {
            $Uri -eq 'https://example.com/API/Safes/12345/?' -and
            $Method -eq 'GET' -and
            $Headers -eq 'dummyToken' -and
            $ContentType -eq 'application/json'
        }
    }

    It 'should call Get-SafeViaPlatformID when PlatformID is provided' {
        $PVWAURL = 'https://example.com'
        $LogonToken = 'dummyToken'
        $PlatformID = 'Platform1'
        $SafeName = 'MySafe'
        $result = Get-Safe -PVWAURL $PVWAURL -LogonToken $LogonToken -PlatformID $PlatformID -SafeName $SafeName

        Assert-MockCalled -CommandName 'Invoke-RestNextLink' -Exactly 1 -Scope It -ParameterFilter {
            $Uri -eq 'https://example.com/API/Platforms/Platform1/Safes/MySafe/?' -and
            $Method -eq 'GET' -and
            $Headers -eq 'dummyToken' -and
            $ContentType -eq 'application/json'
        }
    }

    It 'should call Get-SafeViaQuery when no specific parameters are provided' {
        $PVWAURL = 'https://example.com'
        $LogonToken = 'dummyToken'
        $result = Get-Safe -PVWAURL $PVWAURL -LogonToken $LogonToken

        Assert-MockCalled -CommandName 'Invoke-RestNextLink' -Exactly 1 -Scope It -ParameterFilter {
            $Uri -eq 'https://example.com/API/Safes/?' -and
            $Method -eq 'GET' -and
            $Headers -eq 'dummyToken' -and
            $ContentType -eq 'application/json'
        }
    }

    It 'should return the expected result' {
        $PVWAURL = 'https://example.com'
        $LogonToken = 'dummyToken'
        $result = Get-Safe -PVWAURL $PVWAURL -LogonToken $LogonToken

        $result | Should -BeOfType 'PSCustomObject[]'
        $result.Count | Should -Be 2
        $result[0].Name | Should -Be 'Safe1'
        $result[1].Name | Should -Be 'Safe2'
    }
}

Describe 'Add-SafeQueryParameter' {
    Mock -CommandName 'Write-LogMessage'

    It 'should append includeAccounts parameter to URL' {
        $global:includeAccounts = $true
        $URL = [ref] 'https://example.com/API/Safes/?'
        Add-SafeQueryParameter -URL $URL

        $URL.Value | Should -Be 'https://example.com/API/Safes/?&includeAccounts=true'
        Assert-MockCalled -CommandName 'Write-LogMessage' -Exactly 1 -Scope It -ParameterFilter {
            $type -eq 'Verbose' -and
            $MSG -eq 'Including accounts in results'
        }
    }

    It 'should append extendedDetails parameter to URL' {
        $global:ExtendedDetails = $true
        $URL = [ref] 'https://example.com/API/Safes/?'
        Add-SafeQueryParameter -URL $URL

        $URL.Value | Should -Be 'https://example.com/API/Safes/?&extendedDetails=true'
        Assert-MockCalled -CommandName 'Write-LogMessage' -Exactly 1 -Scope It -ParameterFilter {
            $type -eq 'Verbose' -and
            $MSG -eq 'Including extended details'
        }
    }

    It 'should append search parameter to URL' {
        $global:Search = 'testSearch'
        $URL = [ref] 'https://example.com/API/Safes/?'
        Add-SafeQueryParameter -URL $URL

        $URL.Value | Should -Be 'https://example.com/API/Safes/?&search=testSearch'
        Assert-MockCalled -CommandName 'Write-LogMessage' -Exactly 1 -Scope It -ParameterFilter {
            $type -eq 'Verbose' -and
            $MSG -eq 'Applying a search of "testSearch"'
        }
    }
}
