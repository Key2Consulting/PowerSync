function Connect-PSYOleDbRepository {
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $ConnectionString,
        
        [Parameter(Mandatory = $false)]
        [string] $Schema
    )

    try {
        # Create the instance, passing it our session state. The class should set it's state properties to the session,
        # making the connection available on subsequent requests.
        $repo = New-Object OleDBRepository $ConnectionString, $Schema, $PSYSession.RepositoryState
        $global:PSYSession.Initialized = $true
    }
    catch {
        Write-PSYErrorLog $_
    }
}