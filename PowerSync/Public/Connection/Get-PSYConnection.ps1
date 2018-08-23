function Get-PSYConnection {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Name
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Get-PSYConnection." -Rethrow
    }
}