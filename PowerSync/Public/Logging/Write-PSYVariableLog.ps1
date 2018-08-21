function Write-PSYVariableLog {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $Value
    )

    # Validation
    Confirm-PSYInitialized($Ctx)

    # Write Log and output to screen
    $Ctx.System.Repository.LogVariable($Ctx.System.ActivityStack[$Ctx.System.ActivityStack.Count - 1], $Name, $Value)
    
    if ($Ctx.Option.PrintVerbose) {
        Write-Host "Variable: $Name = $Value"
    }
}