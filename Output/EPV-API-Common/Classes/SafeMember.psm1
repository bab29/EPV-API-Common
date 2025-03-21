
# Class: SafeMember
# This class represents a member with various properties and methods to manage its values.
#
# Properties:
# - [string]$safeUrlId: The safe URL ID of the member.
# - [string]$safeName: The safe name of the member.
# - [string]$safeNumber: The safe number of the member.
# - [string]$memberId: The ID of the member.
# - [string]$memberName: The name of the member.
# - [string]$memberType: The type of the member.
# - [string]$membershipExpirationDate: The expiration date of the membership.
# - [string]$isExpiredMembershipEnable: Indicates if expired membership is enabled.
# - [string]$isPredefinedUser: Indicates if the user is predefined.
# - [string]$isReadOnly: Indicates if the member is read-only.
# - [PSCustomObject]$permissions: The permissions associated with the member.
#
# Constructors:
# - SafeMember(): Initializes a new instance of the SafeMember class.
# - SafeMember([pscustomobject]$PSCustom): Initializes a new instance of the SafeMember class and sets its values based on the provided PSCustomObject.
#
# Methods:
# - [void] SetValues([pscustomobject]$PSCustom): Sets the values of the member properties based on the provided PSCustomObject.
# - [void] ClearValues(): Clears the values of the member properties, setting them to null or their default values.
Using Module .\Base.psm1

Class SafeMember : Base {
    Hidden [string]$safeUrlId
    Hidden [string]$safeName
    Hidden [string]$safeNumber
    [string]$memberId
    [string]$memberName
    [string]$memberType
    [string]$membershipExpirationDate
    [string]$isExpiredMembershipEnable
    [string]$isPredefinedUser
    [string]$isReadOnly
    [SafePerms]$permissions
    hidden [string]$searchIn

    SafeMember() {
    }

    SafeMember([pscustomobject]$PSCustom) : Base([pscustomobject]$PSCustom) {
    }
}

Class SafePerms : base {

    [bool]$listAccounts
    [bool]$UseAccounts
    [bool]$retrieveAccounts
    [bool]$addAccounts
    [bool]$updateAccountProperties
    [bool]$updateAccountContent
    [bool]$initiateCPMAccountManagementOperations
    [bool]$specifyNextAccountContent
    [bool]$renameAccounts
    [bool]$deleteAccounts
    [bool]$unlockAccounts
    [bool]$manageSafe
    [bool]$viewSafeMembers
    [bool]$manageSafeMembers
    [bool]$viewAuditLog
    [bool]$backupSafe
    [bool]$requestsAuthorizationLevel1
    [bool]$requestsAuthorizationLevel2
    [bool]$accessWithoutConfirmation
    [bool]$moveAccountsAndFolders
    [bool]$createFolders
    [bool]$deleteFolders

    SafePerms() {
    }

    SafePerms([pscustomobject]$PSCustom) : Base([pscustomobject]$PSCustom) {
    }
}
