function Get-PSYStateVar {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository

        # Load the state from the repository
        $x = $repo.GetState($Name)
        return $repo.GetState($Name)
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting state '$Name'."
    }
}