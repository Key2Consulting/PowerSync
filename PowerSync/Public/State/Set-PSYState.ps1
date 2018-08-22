function Set-PSYState {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Type = 'DiscreteState',
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $CustomType
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)

        # Log
        Write-PSYVariableLog $Name $Value

        # Set the state in the repository.  If it doesn't exist, it will be created.
        $Ctx.System.Repository.SetState($Name, $Value, $Type, $CustomType)
    }
    catch {
        Write-PSYExceptionLog $_ "Error setting state '$Name'." -Rethrow
    }
}