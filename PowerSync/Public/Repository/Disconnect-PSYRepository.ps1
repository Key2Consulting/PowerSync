function Disconnect-PSYRepository {
    try {
        $global:PSYSession.RepositoryState = @{}
        $global:PSYSession.Initialized = $false
    }
    catch {
        Write-PSYErrorLog $_ "Error disconnecting to repository."
    }
}