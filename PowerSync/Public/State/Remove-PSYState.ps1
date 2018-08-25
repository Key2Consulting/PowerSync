function Remove-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        # Validation
        Confirm-PSYInitialized

        # Log
        $PSYSessionRepository.LogVariable($PSYSessionState.System.ActivityStack[$PSYSessionState.System.ActivityStack.Count - 1], $Name, $null)

        # Remove the state from the repository
        $PSYSessionRepository.DeleteState($Name)
    }
    catch {
        Write-PSYExceptionLog $_ "Error removing state '$Name'."
    }
}