function Set-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [object] $Data
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)

        # Log
        $Ctx.System.Repository.LogVariable($Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1], $Name, $Data)

        # Update the state in the repository
        $Ctx.System.Repository.SaveState($Name, $Data)
    }
    catch {
        throw "Error setting state $Name. $($_.Exception.Message)"
    }
}