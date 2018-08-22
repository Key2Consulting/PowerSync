function Export-PSYOleDb {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $ConnectionName,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $ExtractQuery,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Schema,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Table,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Timeout
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        
    }
    catch {
        Write-PSYExceptionLog $_ "Error in $($MyInvocation.MyCommand)." -Rethrow
    }
}