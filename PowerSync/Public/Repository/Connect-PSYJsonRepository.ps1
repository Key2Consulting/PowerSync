function Connect-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $LockTimeout = 5000
    )

    try {
        # Disconnect if already connected
        Disconnect-PSYRepository

        # Create the instance, passing it our session state. The class should set it's state properties to the session,
        # making the connection available on subsequent requests.
        $repo = New-Object JsonRepository $Path, $LockTimeout, $PSYSession.RepositoryState
        $global:PSYSession.Initialized = $true
    }
    catch {
        Write-PSYExceptionLog $_ "Error connecting to JSON repository."
    }
}