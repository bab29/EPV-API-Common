function Get-SafeMember {
    [CmdletBinding(DefaultParameterSetName = "SafeName")]
    param (
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $CatchAll,
        
        [parameter(Mandatory = $False)]
        [Switch]
        $PassThru,
        
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
        [validateSet("User", "Group")]
        [string]
        $memberType,

        [Parameter(ParameterSetName = 'Search')]
        [validateSet("True", "False")]
        [string]
        $membershipExpired,

        [Parameter(ParameterSetName = 'Search')]
        [validateSet("True", "False")]
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
        [ValidateSet("asc,desc")]
        [string]
        $sort


    )
    Begin {
        $PSBoundParameters.Remove("CatchAll")  | Out-Null
    }
    process {
        IF ([string]::IsNullOrEmpty($SafeName)) {
            Write-LogMessage -type Error -Msg "No Safe Name provided"
            Return
        }

        If (-not [string]::IsNullOrEmpty($memberName)) {
            $SafeMemberURL = "$PVWAURL/API/Safes/{0}/Members/{1}/" -f $SafeName, $memberName
            Write-LogMessage -type Verbose -MSG "Getting `"memberName`" permissions for safe `"$SafeName`"" 
            Return Invoke-Rest -Uri $SafeMemberURL -Method GET -Headers $logonToken -ContentType 'application/json'
        }
        else {
            $SafeMemberURL = "$PVWAURL/API/Safes/{0}/Members/?" -f $SafeName
            Write-LogMessage -type Verbose -MSG "Getting owners permissions for safe `"$SafeName`"" 
            
            $filterList = @()
            IF (-not [string]::IsNullOrEmpty($memberType)) {
                $filterList += "memberType eq $memberType"
            }
            IF (-not [string]::IsNullOrEmpty($membershipExpired)) {
                $filterList += "membershipExpired eq $membershipExpired"
            }
            IF (-not [string]::IsNullOrEmpty($includePredefinedUsers)) {
                $filterList += "includePredefinedUsers eq $includePredefinedUsers"
            }
            if (0 -lt $filterList.count) {
                $filter = $filterList -join " AND "
                $SafeMemberURL = $SafeMemberURL + "filter=" + $filter
                Write-LogMessage -type Verbose -MSG "Applying a filter of `"$filter`""
            }
            IF (-not [string]::IsNullOrEmpty($Search)) {
                $SafeMemberURL = $SafeMemberURL + "&search=$search"
                Write-LogMessage -type Verbose -MSG "Applying a search of `"$search`""
            }
            IF (-not [string]::IsNullOrEmpty($offset)) {
                $SafeMemberURL = $SafeMemberURL + "&offset=$offset"
                Write-LogMessage -type Verbose -MSG "Applying a offset of `"$offset`""
            }
            IF (-not [string]::IsNullOrEmpty($limit)) {
                $SafeMemberURL = $SafeMemberURL + "&limit=$limit"
                Write-LogMessage -type Verbose -MSG "Applying a limit of `"$limit`""
            }
            IF (-not [string]::IsNullOrEmpty($sort)) {
                $SafeMemberURL = $SafeMemberURL + "&sort=$sort"
                Write-LogMessage -type Verbose -MSG "Applying a sort of `"$sort`""
            }
            If ($DoNotPage) {
                Write-LogMessage -type Verbose -MSG "Paging is disabled."
            }

            $restResponse = Invoke-Rest -Uri $SafeMemberURL -Method GET -Headers $logonToken -ContentType 'application/json'

            [pscustomobject[]]$memberList = $restResponse.value

            IF (-not [string]::IsNullOrEmpty($restResponse.NextLink)) {
                If ($DoNotPage) {
                    Write-LogMessage -type Verbose -MSG "A total of $($memberList.Count) members found, but paging is disabled. Returning only $($memberList.count) mmebers"
                }
                else {
                    Do {
                        Write-LogMessage -type Verbose -MSG "NextLink found, getting next page"
                        $restResponse = Invoke-Rest -Uri "$PVWAURL/$($restResponse.NextLink)" -Method GET -Headers $logonToken -ContentType 'application/json'
                        $memberList += $restResponse.value
                    } 
                    until ([string]::IsNullOrEmpty($($restResponse.NextLink)))
                }
            }
            else {
                Write-LogMessage -type Verbose -MSG "Found $($memberList.Count) members"
            }
            return $memberList
        }
    }
}
