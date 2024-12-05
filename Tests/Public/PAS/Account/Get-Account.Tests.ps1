# Tests/Public/PAS/Account/Get-Account.Tests.ps1

# Import the module containing the functions to be tested
Import-Module EPV-API-Common
Import-Module -Name "$PSScriptRoot/../../../Source/Public/PAS/Account/Get-Account.ps1"

Describe 'Get-ViaQuery' {
    Mock -CommandName 'Invoke-RestNextLink' -MockWith {
        return @(
            [PSCustomObject]@{ Name = 'Account1' }
            [PSCustomObject]@{ Name = 'Account2' }
        )
    }

    It 'should call Invoke-RestNextLink with the correct URL and headers' {
        $logonToken = 'dummyToken'
        $AccountURL = 'https://example.com/api/accounts'
        $result = Get-ViaQuery

        Assert-MockCalled -CommandName 'Invoke-RestNextLink' -Exactly 1 -Scope It -ParameterFilter {
            $Uri -eq 'https://example.com/api/accounts' -and
            $Method -eq 'GET' -and
            $Headers -eq 'dummyToken' -and
            $ContentType -eq 'application/json'
        }
    }

    It 'should return the expected result' {
        $result = Get-ViaQuery
        $result | Should -BeOfType 'PSCustomObject[]'
        $result.Count | Should -Be 2
        $result[0].Name | Should -Be 'Account1'
        $result[1].Name | Should -Be 'Account2'
    }
}

Describe 'Add-QueryParameter' {
    Mock -CommandName 'Write-LogMessage'

    It 'should append search parameter to URL' {
        $global:Search = 'testSearch'
        $URL = [ref] 'https://example.com/api/accounts'
        Add-QueryParameter -URL $URL

        $URL.Value | Should -Be 'https://example.com/api/accounts&search=testSearch'
        Assert-MockCalled -CommandName 'Write-LogMessage' -Exactly 1 -Scope It -ParameterFilter {
            $type -eq 'Verbose' -and
            $MSG -eq 'Applying a search of "testSearch"'
        }
    }

    It 'should append searchType parameter to URL' {
        $global:SearchType = 'testSearchType'
        $URL = [ref] 'https://example.com/api/accounts'
        Add-QueryParameter -URL $URL

        $URL.Value | Should -Be 'https://example.com/api/accounts&searchType=testSearchType'
        Assert-MockCalled -CommandName 'Write-LogMessage' -Exactly 1 -Scope It -ParameterFilter {
            $type -eq 'Verbose' -and
            $MSG -eq 'Applying a search type of "testSearchType"'
        }
    }

    It 'should append savedfilter parameter to URL' {
        $global:savedfilter = 'testSavedFilter'
        $URL = [ref] 'https://example.com/api/accounts'
        Add-QueryParameter -URL $URL

        $URL.Value | Should -Be 'https://example.com/api/accounts&savedfilter=testSavedFilter'
        Assert-MockCalled -CommandName 'Write-LogMessage' -Exactly 1 -Scope It -ParameterFilter {
            $type -eq 'Verbose' -and
            $MSG -eq 'Applying a savedfilter of "testSavedFilter"'
        }
    }

    It 'should append filter parameter to URL' {
        $global:filter = 'testFilter'
        $URL = [ref] 'https://example.com/api/accounts'
        Add-QueryParameter -URL $URL

        $URL.Value | Should -Be 'https://example.com/api/accounts&filter=testFilter'
        Assert-MockCalled -CommandName 'Write-LogMessage' -Exactly 1 -Scope It -ParameterFilter {
            $type -eq 'Verbose' -and
            $MSG -eq 'Applying a filter of "testFilter"'
        }
    }
}
