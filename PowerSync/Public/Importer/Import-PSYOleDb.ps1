function Import-PSYOleDb {
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $Connection,
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