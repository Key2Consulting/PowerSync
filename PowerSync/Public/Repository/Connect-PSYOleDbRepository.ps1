function Connect-PSYOleDbRepository {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $ConnectionString
    )

    try {

    }
    catch {
        Write-PSYErrorLog $_ "Error starting activity $Name."
    }
}