<#
.SYNOPSIS
Registers and imports a PowerShell module into the PowerSync framework.

.DESCRIPTION
This function is only required if parallel execution is performed by the project. Registering the module informs PowerSync to load that module during parallel execution.

.PARAMETER Name
The name of the module to import. See PowerShell's Import-Module for more information.
#>
function Import-PSYModule {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        $PSYSession.UserModules.Add($Name)
        Import-Module -Name $Name
    }
    catch {
        Write-PSYErrorLog $_ "Error importing module '$Name'."
    }
}