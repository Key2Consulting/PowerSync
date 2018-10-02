function New-FactoryObject {
    [CmdletBinding()]
    param
    (
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Repository,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [switch] $Connection,
        [Parameter(HelpMessage = "TODO", Mandatory = $false)]
        [string] $TypeName
    )

    # Confirm we're connected and initialized
    if (-not $PSYSession -and $PSYSession.Initialized) {
        Write-PSYException "PowerSync is not properly initialized. See Start-PSYMainActivity for more information."
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
