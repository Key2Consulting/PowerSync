function Unregister-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)

        # Log
        $Ctx.System.Repository.LogVariable($Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1], $Name, $null)

        # Remove the state from the repository
        $Ctx.System.Repository.DeleteState($Name)
    }
    catch {
        throw "Error setting state $Name. $($_.Exception.Message)"
    }
}