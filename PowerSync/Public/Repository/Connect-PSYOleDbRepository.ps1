function Connect-PSYOleDbRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $ConnectionString
    )

    try {

    }
    catch {
        Write-PSYExceptionLog $_ "Error starting activity $Name."
    }
}