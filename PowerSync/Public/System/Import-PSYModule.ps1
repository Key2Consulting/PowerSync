function Import-PSYModule {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        $PSYSessionState.System.UserModules.Add($Name)
        Import-Module -Name $Name
    }
    catch {
        Write-PSYExceptionLog $_ "Error importing module '$Name'."
    }
}