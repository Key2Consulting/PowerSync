function New-FactoryObject {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [switch] $Repository,
        [Parameter(Mandatory = $false)]
        [switch] $Connection,
        [Parameter(Mandatory = $false)]
        [string] $TypeName
    )

    # Confirm we're connected and initialized
    if (-not $PSYSession -or -not $PSYSession.Initialized) {
        throw "PowerSync is not properly initialized. See Start-PSYMainActivity for more information."
    }

    # Instantial new object based on type
    try {
        if ($Repository) {
            New-Object $PSYSession.RepositoryState.ClassType -ArgumentList $PSYSession.RepositoryState
        }
        elseif ($Connection) {
            if ($TypeName -eq 'SqlServer') {
                return [System.Data.SqlClient.SqlConnection]::new()
            }
            elseif ($TypeName -eq 'OleDb') {
                return [System.Data.OleDb.OleDbConnection]::new()
            }
            elseif ($TypeName -eq 'ODBC') {
                return [System.Data.Odbc.OdbcConnection]::new()
            }
        }
        else {
            throw "Unable to create object from factory, missing switch."
        }
    }
    catch {
        Write-PSYErrorLog $_
    }
}
