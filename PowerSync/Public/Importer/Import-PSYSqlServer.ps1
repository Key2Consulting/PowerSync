function Import-PSYSqlServer {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $ConnectionName,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [object] $ImportQuery,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Schema,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $Table,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [int] $Timeout,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Overwrite,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $AutoIndex,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $AutoCreate
    )

    try {
        # Validation
        Confirm-PSYInitialized($Ctx)
        
    }
    catch {
        Write-PSYExceptionLog $_ "Error in Import-PSYSqlServer." -Rethrow
    }
}