function Set-PSYStateVar {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Parent,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $UserType,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Overwrite
    )

    try {
        $repo = New-RepositoryFromFactory       # instantiate repository

        Write-PSYVariableLog $Name $Value       # log

        # Set the state in the repository.  If it doesn't exist, it will be created.
        $repo.SetState($Name, $Value, $UserType)
    }
    catch {
        Write-PSYExceptionLog $_ "Error setting state '$Name'."
    }
}