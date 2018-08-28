function Remove-PSYVariable {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository

        # Log
        $repo.LogVariable($PSYSession.ActivityStack[$PSYSession.ActivityStack.Count - 1], $Name, $null)

        # Remove the state from the repository
        $repo.DeleteState($Name)
    }
    catch {
        Write-PSYExceptionLog $_ "Error removing state '$Name'."
    }
}