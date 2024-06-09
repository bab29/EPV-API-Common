Import-Module C:\GIT\EPV-API-Common\Output\EPV-API-Common\EPV-API-Common.psm1 -Force
Import-Module C:\GIT\EPV-API-Common\Source\Public\Identity\Authentication\IdentityAuth.psm1 -force
Convert-Breakpoint

$userName = "bbors-rest"
$password = 'wx#A]TM+&7pq|+Yze.VIz|\}_h?XIpDfMUIM{!@N' | ConvertTo-SecureString -AsPlainText -Force
$UP = [pscredential]::new($userName , $password )
$PCloudURL = "https://servicesmig.privilegecloud.cyberark.cloud/PasswordVault/"
$identityURL = "https://aba4229.id.cyberark.cloud"
new-Session -Username $username -Password $password -IdentityURL $identityURL -PCloudURL $PCloudURL -LogFile ".\ThisFile.log"
$test = get-Safe -Verbose
$test = get-Safe
