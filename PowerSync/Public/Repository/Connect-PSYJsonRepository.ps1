function Connect-PSYJsonRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $LogPath = 'Log.json',
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $ConfigurationPath = 'Configuration.json'
    )

    try {
        New-Object JsonRepository $LogPath, $ConfigurationPath
    }
    catch {
        Write-PSYExceptionLog $_ "Error connecting to JSON repository." -Rethrow
    }
}