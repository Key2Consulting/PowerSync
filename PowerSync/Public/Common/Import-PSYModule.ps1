<#
.SYNOPSIS
Registers and imports a PowerShell module into the PowerSync framework.

.DESCRIPTION
This function is only required if parallel execution is performed by the project. Registering the module informs PowerSync to load that module during parallel execution.

.PARAMETER Name
The name of the module to import. See PowerShell's Import-Module for more information.

.PARAMETER RegisterOnly
Registers the module with PowerSync, but does not call Import-Module. Useful when PowerSync is loaded as a module dependency of a project.
#>
function Import-PSYModule {
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [switch] $RegisterOnly
    )

    try {
        if (-not $PSYSession.UserModules.Contains($Name)) {
            [void] $PSYSession.UserModules.Add($Name)
            if (-not $RegisterOnly) {
                Import-Module -Name $Name -Global
            }
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}