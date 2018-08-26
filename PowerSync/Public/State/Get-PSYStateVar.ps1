function Get-PSYStateVar {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        # Validation
        Confirm-PSYInitialized

        # Load the state from the repository
        $x = $PSYSessionRepository.GetState($Name)
        return $PSYSessionRepository.GetState($Name)
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting state '$Name'."
    }
}