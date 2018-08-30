function New-FactoryObject {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Repository,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [hashtable] $ClassType,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $NoLogError
    )

    # Confirm we're connected and initialized
    if (-not $PSYSession -and $PSYSession.Initialized) {
        Write-PSYException "PowerSync is not properly initialized. See Start-PSYMainActivity for more information."
    }

    # Instantial new object based on type
    try {
        if ($Repository) {
            New-Object $PSYSession.RepositoryState.ClassType -ArgumentList $PSYSession.RepositoryState
        }
    }
    catch {
        if (-not $NoLogError) {
            Write-PSYExceptionLog -ErrorRecord $_ -Message "Unable to generate factory object."
        }
    }
}
