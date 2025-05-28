<#
.SYNOPSIS
Automates the process of terminating a user's account in Active Directory and clearing memberof and attributes.
.DESCRIPTION
This script performs the following actions to terminate a user's account in Active Directory:
- Clears the manager attribute of the user.
- Removes the user from all group memberships.
- Moves the user to a specified OU (Marked for Deletion).
- Disables the user account.
- Logs the date and time of termination.
- Updates the user's description with the termination date and time.
.PARAMETER upn
The User Principal Name (UPN) of the account to be disabled.
.PARAMETER targetOU
The target Organizational Unit (OU) where the user account will be moved. Default is $targetOU = "OU HERE".
#>
param (
    [string]$upn,
    [string]$targetOU = "OU HERE"
)

Import-Module ActiveDirectory

# Get the current date and time
$ExecutionDateTime = Get-Date

# Function to clear the manager attribute
function Clear-Manager {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$upn
    )

    # Log the UPN being processed
    Write-Output "Processing UPN: $upn"

    # Attempt to get the user from Active Directory
    try {
        $user = Get-ADUser -Filter "UserPrincipalName -eq '$upn'" -ErrorAction Stop
    } catch {
        Write-Output "Error retrieving user with UPN '$upn': $_"
        return
    }

    # Check if the user was found
    if ($null -eq $user) {
        Write-Output "The user with UPN '$upn' does not exist in Active Directory."
        return
    }

    # Attempt to clear the manager attribute
    try {
        Set-ADUser -Identity $user.DistinguishedName -Clear Manager -ErrorAction Stop
        Write-Output "Cleared the manager for $upn"
    } catch {
        Write-Output "Error clearing manager for user with UPN '$upn': $_"
    }
}

# Function to disable a user
function Disable-UserAccount {
    param (
        [string]$upn,
        [string]$targetOU
    )

    $user = Get-ADUser -Filter "UserPrincipalName -eq '$upn'" -Property Description, Manager, UserPrincipalName -ErrorAction SilentlyContinue
    if ($null -eq $user) {
        Write-Output "The user with UPN '$upn' does not exist in Active Directory."
        return
    }

    if ($user.Enabled -eq $false) {
        Write-Output "The account with UPN '$upn' is already disabled."
        return
    }

    # displays information to verify the correct user
    Write-Output "User: $upn"
    Write-Output "Object Location: $($user.DistinguishedName)"
    Write-Output "Description: $($user.Description)"
    $confirmation = Read-Host -Prompt "Are you sure you want to disable the account with UPN $upn ? (yes/no)"
    if (($confirmation -ne "yes") -and ($confirmation -ne "y")) {
        Write-Output "Action cancelled."
        return
    }

    <# Update the user's description with the termination date and time
    $terminationDescription = "Terminated on $ExecutionDateTime"
    Set-ADUser -Identity $user.DistinguishedName -Description $terminationDescription    
    #>

    Disable-ADAccount -Identity $user.DistinguishedName

    $groups = Get-ADUser -Identity $user.DistinguishedName -Property MemberOf | Select-Object -ExpandProperty MemberOf
    foreach ($group in $groups) {
        Remove-ADGroupMember -Identity $group -Members $user.DistinguishedName -Confirm:$false
    }

    Move-ADObject -Identity $user.DistinguishedName -TargetPath $targetOU

    # Call Clear-Manager with the UPN
    Clear-Manager -upn $upn

    Write-Output "User with UPN $upn has been disabled, removed from all groups, and moved to Marked for Deletion"
    Write-Output "Termination Date and Time: $ExecutionDateTime"
}

# Main loop
do {
    $upn = Read-Host -Prompt 'Enter the UPN of the account to disable'
    Disable-UserAccount -upn $upn -targetOU $targetOU
    $choice = Read-Host -Prompt "Do you want to disable another user? (yes/no)"
} while ($choice -eq "yes" -or $choice -eq "y")
