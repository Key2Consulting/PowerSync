function New-RepositoryFromFactory {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [hashtable] $RepositoryState
    )

    # Confirm we're connected and initialized
    if (-not $PSYSession -and $PSYSession.Initialized) {
        Write-PSYException "PowerSync is not properly initialized. See Start-PSYMainActivity for more information."
    }

    # If state is explicitly passed in, use it.  Otherwise, default to session state.
    if ($RepositoryState) {
        $repository = New-Object $State.RepositoryState.ClassType -ArgumentList $State.RepositoryState
    }
    else {
        $repository = New-Object $PSYSession.RepositoryState.ClassType -ArgumentList $PSYSession.RepositoryState
    }
    $repository
}
