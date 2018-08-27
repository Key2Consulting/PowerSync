function Disconnect-PSYRepository {
    try {
        $global:PSYSession.RepositoryState = @{}
        $global:PSYSession.Initialized = $false
    }
    catch {
        Write-PSYExceptionLog $_ "Error disconnecting to repository."
    }
}