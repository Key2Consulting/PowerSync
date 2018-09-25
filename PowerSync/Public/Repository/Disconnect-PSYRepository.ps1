<#
.SYNOPSIS
Disconnections from the current PowerSync repository.
#>
function Disconnect-PSYRepository {
    try {
        $global:PSYSession.RepositoryState = @{}
        $global:PSYSession.Initialized = $false
    }
    catch {
        Write-PSYErrorLog $_
    }
}