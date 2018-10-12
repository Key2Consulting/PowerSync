function Export-PSYOleDb {
    param
    (
        [Parameter(Mandatory = $true)]
        [object] $Connection,
        [Parameter(Mandatory = $false)]
        [object] $ExtractQuery,
        [Parameter(Mandatory = $false)]
        [string] $Schema,
        [Parameter(Mandatory = $false)]
        [string] $Table,
        [Parameter(Mandatory = $false)]
        [int] $Timeout
    )

    try {
        throw "Not implemented"
    }
    catch {
        Write-PSYErrorLog $_
    }
}