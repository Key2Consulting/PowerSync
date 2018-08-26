function Disconnect-PSYRepository {
    try {
        $global:PSYSessionRepository = $null
        $global:PSYSessionState.System.Initialized = $false
    }
    catch {
        Write-PSYExceptionLog $_ "Error disconnecting to repository."
    }
}