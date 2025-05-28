# TermAuto
User termination automation. 


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
The target Organizational Unit (OU) where the user account will be moved. Default is $targetOU = "OU HERE" (see line 19)
