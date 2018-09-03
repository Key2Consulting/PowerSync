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
        $fullPath = Resolve-Path -Path $Path
        $repo = New-Object JsonRepository $fullPath, $LockTimeout, $PSYSession.RepositoryState
        $global:PSYSession.Initialized = $true
    }
    catch {
        Write-PSYErrorLog $_ "Error connecting to JSON repository."
    }
}