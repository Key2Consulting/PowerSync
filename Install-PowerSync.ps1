<#
.DESCRIPTION
Installs PowerSync for all users or only the current user.

IMPORTANT: Before running this script, you must update the Execution Policy to at least RemoteSigned. Otherwise, this script itself cannot run.
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#>
param (
    [Parameter(Mandatory = $false)]
    [switch] $InstallForAllUsers
)

# Ensure PowerSync files are unblocked after downloaded from the Internet.
Get-ChildItem -Path "$PSScriptRoot\PowerSync\" -Recurse | Unblock-File

# Install for all usres under $PSHome or current user under $HOME, depending on InstallForAllUsers switch.
if ($InstallForAllUsers) {
    $installPath = "$PSHome\Modules\PowerSync\"

    # Installing for all users requires administrator privileges, so verify before continuing.
    $currentPrincipal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw 'Install-PowerSync for all users must run as an administrator.'
    }
}
else {
    $installPath = "$HOME\Documents\WindowsPowerShell\Modules\PowerSync\"
}

Write-Host "Installing PowerSync to $installPath"
Remove-Item -Path $installPath -Force -Confirm:$false -Recurse -ErrorAction SilentlyContinue
Copy-Item -Path '.\PowerSync\' -Destination $installPath -Force -Recurse