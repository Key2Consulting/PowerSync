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
        return $Ctx.System.Repository.GetState($Name)
    }
    catch {
        throw "Error getting state $Name. $($_.Exception.Message)"
    }
}