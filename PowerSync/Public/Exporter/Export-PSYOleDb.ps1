function Export-PSYOleDb {
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $true)]
        [string] $Connection,
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
        throw "Not implemented"
    }
    catch {
        Write-PSYErrorLog $_
    }
}