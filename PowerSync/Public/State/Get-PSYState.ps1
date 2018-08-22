function Get-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)

        # Load the state from the repository
        $x = $Ctx.System.Repository.GetState($Name)
        return $Ctx.System.Repository.GetState($Name)
    }
    catch {
        Write-PSYExceptionLog $_ "Error getting state '$Name'." -Rethrow
    }
}