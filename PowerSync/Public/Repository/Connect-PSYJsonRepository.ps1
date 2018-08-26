function Connect-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Path
    )

    try {
        $global:PSYSessionRepository = New-Object JsonRepository $Path
        $global:PSYSessionState.System.Initialized = $true
    }
    catch {
        Write-PSYExceptionLog $_ "Error connecting to JSON repository."
    }
}